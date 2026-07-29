import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/welfare_case.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

final _currencyFmt = NumberFormat('#,##0.00');

class WelfareDetailScreen extends ConsumerStatefulWidget {
  final String welfareCaseId;

  const WelfareDetailScreen({super.key, required this.welfareCaseId});

  @override
  ConsumerState<WelfareDetailScreen> createState() =>
      _WelfareDetailScreenState();
}

class _WelfareDetailScreenState extends ConsumerState<WelfareDetailScreen> {
  WelfareCase? _welfareCase;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCase();
  }

  void _loadCase() {
    final wc = LocalDb.getWelfareCaseById(widget.welfareCaseId);
    if (wc == null) {
      if (mounted) context.pop();
      return;
    }
    _welfareCase = wc;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Welfare Case Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final wc = _welfareCase!;
    final members = ref.watch(memberProvider);
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.welfareManagerRoles.contains(user.role);
    final canDelete = AppRoles.welfareDeleteRoles.contains(user.role);

    final member = members.where((m) => m.id == wc.memberId).firstOrNull;
    final statusColor = WelfareStatus.color(wc.status);
    final priorityColor = WelfarePriority.color(wc.priority);
    final typeIcon = WelfareType.icon(wc.type);
    final welfareHead = LocalDb.getUserById(wc.welfareHeadId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welfare Case Details'),
        actions: [
          if (canManage || canDelete)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/welfare/edit/${wc.id}');
                } else if (action == 'delete') {
                  final ok = await _confirmDelete(context);
                  if (ok) {
                    await ref.read(welfareProvider.notifier).delete(wc.id);
                    if (context.mounted) context.pop();
                  }
                }
              },
              itemBuilder: (_) => [
                if (canManage)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [
                      Icon(Icons.edit_outlined, size: 18),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ]),
                  ),
                if (canDelete)
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
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      CircleAvatar(
                        backgroundColor: statusColor.withValues(alpha: 0.12),
                        child: Icon(typeIcon, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member?.name ?? 'Unknown Member',
                              style: GoogleFonts.poppins(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              WelfareType.label(wc.type),
                              style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    Row(children: [
                      _StatusChip(
                        label: WelfareStatus.label(wc.status),
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: WelfarePriority.label(wc.priority),
                        color: priorityColor,
                      ),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Member info
            if (member != null) ...[
              _DetailSection(
                title: 'Member Information',
                icon: Icons.person_outline,
                children: [
                  if (member.phone.isNotEmpty)
                    _DetailRow(label: 'Phone', value: member.phone),
                  if (member.email.isNotEmpty)
                    _DetailRow(label: 'Email', value: member.email),
                  if (member.address.isNotEmpty)
                    _DetailRow(label: 'Address', value: member.address),
                  _DetailRow(
                    label: 'Gender',
                    value: member.gender.isEmpty ? '-' : member.gender,
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Case details
            _DetailSection(
              title: 'Case Details',
              icon: Icons.assignment_outlined,
              children: [
                _DetailRow(
                  label: 'Date Requested',
                  value: DateFormat('MMM d, yyyy').format(wc.dateRequested),
                ),
                if (wc.dateClosed != null)
                  _DetailRow(
                    label: 'Date Closed',
                    value: DateFormat('MMM d, yyyy').format(wc.dateClosed!),
                  ),
                _DetailRow(
                  label: 'Welfare Head',
                  value: wc.welfareHeadId.isEmpty
                      ? 'Unassigned'
                      : (welfareHead?.name ?? '-'),
                ),
                if (wc.amountRequested > 0)
                  _DetailRow(
                    label: 'Amount Requested',
                    value: 'GH₵ ${_currencyFmt.format(wc.amountRequested)}',
                  ),
                if (wc.amountDisbursed > 0)
                  _DetailRow(
                    label: 'Amount Disbursed',
                    value: 'GH₵ ${_currencyFmt.format(wc.amountDisbursed)}',
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            if (wc.description.isNotEmpty) ...[
              _DetailSection(
                title: 'Description',
                icon: Icons.description_outlined,
                children: [
                  Text(
                    wc.description,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Notes
            if (wc.notes.isNotEmpty) ...[
              _DetailSection(
                title: 'Notes',
                icon: Icons.note_outlined,
                children: [
                  Text(
                    wc.notes,
                    style: GoogleFonts.poppins(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Quick status update
            if (canManage && wc.status != WelfareStatus.closed) ...[
              if (wc.welfareHeadId.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.assignment_ind),
                      label: const Text('Assign to Me'),
                      onPressed: () {
                        final updated = wc.copyWith(welfareHeadId: user.id);
                        ref.read(welfareProvider.notifier).update(updated);
                        setState(() => _welfareCase = updated);
                      },
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text('Quick Actions',
                  style: GoogleFonts.poppins(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: WelfareStatus.all.map((status) {
                  return ActionChip(
                    label: Text(WelfareStatus.label(status)),
                    avatar: Icon(Icons.circle,
                        size: 8, color: WelfareStatus.color(status)),
                    onPressed: () {
                      final updated = wc.copyWith(
                        status: status,
                        dateClosed: status == WelfareStatus.closed
                            ? DateTime.now()
                            : null,
                      );
                      ref.read(welfareProvider.notifier).update(updated);
                      setState(() => _welfareCase = updated);
                    },
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Welfare Case'),
        content: const Text(
            'Remove this welfare case? This cannot be undone.'),
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

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _DetailSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 14, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}
