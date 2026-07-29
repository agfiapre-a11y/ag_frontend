import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/welfare_finance.dart';
import '../../models/department.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';

final _currencyFmt = NumberFormat('#,##0.00');
const _uuid = Uuid();

class DepartmentWelfareScreen extends ConsumerWidget {
  const DepartmentWelfareScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptWelfares = ref.watch(departmentWelfareProvider);
    final departments = ref.watch(departmentProvider);
    final user = ref.watch(appStateProvider).user!;

    // Departments without welfare setup
    final deptsWithWelfare = deptWelfares.map((d) => d.departmentId).toSet();
    final deptsWithoutWelfare =
        departments.where((d) => !deptsWithWelfare.contains(d.id)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Department Welfare')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Department Welfare Funds',
                style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Manage welfare funds for each department',
                style: GoogleFonts.poppins(
                    fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 16),

            // Active department welfare funds
            if (deptWelfares.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.groups_2, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text('No department welfare funds set up',
                          style: GoogleFonts.poppins(color: Colors.grey)),
                      const SizedBox(height: 16),
                      if (deptsWithoutWelfare.isNotEmpty)
                        ElevatedButton.icon(
                          onPressed: () => _showSetupDialog(
                              context, ref, deptsWithoutWelfare, user.id),
                          icon: const Icon(Icons.add),
                          label: const Text('Set Up Department Welfare'),
                        ),
                    ],
                  ),
                ),
              )
            else
              ...deptWelfares.map((dw) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: dw.isActive
                          ? AppColors.emeraldDeep.withValues(alpha: 0.1)
                          : Colors.grey[200],
                      child: Icon(Icons.groups_2,
                          color: dw.isActive
                              ? AppColors.emeraldDeep
                              : Colors.grey),
                    ),
                    title: Text(dw.departmentName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600)),
                    subtitle: Row(
                      children: [
                        Icon(Icons.account_balance_wallet,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text('Balance: ${_currencyFmt.format(dw.fundBalance)}',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: dw.isActive
                                    ? Colors.green
                                    : Colors.grey)),
                        const SizedBox(width: 12),
                        if (!dw.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Inactive',
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: Colors.grey[700])),
                          ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _DeptStatCard(
                                    label: 'Contributions',
                                    value: _currencyFmt
                                        .format(dw.totalContributions),
                                    color: Colors.green,
                                    icon: Icons.savings,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DeptStatCard(
                                    label: 'Disbursements',
                                    value: _currencyFmt
                                        .format(dw.totalDisbursements),
                                    color: Colors.blue,
                                    icon: Icons.volunteer_activism,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _DeptStatCard(
                                    label: 'Balance',
                                    value:
                                        _currencyFmt.format(dw.fundBalance),
                                    color: AppColors.emeraldDeep,
                                    icon: Icons.account_balance_wallet,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push(
                                        '/welfare/finance/transactions'),
                                    icon: const Icon(Icons.receipt_long,
                                        size: 18),
                                    label: const Text('View Transactions'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push(
                                        '/welfare/finance/payment'),
                                    icon: const Icon(Icons.payment, size: 18),
                                    label: const Text('Make Payment'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _toggleActive(ref, dw),
                                    icon: Icon(
                                        dw.isActive
                                            ? Icons.pause_circle_outline
                                            : Icons.play_circle_outline,
                                        size: 18),
                                    label: Text(dw.isActive
                                        ? 'Deactivate'
                                        : 'Activate'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        _confirmDelete(context, ref, dw),
                                    icon: const Icon(Icons.delete_outline,
                                        size: 18),
                                    label: const Text('Remove',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

            // Set up welfare for departments without it
            if (deptsWithoutWelfare.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Departments Without Welfare',
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...deptsWithoutWelfare.map((d) => Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      leading:
                          const Icon(Icons.groups_2, color: Colors.grey),
                      title: Text(d.name),
                      trailing: ElevatedButton(
                        onPressed: () => _setupWelfare(context, ref, d, user.id),
                        child: const Text('Set Up'),
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _showSetupDialog(BuildContext context, WidgetRef ref,
      List<Department> departments, String userId) {
    _setupWelfare(context, ref, departments.first, userId);
  }

  Future<void> _setupWelfare(
      BuildContext context, WidgetRef ref, Department dept, String userId) async {
    final appState = ref.read(appStateProvider);
    final dw = DepartmentWelfare(
      id: _uuid.v4(),
      churchId: appState.church?.id ?? '',
      branchId: appState.user?.branchId ?? dept.branchId,
      departmentId: dept.id,
      departmentName: dept.name,
      managedByWelfareHeadId: userId,
      createdAt: DateTime.now(),
    );
    await ref.read(departmentWelfareProvider.notifier).add(dw);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Welfare fund set up for ${dept.name}')),
      );
    }
  }

  Future<void> _toggleActive(WidgetRef ref, DepartmentWelfare dw) async {
    await ref
        .read(departmentWelfareProvider.notifier)
        .update(dw.copyWith(isActive: !dw.isActive));
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, DepartmentWelfare dw) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Department Welfare'),
        content: Text(
            'Are you sure you want to remove the welfare fund for ${dw.departmentName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(departmentWelfareProvider.notifier)
                  .delete(dw.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DeptStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _DeptStatCard({
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.bold)),
          ),
          Text(label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                  fontSize: 10, color: Colors.grey[600])),
        ],
      ),
    );
  }
}
