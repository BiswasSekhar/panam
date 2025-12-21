import 'package:flutter/foundation.dart';
import '../data/local/hive_service.dart';
import '../features/ai/llm_service.dart';

/// Provider for managing AI/ML feature settings
class AISettingsProvider extends ChangeNotifier {
  static const String _aiEnabledKey = 'ai_enabled';
  static const String _predictionsEnabledKey = 'predictions_enabled';
  static const String _smartCategorizationKey = 'smart_categorization_enabled';
  static const String _localLLMDownloadedKey = 'local_llm_downloaded';
  static const String _localLLMEnabledKey = 'local_llm_enabled';
  static const String _useGemmaKey = 'use_gemma_model';
  static const String _hfTokenKey = 'hf_token';

  final HiveService _hive = HiveService();

  // AI Master switch
  bool _aiEnabled = false;
  bool get aiEnabled => _aiEnabled;

  // Spending predictions
  bool _predictionsEnabled = true;
  bool get predictionsEnabled => _predictionsEnabled && _aiEnabled;

  // Smart categorization (keyword-based)
  bool _smartCategorizationEnabled = true;
  bool get smartCategorizationEnabled => _smartCategorizationEnabled && _aiEnabled;

  // Local LLM
  bool _localLLMDownloaded = false;
  bool get localLLMDownloaded => _localLLMDownloaded;

  bool _localLLMEnabled = false;
  bool get localLLMEnabled => _localLLMEnabled && _localLLMDownloaded && _aiEnabled;

  // Model selection
  bool _useGemma = false;
  bool get useGemma => _useGemma;

  // HuggingFace token (encrypted in production)
  String? _hfToken;
  String? get hfToken => _hfToken;
  bool get hasHfToken => _hfToken != null && _hfToken!.isNotEmpty;

  // Download state
  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;

  bool _isDownloading = false;
  bool get isDownloading => _isDownloading;

  String? _downloadError;
  String? get downloadError => _downloadError;

  bool _isCancelling = false;
  bool get isCancelling => _isCancelling;

  AISettingsProvider() {
    _loadSettings();
    _checkModelStatus();
  }

  bool _getBool(String key, {bool defaultValue = false}) {
    final value = _hive.settingsBox.get(key);
    if (value == null) return defaultValue;
    return value == 'true';
  }

  String? _getString(String key) {
    return _hive.settingsBox.get(key);
  }

  void _loadSettings() {
    _aiEnabled = _getBool(_aiEnabledKey, defaultValue: false);
    _predictionsEnabled = _getBool(_predictionsEnabledKey, defaultValue: true);
    _smartCategorizationEnabled = _getBool(_smartCategorizationKey, defaultValue: true);
    _localLLMDownloaded = _getBool(_localLLMDownloadedKey, defaultValue: false);
    _localLLMEnabled = _getBool(_localLLMEnabledKey, defaultValue: false);
    _useGemma = _getBool(_useGemmaKey, defaultValue: false);
    _hfToken = _getString(_hfTokenKey);
    notifyListeners();
  }

  /// Check if model file actually exists on disk
  Future<void> _checkModelStatus() async {
    final exists = await LLMService().isModelDownloaded(useGemma: _useGemma);
    if (_localLLMDownloaded != exists) {
      _localLLMDownloaded = exists;
      await _hive.settingsBox.put(_localLLMDownloadedKey, exists.toString());
      notifyListeners();
    }
  }

  Future<void> setAIEnabled(bool enabled) async {
    _aiEnabled = enabled;
    await _hive.settingsBox.put(_aiEnabledKey, enabled.toString());
    notifyListeners();
  }

  Future<void> setPredictionsEnabled(bool enabled) async {
    _predictionsEnabled = enabled;
    await _hive.settingsBox.put(_predictionsEnabledKey, enabled.toString());
    notifyListeners();
  }

  Future<void> setSmartCategorizationEnabled(bool enabled) async {
    _smartCategorizationEnabled = enabled;
    await _hive.settingsBox.put(_smartCategorizationKey, enabled.toString());
    notifyListeners();
  }

  Future<void> setLocalLLMEnabled(bool enabled) async {
    _localLLMEnabled = enabled;
    await _hive.settingsBox.put(_localLLMEnabledKey, enabled.toString());
    notifyListeners();
  }

  /// Set which model to use (Gemma vs Phi-2)
  Future<void> setUseGemma(bool useGemma) async {
    _useGemma = useGemma;
    await _hive.settingsBox.put(_useGemmaKey, useGemma.toString());
    
    // Re-check if model is downloaded
    await _checkModelStatus();
    notifyListeners();
  }

  /// Set HuggingFace API token
  /// WARNING: In production, encrypt this token!
  Future<void> setHfToken(String? token) async {
    _hfToken = token;
    if (token != null && token.isNotEmpty) {
      await _hive.settingsBox.put(_hfTokenKey, token);
    } else {
      await _hive.settingsBox.delete(_hfTokenKey);
    }
    notifyListeners();
  }

  /// Download local LLM model
  Future<void> downloadLocalLLM() async {
    if (_isDownloading) return;

    // Validate requirements
    if (_useGemma && !hasHfToken) {
      _downloadError = 'HuggingFace token required for Gemma model';
      notifyListeners();
      throw Exception(_downloadError);
    }

    _isDownloading = true;
    _downloadProgress = 0;
    _downloadError = null;
    _isCancelling = false;
    notifyListeners();

    try {
      final llmService = LLMService();
      
      await llmService.downloadModel(
        useGemma: _useGemma,
        hfToken: _hfToken,
        onProgress: (progress) {
          // Only update if not disposed
          if (_isDownloading) {
            _downloadProgress = progress * 100;
            notifyListeners();
          }
        },
        onError: (error) {
          // Only update if not disposed
          if (_isDownloading) {
            _downloadError = error;
            notifyListeners();
          }
        },
      );

      // Verify download completed successfully
      final downloaded = await llmService.isModelDownloaded(useGemma: _useGemma);
      
      if (downloaded) {
        _localLLMDownloaded = true;
        _localLLMEnabled = true;
        _isDownloading = false;
        _downloadProgress = 100;
        
        await _hive.settingsBox.put(_localLLMDownloadedKey, 'true');
        await _hive.settingsBox.put(_localLLMEnabledKey, 'true');
        notifyListeners();
      } else {
        throw Exception('Download completed but model file not found');
      }
    } catch (e) {
      final errorMsg = e.toString();
      
      // Check if cancelled
      if (errorMsg.contains('cancel')) {
        _downloadError = 'Download cancelled';
      } else {
        _downloadError = errorMsg;
      }
      
      _isDownloading = false;
      _downloadProgress = 0;
      _isCancelling = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Cancel ongoing download
  void cancelDownload() {
    if (!_isDownloading || _isCancelling) return;
    
    _isCancelling = true;
    notifyListeners();
    
    LLMService().cancelDownload();
    
    _isDownloading = false;
    _downloadProgress = 0;
    _downloadError = 'Download cancelled by user';
    _isCancelling = false;
    notifyListeners();
  }

  /// Delete the downloaded LLM model
  Future<void> deleteLocalLLM() async {
    try {
      debugPrint('[AISettings] Deleting LLM model...');
      
      // Cancel any ongoing download first
      if (_isDownloading) {
        cancelDownload();
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      final deleted = await LLMService().deleteModel(useGemma: _useGemma);
      
      if (deleted) {
        _localLLMDownloaded = false;
        _localLLMEnabled = false;
        _downloadProgress = 0;
        _downloadError = null;
        
        await _hive.settingsBox.put(_localLLMDownloadedKey, 'false');
        await _hive.settingsBox.put(_localLLMEnabledKey, 'false');
        notifyListeners();
        
        debugPrint('[AISettings] Model deleted successfully');
      } else {
        debugPrint('[AISettings] Model file not found');
      }
    } catch (e) {
      _downloadError = e.toString();
      notifyListeners();
      debugPrint('[AISettings] Error deleting model: $e');
      rethrow;
    }
  }

  /// Get estimated storage size for selected model
  String get estimatedModelSize {
    return _useGemma ? '~292 MB (Gemma 3)' : '~1.7 GB (Phi-2)';
  }

  /// Get actual model size if downloaded
  Future<String?> getActualModelSize() async {
    final size = await LLMService().getModelSize(useGemma: _useGemma);
    if (size == null) return null;
    
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }

  /// Check if device has sufficient resources for LLM
  bool get deviceSupportsLLM {
    // In production, check:
    // - Available storage
    // - RAM (4GB+ recommended)
    // - CPU capabilities
    return true; // Simplified for now
  }
  
  @override
  void dispose() {
    // Cancel downloads when provider is disposed
    if (_isDownloading) {
      LLMService().cancelDownload();
    }
    super.dispose();
  }
}
