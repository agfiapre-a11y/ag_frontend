import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class MembersScreen extends ConsumerStatefulWidget {
  const MembersScreen({super.key});

  @override
  ConsumerState<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends ConsumerState<MembersScreen> {
  String _search = '';
  bool _activeOnly = false;

  @override
  Widget build(BuildContext context) {
    final members = ref.watch(memberProvider);
    final user = ref.watch(appStateProvider).user!;
    final canAdd = user.role != AppRoles.member;

    final filtered = members.where((m) {
      final q = _search.toLowerCase();
      final matchSearch = m.name.toLowerCase().contains(q) ||
          m.phone.contains(q) ||
          m.email.toLowerCase().contains(q);
      return matchSearch && (!_activeOnly || m.isActive);
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: Icon(
              _activeOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _activeOnly ? AppColors.goldWarm : AppColors.emeraldTextSecondary,
            ),
            tooltip: _activeOnly ? 'Showing active only' : 'Filter active',
            onPressed: () => setState(() => _activeOnly = !_activeOnly),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/members/add'),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email…',
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text(
                '${filtered.length} member${filtered.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (_activeOnly)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Chip(
                    label: const Text('Active only'),
                    labelStyle: const TextStyle(fontSize: 11),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _activeOnly = false),
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
                        const Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No members yet'
                              : 'No results for "$_search"',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                        if (_search.isEmpty && canAdd) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/members/add'),
                            icon: const Icon(Icons.person_add),
                            label: const Text('Add First Member'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _MemberTile(member: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final Member member;

  const _MemberTile({required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(appStateProvider).user?.role ?? '';
    final canEdit = role != AppRoles.member;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor:
              member.isActive ? AppColors.sunriseGold : AppColors.paradiseGray,
          child: Text(
            member.name[0].toUpperCase(),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(member.name,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          member.phone.isNotEmpty ? member.phone : member.email,
          style: GoogleFonts.poppins(
              color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(active: member.isActive),
            if (canEdit)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) async {
                  if (action == 'edit') {
                    context.push('/members/edit/${member.id}');
                  } else if (action == 'toggle') {
                    await ref
                        .read(memberProvider.notifier)
                        .toggleActive(member.id);
                  } else if (action == 'delete') {
                    final ok = await _confirmDelete(context, member.name);
                    if (ok) {
                      await ref
                          .read(memberProvider.notifier)
                          .delete(member.id);
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
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(children: [
                      Icon(
                        member.isActive
                            ? Icons.person_off
                            : Icons.how_to_reg,
                        size: 18,
                        color: member.isActive ? Colors.orange : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(member.isActive ? 'Deactivate' : 'Activate'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: Colors.red)),
                    ]),
                  ),
                ],
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
        title: const Text('Delete Member'),
        content: Text('Remove $name from the church records?'),
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

class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
        style: TextStyle(
          color: active ? AppColors.success : Colors.grey,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
