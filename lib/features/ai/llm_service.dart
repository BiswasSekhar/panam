import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:fllama/fllama.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service for managing local LLM (Gemma 3 / Phi-2) using fllama
/// 
/// Features:
/// - Transaction categorization from description/narration
/// - Spending predictions and analysis
/// - PDF bank statement parsing and parser creation
/// - Psychological spending insights
/// - Bank detection and data extraction
class LLMService {
  static final LLMService _instance = LLMService._internal();
  factory LLMService() => _instance;
  LLMService._internal();

  // Model state
  bool _isModelLoaded = false;
  bool _isLoading = false;
  String? _modelPath;
  String? _modelContextId;
  StreamSubscription? _tokenStreamSubscription;
  
  // Download management
  CancelToken? _downloadCancelToken;

  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  bool get isDownloading => _downloadCancelToken != null && !_downloadCancelToken!.isCancelled;

  /// Model configuration
  /// Using Gemma 3 1B from unsloth (public, no auth required)
  static const String gemmaModelUrl = 'https://huggingface.co/unsloth/gemma-3-1b-it-GGUF/resolve/main/gemma-3-1b-it-Q4_K_M.gguf';
  static const String gemmaModelFileName = 'gemma-3-1b-it-Q4_K_M.gguf';
  static const int gemmaModelSizeMB = 750; // ~750MB for Q4_K_M
  
  static const String phiModelUrl = 'https://huggingface.co/TheBloke/phi-2-GGUF/resolve/main/phi-2.Q4_K_M.gguf';
  static const String phiModelFileName = 'phi-2.Q4_K_M.gguf';
  static const int phiModelSizeMB = 1706;

  /// Get model file path
  Future<String> getModelPath({bool useGemma = false}) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = useGemma ? gemmaModelFileName : phiModelFileName;
    return '${appDir.path}/models/$fileName';
  }

  /// Check if model file exists
  Future<bool> isModelDownloaded({bool useGemma = false}) async {
    final modelPath = await getModelPath(useGemma: useGemma);
    return File(modelPath).exists();
  }

  /// Check available storage space
  Future<bool> hasEnoughStorage({required int requiredMB}) async {
    try {
      final diskSpace = DiskSpacePlus();
      final freeSpace = await diskSpace.getFreeDiskSpace;
      if (freeSpace == null) {
        debugPrint('[LLMService] Could not determine free space, proceeding anyway');
        return true;
      }
      
      // freeSpace is already in MB
      final hasSpace = freeSpace >= (requiredMB + 500);
      
      debugPrint('[LLMService] Free space: ${freeSpace.toInt()}MB, Required: ${requiredMB}MB + 500MB buffer');
      return hasSpace;
    } catch (e) {
      debugPrint('[LLMService] Error checking storage: $e');
      return true;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    if (_downloadCancelToken != null && !_downloadCancelToken!.isCancelled) {
      debugPrint('[LLMService] Cancelling download...');
      _downloadCancelToken!.cancel('User cancelled download');
      _downloadCancelToken = null;
    }
  }

  /// Download model from HuggingFace
  Future<void> downloadModel({
    bool useGemma = false,
    String? hfToken,
    required Function(double progress) onProgress,
    Function(String error)? onError,
  }) async {
    if (_downloadCancelToken != null && !_downloadCancelToken!.isCancelled) {
      throw Exception('Download already in progress');
    }

    // Note: HF token is now optional since we use public repos
    final modelUrl = useGemma ? gemmaModelUrl : phiModelUrl;
    final modelSizeMB = useGemma ? gemmaModelSizeMB : phiModelSizeMB;
    
    final hasSpace = await hasEnoughStorage(requiredMB: modelSizeMB);
    if (!hasSpace) {
      final error = 'Insufficient storage. Need ${modelSizeMB}MB + 500MB buffer.';
      onError?.call(error);
      throw Exception(error);
    }

    _isLoading = true;
    _downloadCancelToken = CancelToken();
    
    try {
      debugPrint('[LLMService] Starting download: ${useGemma ? "Gemma 3" : "Phi-2"}');
      
      final modelPath = await getModelPath(useGemma: useGemma);
      final modelFile = File(modelPath);
      
      await modelFile.parent.create(recursive: true);
      
      if (await modelFile.exists()) {
        await modelFile.delete();
      }

      final dio = Dio();
      final headers = <String, String>{};
      if (useGemma && hfToken != null) {
        headers['Authorization'] = 'Bearer $hfToken';
      }
      
      int lastLoggedPercent = -1;
      
      await dio.download(
        modelUrl,
        modelPath,
        cancelToken: _downloadCancelToken,
        options: Options(headers: headers),
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = received / total;
            final percent = (progress * 100).toInt();
            
            if (percent ~/ 10 > lastLoggedPercent ~/ 10) {
              debugPrint('[LLMService] Download: $percent%');
              lastLoggedPercent = percent;
            }
            
            onProgress(progress);
          }
        },
      );
      
      final fileSize = await modelFile.length();
      final fileSizeMB = fileSize ~/ (1024 * 1024);
      
      if (fileSizeMB < modelSizeMB ~/ 2) {
        await modelFile.delete();
        throw Exception('Download incomplete: ${fileSizeMB}MB (expected ~${modelSizeMB}MB)');
      }

      _modelPath = modelPath;
      _isLoading = false;
      _downloadCancelToken = null;
      
      debugPrint('[LLMService] Download complete: ${fileSizeMB}MB');
    } on DioException catch (e) {
      _isLoading = false;
      _downloadCancelToken = null;
      
      String errorMsg = e.type == DioExceptionType.cancel 
          ? 'Download cancelled' 
          : e.message ?? 'Download failed';
      
      debugPrint('[LLMService] Download error: $errorMsg');
      onError?.call(errorMsg);
      rethrow;
    } catch (e) {
      _isLoading = false;
      _downloadCancelToken = null;
      onError?.call(e.toString());
      rethrow;
    }
  }

  /// Load model into memory using fllama
  Future<void> loadModel({bool useGemma = false}) async {
    if (_isModelLoaded) return;
    
    final modelPath = await getModelPath(useGemma: useGemma);
    if (!await File(modelPath).exists()) {
      throw Exception('Model not found. Download it first.');
    }

    _isLoading = true;
    
    try {
      debugPrint('[LLMService] Loading model from: $modelPath');
      
      // Initialize fllama context
      final context = await Fllama.instance()?.initContext(
        modelPath,
        emitLoadProgress: true,
      );
      
      if (context != null && context['contextId'] != null) {
        _modelContextId = context['contextId'].toString();
        _modelPath = modelPath;
        _isModelLoaded = true;
        
        // Setup token stream listener
        _setupTokenStream();
        
        debugPrint('[LLMService] Model loaded! Context ID: $_modelContextId');
      } else {
        throw Exception('Failed to initialize model context');
      }
      
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      debugPrint('[LLMService] Load error: $e');
      rethrow;
    }
  }

  void _setupTokenStream() {
    _tokenStreamSubscription?.cancel();
    _tokenStreamSubscription = Fllama.instance()?.onTokenStream?.listen((data) {
      if (data['function'] == 'loadProgress') {
        debugPrint('[LLMService] Load progress: ${data['result']}');
      }
    });
  }

  /// Unload model
  Future<void> unloadModel() async {
    if (_modelContextId != null) {
      await Fllama.instance()?.releaseContext(double.parse(_modelContextId!));
      _modelContextId = null;
    }
    _tokenStreamSubscription?.cancel();
    _isModelLoaded = false;
    debugPrint('[LLMService] Model unloaded');
  }

  /// Generate text using fllama
  Future<String> generate({
    required String prompt,
    int maxTokens = 512,
    double temperature = 0.7,
  }) async {
    if (!_isModelLoaded || _modelContextId == null) {
      throw Exception('Model not loaded');
    }

    final completer = Completer<String>();
    final buffer = StringBuffer();
    StreamSubscription? sub;
    
    sub = Fllama.instance()?.onTokenStream?.listen((data) {
      if (data['function'] == 'completion') {
        final token = data['result']?['token'] ?? '';
        buffer.write(token);
        
        // Check for stop conditions
        if (data['result']?['stop'] == true || buffer.length > maxTokens * 4) {
          sub?.cancel();
          if (!completer.isCompleted) {
            completer.complete(buffer.toString().trim());
          }
        }
      }
    });

    try {
      await Fllama.instance()?.completion(
        double.parse(_modelContextId!),
        prompt: prompt,
        nPredict: maxTokens,
        temperature: temperature,
        topP: 0.9,
        stop: ['<end_of_turn>', '</s>', '\n\n\n'],
        emitRealtimeCompletion: true,
      );
      
      // Wait with timeout
      return await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          sub?.cancel();
          return buffer.toString().trim();
        },
      );
    } catch (e) {
      sub?.cancel();
      debugPrint('[LLMService] Generate error: $e');
      rethrow;
    }
  }

  // ============================================================================
  // TRANSACTION CATEGORIZATION
  // ============================================================================

  /// Categorize a transaction based on description and narration
  Future<Map<String, dynamic>> categorizeTransaction({
    required String description,
    String? narration,
    required double amount,
    required bool isIncome,
    required List<String> availableCategories,
  }) async {
    final prompt = '''<start_of_turn>user
You are a financial assistant. Categorize this transaction.

Description: $description
${narration != null && narration.isNotEmpty ? 'Narration: $narration' : ''}
Amount: ₹${amount.toStringAsFixed(2)}
Type: ${isIncome ? 'Income' : 'Expense'}

Categories: ${availableCategories.join(', ')}

Respond ONLY with JSON:
{"category": "CategoryName", "confidence": 0.95, "reasoning": "brief reason"}
<end_of_turn>
<start_of_turn>model
''';

    try {
      final response = await generate(prompt: prompt, maxTokens: 128, temperature: 0.3);
      return _parseJsonResponse(response) ?? {
        'category': _fallbackCategorize(description, narration, isIncome, availableCategories),
        'confidence': 0.5,
        'reasoning': 'Pattern matching fallback',
      };
    } catch (e) {
      return {
        'category': _fallbackCategorize(description, narration, isIncome, availableCategories),
        'confidence': 0.5,
        'reasoning': 'Error: $e',
      };
    }
  }

  String _fallbackCategorize(String desc, String? narration, bool isIncome, List<String> categories) {
    final text = '${desc.toLowerCase()} ${narration?.toLowerCase() ?? ''}';
    
    final patterns = {
      'Food': ['food', 'restaurant', 'cafe', 'swiggy', 'zomato', 'uber eats', 'domino', 'mcdonald', 'kfc', 'pizza'],
      'Transport': ['uber', 'ola', 'rapido', 'metro', 'petrol', 'fuel', 'parking', 'toll'],
      'Shopping': ['amazon', 'flipkart', 'myntra', 'mall', 'store', 'shop', 'mart'],
      'Entertainment': ['netflix', 'spotify', 'prime', 'movie', 'game', 'play'],
      'Bills': ['electricity', 'water', 'gas', 'internet', 'mobile', 'recharge', 'bill'],
      'Healthcare': ['pharmacy', 'hospital', 'doctor', 'medical', 'medicine', 'health'],
      'Groceries': ['grocery', 'vegetables', 'bigbasket', 'dmart', 'supermarket'],
      'Salary': ['salary', 'payroll', 'income', 'stipend'],
      'Transfer': ['transfer', 'neft', 'imps', 'upi'],
    };
    
    for (final entry in patterns.entries) {
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          if (categories.any((c) => c.toLowerCase().contains(entry.key.toLowerCase()))) {
            return categories.firstWhere((c) => c.toLowerCase().contains(entry.key.toLowerCase()));
          }
          return entry.key;
        }
      }
    }
    
    return isIncome ? 'Other Income' : 'Other';
  }

  // ============================================================================
  // SPENDING PREDICTIONS
  // ============================================================================

  /// Predict future spending based on historical data
  Future<Map<String, dynamic>> predictSpending({
    required List<Map<String, dynamic>> monthlyData,
    required int monthsToPredict,
  }) async {
    final dataStr = monthlyData.map((d) => 
      '${d['month']}: ₹${d['amount']} (${d['count']} txns)'
    ).join('\n');

    final prompt = '''<start_of_turn>user
Analyze spending patterns and predict next $monthsToPredict month(s).

Historical Data:
$dataStr

Respond ONLY with JSON:
{
  "predicted_amount": 15000.00,
  "trend": "increasing/decreasing/stable",
  "confidence": 0.85,
  "factors": ["factor1", "factor2"],
  "reasoning": "analysis"
}
<end_of_turn>
<start_of_turn>model
''';

    try {
      final response = await generate(prompt: prompt, maxTokens: 256, temperature: 0.5);
      return _parseJsonResponse(response) ?? _fallbackPrediction(monthlyData);
    } catch (e) {
      return _fallbackPrediction(monthlyData);
    }
  }

  Map<String, dynamic> _fallbackPrediction(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return {'predicted_amount': 0, 'trend': 'unknown', 'confidence': 0};
    }
    final amounts = data.map((d) => (d['amount'] as num).toDouble()).toList();
    final avg = amounts.reduce((a, b) => a + b) / amounts.length;
    return {
      'predicted_amount': avg,
      'trend': 'stable',
      'confidence': 0.6,
      'factors': ['Based on average'],
      'reasoning': 'Statistical average of past months',
    };
  }

  // ============================================================================
  // PDF BANK STATEMENT ANALYSIS
  // ============================================================================

  /// Analyze PDF text to extract bank info and transactions
  Future<Map<String, dynamic>> analyzeBankStatement({
    required String extractedText,
  }) async {
    final prompt = '''<start_of_turn>user
Analyze this bank statement text and extract information.

Text:
${extractedText.substring(0, extractedText.length.clamp(0, 2000))}

Respond ONLY with JSON:
{
  "bank_name": "detected bank name or null",
  "account_type": "savings/current/credit",
  "statement_period": "date range if found",
  "detected_format": "table/list/mixed",
  "sample_transactions": [
    {"date": "YYYY-MM-DD", "description": "text", "amount": 1234.56, "type": "debit/credit"}
  ],
  "parsing_notes": "any issues or recommendations"
}
<end_of_turn>
<start_of_turn>model
''';

    try {
      final response = await generate(prompt: prompt, maxTokens: 512, temperature: 0.3);
      return _parseJsonResponse(response) ?? {'error': 'Could not parse statement'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Create a custom parser pattern for a new bank format
  Future<Map<String, dynamic>> createBankParser({
    required String bankName,
    required String sampleText,
  }) async {
    final prompt = '''<start_of_turn>user
Create a parsing pattern for this bank statement format.

Bank: $bankName
Sample:
${sampleText.substring(0, sampleText.length.clamp(0, 1500))}

Respond ONLY with JSON:
{
  "bank_name": "$bankName",
  "date_format": "DD/MM/YYYY or similar",
  "date_position": "column number or regex pattern",
  "description_position": "column or pattern",
  "amount_format": "number format used",
  "debit_indicator": "DR/D/-/etc",
  "credit_indicator": "CR/C/+/etc",
  "row_separator": "line/comma/tab",
  "header_lines_to_skip": 2,
  "parser_regex": "optional regex pattern",
  "example_parsed": [{"date": "", "desc": "", "amount": 0, "type": ""}]
}
<end_of_turn>
<start_of_turn>model
''';

    try {
      final response = await generate(prompt: prompt, maxTokens: 512, temperature: 0.3);
      return _parseJsonResponse(response) ?? {'error': 'Could not create parser'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ============================================================================
  // PSYCHOLOGICAL SPENDING INSIGHTS
  // ============================================================================

  /// Generate psychological insights about spending behavior
  Future<Map<String, dynamic>> analyzeSpendingBehavior({
    required List<Map<String, dynamic>> transactions,
    required Map<String, double> categoryTotals,
    required double monthlyIncome,
  }) async {
    final topCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final categoryStr = topCategories.take(5).map((e) => 
      '${e.key}: ₹${e.value.toStringAsFixed(0)}'
    ).join('\n');

    final prompt = '''<start_of_turn>user
Analyze this person's spending behavior and provide psychological insights.

Monthly Income: ₹${monthlyIncome.toStringAsFixed(0)}
Total Transactions: ${transactions.length}

Top Spending Categories:
$categoryStr

Provide insights about:
1. Spending patterns (impulse vs planned)
2. Financial health indicators
3. Areas of concern
4. Positive habits
5. Recommendations

Respond ONLY with JSON:
{
  "spending_personality": "type (saver/spender/balanced)",
  "impulse_score": 0.0-1.0,
  "financial_health": "good/moderate/needs_attention",
  "key_insights": ["insight1", "insight2"],
  "concerns": ["concern1"],
  "positive_habits": ["habit1"],
  "recommendations": ["rec1", "rec2"],
  "savings_potential": 5000.00,
  "summary": "brief overall assessment"
}
<end_of_turn>
<start_of_turn>model
''';

    try {
      final response = await generate(prompt: prompt, maxTokens: 512, temperature: 0.6);
      return _parseJsonResponse(response) ?? _fallbackBehaviorAnalysis(categoryTotals, monthlyIncome);
    } catch (e) {
      return _fallbackBehaviorAnalysis(categoryTotals, monthlyIncome);
    }
  }

  Map<String, dynamic> _fallbackBehaviorAnalysis(Map<String, double> categories, double income) {
    final total = categories.values.fold(0.0, (a, b) => a + b);
    final savingsRate = income > 0 ? (income - total) / income : 0;
    
    return {
      'spending_personality': savingsRate > 0.3 ? 'saver' : savingsRate > 0.1 ? 'balanced' : 'spender',
      'impulse_score': 0.5,
      'financial_health': savingsRate > 0.2 ? 'good' : 'moderate',
      'key_insights': ['Based on category distribution'],
      'concerns': total > income ? ['Spending exceeds income'] : [],
      'positive_habits': savingsRate > 0.2 ? ['Good savings rate'] : [],
      'recommendations': ['Track daily expenses', 'Set budget limits'],
      'savings_potential': (income - total).clamp(0, double.infinity),
      'summary': 'Analysis based on spending patterns',
    };
  }

  // ============================================================================
  // RECURRING TRANSACTION DETECTION
  // ============================================================================

  /// Detect recurring transaction patterns
  Future<List<Map<String, dynamic>>> detectRecurringPatterns({
    required List<Map<String, dynamic>> transactions,
  }) async {
    final recentTxns = transactions.take(30).map((t) => 
      '${t['date']}: ${t['description']} - ₹${t['amount']}'
    ).join('\n');

    final prompt = '''<start_of_turn>user
Identify recurring transactions (subscriptions, bills, salary).

Recent Transactions:
$recentTxns

Respond ONLY with JSON array:
[
  {
    "description": "Netflix",
    "amount": 199,
    "frequency": "monthly/weekly/yearly",
    "confidence": 0.95,
    "type": "subscription/bill/income",
    "next_expected": "YYYY-MM-DD"
  }
]
<end_of_turn>
<start_of_turn>model
''';

    try {
      final response = await generate(prompt: prompt, maxTokens: 512, temperature: 0.4);
      final parsed = _parseJsonResponse(response);
      if (parsed != null && parsed.containsKey('list')) {
        final list = parsed['list'];
        if (list is List) {
          return List<Map<String, dynamic>>.from(list.map((e) => Map<String, dynamic>.from(e as Map)));
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // ============================================================================
  // HELPERS
  // ============================================================================

  Map<String, dynamic>? _parseJsonResponse(String response) {
    try {
      // Find JSON in response
      final jsonMatch = RegExp(r'\{[\s\S]*\}|\[[\s\S]*\]').firstMatch(response);
      if (jsonMatch != null) {
        final decoded = jsonDecode(jsonMatch.group(0)!);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        } else if (decoded is List) {
          return {'list': decoded};
        }
      }
    } catch (e) {
      debugPrint('[LLMService] JSON parse error: $e');
    }
    return null;
  }

  /// Delete model file
  Future<bool> deleteModel({bool useGemma = false}) async {
    try {
      cancelDownload();
      if (_isModelLoaded) await unloadModel();
      
      final modelPath = await getModelPath(useGemma: useGemma);
      final modelFile = File(modelPath);
      
      if (await modelFile.exists()) {
        await modelFile.delete();
        _modelPath = null;
        debugPrint('[LLMService] Model deleted');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[LLMService] Delete error: $e');
      return false;
    }
  }

  /// Get model file size
  Future<int?> getModelSize({bool useGemma = false}) async {
    try {
      final modelPath = await getModelPath(useGemma: useGemma);
      final modelFile = File(modelPath);
      if (await modelFile.exists()) {
        return await modelFile.length();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
