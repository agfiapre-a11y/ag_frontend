import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/budget.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _fmt = NumberFormat('#,##0.00');

class BudgetSpendingScreen extends ConsumerWidget {
  const BudgetSpendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetProvider);
    final allTx = ref.watch(financeProvider);
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.financeManagerRoles.contains(user.role);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Budget & Spending'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(budgetProvider.notifier).refresh(),
          ),
        ],
      ),
      body: budgets.isEmpty
          ? _EmptyState(canManage: canManage)
          : _BudgetList(
              budgets: budgets,
              transactions: allTx,
              canManage: canManage,
            ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => _showBudgetForm(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add Budget'),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool canManage;
  const _EmptyState({required this.canManage});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text('No budgets set yet', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          if (canManage) ...[
            const SizedBox(height: 8),
            Text('Tap the button below to create your first budget', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final List<FinanceTransaction> transactions;
  final bool canManage;

  const _BudgetList({
    required this.budgets,
    required this.transactions,
    required this.canManage,
  });

  double _actual(Budget b) {
    return transactions.where((t) {
      return t.category == b.category && BudgetPeriod.key(t.date) == b.period;
    }).fold(0.0, (s, t) => s + t.amount);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: budgets.length,
      itemBuilder: (context, i) {
        final b = budgets[i];
        return _BudgetCard(budget: b, actual: _actual(b), canManage: canManage);
      },
    );
  }
}

class _BudgetCard extends StatelessWidget {
  final Budget budget;
  final double actual;
  final bool canManage;

  const _BudgetCard({
    required this.budget,
    required this.actual,
    required this.canManage,
  });

  @override
  Widget build(BuildContext context) {
    final pct = budget.allocatedAmount > 0 ? (actual / budget.allocatedAmount).clamp(0.0, 1.0) : 0.0;
    final over = actual > budget.allocatedAmount;
    final remaining = budget.allocatedAmount - actual;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: EmeraldTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(budget.category, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(budget.period, style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _AmountBlock(label: 'Budgeted', amount: budget.allocatedAmount, color: AppColors.primary)),
              Expanded(child: _AmountBlock(label: 'Actual', amount: actual, color: over ? Colors.red : Colors.blue)),
              Expanded(child: _AmountBlock(label: 'Remaining', amount: remaining, color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: pct,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(over ? Colors.red : AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _AmountBlock extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _AmountBlock({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text('GH₵ ${_fmt.format(amount)}', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

void _showBudgetForm(BuildContext context, WidgetRef ref, {Budget? budget}) {
  final isEdit = budget != null;
  final categoryCtrl = TextEditingController(text: budget?.category ?? '');
  final amountCtrl = TextEditingController(text: budget != null ? budget.allocatedAmount.toString() : '');
  final periodCtrl = TextEditingController(text: budget?.period ?? BudgetPeriod.key(DateTime.now()));
  final notesCtrl = TextEditingController(text: budget?.notes ?? '');
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(isEdit ? 'Edit Budget' : 'Add Budget'),
      content: Form(
        key: formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: categoryCtrl,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Allocated Amount (GH₵)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final amt = double.tryParse(v.trim().replaceAll(',', ''));
                  if (amt == null || amt <= 0) return 'Invalid amount';
                  return null;
                },
              ),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDatePickerMode: DatePickerMode.year,
                  );
                  if (picked != null) {
                    periodCtrl.text = BudgetPeriod.key(picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Period (Month)',
                    prefixIcon: Icon(Icons.calendar_month),
                  ),
                  child: Text(
                    periodCtrl.text.isNotEmpty ? BudgetPeriod.label(periodCtrl.text) : 'Select month',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                ),
              ),
              TextFormField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            final appState = ref.read(appStateProvider);
            final newBudget = Budget(
              id: budget?.id ?? const Uuid().v4(),
              churchId: appState.church?.id ?? '',
              branchId: appState.user?.branchId ?? '',
              category: categoryCtrl.text.trim(),
              allocatedAmount: double.parse(amountCtrl.text.trim().replaceAll(',', '')),
              period: periodCtrl.text.trim(),
              notes: notesCtrl.text.trim(),
              createdById: appState.user?.id ?? '',
              createdAt: budget?.createdAt ?? DateTime.now(),
            );
            if (isEdit) {
              await ref.read(budgetProvider.notifier).update(newBudget);
            } else {
              await ref.read(budgetProvider.notifier).add(newBudget);
            }
            if (ctx.mounted) Navigator.pop(ctx);
          },
          child: Text(isEdit ? 'Update' : 'Save'),
        ),
      ],
    ),
  );
}
