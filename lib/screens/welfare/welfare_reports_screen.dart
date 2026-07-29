import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/welfare_case.dart';
import '../../models/welfare_finance.dart';
import '../../models/welfare_statement.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/welfare_pdf_service.dart';

final _currencyFmt = NumberFormat('#,##0.00');

class WelfareReportsScreen extends ConsumerStatefulWidget {
  const WelfareReportsScreen({super.key});

  @override
  ConsumerState<WelfareReportsScreen> createState() =>
      _WelfareReportsScreenState();
}

class _WelfareReportsScreenState
    extends ConsumerState<WelfareReportsScreen> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _endDate = DateTime.now();
  String _reportType = 'summary';

  @override
  Widget build(BuildContext context) {
    final txns = ref.watch(welfareFinanceProvider);
    final welfareCases = ref.watch(welfareProvider);
    final members = ref.watch(memberProvider);

    // Filter by date range
    final filteredTxns = txns.where((t) {
      return t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredCases = welfareCases.where((w) {
      return w.dateRequested
              .isAfter(_startDate.subtract(const Duration(days: 1))) &&
          w.dateRequested.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: 'Print Report',
            onPressed: () => _printReport(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download PDF',
            onPressed: () => _downloadPdf(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share to Member',
            onPressed: () => _showShareDialog(context, ref, members),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Report Period',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(true),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                                'From: ${DateFormat('MMM d, y').format(_startDate)}'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickDate(false),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                                'To: ${DateFormat('MMM d, y').format(_endDate)}'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        ActionChip(
                          label: const Text('This Month'),
                          onPressed: () => setState(() {
                            _startDate = DateTime(DateTime.now().year,
                                DateTime.now().month, 1);
                            _endDate = DateTime.now();
                          }),
                        ),
                        ActionChip(
                          label: const Text('This Year'),
                          onPressed: () => setState(() {
                            _startDate =
                                DateTime(DateTime.now().year, 1, 1);
                            _endDate = DateTime.now();
                          }),
                        ),
                        ActionChip(
                          label: const Text('Last 3 Months'),
                          onPressed: () => setState(() {
                            _startDate = DateTime.now()
                                .subtract(const Duration(days: 90));
                            _endDate = DateTime.now();
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _reportType,
                      decoration: const InputDecoration(
                          labelText: 'Report Type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'summary', child: Text('Summary Report')),
                        DropdownMenuItem(
                            value: 'financial',
                            child: Text('Financial Analytics')),
                        DropdownMenuItem(
                            value: 'cases', child: Text('Welfare Cases Report')),
                        DropdownMenuItem(
                            value: 'contributions',
                            child: Text('Contributions Report')),
                        DropdownMenuItem(
                            value: 'department',
                            child: Text('Department Welfare Report')),
                      ],
                      onChanged: (v) => setState(() => _reportType = v!),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report content
            if (_reportType == 'summary')
              _SummaryReport(
                  txns: filteredTxns,
                  welfareCases: filteredCases,
                  members: members),
            if (_reportType == 'financial')
              _FinancialAnalytics(txns: filteredTxns),
            if (_reportType == 'cases')
              _CasesReport(welfareCases: filteredCases, members: members),
            if (_reportType == 'contributions')
              _ContributionsReport(txns: filteredTxns, members: members),
            if (_reportType == 'department')
              _DepartmentReport(txns: filteredTxns, members: members),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _reportTypeLabel() {
    switch (_reportType) {
      case 'summary':
        return 'Welfare Summary Report';
      case 'financial':
        return 'Financial Analytics Report';
      case 'cases':
        return 'Welfare Cases Report';
      case 'contributions':
        return 'Contributions Report';
      case 'department':
        return 'Department Welfare Report';
      default:
        return 'Welfare Report';
    }
  }

  Future<void> _printReport(BuildContext context, WidgetRef ref) async {
    final appState = ref.read(appStateProvider);
    final txns = ref.read(welfareFinanceProvider);
    final welfareCases = ref.read(welfareProvider);
    final members = ref.read(memberProvider);

    final filteredTxns = txns.where((t) {
      return t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredCases = welfareCases.where((w) {
      return w.dateRequested
              .isAfter(_startDate.subtract(const Duration(days: 1))) &&
          w.dateRequested.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    try {
      await WelfarePdfService.printReport(
        title: _reportTypeLabel(),
        churchName: appState.church?.name ?? 'Paradise AG',
        startDate: _startDate,
        endDate: _endDate,
        transactions: filteredTxns,
        welfareCases: filteredCases,
        members: members,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    final appState = ref.read(appStateProvider);
    final txns = ref.read(welfareFinanceProvider);
    final welfareCases = ref.read(welfareProvider);
    final members = ref.read(memberProvider);

    final filteredTxns = txns.where((t) {
      return t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final filteredCases = welfareCases.where((w) {
      return w.dateRequested
              .isAfter(_startDate.subtract(const Duration(days: 1))) &&
          w.dateRequested.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    try {
      final bytes = await WelfarePdfService.generateReportPdf(
        title: _reportTypeLabel(),
        churchName: appState.church?.name ?? 'Paradise AG',
        startDate: _startDate,
        endDate: _endDate,
        transactions: filteredTxns,
        welfareCases: filteredCases,
        members: members,
      );
      final filename =
          'welfare_report_${_reportType}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await WelfarePdfService.downloadPdf(bytes, filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  void _showShareDialog(
      BuildContext context, WidgetRef ref, List<Member> members) {
    String? selectedMemberId;
    final messageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Share Report to Member'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Share: ${_reportTypeLabel()}',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMemberId,
                  decoration: const InputDecoration(
                    labelText: 'Select Member',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  items: members
                      .map((m) => DropdownMenuItem(
                          value: m.id, child: Text(m.name)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => selectedMemberId = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Message (optional)',
                    prefixIcon: Icon(Icons.message_outlined),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Share'),
              onPressed: selectedMemberId == null
                  ? null
                  : () async {
                      final appState = ref.read(appStateProvider);
                      final report = SharedReport(
                        id: const Uuid().v4(),
                        churchId: appState.church?.id ?? '',
                        branchId: appState.user?.branchId ?? '',
                        title: _reportTypeLabel(),
                        reportType: _reportType,
                        sharedById: appState.user?.id ?? '',
                        sharedToMemberId: selectedMemberId!,
                        sharedAt: DateTime.now(),
                        message: messageCtrl.text.isNotEmpty
                            ? messageCtrl.text
                            : null,
                      );
                      await ref
                          .read(sharedReportProvider.notifier)
                          .add(report);
                      if (ctx.mounted) Navigator.pop(dialogContext);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Report shared to member')),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Summary Report ───────────────────────────────────────────────────────────

class _SummaryReport extends StatelessWidget {
  final List<WelfareTransaction> txns;
  final List<WelfareCase> welfareCases;
  final List<Member> members;

  const _SummaryReport({
    required this.txns,
    required this.welfareCases,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final contributions =
        txns.where((t) => t.isContribution).fold<double>(0, (s, t) => s + t.amount);
    final disbursements =
        txns.where((t) => t.isDisbursement).fold<double>(0, (s, t) => s + t.amount);
    final expenses =
        txns.where((t) => t.isExpense).fold<double>(0, (s, t) => s + t.amount);
    final balance = contributions - disbursements - expenses;

    final openCases = welfareCases.where((w) => w.status == WelfareStatus.open).length;
    final closedCases =
        welfareCases.where((w) => w.status == WelfareStatus.closed).length;
    final urgentCases = welfareCases
        .where((w) =>
            w.priority == WelfarePriority.urgent &&
            w.status != WelfareStatus.closed)
        .length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welfare Summary Report',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _ReportSection(title: 'Financial Overview', children: [
              _ReportRow('Total Contributions', _currencyFmt.format(contributions),
                  color: Colors.green),
              _ReportRow('Total Disbursements', _currencyFmt.format(disbursements),
                  color: Colors.blue),
              _ReportRow('Total Expenses', _currencyFmt.format(expenses),
                  color: Colors.orange),
              _ReportRow('Net Balance', _currencyFmt.format(balance),
                  bold: true, color: AppColors.emeraldDeep),
              _ReportRow('Total Transactions', '${txns.length}'),
            ]),
            const SizedBox(height: 16),
            _ReportSection(title: 'Welfare Cases', children: [
              _ReportRow('Total Cases', '${welfareCases.length}'),
              _ReportRow('Open Cases', '$openCases'),
              _ReportRow('Closed Cases', '$closedCases'),
              _ReportRow('Urgent Cases', '$urgentCases',
                  color: urgentCases > 0 ? Colors.red : null),
              _ReportRow(
                  'Total Requested',
                  _currencyFmt.format(
                      welfareCases.fold(0.0, (s, w) => s + w.amountRequested))),
              _ReportRow(
                  'Total Disbursed (Cases)',
                  _currencyFmt.format(
                      welfareCases.fold(0.0, (s, w) => s + w.amountDisbursed))),
            ]),
            const SizedBox(height: 16),
            _ReportSection(title: 'Members', children: [
              _ReportRow('Total Members', '${members.length}'),
              _ReportRow('Members with Cases',
                  '${welfareCases.map((w) => w.memberId).toSet().length}'),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Financial Analytics ──────────────────────────────────────────────────────

class _FinancialAnalytics extends StatelessWidget {
  final List<WelfareTransaction> txns;

  const _FinancialAnalytics({required this.txns});

  @override
  Widget build(BuildContext context) {
    final contributions =
        txns.where((t) => t.isContribution).toList();
    final disbursements =
        txns.where((t) => t.isDisbursement).toList();
    final expenses = txns.where((t) => t.isExpense).toList();

    final totalContributions =
        contributions.fold<double>(0, (s, t) => s + t.amount);
    final totalDisbursements =
        disbursements.fold<double>(0, (s, t) => s + t.amount);
    final totalExpenses =
        expenses.fold<double>(0, (s, t) => s + t.amount);

    // Monthly breakdown
    final monthly = <String, _MonthData>{};
    for (final t in txns) {
      final key = DateFormat('MMM y').format(t.date);
      monthly.putIfAbsent(key, () => _MonthData());
      if (t.isContribution) {
        monthly[key]!.contributions += t.amount;
      } else if (t.isDisbursement) {
        monthly[key]!.disbursements += t.amount;
      } else {
        monthly[key]!.expenses += t.amount;
      }
    }

    // Payment method breakdown
    final methodTotals = <String, double>{};
    for (final t in txns) {
      methodTotals.update(t.paymentMethod, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }

    // Top contributors
    final contributorTotals = <String, double>{};
    for (final t in contributions) {
      contributorTotals.update(t.memberId, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    final topContributors = contributorTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Disbursement ratio
    final disbursementRatio = totalContributions > 0
        ? (totalDisbursements / totalContributions * 100)
        : 0.0;
    final expenseRatio = totalContributions > 0
        ? (totalExpenses / totalContributions * 100)
        : 0.0;
    final savingsRatio = 100 - disbursementRatio - expenseRatio;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Financial Analytics',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),

            // Key ratios
            _ReportSection(title: 'Key Financial Ratios', children: [
              _ReportRow('Disbursement Rate',
                  '${disbursementRatio.toStringAsFixed(1)}%'),
              _ReportRow('Expense Rate',
                  '${expenseRatio.toStringAsFixed(1)}%'),
              _ReportRow('Savings Rate',
                  '${savingsRatio.toStringAsFixed(1)}%',
                  color: savingsRatio > 0 ? Colors.green : Colors.red),
              _ReportRow('Avg Contribution',
                  _currencyFmt.format(contributions.isNotEmpty ? totalContributions / contributions.length : 0)),
              _ReportRow('Avg Disbursement',
                  _currencyFmt.format(disbursements.isNotEmpty ? totalDisbursements / disbursements.length : 0)),
            ]),

            const SizedBox(height: 16),

            // Monthly trend
            _ReportSection(title: 'Monthly Trend', children: [
              ...monthly.entries.map((e) {
                final net = e.value.contributions -
                    e.value.disbursements -
                    e.value.expenses;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 80,
                          child: Text(e.key,
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500))),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'In: ${_currencyFmt.format(e.value.contributions)} | Out: ${_currencyFmt.format(e.value.disbursements + e.value.expenses)} | Net: ${_currencyFmt.format(net)}',
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: net >= 0 ? Colors.green : Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ]),

            const SizedBox(height: 16),

            // Payment method breakdown
            _ReportSection(title: 'Payment Methods', children: [
              ...(methodTotals.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .map((e) => _ReportRow(
                      WelfarePaymentMethod.label(e.key),
                      _currencyFmt.format(e.value))),
            ]),

            const SizedBox(height: 16),

            // Top contributors
            _ReportSection(title: 'Top Contributors', children: [
              if (topContributors.isEmpty)
                Text('No contributions in this period',
                    style: GoogleFonts.poppins(
                        fontSize: 13, color: Colors.grey))
              else
                ...topContributors.take(10).toList().asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  return _ReportRow('${i + 1}. Member ${c.key.substring(0, 6)}...',
                      _currencyFmt.format(c.value));
                }),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Cases Report ─────────────────────────────────────────────────────────────

class _CasesReport extends StatelessWidget {
  final List<WelfareCase> welfareCases;
  final List<Member> members;

  const _CasesReport({
    required this.welfareCases,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    // Type breakdown
    final typeCount = <String, int>{};
    for (final w in welfareCases) {
      typeCount.update(w.type, (v) => v + 1, ifAbsent: () => 1);
    }

    // Status breakdown
    final statusCount = <String, int>{};
    for (final w in welfareCases) {
      statusCount.update(w.status, (v) => v + 1, ifAbsent: () => 1);
    }

    // Priority breakdown
    final priorityCount = <String, int>{};
    for (final w in welfareCases) {
      priorityCount.update(w.priority, (v) => v + 1, ifAbsent: () => 1);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welfare Cases Report',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _ReportSection(title: 'By Type', children: [
              ...(typeCount.entries.toList()
                    ..sort((a, b) => b.value.compareTo(a.value)))
                  .map((e) => _ReportRow(WelfareType.label(e.key), '${e.value} cases')),
            ]),
            const SizedBox(height: 16),
            _ReportSection(title: 'By Status', children: [
              ...statusCount.entries.map((e) =>
                  _ReportRow(WelfareStatus.label(e.key), '${e.value} cases')),
            ]),
            const SizedBox(height: 16),
            _ReportSection(title: 'By Priority', children: [
              ...priorityCount.entries.map((e) =>
                  _ReportRow(WelfarePriority.label(e.key), '${e.value} cases')),
            ]),
            const SizedBox(height: 16),
            _ReportSection(title: 'Financial Impact', children: [
              _ReportRow(
                  'Total Requested',
                  _currencyFmt.format(
                      welfareCases.fold(0.0, (s, w) => s + w.amountRequested))),
              _ReportRow(
                  'Total Disbursed',
                  _currencyFmt.format(
                      welfareCases.fold(0.0, (s, w) => s + w.amountDisbursed))),
              _ReportRow(
                  'Outstanding',
                  _currencyFmt.format(welfareCases.fold(
                      0.0,
                      (s, w) =>
                          s + (w.amountRequested - w.amountDisbursed)))),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Contributions Report ─────────────────────────────────────────────────────

class _ContributionsReport extends StatelessWidget {
  final List<WelfareTransaction> txns;
  final List<Member> members;

  const _ContributionsReport({
    required this.txns,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    final contributions = txns.where((t) => t.isContribution).toList();
    final total = contributions.fold<double>(0, (s, t) => s + t.amount);

    // Per member
    final perMember = <String, double>{};
    for (final t in contributions) {
      perMember.update(t.memberId, (v) => v + t.amount,
          ifAbsent: () => t.amount);
    }
    final sorted = perMember.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contributions Report',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _ReportRow('Total Contributions', _currencyFmt.format(total),
                bold: true),
            _ReportRow('Number of Contributions', '${contributions.length}'),
            _ReportRow('Average Contribution',
                _currencyFmt.format(contributions.isNotEmpty ? total / contributions.length : 0)),
            _ReportRow('Unique Contributors', '${perMember.length}'),
            const SizedBox(height: 16),
            Text('Per Member Breakdown',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (sorted.isEmpty)
              Text('No contributions in this period',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey))
            else
              ...sorted.map((e) {
                final member =
                    members.where((m) => m.id == e.key).firstOrNull;
                final pct = total > 0 ? (e.value / total * 100) : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(member?.name ?? 'Unknown',
                            style: GoogleFonts.poppins(fontSize: 13)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(_currencyFmt.format(e.value),
                            style: GoogleFonts.poppins(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text('${pct.toStringAsFixed(1)}%',
                            style: GoogleFonts.poppins(
                                fontSize: 12, color: Colors.grey[600])),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Department Welfare Report ────────────────────────────────────────────────

class _DepartmentReport extends ConsumerWidget {
  final List<WelfareTransaction> txns;
  final List<Member> members;

  const _DepartmentReport({
    required this.txns,
    required this.members,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptWelfares = ref.watch(departmentWelfareProvider);
    final deptTxns = txns.where((t) => t.departmentId != null).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department Welfare Report',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            if (deptWelfares.isEmpty)
              Text('No department welfare funds set up',
                  style: GoogleFonts.poppins(
                      fontSize: 13, color: Colors.grey))
            else
              ...deptWelfares.map((dw) {
                final dwTxns =
                    deptTxns.where((t) => t.departmentId == dw.departmentId).toList();
                final dwContributions = dwTxns
                    .where((t) => t.isContribution)
                    .fold<double>(0, (s, t) => s + t.amount);
                final dwDisbursements = dwTxns
                    .where((t) => !t.isContribution)
                    .fold<double>(0, (s, t) => s + t.amount);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dw.departmentName,
                            style: GoogleFonts.poppins(
                                fontSize: 15, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        _ReportRow('Fund Balance',
                            _currencyFmt.format(dw.fundBalance),
                            bold: true),
                        _ReportRow('Total Contributions (All Time)',
                            _currencyFmt.format(dw.totalContributions)),
                        _ReportRow('Total Disbursements (All Time)',
                            _currencyFmt.format(dw.totalDisbursements)),
                        _ReportRow('Contributions (Period)',
                            _currencyFmt.format(dwContributions)),
                        _ReportRow('Disbursements (Period)',
                            _currencyFmt.format(dwDisbursements)),
                        _ReportRow('Transactions (Period)',
                            '${dwTxns.length}'),
                        _ReportRow('Status',
                            dw.isActive ? 'Active' : 'Inactive'),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

class _ReportSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ReportSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 15, fontWeight: FontWeight.w600,
                color: AppColors.emeraldDeep)),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _ReportRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? color;

  const _ReportRow(this.label, this.value, {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
                  color: Colors.grey[700])),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }
}

class _MonthData {
  double contributions = 0;
  double disbursements = 0;
  double expenses = 0;
}
