# Integrating Gemma 3 270M for AI-Powered Expense Tracking

This guide explains how to integrate the Gemma 3 270M LLM (292MB) into the Panam expense tracker for real AI capabilities.

## 🎯 What Gemma 3 270M Will Power

1. **Smart Categorization**: Understand transaction descriptions in natural language
2. **Spending Prediction**: Mathematical reasoning for future expense forecasting
3. **Recurrence Detection**: Intelligent pattern recognition for recurring bills
4. **PDF/Statement Parsing**: Extract structured data from bank statements
5. **Financial Insights**: Natural language analysis of spending habits

## 📦 Required Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  # Choose ONE of these LLM packages:
  
  # Option 1: LLama.cpp bindings (Recommended)
  llama_cpp_dart: ^0.2.0
  
  # Option 2: Flutter LLama
  # flutter_llama: ^0.1.0
  
  # Option 3: ONNX Runtime (Alternative)
  # onnxruntime: ^1.16.0
  
  # Required utilities
  http: ^1.1.0
  path_provider: ^2.1.0
```

## 🔽 Getting Gemma 3 270M

### Model Specifications
- **Model**: Gemma 3 270M Instruct (Quantized)
- **Format**: GGUF (Q4_K_M quantization)
- **Size**: ~292MB
- **Context**: 32K tokens
- **Perfect for**: On-device inference on mobile

### Download Options

#### Option 1: HuggingFace (Recommended)
```bash
# Download from HuggingFace
wget https://huggingface.co/google/gemma-3-270m-it-gguf/resolve/main/gemma-3-270m-it-q4_k_m.gguf

# Or use HuggingFace CLI
huggingface-cli download google/gemma-3-270m-it-gguf gemma-3-270m-it-q4_k_m.gguf
```

#### Option 2: In-App Download
Implement automatic download in `AISettingsProvider.downloadLocalLLM()`:

```dart
import 'package:http/http.dart' as http;
import 'dart:io';

Future<void> downloadModel() async {
  const modelUrl = 'https://huggingface.co/google/gemma-3-270m-it-gguf/resolve/main/gemma-3-270m-it-q4_k_m.gguf';
  final modelPath = await LLMService().getModelPath();
  final modelFile = File(modelPath);
  
  await modelFile.parent.create(recursive: true);
  
  final request = http.Request('GET', Uri.parse(modelUrl));
  final response = await request.send();
  
  final contentLength = response.contentLength ?? 0;
  int bytesReceived = 0;
  
  final sink = modelFile.openWrite();
  
  await for (final chunk in response.stream) {
    sink.add(chunk);
    bytesReceived += chunk.length;
    final progress = bytesReceived / contentLength;
    onProgress(progress); // Update UI
  }
  
  await sink.close();
}
```

## 🚀 Implementation Steps

### Step 1: Install llama.cpp Dart bindings

```bash
flutter pub add llama_cpp_dart
flutter pub add path_provider
flutter pub add http
```

### Step 2: Update LLMService with Real Implementation

Replace the TODO sections in `lib/features/ai/llm_service.dart`:

```dart
import 'package:llama_cpp_dart/llama_cpp_dart.dart';

class LLMService {
  LlamaCpp? _model;
  LlamaContext? _context;
  
  Future<void> loadModel() async {
    final modelPath = await getModelPath();
    
    _model = await LlamaCpp.create(
      modelPath: modelPath,
      params: LlamaParams(
        contextSize: 2048,      // Use 2K context for efficiency
        batchSize: 512,
        threads: 4,             // Adjust based on device
        gpuLayers: 0,           // CPU only for mobile
      ),
    );
    
    _context = _model!.createContext();
    _isModelLoaded = true;
  }
  
  Future<String> generate({
    required String prompt,
    int maxTokens = 256,
    double temperature = 0.7,
  }) async {
    final completion = await _context!.complete(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: temperature,
      topP: 0.9,
      stopTokens: ['</s>', '<end_of_turn>'],
    );
    
    return completion.text;
  }
}
```

### Step 3: Update Smart Categorizer to Use Real LLM

```dart
// lib/features/ai/smart_categorizer.dart
import 'llm_service.dart';

class SmartCategorizer {
  static Future<String?> categorizeTransaction({
    required String description,
    String? narration,
    required List<Category> availableCategories,
    required bool isIncome,
  }) async {
    final llm = LLMService();
    
    if (!llm.isModelLoaded) {
      // Fallback to pattern matching
      return _patternBasedCategorization(...);
    }
    
    final result = await llm.categorizeTransaction(
      description: description,
      narration: narration,
      amount: 0,
      isIncome: isIncome,
      availableCategories: availableCategories.map((c) => c.name).toList(),
    );
    
    // Find category by name
    final categoryName = result['category'];
    return availableCategories
        .firstWhere((c) => c.name == categoryName, orElse: () => null)
        ?.id;
  }
}
```

### Step 4: Enhanced Spending Predictor with LLM Reasoning

```dart
// lib/features/ai/spending_predictor.dart
static Future<SpendingPrediction?> predictNextMonthWithLLM(
  List<Transaction> transactions,
) async {
  final llm = LLMService();
  
  if (!llm.isModelLoaded) {
    // Fallback to statistical method
    return predictNextMonth(transactions);
  }
  
  final monthlyData = _aggregateMonthlySpending(transactions);
  final historicalData = monthlyData.map((m) => {
    'month': m.monthYear,
    'amount': m.totalSpending,
    'count': m.transactionCount,
  }).toList();
  
  final result = await llm.predictSpending(
    historicalData: historicalData,
    monthsToPredict: 1,
  );
  
  return SpendingPrediction(
    predictedAmount: result['predicted_amount'],
    confidence: result['confidence'],
    trend: result['trend'],
    percentageChange: 0, // Calculate from data
    categoryPredictions: {},
    explanation: result['reasoning'],
  );
}
```

### Step 5: LLM-Powered PDF Extraction

```dart
// lib/features/import/pdf_extractor.dart
import '../ai/llm_service.dart';

class PDFExtractor {
  static Future<List<Transaction>> extractFromPDF(File pdfFile) async {
    // Extract text from PDF using pdf package
    final pdfText = await PdfText.extract(pdfFile);
    
    // Use LLM to structure the data
    final llm = LLMService();
    final transactions = await llm.extractTransactionsFromText(
      text: pdfText,
    );
    
    // Convert to Transaction objects
    return transactions.map((t) => Transaction(
      id: Uuid().v4(),
      amount: t['amount'],
      description: t['description'],
      date: DateTime.parse(t['date']),
      type: t['type'] == 'credit' 
          ? TransactionType.income 
          : TransactionType.expense,
      // ... other fields
    )).toList();
  }
}
```

## 🎨 Updated Settings UI

The settings already include the download UI. Just update `AISettingsProvider.downloadLocalLLM()`:

```dart
Future<void> downloadLocalLLM() async {
  final llm = LLMService();
  
  await llm.downloadModel(
    onProgress: (progress) {
      _downloadProgress = progress * 100;
      notifyListeners();
    },
  );
  
  // Auto-load after download
  await llm.loadModel();
  
  _localLLMDownloaded = true;
  _localLLMEnabled = true;
  await _hive.settingsBox.put(_localLLMDownloadedKey, 'true');
  await _hive.settingsBox.put(_localLLMEnabledKey, 'true');
  notifyListeners();
}
```

## 📊 Prompting Best Practices for Gemma 3

### Gemma 3 Prompt Format
```
<start_of_turn>user
Your instruction here
<end_of_turn>
<start_of_turn>model
Model's response
<end_of_turn>
```

### Example Prompts

#### Categorization
```
<start_of_turn>user
Categorize: "Swiggy Order - Biryani"
Amount: ₹299
Categories: Food, Transport, Shopping
<end_of_turn>
<start_of_turn>model
Category: Food
Confidence: 0.95
Reasoning: Swiggy is a food delivery service
<end_of_turn>
```

#### Spending Prediction
```
<start_of_turn>user
Past 3 months spending: ₹12000, ₹13500, ₹12800
Predict next month considering trend.
<end_of_turn>
<start_of_turn>model
Predicted: ₹13100
Trend: Slight increase
Confidence: 0.82
Factors: Steady upward trend, no major spikes
<end_of_turn>
```

## 🔧 Performance Optimization

### Memory Management
```dart
// Load model only when needed
if (needsLLM && !LLMService().isModelLoaded) {
  await LLMService().loadModel();
}

// Unload when app goes to background
class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      LLMService().unloadModel();
    }
  }
}
```

### Batching Requests
```dart
// Categorize multiple transactions at once
Future<List<String?>> batchCategorize(List<Transaction> txns) async {
  final prompt = '''
  Categorize these transactions:
  ${txns.map((t) => '${t.description} - ₹${t.amount}').join('\n')}
  ''';
  
  final response = await llm.generate(prompt: prompt);
  return parseCategories(response);
}
```

## 📱 Device Requirements

- **RAM**: 2GB+ (4GB recommended)
- **Storage**: 500MB free (for model + cache)
- **CPU**: ARM64 or x86_64
- **OS**: Android 7.0+ / iOS 13.0+

## 🎯 Feature Roadmap

- [x] Pattern-based categorization (current)
- [ ] LLM-based categorization (with Gemma 3)
- [ ] LLM-powered spending prediction
- [ ] Intelligent recurrence detection
- [ ] PDF/Statement parsing
- [ ] Natural language queries ("How much did I spend on food last month?")
- [ ] Budget recommendations
- [ ] Anomaly detection

## 🔐 Privacy & Security

- ✅ **100% On-Device**: No data sent to cloud
- ✅ **Offline-First**: Works without internet
- ✅ **No Telemetry**: Model doesn't phone home
- ✅ **User Control**: Optional download and disable anytime

## 📚 Resources

- [Gemma 3 Model Card](https://ai.google.dev/gemma)
- [llama.cpp Documentation](https://github.com/ggerganov/llama.cpp)
- [GGUF Format Spec](https://github.com/ggerganov/ggml/blob/master/docs/gguf.md)
- [Flutter LLM Integration](https://pub.dev/packages/llama_cpp_dart)
