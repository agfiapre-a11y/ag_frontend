import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _currencyFmt = NumberFormat('#,##0.00');

class FinanceScreen extends ConsumerStatefulWidget {
  const FinanceScreen({super.key});

  @override
  ConsumerState<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends ConsumerState<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedMonth = DateTime.now();
  String? _branchFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _forMonth(List<FinanceTransaction> all) {
    return all.where((t) {
      final sameMonth = t.date.month == _selectedMonth.month &&
          t.date.year == _selectedMonth.year;
      final sameBranch =
          _branchFilter == null || t.branchId == _branchFilter;
      return sameMonth && sameBranch;
    }).toList();
  }

  void _prevMonth() => setState(() {
        _selectedMonth =
            DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() {
    final now = DateTime.now();
    if (_selectedMonth.year == now.year &&
        _selectedMonth.month == now.month) {
      return;
    }
    setState(() {
      _selectedMonth =
          DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _exportCsv(BuildContext context, List<FinanceTransaction> txns) {
    final buffer = StringBuffer();
    buffer.writeln('Date,Type,Category,Description,Amount,Recorded By ID,Recurring');
    for (final t in txns) {
      final desc = t.description.replaceAll(',', ';');
      buffer.writeln(
        '${DateFormat('yyyy-MM-dd').format(t.date)},'
        '${t.isIncome ? 'Income' : 'Expense'},'
        '${t.category},'
        '$desc,'
        '${t.amount.toStringAsFixed(2)},'
        '${t.recordedById},'
        '${t.isRecurring ? RecurrenceInterval.label(t.recurrenceInterval) : 'No'}',
      );
    }
    final fileName =
        'finance_${DateFormat('yyyy_MM').format(_selectedMonth)}.csv';
    Share.share(buffer.toString(), subject: 'Finance Export - $fileName');
  }

  @override
  Widget build(BuildContext context) {
    final allTx = ref.watch(financeProvider);
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final isSystemLevel = AppRoles.crossBranchRoles.contains(user.role);
    final canManage = AppRoles.financeManagerRoles.contains(user.role);
    final canAdd = canManage;

    final monthTx = _forMonth(allTx);
    final income =
        monthTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final expenses =
        monthTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final balance = income - expenses;

    final incomeTx =
        monthTx.where((t) => t.isIncome).toList();
    final expenseTx =
        monthTx.where((t) => !t.isIncome).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Finance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: () => _exportCsv(context, monthTx),
          ),
          if (isSystemLevel && branches.isNotEmpty)
            PopupMenuButton<String?>(
              icon: Icon(
                _branchFilter != null
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
                color: _branchFilter != null ? AppColors.accent : Colors.white,
              ),
              tooltip: 'Filter by branch',
              onSelected: (v) => setState(() => _branchFilter = v),
              itemBuilder: (_) => [
                const PopupMenuItem(value: null, child: Text('All branches')),
                ...branches.map((b) =>
                    PopupMenuItem(value: b.id, child: Text(b.name))),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldWarm,
          labelColor: AppColors.emeraldTextPrimary,
          unselectedLabelColor: AppColors.emeraldTextSecondary,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Income'),
            Tab(text: 'Expenses'),
            Tab(text: 'Audit Trail'),
          ],
        ),
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/finance/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          // Month selector
          Container(
            color: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _prevMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    DateFormat('MMMM yyyy').format(_selectedMonth),
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _nextMonth,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
          ),

          // Summary cards
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(children: [
              Expanded(
                child: _SummaryCard(
                  label: 'Income',
                  amount: income,
                  color: AppColors.success,
                  icon: Icons.arrow_downward,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Expenses',
                  amount: expenses,
                  color: AppColors.error,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Balance',
                  amount: balance,
                  color: balance >= 0 ? AppColors.primary : AppColors.warning,
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ]),
          ),

          const SizedBox(height: 4),

          // Transaction tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _TxList(
                    transactions: monthTx,
                    isSuperAdmin: isSystemLevel,
                    canManage: canManage,
                    branches: branches),
                _TxList(
                    transactions: incomeTx,
                    isSuperAdmin: isSystemLevel,
                    canManage: canManage,
                    branches: branches),
                _TxList(
                    transactions: expenseTx,
                    isSuperAdmin: isSystemLevel,
                    canManage: canManage,
                    branches: branches),
                _AuditTrailList(transactions: monthTx, branches: branches),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.amount,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: color,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(
            'GH₵ ${_currencyFmt.format(amount.abs())}',
            style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TxList extends ConsumerWidget {
  final List<FinanceTransaction> transactions;
  final bool isSuperAdmin;
  final bool canManage;
  final List branches;

  const _TxList({
    required this.transactions,
    required this.isSuperAdmin,
    required this.canManage,
    required this.branches,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet_outlined,
                size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No transactions this month',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: transactions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _TxTile(
        tx: transactions[i],
        isSuperAdmin: isSuperAdmin,
        canManage: canManage,
        branches: branches,
      ),
    );
  }
}

class _TxTile extends ConsumerWidget {
  final FinanceTransaction tx;
  final bool isSuperAdmin;
  final bool canManage;
  final List branches;

  const _TxTile({
    required this.tx,
    required this.isSuperAdmin,
    required this.canManage,
    required this.branches,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isIncome = tx.isIncome;
    final color = isIncome ? AppColors.success : AppColors.error;
    final branchName = branches
        .where((b) => b.id == tx.branchId)
        .firstOrNull
        ?.name;
    final canDelete = canManage;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: color,
            size: 20,
          ),
        ),
        title: Row(children: [
          Expanded(
            child: Text(
              tx.category,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
          Text(
            '${isIncome ? '+' : '-'} GH₵ ${_currencyFmt.format(tx.amount)}',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color),
          ),
        ]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tx.description.isNotEmpty)
              Text(tx.description,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Text(
                DateFormat('MMM d, yyyy').format(tx.date),
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              if (isSuperAdmin && branchName != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(branchName,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                ),
              ],
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                onSelected: (action) async {
                  if (action == 'edit') {
                    context.push('/finance/edit/${tx.id}');
                  } else if (action == 'delete') {
                    final ok = await _confirmDelete(context);
                    if (ok) {
                      await ref.read(financeProvider.notifier).delete(tx.id);
                    }
                  }
                },
                itemBuilder: (_) => [
                  if (canManage)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
                  if (canDelete)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete',
                            style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  if (!canManage)
                    const PopupMenuItem(
                      enabled: false,
                      value: 'view',
                      child: Row(children: [
                        Icon(Icons.visibility_outlined, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('View only', style: TextStyle(color: Colors.grey)),
                      ]),
                    ),
                ],
              ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Transaction'),
        content:
            const Text('Remove this transaction? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _AuditTrailList extends StatelessWidget {
  final List<FinanceTransaction> transactions;
  final List branches;

  const _AuditTrailList({
    required this.transactions,
    required this.branches,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, size: 56, color: Colors.grey),
            const SizedBox(height: 12),
            Text('No transactions this month',
                style: GoogleFonts.poppins(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    final sorted = [...transactions]
      ..sort((a, b) => (b.lastModifiedAt ?? b.createdAt)
          .compareTo(a.lastModifiedAt ?? a.createdAt));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = sorted[i];
        final branchName = branches
            .where((b) => b.id == t.branchId)
            .firstOrNull
            ?.name;
        final modified = t.lastModifiedAt != null;
        final actionTime = t.lastModifiedAt ?? t.createdAt;

        return Card(
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: (modified ? Colors.orange : Colors.green)
                  .withValues(alpha: 0.12),
              child: Icon(
                modified ? Icons.edit : Icons.add_circle_outline,
                color: modified ? Colors.orange : Colors.green,
                size: 20,
              ),
            ),
            title: Text(
              '${modified ? "Edited" : "Created"}: ${t.category}',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t.isIncome ? "Income" : "Expense"} - GH₵ ${_currencyFmt.format(t.amount)}',
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Row(children: [
                  Icon(Icons.schedule, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, yyyy · h:mm a').format(actionTime),
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  if (branchName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(branchName,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ),
                  ],
                ]),
                if (t.isRecurring) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.repeat, size: 12, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      'Recurring: ${RecurrenceInterval.label(t.recurrenceInterval)}',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.primary),
                    ),
                  ]),
                ],
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}
