import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../features/import/statement_parser.dart';
import '../../features/ai/ai_pdf_analyzer.dart';
import '../../features/ai/smart_categorizer.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../data/models/transaction.dart';
import 'widgets/account_selector_dialog.dart';
import 'widgets/month_filter_dialog.dart';

class ImportStatementScreen extends StatefulWidget {
  const ImportStatementScreen({super.key});

  @override
  State<ImportStatementScreen> createState() => _ImportStatementScreenState();
}

class _ImportStatementScreenState extends State<ImportStatementScreen> {
  bool _busy = false;

  Future<void> _importPdf() async {
    if (_busy) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final bytes = await File(path).readAsBytes();
      String? password;
      PdfDocument? doc;
      
      // Try to open without password first
      try {
        doc = PdfDocument(inputBytes: bytes);
      } catch (e) {
        // Check if it's a security/password error
        if (e.toString().contains('password') || 
            e.toString().contains('encrypted') ||
            e.toString().contains('security')) {
          // Ask user for password
          password = await _showPasswordDialog();
          if (password == null || password.isEmpty) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Password required to open this PDF')),
            );
            return;
          }
          
          // Try to open with password
          try {
            doc = PdfDocument(inputBytes: bytes, password: password);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Incorrect password or unable to open PDF')),
            );
            return;
          }
        } else {
          rethrow;
        }
      }
      
      final extractor = PdfTextExtractor(doc);
      final text = extractor.extractText();
      doc.dispose();

      await _processExtractedText(text, TransactionSource.importPdfText);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to read PDF: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Password Protected PDF'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This PDF is password protected. Please enter the password to continue.'),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                onSubmitted: (value) => Navigator.of(context).pop(value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Open'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _importImageOcr() async {
    if (_busy) return;

    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() => _busy = true);
    try {
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final input = InputImage.fromFilePath(path);
      final recognized = await recognizer.processImage(input);
      await recognizer.close();

      await _processExtractedText(recognized.text, TransactionSource.importOcrImage);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('OCR failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _processExtractedText(String text, TransactionSource source) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No text found in the file.')),
      );
      return;
    }

    // AI-powered bank detection
    final pdfAnalyzer = AIPdfAnalyzer();
    final bankAnalysis = await pdfAnalyzer.analyzePdfText(cleaned);
    
    if (bankAnalysis.isKnownFormat) {
      debugPrint('[Import] AI detected bank: ${bankAnalysis.bankName} (confidence: ${bankAnalysis.confidence})');
    } else {
      debugPrint('[Import] Unknown bank format detected: ${bankAnalysis.bankName}');
      // Could optionally create a custom parser here with AI
    }

    final parsed = StatementParser.parse(cleaned);
    if (parsed.transactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not detect bank statement transactions from this file.'),
        ),
      );
      return;
    }

    // Show account selector based on detected bank name
    final accProvider = context.read<AccountProvider>();
    String? selectedAccountId;

    if (parsed.bankName != null) {
      // Try to find matching account
      final matchingAccount = accProvider.accounts.where((a) {
        return a.name.toLowerCase().contains(parsed.bankName!.toLowerCase()) ||
            (a.icon != null && a.icon!.toLowerCase() == parsed.bankName!.toLowerCase());
      }).firstOrNull;

      selectedAccountId = await showDialog<String>(
        context: context,
        builder: (context) => AccountSelectorDialog(
          detectedBank: parsed.bankName,
          matchingAccount: matchingAccount,
        ),
      );
    } else {
      // No bank detected, show account selector without suggestion
      selectedAccountId = await showDialog<String>(
        context: context,
        builder: (context) => const AccountSelectorDialog(),
      );
    }

    if (selectedAccountId == null) return;

    // If opening balance is available and account is new or has no transactions,
    // ask user if they want to set the initial balance
    if (parsed.openingBalance != null) {
      final provider = context.read<TransactionProvider>();
      final existingTransactions = provider.transactions
          .where((t) => t.accountId == selectedAccountId)
          .toList();
      
      if (existingTransactions.isEmpty) {
        final shouldSetBalance = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Opening Balance Detected'),
            content: Text(
              'The statement shows an opening balance of ₹${parsed.openingBalance!.toStringAsFixed(2)}\n\n'
              'Would you like to set this as the initial balance for this account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        
        if (shouldSetBalance == true) {
          // Update account's initial balance
          final account = accProvider.accounts.firstWhere((a) => a.id == selectedAccountId);
          final updatedAccount = account.copyWith(initialBalance: parsed.openingBalance);
          await accProvider.updateAccount(updatedAccount);
        }
      }
    }

    // Show month filter dialog
    final selectedMonths = await showDialog<Set<DateTime>>(
      context: context,
      builder: (context) => MonthFilterDialog(
        transactions: parsed.transactions,
      ),
    );

    if (selectedMonths == null || selectedMonths.isEmpty) return;

    // Filter transactions by selected months
    final filteredTransactions = parsed.transactions.where((t) {
      final txMonth = DateTime(t.date.year, t.date.month);
      return selectedMonths.contains(txMonth);
    }).toList();

    if (filteredTransactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions in selected months.')),
      );
      return;
    }

    // Always import all transactions. Self-transfer handling is confirmed later
    // by matching against existing transactions in other accounts.
    final transactionsToImport = filteredTransactions;

    if (transactionsToImport.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No transactions to import after filtering.')),
      );
      return;
    }

    // Convert to provider format and auto-categorize with AI
    final categoryProvider = context.read<CategoryProvider>();
    final items = <({
      DateTime date,
      double amount,
      TransactionType type,
      String description,
      String? externalRef,
      bool? isSelfTransfer,
      String? categoryId,
    })>[];
    
    for (final t in transactionsToImport) {
      String? categoryId;
      
      // Try AI categorization if description is meaningful
      if (t.description.trim().length > 3) {
        categoryId = await SmartCategorizer.categorizeWithLLM(
          description: t.description,
          amount: t.amount.abs(),
          availableCategories: categoryProvider.categories,
          isIncome: t.type == TransactionType.income,
        );
        
        if (categoryId != null) {
          final category = categoryProvider.categories.firstWhere((c) => c.id == categoryId);
          debugPrint('[Import] AI categorized "${t.description}" as "${category.name}"');
        }
      }
      
      items.add((
        date: t.date,
        amount: t.amount,
        type: t.type,
        description: t.description,
        externalRef: t.externalRef,
        isSelfTransfer: t.isSelfTransfer ?? false,
        categoryId: categoryId,
      ));
    }

    final provider = context.read<TransactionProvider>();
    final duplicates = provider.countPossibleDuplicatesForImport(
      accountId: selectedAccountId,
      items: items,
    );

    var importDuplicates = false;
    if (duplicates > 0) {
      final choice = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Duplicates detected'),
            content: Text(
              '$duplicates of ${items.length} entries look like duplicates (same date & amount).\n\n'
              'Do you want to import duplicates too?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Skip duplicates'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Import all'),
              ),
            ],
          );
        },
      );
      importDuplicates = choice ?? false;
    }

    final importResult = await provider.importTransactions(
      items: items,
      source: source,
      importDuplicates: importDuplicates,
      accountId: selectedAccountId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Imported ${importResult.imported}/${importResult.total} '
          '(${importResult.skippedDuplicates} skipped as duplicates)',
        ),
      ),
    );

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Import Statement')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded),
              title: const Text('Select PDF (text-based)'),
              subtitle: const Text('Reads selectable PDF text (not scanned).'),
              enabled: !_busy,
              onTap: _importPdf,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('Select Image (OCR)'),
              subtitle: const Text('Runs OCR and extracts transactions.'),
              enabled: !_busy,
              onTap: _importImageOcr,
            ),
            if (_busy) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }
}
