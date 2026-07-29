import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../core/constants.dart';
import '../../models/ministry.dart';
import '../../models/ministry_finance.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _dateFmt = DateFormat('MMM d, yyyy');

class MinistryReportsScreen extends ConsumerStatefulWidget {
  final String ministryType;

  const MinistryReportsScreen({super.key, required this.ministryType});

  @override
  ConsumerState<MinistryReportsScreen> createState() =>
      _MinistryReportsScreenState();
}

class _MinistryReportsScreenState
    extends ConsumerState<MinistryReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 90));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final ministryColor = MinistryType.color(widget.ministryType);
    final ministryLabel = MinistryType.label(widget.ministryType);
    final transactions = ref.watch(ministryFinanceProvider);
    final members = ref.watch(memberProvider);

    // Auto-assigned members based on age/gender
    final autoMembers = MinistryAssignment.getMembersForMinistry(
        members, widget.ministryType);

    // Filter transactions by date range
    final filteredTx = transactions.where((t) {
      return t.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    final totalIncome =
        filteredTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final totalExpense =
        filteredTx.where((t) => !t.isIncome).fold(0.0, (s, t) => s + t.amount);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text('$ministryLabel Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ministryFinanceProvider.notifier).refresh();
              ref.read(memberProvider.notifier).refresh();
            },
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
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emeraldTextPrimary)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(_dateFmt.format(_startDate)),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _startDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setState(() => _startDate = d);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('to'),
                        ),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(_dateFmt.format(_endDate)),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: _endDate,
                                firstDate: _startDate,
                                lastDate: DateTime.now(),
                              );
                              if (d != null) {
                                setState(() => _endDate = d);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Report cards
            _ReportCard(
              title: 'Finance Report',
              description:
                  'Income and expense summary with transaction details',
              icon: Icons.account_balance_wallet,
              color: ministryColor,
              stats: [
                'Income: ${NumberFormat('#,##0.00').format(totalIncome)}',
                'Expense: ${NumberFormat('#,##0.00').format(totalExpense)}',
                'Balance: ${NumberFormat('#,##0.00').format(totalIncome - totalExpense)}',
                'Transactions: ${filteredTx.length}',
              ],
              onPrint: () => _printFinanceReport(filteredTx),
              onDownload: () => _downloadFinanceReport(filteredTx),
            ),
            const SizedBox(height: 12),

            _ReportCard(
              title: 'Member Report',
              description:
                  'All members auto-assigned to $ministryLabel by age and gender',
              icon: Icons.people,
              color: ministryColor,
              stats: [
                'Total Members: ${autoMembers.length}',
                'Male: ${autoMembers.where((m) => m.gender.toLowerCase() == "male").length}',
                'Female: ${autoMembers.where((m) => m.gender.toLowerCase() == "female").length}',
                'No DOB: ${members.where((m) => m.dateOfBirth == null).length}',
              ],
              onPrint: () => _printMemberReport(autoMembers),
              onDownload: () => _downloadMemberReport(autoMembers),
            ),
            const SizedBox(height: 12),

            _ReportCard(
              title: 'Ministry Summary',
              description:
                  'Overview of ministry status, membership and finances',
              icon: Icons.assessment,
              color: ministryColor,
              stats: [
                'Ministry: $ministryLabel',
                'Members: ${autoMembers.length}',
                'Transactions: ${filteredTx.length}',
                'Period: ${_dateFmt.format(_startDate)} - ${_dateFmt.format(_endDate)}',
              ],
              onPrint: () => _printSummaryReport(autoMembers, filteredTx),
              onDownload: () => _downloadSummaryReport(autoMembers, filteredTx),
            ),

            // Auto-assignment info
            const SizedBox(height: 20),
            Card(
              color: ministryColor.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: ministryColor),
                        const SizedBox(width: 8),
                        Text('Auto-Assignment Rules',
                            style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: ministryColor)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Below 13 years → Children\'s Ministry\n'
                      '• 13 to 45 years → Youth Ministry\n'
                      '• Above 45 years (Male) → Men\'s Fellowship\n'
                      '• Above 45 years (Female) → Women\'s Fellowship',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printFinanceReport(List<MinistryFinance> txs) async {
    final appState = ref.read(appStateProvider);
    final churchName = appState.church?.name ?? 'Church';
    final pdfBytes = await MinistryPdfService.generateFinanceReport(
      title: 'Finance Report',
      ministryName: MinistryType.label(widget.ministryType),
      churchName: churchName,
      startDate: _startDate,
      endDate: _endDate,
      transactions: txs,
    );
    await Printing.layoutPdf(
      name: '${MinistryType.shortLabel(widget.ministryType)}_Finance_Report',
      onLayout: (_) async => pdfBytes,
    );
  }

  Future<void> _downloadFinanceReport(List<MinistryFinance> txs) async {
    final appState = ref.read(appStateProvider);
    final churchName = appState.church?.name ?? 'Church';
    final pdfBytes = await MinistryPdfService.generateFinanceReport(
      title: 'Finance Report',
      ministryName: MinistryType.label(widget.ministryType),
      churchName: churchName,
      startDate: _startDate,
      endDate: _endDate,
      transactions: txs,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          '${MinistryType.shortLabel(widget.ministryType)}_finance_${_dateFmt.format(_endDate)}.pdf',
    );
  }

  Future<void> _printMemberReport(List<Member> members) async {
    final appState = ref.read(appStateProvider);
    final churchName = appState.church?.name ?? 'Church';
    final pdfBytes = await MinistryPdfService.generateMemberReport(
      ministryName: MinistryType.label(widget.ministryType),
      churchName: churchName,
      members: members,
      ministryType: widget.ministryType,
    );
    await Printing.layoutPdf(
      name: '${MinistryType.shortLabel(widget.ministryType)}_Member_Report',
      onLayout: (_) async => pdfBytes,
    );
  }

  Future<void> _downloadMemberReport(List<Member> members) async {
    final appState = ref.read(appStateProvider);
    final churchName = appState.church?.name ?? 'Church';
    final pdfBytes = await MinistryPdfService.generateMemberReport(
      ministryName: MinistryType.label(widget.ministryType),
      churchName: churchName,
      members: members,
      ministryType: widget.ministryType,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          '${MinistryType.shortLabel(widget.ministryType)}_members_${_dateFmt.format(DateTime.now())}.pdf',
    );
  }

  Future<void> _printSummaryReport(
      List<Member> members, List<MinistryFinance> txs) async {
    final appState = ref.read(appStateProvider);
    final churchName = appState.church?.name ?? 'Church';
    final pdfBytes = await MinistryPdfService.generateFinanceReport(
      title: 'Ministry Summary Report',
      ministryName: MinistryType.label(widget.ministryType),
      churchName: churchName,
      startDate: _startDate,
      endDate: _endDate,
      transactions: txs,
    );
    await Printing.layoutPdf(
      name: '${MinistryType.shortLabel(widget.ministryType)}_Summary',
      onLayout: (_) async => pdfBytes,
    );
  }

  Future<void> _downloadSummaryReport(
      List<Member> members, List<MinistryFinance> txs) async {
    final appState = ref.read(appStateProvider);
    final churchName = appState.church?.name ?? 'Church';
    final pdfBytes = await MinistryPdfService.generateFinanceReport(
      title: 'Ministry Summary Report',
      ministryName: MinistryType.label(widget.ministryType),
      churchName: churchName,
      startDate: _startDate,
      endDate: _endDate,
      transactions: txs,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename:
          '${MinistryType.shortLabel(widget.ministryType)}_summary_${_dateFmt.format(DateTime.now())}.pdf',
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> stats;
  final VoidCallback onPrint;
  final VoidCallback onDownload;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.stats,
    required this.onPrint,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emeraldTextPrimary)),
                      Text(description,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: Colors.grey[600])),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 6, color: color),
                      const SizedBox(width: 8),
                      Text(s,
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: Colors.grey[700])),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('Print'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: color),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
