import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/transaction_provider.dart';
import '../../providers/account_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/ai_settings_provider.dart';
import '../../data/models/category.dart';
import '../../data/models/transaction.dart';
import '../../features/categorization/category_suggester.dart';
import '../../features/ai/smart_categorizer.dart';
import '../import/import_statement_screen.dart';

class AddTransactionSheet extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionSheet({
    super.key,
    this.transaction,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _noteController;

  late bool _isIncome;
  late DateTime _dateTime;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  bool _saving = false;
  bool _autoSuggestEnabled = true;

  bool get _isEdit => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.transaction;
    _isIncome = existing?.type == TransactionType.income;
    _dateTime = existing?.date ?? DateTime.now();
    _selectedAccountId = existing?.accountId;
    _selectedCategoryId = existing?.categoryId;

    _amountController = TextEditingController(text: existing?.amount.toString() ?? '');
    _descriptionController = TextEditingController(text: existing?.description ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    
    // Add listener for auto-suggestion
    _descriptionController.addListener(_onDescriptionChanged);
  }
  
  void _onDescriptionChanged() {
    if (!_autoSuggestEnabled || _isEdit) return;
    if (_descriptionController.text.trim().length < 3) return;
    
    // Auto-suggest category based on description
    final catProvider = context.read<CategoryProvider>();
    final aiSettings = context.read<AISettingsProvider>();
    
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    
    String? suggestedCategoryId;
    
    // Try AI-powered categorization first if enabled
    if (aiSettings.smartCategorizationEnabled) {
      suggestedCategoryId = SmartCategorizer.categorizeTransaction(
        description: _descriptionController.text,
        narration: _noteController.text.isNotEmpty ? _noteController.text : null,
        availableCategories: catProvider.categories,
        isIncome: _isIncome,
      );
    }
    
    // Fall back to keyword-based suggestion if no AI match
    if (suggestedCategoryId == null) {
      final suggested = CategorySuggester.suggestCategory(
        description: _descriptionController.text,
        amount: amount,
        availableCategories: catProvider.categories,
        isIncome: _isIncome,
      );
      suggestedCategoryId = suggested?.id;
    }
    
    if (suggestedCategoryId != null && suggestedCategoryId != _selectedCategoryId) {
      setState(() {
        _selectedCategoryId = suggestedCategoryId;
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_onDescriptionChanged);
    _amountController.dispose();
    _descriptionController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _dateTime.hour,
        _dateTime.minute,
      );
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (picked == null) return;
    setState(() {
      _dateTime = DateTime(
        _dateTime.year,
        _dateTime.month,
        _dateTime.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<bool> _confirmDuplicate(Transaction duplicate) async {
    final fmt = DateFormat('dd MMM yyyy, HH:mm');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Possible duplicate'),
          content: Text(
            'A similar transaction already exists:\n\n'
            '${duplicate.description}\n'
            '₹${duplicate.amount.toStringAsFixed(2)} • ${fmt.format(duplicate.date)}\n\n'
            'Add anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Add anyway'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an account')),
      );
      return;
    }

    final provider = context.read<TransactionProvider>();

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final description = _descriptionController.text.trim();
      final note = _noteController.text.trim().isEmpty ? null : _noteController.text.trim();

      if (_isEdit) {
        await provider.updateTransaction(
          id: widget.transaction!.id,
          amount: amount,
          description: description,
          date: _dateTime,
          isIncome: _isIncome,
          accountId: _selectedAccountId!,
          note: note,
          categoryId: _selectedCategoryId,
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }

      final duplicate = await provider.addManualTransaction(
        isIncome: _isIncome,
        amount: amount,
        description: description,
        date: _dateTime,
        note: note,
        allowDuplicate: false,
        accountId: _selectedAccountId!,
        categoryId: _selectedCategoryId,
      );

      if (duplicate != null) {
        final addAnyway = await _confirmDuplicate(duplicate);
        if (!addAnyway) return;

        await provider.addManualTransaction(
          isIncome: _isIncome,
          amount: amount,
          description: description,
          date: _dateTime,
          note: note,
          allowDuplicate: true,
          accountId: _selectedAccountId!,
          categoryId: _selectedCategoryId,
        );
      }

      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createCategory(BuildContext context) async {
    final provider = context.read<CategoryProvider>();
    final controller = TextEditingController();
    String selectedEmoji = '📁';
    
    final result = await showDialog<({String name, String emoji})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Category'),
              content: SizedBox(
                width: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Category name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Select Icon:', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            '🍔', '🍕', '☕', '🛒', '🚗', '⛽', '🚌', '🏠', '💡', '💳',
                            '💰', '📱', '🎮', '🎬', '🏥', '💊', '📚', '✈️', '🏨', '🎁',
                            '👕', '👟', '💻', '📺', '🎵', '🏋️', '⚽', '🎨', '🔧', '🔑',
                            '🍽️', '🍞', '🥗', '🍜', '🚕', '🚇', '🏦', '💼', '📊', '🎓',
                            '🏪', '🛍️', '💸', '📦', '🎯', '🌐', '📁', '📅', '⭐', '🌟',
                          ].map((emoji) => GestureDetector(
                            onTap: () => setState(() => selectedEmoji = emoji),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: selectedEmoji == emoji
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedEmoji == emoji
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(emoji, style: const TextStyle(fontSize: 24)),
                              ),
                            ),
                          )).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop((
                    name: controller.text,
                    emoji: selectedEmoji,
                  )),
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    final trimmed = (result?.name ?? '').trim();
    if (trimmed.isEmpty) return;

    final created = await provider.createCategory(
      name: trimmed,
      isIncome: _isIncome,
      icon: result!.emoji,
    );
    if (!mounted) return;
    setState(() => _selectedCategoryId = created.id);
  }

  void _openScanner() {
    if (_isEdit) return;
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ImportStatementScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('dd MMM yyyy, HH:mm');

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(24),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isEdit ? 'Edit Transaction' : 'Add Transaction',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (!_isEdit)
                            IconButton(
                              onPressed: _openScanner,
                              icon: const Icon(Icons.document_scanner_rounded),
                              tooltip: 'Import Statement',
                            ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Income/Expense toggle
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isIncome = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: !_isIncome ? theme.colorScheme.primaryContainer : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward_rounded,
                                        color: !_isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Expense',
                                        style: TextStyle(
                                          fontWeight: !_isIncome ? FontWeight.bold : FontWeight.normal,
                                          color: !_isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _isIncome = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  decoration: BoxDecoration(
                                    color: _isIncome ? theme.colorScheme.primaryContainer : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_downward_rounded,
                                        color: _isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Credit',
                                        style: TextStyle(
                                          fontWeight: _isIncome ? FontWeight.bold : FontWeight.normal,
                                          color: _isIncome ? theme.colorScheme.onPrimaryContainer : null,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _amountController,
                          autofocus: false,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixText: '₹',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          final value = v?.trim() ?? '';
                          final parsed = double.tryParse(value);
                          if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if ((v?.trim() ?? '').isEmpty) return 'Enter a description';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Consumer<AccountProvider>(builder: (context, accProvider, _) {
                        final accounts = accProvider.accounts;
                        if (accounts.isEmpty) {
                          return const Text('No accounts available. Add one in the Accounts tab.');
                        }
                        if (_selectedAccountId == null && accounts.isNotEmpty) {
                          _selectedAccountId = accounts.first.id;
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedAccountId,
                          decoration: InputDecoration(
                            labelText: 'Account',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: accounts
                              .map((a) => DropdownMenuItem(
                                    value: a.id,
                                    child: Text(a.name),
                                  ))
                              .toList(growable: false),
                          onChanged: (v) => setState(() => _selectedAccountId = v),
                        );
                      }),
                      const SizedBox(height: 12),
                      Consumer<CategoryProvider>(builder: (context, catProvider, _) {
                        final cats = catProvider.categories.where((c) => c.isIncome == _isIncome).toList(growable: false);
                        if (cats.isEmpty) {
                          return const Text('No categories available.');
                        }

                        if (_selectedCategoryId == null || !cats.any((c) => c.id == _selectedCategoryId)) {
                          final defaultCat = cats.where((c) => c.isDefault).toList();
                          _selectedCategoryId = (defaultCat.isNotEmpty ? defaultCat.first.id : cats.first.id);
                        }

                        // Smart sorting: selected first, then most used, then alphabetically
                        final txnProvider = context.read<TransactionProvider>();
                        final sortedCats = CategorySuggester.sortCategoriesSmartly(
                          categories: cats,
                          transactions: txnProvider.transactions,
                          isIncome: _isIncome,
                          selectedCategoryId: _selectedCategoryId,
                        );

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isIncome ? Icons.trending_up : Icons.trending_down,
                                  size: 18,
                                  color: _isIncome ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isIncome ? 'Income Categories' : 'Expense Categories',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: _isIncome ? Colors.green : Colors.red,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _createCategory(context),
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  tooltip: 'Add category',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 160),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                border: Border.all(
                                  color: (_isIncome ? Colors.green : Colors.red).withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(8),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 6,
                                  children: sortedCats.map((cat) {
                                    final isSelected = cat.id == _selectedCategoryId;
                                    final isEmoji = cat.icon.length <= 4 && !cat.icon.contains('_');
                                    
                                    return FilterChip(
                                      selected: isSelected,
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isEmoji)
                                            Text(cat.icon, style: const TextStyle(fontSize: 14))
                                          else
                                            Icon(
                                              _getIconData(cat.icon),
                                              size: 14,
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurfaceVariant,
                                            ),
                                          const SizedBox(width: 4),
                                          Text(
                                            cat.name,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      onSelected: (_) => setState(() => _selectedCategoryId = cat.id),
                                      selectedColor: _isIncome ? Colors.green : Colors.red,
                                      backgroundColor: theme.colorScheme.surface,
                                      labelStyle: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : theme.colorScheme.onSurface,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Date & Time',
                                  style: theme.textTheme.labelMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dtFmt.format(_dateTime),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.calendar_today_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: _pickTime,
                                  icon: const Icon(Icons.schedule_rounded),
                                  style: IconButton.styleFrom(
                                    backgroundColor: theme.colorScheme.surface,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _saving ? 'Saving…' : (_isEdit ? 'Save Changes' : 'Save Transaction'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'category': Icons.category,
      'restaurant': Icons.restaurant,
      'local_grocery_store': Icons.local_grocery_store,
      'fastfood': Icons.fastfood,
      'local_cafe': Icons.local_cafe,
      'delivery_dining': Icons.delivery_dining,
      'local_gas_station': Icons.local_gas_station,
      'directions_bus': Icons.directions_bus,
      'local_taxi': Icons.local_taxi,
      'local_parking': Icons.local_parking,
      'build': Icons.build,
      'checkroom': Icons.checkroom,
      'devices': Icons.devices,
      'weekend': Icons.weekend,
      'shopping_bag': Icons.shopping_bag,
      'shopping_cart': Icons.shopping_cart,
      'electric_bolt': Icons.electric_bolt,
      'water_drop': Icons.water_drop,
      'propane_tank': Icons.propane_tank,
      'wifi': Icons.wifi,
      'phone': Icons.phone,
      'home': Icons.home,
      'shield': Icons.shield,
      'movie': Icons.movie,
      'subscriptions': Icons.subscriptions,
      'sports_esports': Icons.sports_esports,
      'celebration': Icons.celebration,
      'fitness_center': Icons.fitness_center,
      'medical_services': Icons.medical_services,
      'local_pharmacy': Icons.local_pharmacy,
      'dentistry': Icons.medical_services,
      'health_and_safety': Icons.health_and_safety,
      'biotech': Icons.biotech,
      'school': Icons.school,
      'menu_book': Icons.menu_book,
      'laptop_chromebook': Icons.laptop_chromebook,
      'edit_note': Icons.edit_note,
      'content_cut': Icons.content_cut,
      'face': Icons.face,
      'hotel': Icons.hotel,
      'flight': Icons.flight,
      'luggage': Icons.luggage,
      'beach_access': Icons.beach_access,
      'music_note': Icons.music_note,
      'ondemand_video': Icons.ondemand_video,
      'cloud': Icons.cloud,
      'computer': Icons.computer,
      'auto_stories': Icons.auto_stories,
      'card_giftcard': Icons.card_giftcard,
      'volunteer_activism': Icons.volunteer_activism,
      'favorite': Icons.favorite,
      'account_balance': Icons.account_balance,
      'payments': Icons.payments,
      'credit_card': Icons.credit_card,
      'receipt_long': Icons.receipt_long,
      'trending_up': Icons.trending_up,
      'pets': Icons.pets,
      'local_laundry_service': Icons.local_laundry_service,
      'mail': Icons.mail,
      'gavel': Icons.gavel,
      'more_horiz': Icons.more_horiz,
      'work': Icons.work,
      'business_center': Icons.business_center,
      'savings': Icons.savings,
      'home_work': Icons.home_work,
      'history': Icons.history,
      'workspace_premium': Icons.workspace_premium,
      'redeem': Icons.redeem,
      'loyalty': Icons.loyalty,
      'elderly': Icons.elderly,
      'attach_money': Icons.attach_money,
      'receipt': Icons.receipt,
      'directions_car': Icons.directions_car,
      // New icons
      'handyman': Icons.handyman,
      'child_care': Icons.child_care,
      'baby_changing_station': Icons.baby_changing_station,
      'countertops': Icons.countertops,
      'business': Icons.business,
      'yard': Icons.yard,
      'home_repair_service': Icons.home_repair_service,
      'spa': Icons.spa,
      'newspaper': Icons.newspaper,
      'atm': Icons.atm,
      'sync_alt': Icons.sync_alt,
      'sell': Icons.sell,
      'schedule': Icons.schedule,
      'volunteer_activism': Icons.volunteer_activism,
      'account_balance_wallet': Icons.account_balance_wallet,
      'school': Icons.school,
      'emoji_events': Icons.emoji_events,
      'copyright': Icons.copyright,
    };
    return iconMap[iconName] ?? Icons.category;
  }
}
