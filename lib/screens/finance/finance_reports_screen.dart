import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/finance_pdf_service.dart';
import '../../widgets/responsive_scaffold.dart';

final _fmt = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('MMM d, yyyy');

class FinanceReportsScreen extends ConsumerStatefulWidget {
  const FinanceReportsScreen({super.key});
  @override
  ConsumerState<FinanceReportsScreen> createState() => _FinanceReportsScreenState();
}

class _FinanceReportsScreenState extends ConsumerState<FinanceReportsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final allTx = ref.watch(financeProvider);
    final budgets = ref.watch(budgetProvider);
    final appState = ref.watch(appStateProvider);
    final filtered = allTx.where((t) {
      if (_startDate != null && t.date.isBefore(_startDate!)) return false;
      if (_endDate != null && t.date.isAfter(_endDate!)) return false;
      return true;
    }).toList();
    final income = filtered.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expense = filtered.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final balance = income - expense;

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Finance Reports'), actions: [
        IconButton(
          icon: _generating
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.picture_as_pdf),
          onPressed: _generating ? null : () async {
            setState(() => _generating = true);
            try {
              await FinancePdfService.generateAndPrintReport(
                church: appState.church!,
                user: appState.user!,
                transactions: allTx,
                budgets: budgets,
                startDate: _startDate,
                endDate: _endDate,
              );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: AppColors.error),
                );
              }
            } finally {
              if (context.mounted) setState(() => _generating = false);
            }
          },
        ),
      ]),
      body: Column(children: [
        _DateFilter(startDate: _startDate, endDate: _endDate, onStartChanged: (d) => setState(() => _startDate = d), onEndChanged: (d) => setState(() => _endDate = d)),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SummaryCard(label: 'Income', amount: income, color: Colors.blue),
          _SummaryCard(label: 'Expenses', amount: expense, color: Colors.red),
          _SummaryCard(label: 'Balance', amount: balance, color: AppColors.primary),
          const SizedBox(height: 20),
          Text('Transactions (${filtered.length})', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          if (filtered.isEmpty) const Text('No transactions') else ...filtered.map((t) => _TransactionTile(t: t)),
        ]))),
      ]),
    );
  }
}

class _DateFilter extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime?) onStartChanged;
  final Function(DateTime?) onEndChanged;
  const _DateFilter({required this.startDate, required this.endDate, required this.onStartChanged, required this.onEndChanged});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.all(16), padding: const EdgeInsets.all(12), decoration: EmeraldTheme.cardDecoration, child: Row(children: [
      Expanded(child: _DateField(label: 'From', date: startDate, onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onStartChanged(picked);
      })),
      const SizedBox(width: 16),
      Expanded(child: _DateField(label: 'To', date: endDate, onTap: () async {
        final picked = await showDatePicker(context: context, initialDate: endDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
        if (picked != null) onEndChanged(picked);
      })),
    ]));
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateField({required this.label, required this.date, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      Text(date != null ? _dateFmt.format(date!) : 'All time', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
    ]));
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  const _SummaryCard({required this.label, required this.amount, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(16), decoration: EmeraldTheme.cardDecoration, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: GoogleFonts.poppins(fontSize: 14)),
      Text('GH₵ ${_fmt.format(amount)}', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    ]));
  }
}

class _TransactionTile extends StatelessWidget {
  final FinanceTransaction t;
  const _TransactionTile({required this.t});
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12), decoration: EmeraldTheme.cardDecoration, child: Row(children: [
      Icon(t.isIncome ? Icons.arrow_downward : Icons.arrow_upward, color: t.isIncome ? Colors.blue : Colors.red, size: 20),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(t.category, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        Text(t.description, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ])),
      Text('GH₵ ${_fmt.format(t.amount)}', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
    ]));
  }
}
