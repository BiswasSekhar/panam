import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../features/import/kotak_statement_parser.dart';
import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
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
      final doc = PdfDocument(inputBytes: bytes);
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

    final parsed = KotakStatementParser.parse(cleaned);
    if (parsed.transactions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not detect Kotak statement transactions from this file.'),
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

    // Convert to provider format and check duplicates
    final items = filteredTransactions.map((t) {
      return (
        date: t.date,
        amount: t.amount,
        type: t.type,
        description: t.description,
        externalRef: t.externalRef,
        isSelfTransfer: t.isSelfTransfer,
      );
    }).toList();

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
