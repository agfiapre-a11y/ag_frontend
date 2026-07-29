import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';
import '../../widgets/responsive_scaffold.dart';

class BranchesScreen extends ConsumerWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchProvider);
    final user = ref.watch(appStateProvider).user!;
    final isSuperAdmin = AppRoles.structureManagerRoles.contains(user.role);

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Branches')),
      floatingActionButton: isSuperAdmin
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/branches/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Branch'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: branches.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_tree_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No branches yet',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary)),
                  if (isSuperAdmin) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/branches/add'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Branch'),
                    ),
                  ],
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: branches.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _BranchTile(branch: branches[i]),
            ),
    );
  }
}

class _BranchTile extends ConsumerWidget {
  final Branch branch;

  const _BranchTile({required this.branch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allMembers = ref.watch(memberProvider);
    final memberCount =
        allMembers.where((m) => m.branchId == branch.id).length;
    final activeCount = allMembers
        .where((m) => m.branchId == branch.id && m.isActive)
        .length;
    final pastor = LocalDb.getUserById(branch.pastorId);
    final isSuperAdmin = AppRoles.structureManagerRoles
        .contains(ref.watch(appStateProvider).user?.role);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  branch.name[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(branch.name,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                    if (branch.location.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on,
                            size: 13, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(branch.location,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary)),
                      ]),
                  ],
                ),
              ),
              if (isSuperAdmin)
                PopupMenuButton<String>(
                  onSelected: (action) async {
                    if (action == 'edit') {
                      context.push('/branches/edit/${branch.id}');
                    } else if (action == 'delete') {
                      final ok = await _confirmDelete(context, branch.name);
                      if (ok) {
                        await ref
                            .read(branchProvider.notifier)
                            .delete(branch.id);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
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
                  ],
                ),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              _InfoChip(Icons.people, '$memberCount members', Colors.blue),
              const SizedBox(width: 8),
              _InfoChip(Icons.how_to_reg, '$activeCount active',
                  AppColors.success),
              if (pastor != null) ...[
                const SizedBox(width: 8),
                _InfoChip(Icons.person, pastor.name, Colors.purple),
              ],
            ]),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Branch'),
        content: Text(
            'Delete "$name"? Members in this branch will not be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
