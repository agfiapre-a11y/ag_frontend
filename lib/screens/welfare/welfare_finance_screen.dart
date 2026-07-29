import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/welfare_finance.dart';
import '../../providers/data_provider.dart';

final _currencyFmt = NumberFormat('#,##0.00');

class WelfareFinanceScreen extends ConsumerWidget {
  const WelfareFinanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txns = ref.watch(welfareFinanceProvider);

    final contributions =
        txns.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final disbursements =
        txns.where((t) => t.isDisbursement).fold<double>(0, (s, t) => s + t.amount);
    final expenses =
        txns.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final balance = contributions - disbursements - expenses;

    final recent = txns.take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Welfare Finance')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Balance card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emeraldDeep, AppColors.emeraldForest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welfare Fund Balance',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.cardWhite.withValues(alpha: 0.8))),
                  const SizedBox(height: 8),
                  Text(_currencyFmt.format(balance),
                      style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppColors.cardWhite)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Contributions',
                    value: _currencyFmt.format(contributions),
                    icon: Icons.savings,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Disbursements',
                    value: _currencyFmt.format(disbursements),
                    icon: Icons.volunteer_activism,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryCard(
                    title: 'Expenses',
                    value: _currencyFmt.format(expenses),
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryCard(
                    title: 'Transactions',
                    value: '${txns.length}',
                    icon: Icons.receipt_long,
                    color: AppColors.emeraldDeep,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Navigation items
            _NavTile(
              icon: Icons.receipt_long,
              title: 'All Transactions',
              subtitle: 'View and manage all welfare transactions',
              onTap: () => context.push('/welfare/finance/transactions'),
            ),
            _NavTile(
              icon: Icons.calendar_month,
              title: 'Monthly Contributions',
              subtitle: 'View individual monthly welfare contributions',
              onTap: () => context.push('/welfare/finance/contributions'),
            ),
            _NavTile(
              icon: Icons.payment,
              title: 'Make Payment',
              subtitle: 'Record a payment on behalf of a member',
              onTap: () => context.push('/welfare/finance/payment'),
            ),
            _NavTile(
              icon: Icons.groups_2,
              title: 'Department Welfare',
              subtitle: 'Manage department welfare funds',
              onTap: () => context.push('/welfare/finance/departments'),
            ),
            _NavTile(
              icon: Icons.assessment,
              title: 'Generate Reports',
              subtitle: 'Financial analytics and welfare reports',
              onTap: () => context.push('/welfare/finance/reports'),
            ),

            const SizedBox(height: 24),

            // Recent transactions
            Text('Recent Transactions',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No transactions yet',
                          style: GoogleFonts.poppins(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              ...recent.map((t) => _TransactionTile(txn: t)),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.emeraldDeep),
        title: Text(title,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final WelfareTransaction txn;

  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: WelfareTxnType.color(txn.type).withValues(alpha: 0.12),
          child: Icon(WelfareTxnType.icon(txn.type),
              color: WelfareTxnType.color(txn.type), size: 20),
        ),
        title: Text(WelfareTxnType.label(txn.type),
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${txn.category} · ${DateFormat('MMM d, y').format(txn.date)}',
          style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: Text(
          _currencyFmt.format(txn.amount),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: txn.isContribution ? Colors.green : Colors.red,
          ),
        ),
        onTap: () => context.push('/welfare/finance/transactions'),
      ),
    );
  }
}
