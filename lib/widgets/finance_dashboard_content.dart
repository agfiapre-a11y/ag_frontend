import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/responsive.dart';
import '../../core/theme.dart';
import '../../models/app_user.dart';
import '../../models/budget.dart';
import '../../models/contribution.dart';
import '../../models/finance_approval.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

final _moneyFmt = NumberFormat('#,##0.00');
final _monthFmt = DateFormat('MMMM yyyy');

class FinanceDashboardContent extends ConsumerStatefulWidget {
  final AppUser user;
  const FinanceDashboardContent({super.key, required this.user});

  @override
  ConsumerState<FinanceDashboardContent> createState() =>
      _FinanceDashboardContentState();
}

class _FinanceDashboardContentState
    extends ConsumerState<FinanceDashboardContent> {
  DateTime _selectedMonth = DateTime.now();
  String _searchQuery = '';
  String? _categoryFilter;
  bool _showAllRecent = false;

  List<FinanceTransaction> _forMonth(List<FinanceTransaction> all) {
    return all.where((t) {
      return t.date.month == _selectedMonth.month &&
          t.date.year == _selectedMonth.year;
    }).toList();
  }

  List<FinanceTransaction> _forPrevMonth(List<FinanceTransaction> all) {
    final prev = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    return all.where((t) {
      return t.date.month == prev.month && t.date.year == prev.year;
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

  String _currency() {
    final church = ref.read(appStateProvider).church;
    return church?.currency ?? 'GH₵';
  }

  String _money(double v) => '${_currency()} ${_moneyFmt.format(v)}';

  @override
  Widget build(BuildContext context) {
    final allTxns = ref.watch(financeProvider);
    final welfareTxns = ref.watch(welfareFinanceProvider);
    final ministryTxns = ref.watch(ministryFinanceProvider);
    final budgets = ref.watch(budgetProvider);
    final approvals = ref.watch(financeApprovalProvider);
    final contributions = ref.watch(contributionProvider);

    final monthTx = _forMonth(allTxns);
    final prevMonthTx = _forPrevMonth(allTxns);

    final income = monthTx.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final expense = monthTx.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final balance = income - expense;

    final prevIncome = prevMonthTx.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final prevExpense = prevMonthTx.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final prevBalance = prevIncome - prevExpense;

    final incomeChange = prevIncome > 0 ? ((income - prevIncome) / prevIncome * 100) : 0.0;
    final expenseChange = prevExpense > 0 ? ((expense - prevExpense) / prevExpense * 100) : 0.0;
    final balanceChange = prevBalance != 0 ? ((balance - prevBalance) / prevBalance.abs() * 100) : 0.0;

    final tithe = monthTx.where((t) => t.isIncome && t.category == IncomeCategories.tithe).fold<double>(0, (s, t) => s + t.amount);
    final offering = monthTx.where((t) => t.isIncome && t.category == IncomeCategories.offering).fold<double>(0, (s, t) => s + t.amount);
    final donation = monthTx.where((t) => t.isIncome && t.category == IncomeCategories.donation).fold<double>(0, (s, t) => s + t.amount);
    final fundraising = monthTx.where((t) => t.isIncome && t.category == IncomeCategories.fundraising).fold<double>(0, (s, t) => s + t.amount);

    final salary = monthTx.where((t) => !t.isIncome && t.category == ExpenseCategories.salary).fold<double>(0, (s, t) => s + t.amount);
    final utilities = monthTx.where((t) => !t.isIncome && t.category == ExpenseCategories.utilities).fold<double>(0, (s, t) => s + t.amount);
    final rent = monthTx.where((t) => !t.isIncome && t.category == ExpenseCategories.rent).fold<double>(0, (s, t) => s + t.amount);
    final maintenance = monthTx.where((t) => !t.isIncome && t.category == ExpenseCategories.maintenance).fold<double>(0, (s, t) => s + t.amount);
    final welfareExp = monthTx.where((t) => !t.isIncome && t.category == ExpenseCategories.welfare).fold<double>(0, (s, t) => s + t.amount);
    final missionsExp = monthTx.where((t) => !t.isIncome && t.category == ExpenseCategories.missions).fold<double>(0, (s, t) => s + t.amount);

    final wContrib = welfareTxns.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final wDisb = welfareTxns.where((t) => t.isDisbursement).fold<double>(0, (s, t) => s + t.amount);
    final wBalance = wContrib - wDisb;

    final mIncome = ministryTxns.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
    final mExpense = ministryTxns.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);

    final pendingApprovals = approvals.where((r) => r.status == FinanceApprovalStatus.pending).length;

    final currentPeriodKey = BudgetPeriod.key(_selectedMonth);
    final activeBudgets = budgets.where((b) => b.period == currentPeriodKey).toList();

    final deptContributions = contributions.where((c) => c.welfareScope == WelfareScope.department).fold<double>(0, (s, c) => s + c.amount);
    final churchContributions = contributions.where((c) => c.welfareScope == WelfareScope.church).fold<double>(0, (s, c) => s + c.amount);

    var filteredRecent = ([...monthTx]..sort((a, b) => b.date.compareTo(a.date)));
    if (_searchQuery.isNotEmpty) {
      filteredRecent = filteredRecent.where((t) {
        return t.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            t.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    if (_categoryFilter != null) {
      filteredRecent = filteredRecent.where((t) => t.category == _categoryFilter).toList();
    }
    final recent = _showAllRecent ? filteredRecent : filteredRecent.take(5).toList();

    final allCategories = [...IncomeCategories.all, ...ExpenseCategories.all];

    final last6Months = List.generate(6, (i) {
      final d = DateTime(_selectedMonth.year, _selectedMonth.month - (5 - i));
      final tx = allTxns.where((t) => t.date.month == d.month && t.date.year == d.year).toList();
      final inc = tx.where((t) => t.isIncome).fold<double>(0, (s, t) => s + t.amount);
      final exp = tx.where((t) => !t.isIncome).fold<double>(0, (s, t) => s + t.amount);
      return _MonthData(DateFormat('MMM').format(d), inc, exp);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMonthSelector(),
        _buildPeriodToggle(),
        _section('Financial Summary'),
        _statGrid(context, [
          _Stat('Income', _money(income), Icons.trending_up, '/finance'),
          _Stat('Expenses', _money(expense), Icons.trending_down, '/finance'),
          _Stat('Balance', _money(balance), Icons.account_balance, '/finance'),
          _Stat('Transactions', '${monthTx.length}', Icons.receipt_long, '/finance'),
        ]),
        _buildMoMComparison(incomeChange, expenseChange, balanceChange),
        _section('Income vs Expense (6 Months)'),
        _buildMiniBarChart(last6Months),
        _section('Income Breakdown'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryChip('Tithe', tithe, Colors.teal),
              _categoryChip('Offering', offering, Colors.blue),
              _categoryChip('Donation', donation, Colors.purple),
              _categoryChip('Fundraising', fundraising, Colors.orange),
            ],
          ),
        ),
        _section('Expense Breakdown'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _categoryChip('Salary', salary, Colors.red),
              _categoryChip('Utilities', utilities, Colors.deepOrange),
              _categoryChip('Rent', rent, Colors.brown),
              _categoryChip('Maintenance', maintenance, Colors.grey),
              _categoryChip('Welfare', welfareExp, Colors.pink),
              _categoryChip('Missions', missionsExp, Colors.indigo),
            ],
          ),
        ),
        if (pendingApprovals > 0) ...[
          const SizedBox(height: 8),
          _buildPendingApprovalsBanner(pendingApprovals),
        ],
        if (activeBudgets.isNotEmpty) ...[
          _section('Budget Status', actionLabel: 'View all', onAction: () => context.push('/finance/budget-spending')),
          ...activeBudgets.map((b) => _buildBudgetCard(b, monthTx)),
        ],
        _section('Welfare Finance'),
        _statGrid(context, [
          _Stat('Contributions', _money(wContrib), Icons.savings, '/welfare/finance'),
          _Stat('Disbursed', _money(wDisb), Icons.volunteer_activism, '/welfare/finance'),
          _Stat('Fund Balance', _money(wBalance), Icons.account_balance_wallet, '/welfare/finance'),
          _Stat('Transactions', '${welfareTxns.length}', Icons.receipt_long, '/welfare/finance/transactions'),
        ]),
        _section('Ministry & Department Finance'),
        _statGrid(context, [
          _Stat('Ministry Income', _money(mIncome), Icons.church, '/ministry/finance'),
          _Stat('Ministry Expenses', _money(mExpense), Icons.payments, '/ministry/finance'),
          _Stat('Net', _money(mIncome - mExpense), Icons.balance, '/ministry/finance'),
          _Stat('Transactions', '${ministryTxns.length}', Icons.receipt_long, '/ministry/finance'),
        ]),
        _section('Department Contributions'),
        _statGrid(context, [
          _Stat('Church Welfare', _money(churchContributions), Icons.savings, '/welfare/finance/contributions'),
          _Stat('Dept Welfare', _money(deptContributions), Icons.groups_2, '/welfare/finance/departments'),
          _Stat('Total', _money(churchContributions + deptContributions), Icons.account_balance_wallet, '/welfare/finance/contributions'),
          _Stat('Contributors', '${contributions.length}', Icons.people, '/welfare/finance/contributions'),
        ]),
        _section('Quick Actions'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: Responsive.actionGridColumns(context),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
            children: [
              _actionBtn(context, Icons.add_card, 'Add Txn', '/finance/add'),
              _actionBtn(context, Icons.account_balance_wallet, 'All Finance', '/finance'),
              _actionBtn(context, Icons.volunteer_activism, 'Welfare', '/welfare/finance'),
              _actionBtn(context, Icons.church, 'Ministry', '/ministry/finance'),
              _actionBtn(context, Icons.savings, 'Contributions', '/welfare/finance/contributions'),
              _actionBtn(context, Icons.payment, 'Payment', '/welfare/finance/payment'),
              _actionBtn(context, Icons.groups_2, 'Dept Welfare', '/welfare/finance/departments'),
              _actionBtn(context, Icons.favorite, 'Tithes', '/finance/tithes-offerings-donations'),
              _actionBtn(context, Icons.account_balance_wallet, 'Budget', '/finance/budget-spending'),
              _actionBtn(context, Icons.add_circle, 'Income', '/finance/income-entry'),
              _actionBtn(context, Icons.approval, 'Approvals', '/finance/approvals'),
              _actionBtn(context, Icons.assessment, 'Reports', '/finance/reports'),
            ],
          ),
        ),
        _section('Recent Transactions', actionLabel: _showAllRecent ? 'Show less' : 'View all', onAction: () => setState(() => _showAllRecent = !_showAllRecent)),
        _buildSearchAndFilter(allCategories),
        if (recent.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Text('No transactions for this period', style: TextStyle(color: Colors.grey)),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
            child: Column(
              children: recent.map((t) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(t.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    color: t.isIncome ? Colors.blue : Colors.red, size: 20),
                title: Text('${t.category} - ${_money(t.amount)}',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text('${t.isIncome ? "Income" : "Expense"} - ${DateFormat('MMM d, y').format(t.date)}${t.isRecurring ? ' - ${RecurrenceInterval.label(t.recurrenceInterval)}' : ''}',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[600])),
                onTap: () => context.push('/finance/edit/${t.id}'),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppColors.spacing24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: EmeraldTheme.cardDecoration,
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: _prevMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        Expanded(
          child: Center(
            child: Text(
              _monthFmt.format(_selectedMonth),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.emeraldTextPrimary),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: _nextMonth,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  Widget _buildPeriodToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Row(children: [
        Text('Showing data for: ',
            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.emeraldTextSecondary)),
        Text(_monthFmt.format(_selectedMonth),
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]),
    );
  }

  Widget _buildMoMComparison(double incomeChange, double expenseChange, double balanceChange) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: EmeraldTheme.cardDecoration,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMoMItem('Income', incomeChange, true),
            _buildMoMItem('Expenses', expenseChange, false),
            _buildMoMItem('Balance', balanceChange, true),
          ],
        ),
      ),
    );
  }

  Widget _buildMoMItem(String label, double pct, bool higherIsBetter) {
    final isUp = pct > 0;
    final isGood = higherIsBetter ? isUp : !isUp;
    final color = isGood ? AppColors.successGreen : AppColors.errorRed;
    final icon = isUp ? Icons.arrow_upward : (pct < 0 ? Icons.arrow_downward : Icons.remove);
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.emeraldTextSecondary)),
        const SizedBox(height: 2),
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 2),
          Text('${pct.abs().toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ]),
        Text('vs last month', style: GoogleFonts.poppins(fontSize: 9, color: AppColors.emeraldTextMuted)),
      ],
    );
  }

  Widget _buildMiniBarChart(List<_MonthData> data) {
    final maxVal = data.fold<double>(0, (m, d) => math.max(m, math.max(d.income, d.expense)));
    if (maxVal == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
        child: Text('No data for chart', style: GoogleFonts.poppins(fontSize: 12, color: AppColors.emeraldTextSecondary)),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: EmeraldTheme.cardDecoration,
        child: SizedBox(
          height: 120,
          child: CustomPaint(
            size: Size.infinite,
            painter: _BarChartPainter(data, maxVal),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalsBanner(int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.pending_actions, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count pending approval(s) awaiting review',
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.amber[800]),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/finance/approvals'),
            child: const Text('Review'),
          ),
        ]),
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget, List<FinanceTransaction> monthTx) {
    final actual = monthTx.where((t) {
      return t.category == budget.category &&
          BudgetPeriod.key(t.date) == budget.period &&
          !t.isIncome;
    }).fold<double>(0, (s, t) => s + t.amount);
    final pct = budget.allocatedAmount > 0 ? (actual / budget.allocatedAmount).clamp(0.0, 1.0) : 0.0;
    final over = actual > budget.allocatedAmount;
    final remaining = budget.allocatedAmount - actual;
    final isWarning = pct >= 0.8 && !over;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: EmeraldTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(budget.category, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
                Text(BudgetPeriod.label(budget.period), style: GoogleFonts.poppins(fontSize: 11, color: AppColors.emeraldTextSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _budgetAmountBlock('Budgeted', budget.allocatedAmount, AppColors.primary)),
                Expanded(child: _budgetAmountBlock('Spent', actual, over ? Colors.red : Colors.blue)),
                Expanded(child: _budgetAmountBlock('Remaining', remaining, over ? Colors.red : AppColors.emeraldTextPrimary)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: pct,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(over ? Colors.red : (isWarning ? Colors.orange : AppColors.primary)),
            ),
            if (over)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Over budget by ${_money(actual - budget.allocatedAmount)}',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.red, fontWeight: FontWeight.w600)),
              )
            else if (isWarning)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('${(pct * 100).toStringAsFixed(0)}% of budget used',
                    style: GoogleFonts.poppins(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _budgetAmountBlock(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 10, color: AppColors.emeraldTextSecondary)),
        const SizedBox(height: 2),
        Text(_money(amount), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildSearchAndFilter(List<String> allCategories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24, vertical: 4),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search transactions...',
              prefixIcon: const Icon(Icons.search, size: 18),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _categoryFilter == null,
                  onSelected: (_) => setState(() => _categoryFilter = null),
                ),
                const SizedBox(width: 6),
                ...allCategories.map((c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c),
                    selected: _categoryFilter == c,
                    onSelected: (_) => setState(() => _categoryFilter = _categoryFilter == c ? null : c),
                  ),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, {String? actionLabel, VoidCallback? onAction}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.emeraldTextPrimary)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }

  Widget _statGrid(BuildContext context, List<_Stat> stats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppColors.spacing24),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: Responsive.statGridColumns(context),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: Responsive.isMobile(context) ? 1.1 : 1.3,
        children: stats.map((s) => _statCard(context, s)).toList(),
      ),
    );
  }

  Widget _statCard(BuildContext context, _Stat s) {
    return InkWell(
      onTap: s.route != null ? () => context.push(s.route!) : null,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(s.icon, size: 16, color: AppColors.primary),
            Text(s.value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emeraldTextPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(s.title, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.emeraldTextSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          const SizedBox(width: 4),
          Text(_money(amount), style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _actionBtn(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDefault, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w500, color: AppColors.emeraldTextPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  final String title;
  final String value;
  final IconData icon;
  final String? route;
  const _Stat(this.title, this.value, this.icon, [this.route]);
}

class _MonthData {
  final String label;
  final double income;
  final double expense;
  const _MonthData(this.label, this.income, this.expense);
}

class _BarChartPainter extends CustomPainter {
  final List<_MonthData> data;
  final double maxVal;

  _BarChartPainter(this.data, this.maxVal);

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = (size.width - (data.length + 1) * 8) / (data.length * 2);
    final chartHeight = size.height - 20;

    for (var i = 0; i < data.length; i++) {
      final d = data[i];
      final xStart = 8.0 + i * (barWidth * 2 + 8);

      final incomeHeight = (d.income / maxVal * chartHeight).clamp(2.0, chartHeight);
      final expenseHeight = (d.expense / maxVal * chartHeight).clamp(2.0, chartHeight);

      final incomeRect = RRect.fromRectXY(
        Rect.fromLTWH(xStart, chartHeight - incomeHeight, barWidth, incomeHeight),
        3, 3,
      );
      canvas.drawRRect(incomeRect, Paint()..color = AppColors.infoBlue);

      final expenseRect = RRect.fromRectXY(
        Rect.fromLTWH(xStart + barWidth + 2, chartHeight - expenseHeight, barWidth, expenseHeight),
        3, 3,
      );
      canvas.drawRRect(expenseRect, Paint()..color = AppColors.errorRed);

      final tp = TextPainter(
        text: TextSpan(text: d.label, style: const TextStyle(fontSize: 9, color: AppColors.emeraldTextSecondary)),
        textDirection: ui.TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(xStart + barWidth - tp.width / 2 + 1, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
