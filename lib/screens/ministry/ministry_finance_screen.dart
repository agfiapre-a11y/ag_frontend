import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/ministry.dart';
import '../../models/ministry_finance.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

const _uuid = Uuid();
final _currencyFmt = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('MMM d, yyyy');

class MinistryFinanceScreen extends ConsumerStatefulWidget {
  final String ministryType;

  const MinistryFinanceScreen({super.key, required this.ministryType});

  @override
  ConsumerState<MinistryFinanceScreen> createState() =>
      _MinistryFinanceScreenState();
}

class _MinistryFinanceScreenState
    extends ConsumerState<MinistryFinanceScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final transactions = ref.watch(ministryFinanceProvider);
    final user = ref.watch(appStateProvider).user!;
    final ministryColor = MinistryType.color(widget.ministryType);
    final ministryLabel = MinistryType.label(widget.ministryType);

    final filtered = _filterType == 'all'
        ? transactions
        : transactions.where((t) => t.type == _filterType).toList();

    final totalIncome =
        transactions.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => !t.isIncome)
        .fold(0.0, (s, t) => s + t.amount);
    final balance = totalIncome - totalExpense;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text('$ministryLabel Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(ministryFinanceProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    label: 'Income',
                    value: totalIncome,
                    color: Colors.green,
                    icon: Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    label: 'Expense',
                    value: totalExpense,
                    color: Colors.red,
                    icon: Icons.trending_down,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SummaryCard(
                    label: 'Balance',
                    value: balance,
                    color: balance >= 0 ? Colors.blue : Colors.red,
                    icon: Icons.account_balance_wallet,
                  ),
                ),
              ],
            ),
          ),
          // Filter tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                    label: 'All',
                    selected: _filterType == 'all',
                    color: ministryColor,
                    onSelected: () =>
                        setState(() => _filterType = 'all')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Income',
                    selected: _filterType == 'income',
                    color: ministryColor,
                    onSelected: () =>
                        setState(() => _filterType = 'income')),
                const SizedBox(width: 8),
                _FilterChip(
                    label: 'Expense',
                    selected: _filterType == 'expense',
                    color: ministryColor,
                    onSelected: () =>
                        setState(() => _filterType = 'expense')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Transaction list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No transactions yet',
                            style: GoogleFonts.poppins(
                                color: Colors.grey[500], fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddDialog(user),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Transaction'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final tx = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (tx.isIncome ? Colors.green : Colors.red)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              tx.isIncome
                                  ? Icons.arrow_downward
                                  : Icons.arrow_upward,
                              color: tx.isIncome ? Colors.green : Colors.red,
                              size: 20,
                            ),
                          ),
                          title: Text(tx.category,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: Text(
                              '${_dateFmt.format(tx.date)} - ${tx.description}',
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.grey[600])),
                          trailing: Text(
                            '${tx.isIncome ? '+' : '-'}${_currencyFmt.format(tx.amount)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: tx.isIncome ? Colors.green : Colors.red,
                            ),
                          ),
                          onLongPress: () => _confirmDelete(tx),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(user),
        backgroundColor: ministryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddDialog(AppUser user) {
    final typeCtrl = 'income';
    String selectedType = typeCtrl;
    String selectedCategory = 'Offering';
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final incomeCats = [
      'Offering',
      'Donation',
      'Fundraising',
      'Dues',
      'Other Income'
    ];
    final expenseCats = [
      'Events',
      'Materials',
      'Transport',
      'Food',
      'Venue',
      'Other Expense'
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Add Transaction'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type toggle
                RadioGroup<String>(
                  groupValue: selectedType,
                  onChanged: (v) => setState(() {
                    selectedType = v!;
                    selectedCategory = v == 'income' ? incomeCats.first : expenseCats.first;
                  }),
                  child: Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Income'),
                        value: 'income',
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Expense'),
                        value: 'expense',
                      ),
                    ),
                  ],
                ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: (selectedType == 'income'
                          ? incomeCats
                          : expenseCats)
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedCategory = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(_dateFmt.format(selectedDate)),
                  trailing: const Icon(Icons.edit, size: 18),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (d != null) {
                      setState(() => selectedDate = d);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) return;
                final appState = ref.read(appStateProvider);
                final tx = MinistryFinance(
                  id: _uuid.v4(),
                  churchId: appState.church?.id ?? '',
                  branchId: user.branchId,
                  ministryType: widget.ministryType,
                  type: selectedType,
                  category: selectedCategory,
                  amount: amount,
                  description: descCtrl.text,
                  date: selectedDate,
                  recordedById: user.id,
                  createdAt: DateTime.now(),
                  organizationId: user.organizationId,
                  regionId: user.regionId,
                  districtId: user.districtId,
                  areaId: user.areaId,
                );
                await ref
                    .read(ministryFinanceProvider.notifier)
                    .add(tx);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(MinistryFinance tx) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction?'),
        content: Text(
            'Delete "${tx.category}" of ${_currencyFmt.format(tx.amount)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref
                  .read(ministryFinanceProvider.notifier)
                  .delete(tx.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(_currencyFmt.format(value),
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: selected ? color : Colors.grey[600],
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
