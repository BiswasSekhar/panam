import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../ai/llm_service.dart';
import '../../data/local/hive_service.dart';

/// Service for AI-powered PDF bank statement analysis
/// 
/// Features:
/// - Detect bank name from statement
/// - Create custom parsers for unknown bank formats
/// - Extract transaction data intelligently
class AIPdfAnalyzer {
  final LLMService _llm = LLMService();
  final HiveService _hive = HiveService();
  
  static const String _parsersKey = 'custom_bank_parsers';

  /// Analyze PDF text and detect bank/format
  Future<BankAnalysisResult> analyzePdfText(String text) async {
    debugPrint('[AIPdfAnalyzer] Analyzing PDF text (${text.length} chars)');
    
    // First try pattern matching for known banks
    final knownBank = _detectKnownBank(text);
    if (knownBank != null) {
      debugPrint('[AIPdfAnalyzer] Detected known bank: $knownBank');
      return BankAnalysisResult(
        bankName: knownBank,
        isKnownFormat: true,
        confidence: 0.95,
        parserType: _getParserType(knownBank),
      );
    }

    // If LLM is available, use it for analysis
    if (_llm.isModelLoaded) {
      try {
        final analysis = await _llm.analyzeBankStatement(extractedText: text);
        
        return BankAnalysisResult(
          bankName: analysis['bank_name'] ?? 'Unknown',
          isKnownFormat: false,
          confidence: 0.7,
          accountType: analysis['account_type'],
          statementPeriod: analysis['statement_period'],
          detectedFormat: analysis['detected_format'],
          sampleTransactions: _parseSampleTxns(analysis['sample_transactions']),
          parsingNotes: analysis['parsing_notes'],
        );
      } catch (e) {
        debugPrint('[AIPdfAnalyzer] LLM analysis failed: $e');
      }
    }

    // Fallback to heuristic detection
    return _heuristicAnalysis(text);
  }

  /// Create a custom parser for a new bank format
  Future<CustomBankParser?> createCustomParser({
    required String bankName,
    required String sampleText,
  }) async {
    if (!_llm.isModelLoaded) {
      debugPrint('[AIPdfAnalyzer] LLM not loaded, cannot create parser');
      return null;
    }

    try {
      final result = await _llm.createBankParser(
        bankName: bankName,
        sampleText: sampleText,
      );

      if (result.containsKey('error')) {
        debugPrint('[AIPdfAnalyzer] Parser creation failed: ${result['error']}');
        return null;
      }

      final parser = CustomBankParser.fromJson(result);
      
      // Save parser
      await _saveCustomParser(parser);
      
      debugPrint('[AIPdfAnalyzer] Created parser for: $bankName');
      return parser;
    } catch (e) {
      debugPrint('[AIPdfAnalyzer] Error creating parser: $e');
      return null;
    }
  }

  /// Get all saved custom parsers
  Future<List<CustomBankParser>> getSavedParsers() async {
    try {
      final data = _hive.settingsBox.get(_parsersKey);
      if (data == null) return [];
      
      final list = jsonDecode(data) as List;
      return list.map((e) => CustomBankParser.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _saveCustomParser(CustomBankParser parser) async {
    final parsers = await getSavedParsers();
    
    // Remove existing parser for same bank
    parsers.removeWhere((p) => p.bankName.toLowerCase() == parser.bankName.toLowerCase());
    parsers.add(parser);
    
    await _hive.settingsBox.put(_parsersKey, jsonEncode(parsers.map((p) => p.toJson()).toList()));
  }

  /// Detect known banks from text patterns
  String? _detectKnownBank(String text) {
    final lower = text.toLowerCase();
    
    final patterns = {
      'HDFC Bank': ['hdfc bank', 'hdfc ltd', 'hdfcbank'],
      'ICICI Bank': ['icici bank', 'icici ltd'],
      'SBI': ['state bank of india', 'sbi ', 'sbicaps'],
      'Axis Bank': ['axis bank', 'axis ltd'],
      'Kotak': ['kotak mahindra', 'kotak bank'],
      'Yes Bank': ['yes bank'],
      'IndusInd Bank': ['indusind bank'],
      'IDFC First': ['idfc first', 'idfc bank'],
      'PNB': ['punjab national bank', 'pnb '],
      'Bank of Baroda': ['bank of baroda', 'bob '],
      'Canara Bank': ['canara bank'],
      'Union Bank': ['union bank of india'],
      'Federal Bank': ['federal bank'],
      'RBL Bank': ['rbl bank'],
      'Paytm Payments Bank': ['paytm payments bank'],
      'Airtel Payments Bank': ['airtel payments bank'],
      'PhonePe': ['phonepe'],
      'Amazon Pay': ['amazon pay'],
      'Google Pay': ['google pay', 'gpay'],
    };

    for (final entry in patterns.entries) {
      for (final pattern in entry.value) {
        if (lower.contains(pattern)) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  String _getParserType(String bankName) {
    // Map known banks to parser types
    final parserMap = {
      'HDFC Bank': 'hdfc_standard',
      'ICICI Bank': 'icici_standard',
      'SBI': 'sbi_standard',
      'Axis Bank': 'axis_standard',
      'Kotak': 'kotak_standard',
    };
    
    return parserMap[bankName] ?? 'generic';
  }

  List<Map<String, dynamic>> _parseSampleTxns(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return List<Map<String, dynamic>>.from(data.map((e) => Map<String, dynamic>.from(e)));
    }
    return [];
  }

  BankAnalysisResult _heuristicAnalysis(String text) {
    // Try to detect format from structure
    String format = 'unknown';
    
    if (text.contains('\t') || RegExp(r'\s{4,}').hasMatch(text)) {
      format = 'table';
    } else if (text.contains(',') && text.split('\n').any((l) => l.split(',').length > 3)) {
      format = 'csv';
    } else {
      format = 'mixed';
    }

    return BankAnalysisResult(
      bankName: 'Unknown Bank',
      isKnownFormat: false,
      confidence: 0.3,
      detectedFormat: format,
      parsingNotes: 'Could not identify bank. Manual configuration may be needed.',
    );
  }
}

/// Result of bank statement analysis
class BankAnalysisResult {
  final String bankName;
  final bool isKnownFormat;
  final double confidence;
  final String? accountType;
  final String? statementPeriod;
  final String? detectedFormat;
  final List<Map<String, dynamic>>? sampleTransactions;
  final String? parsingNotes;
  final String? parserType;

  BankAnalysisResult({
    required this.bankName,
    required this.isKnownFormat,
    required this.confidence,
    this.accountType,
    this.statementPeriod,
    this.detectedFormat,
    this.sampleTransactions,
    this.parsingNotes,
    this.parserType,
  });
}

/// Custom parser configuration for a bank
class CustomBankParser {
  final String bankName;
  final String dateFormat;
  final String? datePosition;
  final String? descriptionPosition;
  final String? amountFormat;
  final String? debitIndicator;
  final String? creditIndicator;
  final String? rowSeparator;
  final int headerLinesToSkip;
  final String? parserRegex;
  final DateTime createdAt;

  CustomBankParser({
    required this.bankName,
    required this.dateFormat,
    this.datePosition,
    this.descriptionPosition,
    this.amountFormat,
    this.debitIndicator,
    this.creditIndicator,
    this.rowSeparator,
    this.headerLinesToSkip = 0,
    this.parserRegex,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory CustomBankParser.fromJson(Map<String, dynamic> json) {
    return CustomBankParser(
      bankName: json['bank_name'] ?? 'Unknown',
      dateFormat: json['date_format'] ?? 'DD/MM/YYYY',
      datePosition: json['date_position'],
      descriptionPosition: json['description_position'],
      amountFormat: json['amount_format'],
      debitIndicator: json['debit_indicator'],
      creditIndicator: json['credit_indicator'],
      rowSeparator: json['row_separator'],
      headerLinesToSkip: json['header_lines_to_skip'] ?? 0,
      parserRegex: json['parser_regex'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bank_name': bankName,
      'date_format': dateFormat,
      'date_position': datePosition,
      'description_position': descriptionPosition,
      'amount_format': amountFormat,
      'debit_indicator': debitIndicator,
      'credit_indicator': creditIndicator,
      'row_separator': rowSeparator,
      'header_lines_to_skip': headerLinesToSkip,
      'parser_regex': parserRegex,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
