import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/welfare_statement.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/welfare_pdf_service.dart';

final _dateFmt = DateFormat('MMM d, yyyy');
const _uuid = Uuid();

class WelfareStatementScreen extends ConsumerStatefulWidget {
  const WelfareStatementScreen({super.key});

  @override
  ConsumerState<WelfareStatementScreen> createState() =>
      _WelfareStatementScreenState();
}

class _WelfareStatementScreenState
    extends ConsumerState<WelfareStatementScreen> {
  String? _selectedMemberId;
  String _statementType = StatementType.fullAccount;
  DateTime _startDate = DateTime(DateTime.now().year, 1, 1);
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final statements = ref.watch(welfareStatementProvider);
    final members = ref.watch(memberProvider);
    final user = ref.watch(appStateProvider).user!;
    final isWelfareHead = user.role == AppRoles.welfareHead;

    return Scaffold(
      appBar: AppBar(title: const Text('Welfare Statements')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWelfareHead) ...[
              // Generate statement section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Generate Financial Statement',
                          style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                          'Generate a statement of account for a member\'s welfare contributions',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: Colors.grey[600])),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedMemberId,
                        decoration: const InputDecoration(
                          labelText: 'Select Member',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        items: members
                            .map((m) => DropdownMenuItem(
                                value: m.id, child: Text(m.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedMemberId = v),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _statementType,
                        decoration: const InputDecoration(
                          labelText: 'Statement Type',
                        ),
                        items: StatementType.all
                            .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(StatementType.label(t))))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _statementType = v!),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(true),
                              icon: const Icon(Icons.calendar_today,
                                  size: 18),
                              label: Text(
                                  'From: ${_dateFmt.format(_startDate)}'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _pickDate(false),
                              icon: const Icon(Icons.calendar_today,
                                  size: 18),
                              label:
                                  Text('To: ${_dateFmt.format(_endDate)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _selectedMemberId == null
                                  ? null
                                  : () => _generateStatement(context),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Generate & Preview'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _selectedMemberId == null
                                  ? null
                                  : () => _printStatement(context),
                              icon: const Icon(Icons.print),
                              label: const Text('Print'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Statement requests
            Text('Statement Requests',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (statements.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long,
                          size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                          isWelfareHead
                              ? 'No statement requests yet'
                              : 'You have no statement requests',
                          style: GoogleFonts.poppins(color: Colors.grey)),
                      if (!isWelfareHead) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => _showRequestDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Request Statement'),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              ...statements.map((s) {
                final member =
                    members.where((m) => m.id == s.memberId).firstOrNull;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          StatementStatus.color(s.status).withValues(alpha: 0.12),
                      child: Icon(StatementStatus.icon(s.status),
                          color: StatementStatus.color(s.status)),
                    ),
                    title: Text(
                        member?.name ?? 'Unknown Member',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      '${StatementType.label(s.statementType)} · ${_dateFmt.format(s.startDate)} - ${_dateFmt.format(s.endDate)}',
                      style: GoogleFonts.poppins(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: StatementStatus.color(s.status)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            StatementStatus.label(s.status),
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: StatementStatus.color(s.status)),
                          ),
                        ),
                        if (isWelfareHead &&
                            s.status == StatementStatus.pending) ...[
                          const SizedBox(width: 4),
                          PopupMenuButton(
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                  value: 'approve',
                                  child: Text('Approve & Generate')),
                              const PopupMenuItem(
                                  value: 'reject',
                                  child: Text('Reject')),
                            ],
                            onSelected: (v) {
                              if (v == 'approve') {
                                _approveStatement(s);
                              } else {
                                _rejectStatement(context, s);
                              }
                            },
                          ),
                        ],
                        if (s.status == StatementStatus.generated) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.download, size: 20),
                            onPressed: () => _downloadStatement(context, s),
                            tooltip: 'Download PDF',
                          ),
                          IconButton(
                            icon: const Icon(Icons.print, size: 20),
                            onPressed: () => _printExistingStatement(context, s),
                            tooltip: 'Print',
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),

            if (!isWelfareHead) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showRequestDialog(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Request New Statement'),
                ),
              ),
            ],
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

  Future<void> _generateStatement(BuildContext context) async {
    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final stmt = WelfareStatement(
      id: _uuid.v4(),
      churchId: appState.church?.id ?? '',
      branchId: user.branchId,
      memberId: _selectedMemberId!,
      requestedById: user.id,
      approvedById: user.id,
      status: StatementStatus.generated,
      statementType: _statementType,
      startDate: _startDate,
      endDate: _endDate,
      requestedAt: DateTime.now(),
      approvedAt: DateTime.now(),
      generatedAt: DateTime.now(),
    );
    await ref.read(welfareStatementProvider.notifier).add(stmt);
    if (context.mounted) await _printExistingStatement(context, stmt);
  }

  Future<void> _printStatement(BuildContext context) async {
    await _generateStatement(context);
  }

  void _showRequestDialog(BuildContext context) {
    String stmtType = StatementType.fullAccount;
    DateTime startDate = DateTime(DateTime.now().year, 1, 1);
    DateTime endDate = DateTime.now();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Request Statement'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: stmtType,
                  decoration: const InputDecoration(
                      labelText: 'Statement Type'),
                  items: StatementType.all
                      .map((t) => DropdownMenuItem(
                          value: t, child: Text(StatementType.label(t))))
                      .toList(),
                  onChanged: (v) => setState(() => stmtType = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => startDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_dateFmt.format(startDate)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: endDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => endDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(_dateFmt.format(endDate)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final appState = ref.read(appStateProvider);
                final user = appState.user!;
                final stmt = WelfareStatement(
                  id: _uuid.v4(),
                  churchId: appState.church?.id ?? '',
                  branchId: user.branchId,
                  memberId: user.id,
                  requestedById: user.id,
                  status: StatementStatus.pending,
                  statementType: stmtType,
                  startDate: startDate,
                  endDate: endDate,
                  requestedAt: DateTime.now(),
                );
                await ref
                    .read(welfareStatementProvider.notifier)
                    .add(stmt);
                if (ctx.mounted) Navigator.pop(dialogContext);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text(
                            'Statement request submitted. Welfare Head will review it.')),
                  );
                }
              },
              child: const Text('Submit Request'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveStatement(WelfareStatement stmt) async {
    final user = ref.read(appStateProvider).user!;
    await ref.read(welfareStatementProvider.notifier).update(
          stmt.copyWith(
            status: StatementStatus.generated,
            approvedById: user.id,
            approvedAt: DateTime.now(),
            generatedAt: DateTime.now(),
          ),
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Statement approved and generated')),
      );
    }
  }

  void _rejectStatement(BuildContext context, WelfareStatement stmt) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Statement Request'),
        content: TextField(
          controller: reasonCtrl,
          decoration: const InputDecoration(
              labelText: 'Reason for rejection'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(welfareStatementProvider.notifier).update(
                    stmt.copyWith(
                      status: StatementStatus.rejected,
                      rejectionReason: reasonCtrl.text,
                      approvedAt: DateTime.now(),
                    ),
                  );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Reject',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadStatement(
      BuildContext context, WelfareStatement stmt) async {
    final appState = ref.read(appStateProvider);
    final members = ref.read(memberProvider);
    final allTxns = ref.read(welfareFinanceProvider);

    final member = members.where((m) => m.id == stmt.memberId).firstOrNull;
    var memberTxns = allTxns.where((t) => t.memberId == stmt.memberId).toList();
    memberTxns = memberTxns.where((t) {
      return t.date
              .isAfter(stmt.startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(stmt.endDate.add(const Duration(days: 1)));
    }).toList();

    if (stmt.statementType == StatementType.contributions) {
      memberTxns = memberTxns.where((t) => t.isContribution).toList();
    } else if (stmt.statementType == StatementType.disbursements) {
      memberTxns = memberTxns.where((t) => t.isDisbursement).toList();
    }

    try {
      final bytes = await WelfarePdfService.generateStatementPdf(
        churchName: appState.church?.name ?? 'Paradise AG',
        memberName: member?.name ?? 'Unknown',
        statement: stmt,
        transactions: memberTxns,
      );
      final filename =
          'statement_${stmt.memberId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf';
      await WelfarePdfService.downloadPdf(bytes, filename);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _printExistingStatement(
      BuildContext context, WelfareStatement stmt) async {
    final appState = ref.read(appStateProvider);
    final members = ref.read(memberProvider);
    final allTxns = ref.read(welfareFinanceProvider);

    final member = members.where((m) => m.id == stmt.memberId).firstOrNull;
    var memberTxns = allTxns.where((t) => t.memberId == stmt.memberId).toList();
    memberTxns = memberTxns.where((t) {
      return t.date
              .isAfter(stmt.startDate.subtract(const Duration(days: 1))) &&
          t.date.isBefore(stmt.endDate.add(const Duration(days: 1)));
    }).toList();

    if (stmt.statementType == StatementType.contributions) {
      memberTxns = memberTxns.where((t) => t.isContribution).toList();
    } else if (stmt.statementType == StatementType.disbursements) {
      memberTxns = memberTxns.where((t) => t.isDisbursement).toList();
    }

    try {
      await WelfarePdfService.printStatement(
        churchName: appState.church?.name ?? 'Paradise AG',
        memberName: member?.name ?? 'Unknown',
        statement: stmt,
        transactions: memberTxns,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Print failed: $e')),
        );
      }
    }
  }
}
