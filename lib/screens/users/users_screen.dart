import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  String _search = '';
  String? _roleFilter;

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(userProvider);
    final currentUserId = ref.watch(appStateProvider).user?.id;

    final filtered = users.where((u) {
      final q = _search.toLowerCase();
      final matchSearch = u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.contains(q);
      final matchRole = _roleFilter == null || u.role == _roleFilter;
      return matchSearch && matchRole;
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download, color: Colors.white),
            tooltip: 'Export to CSV',
            onPressed: () => _exportCsv(filtered),
          ),
          PopupMenuButton<String?>(
            icon: Icon(
              _roleFilter != null ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _roleFilter != null ? AppColors.accent : Colors.white,
            ),
            tooltip: 'Filter by role',
            onSelected: (v) => setState(() => _roleFilter = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All roles')),
              const PopupMenuItem(value: AppRoles.localChurchAdmin, child: Text('Church Admin')),
              const PopupMenuItem(value: AppRoles.seniorPastor, child: Text('Senior Pastor')),
              const PopupMenuItem(value: AppRoles.associatePastor, child: Text('Associate Pastor')),
              const PopupMenuItem(value: AppRoles.churchSecretary, child: Text('Church Secretary')),
              const PopupMenuItem(value: AppRoles.financeOfficer, child: Text('Finance Officer')),
              const PopupMenuItem(value: AppRoles.welfareHead, child: Text('Welfare Head')),
              const PopupMenuItem(value: AppRoles.ministryHead, child: Text('Ministry Head')),
              const PopupMenuItem(value: AppRoles.cellLeader, child: Text('Cell Leader')),
              const PopupMenuItem(value: AppRoles.volunteer, child: Text('Volunteer')),
              const PopupMenuItem(value: AppRoles.member, child: Text('Member')),
              const PopupMenuItem(value: AppRoles.guest, child: Text('Guest')),
              const PopupMenuItem(value: AppRoles.superAdmin, child: Text('Super Admin (Legacy)')),
              const PopupMenuItem(value: AppRoles.pastor, child: Text('Pastor (Legacy)')),
              const PopupMenuItem(value: AppRoles.accountant, child: Text('Accountant (Legacy)')),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'bulk',
            onPressed: () => context.push('/users/bulk-add'),
            tooltip: 'Bulk Add Users',
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'single',
            onPressed: () => context.push('/users/add'),
            icon: const Icon(Icons.person_add),
            label: const Text('Add User'),
            backgroundColor: AppColors.primary,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats summary
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                _StatChip(icon: Icons.people, label: 'Total', value: '${users.length}', color: AppColors.primary),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.admin_panel_settings, label: 'Admins', value: '${users.where((u) => u.role.contains('Admin') || u.role == AppRoles.superAdmin).length}', color: Colors.orange),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.badge, label: 'Staff', value: '${users.where((u) => [AppRoles.financeOfficer, AppRoles.churchSecretary, AppRoles.welfareHead, AppRoles.seniorPastor, AppRoles.associatePastor].contains(u.role)).length}', color: Colors.teal),
                const SizedBox(width: 8),
                _StatChip(icon: Icons.person, label: 'Members', value: '${users.where((u) => u.role == AppRoles.member).length}', color: Colors.blue),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search by name, email or phone…',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _search = ''),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => context.push('/users/bulk-add'),
                  icon: const Icon(Icons.group_add, size: 18),
                  label: const Text('Bulk'),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text(
                '${filtered.length} user${filtered.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (_roleFilter != null)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    label: Text(AppRoles.label(_roleFilter!)),
                    labelStyle: const TextStyle(fontSize: 11),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _roleFilter = null),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.manage_accounts_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No users found'
                              : 'No results for "$_search"',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _UserTile(
                      user: filtered[i],
                      isSelf: filtered[i].id == currentUserId,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(List<AppUser> users) async {
    final buf = StringBuffer();
    buf.writeln('name,email,phone,role,branchId,createdAt');
    for (final u in users) {
      buf.writeln('${_csvEscape(u.name)},${_csvEscape(u.email)},${_csvEscape(u.phone)},${_csvEscape(u.role)},${_csvEscape(u.branchId)},${u.createdAt.toIso8601String()}');
    }
    final bytes = Uint8List.fromList(utf8.encode(buf.toString()));
    if (mounted) {
      await Share.shareXFiles(
        [XFile.fromData(bytes, name: 'paradise_users_export.csv', mimeType: 'text/csv')],
        text: 'Paradise AG - Users Export (${users.length} users)',
      );
    }
  }

  String _csvEscape(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }
}

class _UserTile extends ConsumerWidget {
  final AppUser user;
  final bool isSelf;

  const _UserTile({required this.user, required this.isSelf});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchProvider);
    final branchName = branches
        .where((b) => b.id == user.branchId)
        .map((b) => b.name)
        .firstOrNull;

    final roleColor = _roleColor(user.role);

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: roleColor.withValues(alpha: 0.15),
          child: Text(
            user.name[0].toUpperCase(),
            style: TextStyle(
                color: roleColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                user.name,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            if (isSelf)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('You',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              user.email,
              style: GoogleFonts.poppins(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(children: [
              _RoleBadge(role: user.role, color: roleColor),
              if (branchName != null) ...[
                const SizedBox(width: 6),
                _BranchBadge(name: branchName),
              ],
            ]),
          ],
        ),
        isThreeLine: true,
        trailing: isSelf
            ? null
            : PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) async {
                  if (action == 'edit') {
                    context.push('/users/edit/${user.id}');
                  } else if (action == 'delete') {
                    final ok = await _confirmDelete(context, user.name);
                    if (ok) {
                      await ref.read(userProvider.notifier).delete(user.id);
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
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
              ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String name) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove User'),
        content: Text(
            'Remove $name? They will no longer be able to log in.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Color _roleColor(String role) {
    switch (role) {
      case AppRoles.superAdmin:
        return AppColors.sunriseGold;
      case AppRoles.pastor:
        return AppColors.royalBlue;
      case AppRoles.accountant:
        return AppColors.skyBlue;
      default:
        return AppColors.paradiseGray;
    }
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: color)),
            Text(label, style: GoogleFonts.poppins(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;

  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        AppRoles.label(role),
        style: TextStyle(
            fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _BranchBadge extends StatelessWidget {
  final String name;

  const _BranchBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.account_tree, size: 10, color: Colors.grey),
        const SizedBox(width: 3),
        Text(name,
            style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
