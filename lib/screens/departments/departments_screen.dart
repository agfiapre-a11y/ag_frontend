import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/branch.dart';
import '../../models/department.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';
import '../../widgets/responsive_scaffold.dart';

class DepartmentsScreen extends ConsumerWidget {
  const DepartmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final departments = ref.watch(departmentProvider);
    final branches = ref.watch(branchProvider);
    final user = ref.watch(appStateProvider).user!;
    final isSuperAdmin = AppRoles.structureManagerRoles.contains(user.role);

    // Group departments by branchId for SuperAdmin
    final Map<String, List<Department>> grouped = {};
    for (final d in departments) {
      grouped.putIfAbsent(d.branchId, () => []).add(d);
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Departments'),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: 'Add Department',
              onPressed: () => context.push('/departments/add'),
            ),
        ],
      ),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/departments/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Department'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.read(departmentProvider.notifier).refresh(),
        child: departments.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.groups_2_outlined,
                        size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('No departments yet',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    if (isSuperAdmin)
                      Text('Tap + to create your first department',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: isSuperAdmin
                    ? _buildGroupedList(
                        context, ref, grouped, branches, isSuperAdmin)
                    : departments
                        .map((d) => _DeptTile(
                            dept: d,
                            branchName: _branchName(d.branchId, branches),
                            canEdit: isSuperAdmin,
                            onDelete: isSuperAdmin
                                ? () => _confirmDelete(context, ref, d)
                                : null))
                        .toList(),
              ),
      ),
    );
  }

  List<Widget> _buildGroupedList(
      BuildContext context,
      WidgetRef ref,
      Map<String, List<Department>> grouped,
      List<Branch> branches,
      bool canEdit) {
    final widgets = <Widget>[];
    for (final branchId in grouped.keys) {
      final branchName = _branchName(branchId, branches);
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(children: [
            const Icon(Icons.account_tree_outlined,
                size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(branchName,
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ]),
        ),
      );
      for (final d in grouped[branchId]!) {
        widgets.add(_DeptTile(
          dept: d,
          branchName: branchName,
          canEdit: canEdit,
          onDelete: () => _confirmDelete(context, ref, d),
        ));
      }
    }
    return widgets;
  }

  String _branchName(String branchId, List<Branch> branches) {
    return branches
            .where((b) => b.id == branchId)
            .firstOrNull
            ?.name ??
        'Unknown Branch';
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, Department dept) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Department'),
        content: Text(
            'Are you sure you want to delete "${dept.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(departmentProvider.notifier).delete(dept.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Department deleted')),
                );
              }
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _DeptTile extends StatelessWidget {
  final Department dept;
  final String branchName;
  final bool canEdit;
  final VoidCallback? onDelete;

  const _DeptTile({
    required this.dept,
    required this.branchName,
    required this.canEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final memberCount = LocalDb.getAllMembers(departmentId: dept.id).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push('/departments/${dept.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child:
                  Icon(Icons.groups_2, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dept.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  if (dept.description.isNotEmpty)
                    Text(dept.description,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.people_outline,
                        size: 12, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('$memberCount members',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ]),
                ],
              ),
            ),
            if (canEdit)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 18, color: AppColors.textSecondary),
                onSelected: (v) {
                  if (v == 'edit') {
                    context.push('/departments/edit/${dept.id}');
                  } else if (v == 'delete') {
                    onDelete?.call();
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: AppColors.error))),
                ],
              )
            else
              const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ]),
        ),
      ),
    );
  }
}
