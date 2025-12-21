import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/ai_settings_provider.dart';
import '../../data/local/hive_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final aiProvider = context.watch<AISettingsProvider>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 56, 16, 30),
        children: [
          Text(
            'Theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          RadioListTile<ThemeMode>(
            value: ThemeMode.system,
            groupValue: appProvider.themeMode,
            title: const Text('System'),
            onChanged: (v) {
              if (v != null) appProvider.setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.light,
            groupValue: appProvider.themeMode,
            title: const Text('Light'),
            onChanged: (v) {
              if (v != null) appProvider.setThemeMode(v);
            },
          ),
          RadioListTile<ThemeMode>(
            value: ThemeMode.dark,
            groupValue: appProvider.themeMode,
            title: const Text('Dark'),
            onChanged: (v) {
              if (v != null) appProvider.setThemeMode(v);
            },
          ),
          const SizedBox(height: 32),
          
          // AI Features Section
          Row(
            children: [
              Text(
                'AI Features',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'BETA',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'All AI processing happens on your device for privacy.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: aiProvider.aiEnabled,
            title: const Text('Enable AI Features'),
            subtitle: const Text('Master switch for all AI/ML capabilities'),
            secondary: const Icon(Icons.psychology_rounded),
            onChanged: (v) => aiProvider.setAIEnabled(v),
          ),
          AnimatedOpacity(
            opacity: aiProvider.aiEnabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: Column(
              children: [
                SwitchListTile(
                  value: aiProvider.predictionsEnabled,
                  title: const Text('Spending Predictions'),
                  subtitle: const Text('AI-powered spending forecasts'),
                  secondary: const Icon(Icons.insights_rounded),
                  onChanged: aiProvider.aiEnabled 
                      ? (v) => aiProvider.setPredictionsEnabled(v)
                      : null,
                ),
                SwitchListTile(
                  value: aiProvider.smartCategorizationEnabled,
                  title: const Text('Smart Categorization'),
                  subtitle: const Text('Auto-suggest categories based on keywords'),
                  secondary: const Icon(Icons.auto_awesome_rounded),
                  onChanged: aiProvider.aiEnabled 
                      ? (v) => aiProvider.setSmartCategorizationEnabled(v)
                      : null,
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.memory_rounded,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                  title: const Text('Local AI Model'),
                  subtitle: Text(
                    aiProvider.localLLMDownloaded
                        ? 'Downloaded • Ready to use'
                        : 'Advanced categorization with local LLM (${aiProvider.estimatedModelSize})',
                  ),
                  trailing: _buildLLMButton(context, aiProvider),
                ),
                if (aiProvider.isDownloading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: aiProvider.downloadProgress / 100,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Downloading... ${aiProvider.downloadProgress.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (aiProvider.localLLMDownloaded && aiProvider.aiEnabled)
                  SwitchListTile(
                    value: aiProvider.localLLMEnabled,
                    title: const Text('Use Local LLM'),
                    subtitle: const Text('Enhanced categorization using on-device AI'),
                    secondary: const Icon(Icons.smart_toy_rounded),
                    onChanged: (v) => aiProvider.setLocalLLMEnabled(v),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          
          Text(
            'Data',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            value: appProvider.showSelfTransfers,
            title: const Text('Show self transfers'),
            subtitle: const Text('Include self transfers in totals & analytics'),
            onChanged: (v) => appProvider.setShowSelfTransfers(v),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
            title: const Text('Clear All Data'),
            subtitle: const Text('Delete all transactions, accounts, and categories'),
            onTap: () => _showClearDataDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLLMButton(BuildContext context, AISettingsProvider aiProvider) {
    if (aiProvider.isDownloading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (aiProvider.localLLMDownloaded) {
      return PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'delete') {
            _showDeleteLLMDialog(context, aiProvider);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Delete Model'),
              ],
            ),
          ),
        ],
      );
    }

    return FilledButton.tonal(
      onPressed: aiProvider.aiEnabled
          ? () => _showDownloadDialog(context, aiProvider)
          : null,
      child: const Text('Download'),
    );
  }

  void _showDownloadDialog(BuildContext context, AISettingsProvider aiProvider) {
    final TextEditingController tokenController = TextEditingController(text: aiProvider.hfToken ?? '');
    bool localUseGemma = aiProvider.useGemma;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text('Download ${localUseGemma ? "Gemma 3" : "Phi-2"}'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!aiProvider.isDownloading) ...[
                    // Model Selection
                    const Text('Select Model:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    RadioListTile<bool>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Gemma 3 1B (~750MB)'),
                      subtitle: const Text('Recommended, good quality'),
                      value: true,
                      groupValue: localUseGemma,
                      onChanged: (v) {
                        setDialogState(() {
                          localUseGemma = v!;
                        });
                      },
                    ),
                    RadioListTile<bool>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Phi-2 2.7B (1.7GB)'),
                      subtitle: const Text('Public, no token needed'),
                      value: false,
                      groupValue: localUseGemma,
                      onChanged: (v) {
                        setDialogState(() {
                          localUseGemma = v!;
                        });
                      },
                    ),
                    
                    // HF Token (optional, for gated models)
                    const SizedBox(height: 16),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Advanced Options', style: TextStyle(fontSize: 14)),
                      children: [
                        const Text('HuggingFace Token (optional):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: tokenController,
                          decoration: const InputDecoration(
                            hintText: 'hf_...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            helperText: 'Only needed for gated models',
                            helperMaxLines: 2,
                          ),
                          obscureText: true,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('• Smart transaction categorization', style: TextStyle(fontSize: 12)),
                    const Text('• Spending predictions with reasoning', style: TextStyle(fontSize: 12)),
                    const Text('• Recurrence pattern detection', style: TextStyle(fontSize: 12)),
                    const Text('• PDF/Statement data extraction', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.storage_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text('Size: ${localUseGemma ? "~750 MB" : "~1.7 GB"}', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.lock_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('100% on-device', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Keep app open during download. Requires WiFi.',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Downloading state
                    Text('Downloading ${localUseGemma ? "Gemma 3" : "Phi-2"}...'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: aiProvider.downloadProgress / 100,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${aiProvider.downloadProgress.toStringAsFixed(1)}% complete',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (aiProvider.isCancelling) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Cancelling...',
                        style: TextStyle(color: Colors.orange, fontSize: 12),
                      ),
                    ],
                  ],
                  
                  // Error display
                  if (aiProvider.downloadError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              aiProvider.downloadError!,
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              if (!aiProvider.isDownloading) ...[
                TextButton(
                  onPressed: () {
                    tokenController.dispose();
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    // Validate
                    if (localUseGemma && tokenController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('HuggingFace token required for Gemma model'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    // Save settings
                    await aiProvider.setUseGemma(localUseGemma);
                    if (localUseGemma) {
                      await aiProvider.setHfToken(tokenController.text.trim());
                    }
                    
                    // Start download
                    try {
                      await aiProvider.downloadLocalLLM();
                      
                      if (!dialogContext.mounted) return;
                      tokenController.dispose();
                      Navigator.pop(dialogContext);
                      
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✓ ${localUseGemma ? "Gemma 3" : "Phi-2"} downloaded successfully!'),
                          backgroundColor: Colors.green,
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } catch (e) {
                      // Error shown in dialog, just rebuild
                      if (dialogContext.mounted) {
                        setDialogState(() {});
                      }
                    }
                  },
                  child: const Text('Download'),
                ),
              ] else ...[
                TextButton(
                  onPressed: aiProvider.isCancelling ? null : () {
                    aiProvider.cancelDownload();
                  },
                  child: Text(aiProvider.isCancelling ? 'Cancelling...' : 'Cancel Download'),
                ),
              ],
            ],
          );
        },
      ),
    ).then((_) {
      tokenController.dispose();
    });
  }

  void _showDeleteLLMDialog(BuildContext context, AISettingsProvider aiProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI Model?'),
        content: const Text(
          'This will remove the downloaded AI model and free up storage space. '
          'You can re-download it anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              aiProvider.deleteLocalLLM();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('AI model deleted')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDataDialog(BuildContext context) async {
    final accountProvider = context.read<AccountProvider>();
    final categoryProvider = context.read<CategoryProvider>();
    final transactionProvider = context.read<TransactionProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear All Data?'),
          content: const Text(
            'This will permanently delete all your transactions, accounts, and categories. This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete Everything'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    // Clear all Hive boxes
    await HiveService().transactionsBox.clear();
    await HiveService().accountsBox.clear();
    await HiveService().categoriesBox.clear();

    // Refresh providers and re-seed defaults so the UI updates without restart.
    await Future.wait([
      accountProvider.reload(seedIfEmpty: true),
      categoryProvider.reload(seedIfEmpty: true),
    ]);
    transactionProvider.reload();

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All data cleared.'),
        duration: Duration(seconds: 5),
      ),
    );
  }
}
