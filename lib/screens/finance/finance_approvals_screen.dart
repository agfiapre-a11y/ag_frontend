import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/finance_approval.dart';
import '../../models/transaction.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

final _fmt = NumberFormat('#,##0.00');
final _dateFmt = DateFormat('MMM d, yyyy');

class FinanceApprovalsScreen extends ConsumerStatefulWidget {
  const FinanceApprovalsScreen({super.key});

  @override
  ConsumerState<FinanceApprovalsScreen> createState() => _FinanceApprovalsScreenState();
}

class _FinanceApprovalsScreenState extends ConsumerState<FinanceApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final approvals = ref.watch(financeApprovalProvider);
    final user = ref.watch(appStateProvider).user!;
    final canApprove = AppRoles.financeApprovalRoles.contains(user.role);

    final pending = approvals.where((r) => r.status == FinanceApprovalStatus.pending).toList();
    final approved = approvals.where((r) => r.status == FinanceApprovalStatus.approved).toList();
    final rejected = approvals.where((r) => r.status == FinanceApprovalStatus.rejected).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Finance Approvals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(financeApprovalProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Approved', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _ApprovalList(requests: pending, canApprove: canApprove, onApprove: _approve, onReject: _reject),
          _ApprovalList(requests: approved, canApprove: false, onApprove: null, onReject: null),
          _ApprovalList(requests: rejected, canApprove: false, onApprove: null, onReject: null),
        ],
      ),
    );
  }

  Future<void> _approve(FinanceApprovalRequest r) async {
    final user = ref.read(appStateProvider).user!;
    await ref.read(financeApprovalProvider.notifier).approve(r, user.id, user.name);
    final txn = FinanceTransaction(
      id: const Uuid().v4(),
      churchId: r.churchId,
      branchId: r.branchId,
      type: TransactionType.income,
      category: r.category,
      amount: r.amount,
      description: r.description,
      date: r.date,
      recordedById: r.requestedById,
      createdAt: DateTime.now(),
    );
    await ref.read(financeProvider.notifier).add(txn);
  }

  Future<void> _reject(FinanceApprovalRequest r) async {
    final user = ref.read(appStateProvider).user!;
    await ref.read(financeApprovalProvider.notifier).reject(r, user.id, user.name, 'Rejected by approver');
  }
}

class _ApprovalList extends StatelessWidget {
  final List<FinanceApprovalRequest> requests;
  final bool canApprove;
  final Function(FinanceApprovalRequest)? onApprove;
  final Function(FinanceApprovalRequest)? onReject;

  const _ApprovalList({
    required this.requests,
    required this.canApprove,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            const Text('No requests'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, i) {
        final r = requests[i];
        return _ApprovalCard(
          request: r,
          canApprove: canApprove,
          onApprove: onApprove,
          onReject: onReject,
        );
      },
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  final FinanceApprovalRequest request;
  final bool canApprove;
  final Function(FinanceApprovalRequest)? onApprove;
  final Function(FinanceApprovalRequest)? onReject;

  const _ApprovalCard({
    required this.request,
    required this.canApprove,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == FinanceApprovalStatus.pending;

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
              Text(request.type.toUpperCase(), style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
              _StatusBadge(status: request.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(request.category, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(request.description, style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.person, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(request.requestedByName, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(width: 12),
              Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(_dateFmt.format(request.date), style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('GH₵ ${_fmt.format(request.amount)}', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          if (isPending && canApprove) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => onReject?.call(request),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onApprove?.call(request),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Approve'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    switch (status) {
      case FinanceApprovalStatus.approved:
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case FinanceApprovalStatus.rejected:
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
