import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/role_dashboard_catalog.dart';
import '../../models/app_user.dart';
import '../../models/access_control_grant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/access_control_provider.dart';
import '../../services/local_db.dart';
import '../../services/access_control_service.dart';

/// Access Control Management Screen
///
/// Adapted from SIMS's AssignedRolesPage. Allows admins to:
/// - View all access grants they've issued
/// - Assign users to other dashboards with full or page-level access
/// - Revoke access grants
/// - View activity logs for their dashboard
class AccessControlScreen extends ConsumerStatefulWidget {
  const AccessControlScreen({super.key});

  @override
  ConsumerState<AccessControlScreen> createState() => _AccessControlScreenState();
}

class _AccessControlScreenState extends ConsumerState<AccessControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AppUser> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadUsers() {
    final currentUser = ref.read(appStateProvider).user;
    if (currentUser == null) return;
    setState(() {
      _allUsers = LocalDb.getAllUsers().where((u) => u.id != currentUser.id).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(appStateProvider).user;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    final accessState = ref.watch(accessControlProvider);
    final currentDashboardKey =
        RoleDashboardCatalog.dashboardKeyForRole(currentUser.activeRole);
    final assignees =
        AccessControlService.getAssigneesForDashboard(currentDashboardKey);
    final activities =
        AccessControlService.getActivitiesForDashboard(currentDashboardKey);

    return Scaffold(
      appBar: AppBar(
        title: Text('Access Control', style: GoogleFonts.poppins()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Grants'),
            Tab(text: 'Assignees'),
            Tab(text: 'Activity'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _GrantsTab(
            grants: accessState.grants,
            onRevoke: (id) async {
              await ref.read(accessControlProvider.notifier).revokeAccess(id);
            },
            onAssign: () => _showAssignDialog(context),
          ),
          _AssigneesTab(assignees: assignees, onRevoke: (id) async {
            await ref.read(accessControlProvider.notifier).revokeAccess(id);
          }),
          _ActivityTab(activities: activities),
        ],
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    if (_allUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No other users available to assign')),
      );
      return;
    }

    AppUser? selectedUser;
    String? selectedDashboardKey;
    dynamic allowedPages = 'all';
    List<String> selectedPages = [];

    final dashboards = RoleDashboardCatalog.allDashboards();
    final currentUser = ref.read(appStateProvider).user;
    // Exclude the current user's own dashboard from the list
    final availableDashboards = dashboards
        .where((d) => d.role != currentUser!.activeRole)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Assign Dashboard Access',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User selection
                  Text('Select User',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<AppUser>(
                    value: selectedUser,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: _allUsers
                        .map((u) => DropdownMenuItem(
                              value: u,
                              child: Text('${u.name} (${u.email})',
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setDialogState(() => selectedUser = v),
                  ),
                  const SizedBox(height: 16),

                  // Dashboard selection
                  Text('Select Dashboard',
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedDashboardKey,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    items: availableDashboards
                        .map((d) => DropdownMenuItem(
                              value: d.key,
                              child: Text(d.label,
                                  style: GoogleFonts.poppins(fontSize: 13)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setDialogState(() {
                        selectedDashboardKey = v;
                        selectedPages = [];
                        allowedPages = 'all';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Access level
                  if (selectedDashboardKey != null) ...[
                    Text('Access Level',
                        style: GoogleFonts.poppins(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    RadioListTile<String>(
                      title: Text('Full Access (all pages)',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      value: 'all',
                      groupValue: allowedPages == 'all' ? 'all' : 'pages',
                      onChanged: (v) => setDialogState(() {
                        allowedPages = 'all';
                        selectedPages = [];
                      }),
                    ),
                    RadioListTile<String>(
                      title: Text('Specific Pages Only',
                          style: GoogleFonts.poppins(fontSize: 13)),
                      value: 'pages',
                      groupValue: allowedPages == 'all' ? 'all' : 'pages',
                      onChanged: (v) => setDialogState(() {
                        allowedPages = 'pages';
                      }),
                    ),

                    // Page selection
                    if (allowedPages == 'pages') ...[
                      const SizedBox(height: 8),
                      ..._buildPageCheckboxes(
                          selectedDashboardKey!, selectedPages, setDialogState),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUser == null || selectedDashboardKey == null
                  ? null
                  : () async {
                      final dashDef = RoleDashboardCatalog
                          .dashboardMap[selectedDashboardKey!]!;
                      await ref
                          .read(accessControlProvider.notifier)
                          .assignAccess(
                            userId: selectedUser!.id,
                            username: selectedUser!.email,
                            displayName: selectedUser!.name,
                            dashboardKey: selectedDashboardKey!,
                            allowedPages: allowedPages == 'all'
                                ? 'all'
                                : selectedPages,
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Access granted: ${selectedUser!.name} → ${dashDef.label}',
                          ),
                        ),
                      );
                    },
              child: const Text('Grant Access'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPageCheckboxes(
    String dashboardKey,
    List<String> selectedPages,
    void Function(void Function()) setDialogState,
  ) {
    final dashDef = RoleDashboardCatalog.dashboardMap[dashboardKey];
    if (dashDef == null) return [];

    return dashDef.pages.map((page) {
      return CheckboxListTile(
        title: Text(page.label, style: GoogleFonts.poppins(fontSize: 13)),
        value: selectedPages.contains(page.key),
        onChanged: (v) {
          setDialogState(() {
            if (v == true) {
              selectedPages.add(page.key);
            } else {
              selectedPages.remove(page.key);
            }
          });
        },
        dense: true,
      );
    }).toList();
  }
}

class _GrantsTab extends StatelessWidget {
  final List<AccessControlGrant> grants;
  final Future<void> Function(String) onRevoke;
  final VoidCallback onAssign;

  const _GrantsTab({
    required this.grants,
    required this.onRevoke,
    required this.onAssign,
  });

  @override
  Widget build(BuildContext context) {
    if (grants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Access Grants',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'Assign users to other dashboards with\nfull or page-level access',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.add),
              label: const Text('Assign Access'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: onAssign,
              icon: const Icon(Icons.add),
              label: const Text('Assign Access'),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: grants.length,
            itemBuilder: (ctx, i) {
              final grant = grants[i];
              return Card(
                child: ListTile(
                  title: Text(grant.displayName,
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(grant.dashboardLabel,
                          style: GoogleFonts.poppins(fontSize: 12)),
                      if (grant.isFullAccess)
                        Text('Full Access',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.green))
                      else
                        Text('${grant.pageList.length} page(s)',
                            style: GoogleFonts.poppins(
                                fontSize: 11, color: Colors.blue)),
                      Text('Granted by ${grant.grantedBy}',
                          style: GoogleFonts.poppins(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Revoke Access?'),
                          content: Text(
                              'Revoke ${grant.displayName}\'s access to ${grant.dashboardLabel}?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Revoke',
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) await onRevoke(grant.id);
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AssigneesTab extends StatelessWidget {
  final List<AccessControlGrant> assignees;
  final Future<void> Function(String) onRevoke;

  const _AssigneesTab({required this.assignees, required this.onRevoke});

  @override
  Widget build(BuildContext context) {
    if (assignees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Assignees',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'No one has been assigned to your dashboard.\nWhen you assign someone, they\'ll appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: assignees.length,
      itemBuilder: (ctx, i) {
        final assignee = assignees[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(assignee.displayName.isNotEmpty
                  ? assignee.displayName[0].toUpperCase()
                  : '?'),
            ),
            title: Text(assignee.displayName,
                style: GoogleFonts.poppins(
                    fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${assignee.username}',
                    style: GoogleFonts.poppins(fontSize: 12)),
                if (assignee.isFullAccess)
                  Text('Full Access',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.green))
                else
                  Text('${assignee.pageList.length} page(s)',
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: Colors.blue)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Revoke Access?'),
                    content: Text(
                        'Revoke ${assignee.displayName}\'s access?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Revoke',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm == true) await onRevoke(assignee.id);
              },
            ),
          ),
        );
      },
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final List<AccessActivity> activities;

  const _ActivityTab({required this.activities});

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timeline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No Activity Yet',
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              'When assigned users navigate to pages\non your dashboard, their activity will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activities.length,
      itemBuilder: (ctx, i) {
        final act = activities[i];
        final dt = DateTime.tryParse(act.timestamp);
        final timeStr = dt != null
            ? '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : act.timestamp;

        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.visibility)),
            title: Text('${act.displayName} — ${act.action}',
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500)),
            subtitle: Text('${act.pageLabel} ($act.timeStr)',
                style: GoogleFonts.poppins(fontSize: 11)),
            trailing: Text(timeStr,
                style: GoogleFonts.poppins(
                    fontSize: 10, color: Colors.grey)),
          ),
        );
      },
    );
  }
}
