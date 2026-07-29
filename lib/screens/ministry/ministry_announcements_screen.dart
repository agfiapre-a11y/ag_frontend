import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants.dart';
import '../../models/ministry.dart';
import '../../models/ministry_finance.dart';
import '../../models/member.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

const _uuid = Uuid();
final _dateTimeFmt = DateFormat('MMM d, yyyy - hh:mm a');

class MinistryAnnouncementsScreen extends ConsumerStatefulWidget {
  final String ministryType;

  const MinistryAnnouncementsScreen({super.key, required this.ministryType});

  @override
  ConsumerState<MinistryAnnouncementsScreen> createState() =>
      _MinistryAnnouncementsScreenState();
}

class _MinistryAnnouncementsScreenState
    extends ConsumerState<MinistryAnnouncementsScreen> {
  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(ministryAnnouncementProvider);
    final members = ref.watch(memberProvider);
    final ministryColor = MinistryType.color(widget.ministryType);
    final ministryLabel = MinistryType.label(widget.ministryType);

    // Auto-assigned members for this ministry
    final autoMembers = MinistryAssignment.getMembersForMinistry(
        members, widget.ministryType);

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text('$ministryLabel Announcements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(ministryAnnouncementProvider.notifier).refresh();
              ref.read(memberProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: announcements.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.campaign_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text('No announcements yet',
                      style: GoogleFonts.poppins(
                          color: Colors.grey[500], fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Send messages to your ministry members',
                      style: GoogleFonts.poppins(
                          color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: announcements.length,
              itemBuilder: (ctx, i) {
                final ann = announcements[i];
                final isBroadcast = ann.isBroadcast;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ministryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.campaign,
                                  color: ministryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(ann.title,
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors
                                              .emeraldTextPrimary)),
                                  Text(
                                      'From: ${ann.fromName}',
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                                ],
                              ),
                            ),
                            if (isBroadcast)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ministryColor
                                      .withValues(alpha: 0.15),
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text('Broadcast',
                                    style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        color: ministryColor,
                                        fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(ann.message,
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey[800])),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(_dateTimeFmt.format(ann.createdAt),
                                style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: Colors.grey[500])),
                            const Spacer(),
                            if (!isBroadcast)
                              Text(
                                  'To: ${ann.targetMemberIds.length} members',
                                  style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: Colors.grey[500])),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: Colors.red),
                              onPressed: () async {
                                await ref
                                    .read(ministryAnnouncementProvider
                                        .notifier)
                                    .delete(ann.id);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(autoMembers),
        backgroundColor: ministryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showCreateDialog(List<Member> autoMembers) {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    bool isBroadcast = true;
    final selectedIds = <String>{};

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('New Announcement'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: msgCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      prefixIcon: Icon(Icons.message),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Broadcast to all ministry members'),
                    subtitle: Text(
                        '${autoMembers.length} members in ${MinistryType.label(widget.ministryType)}'),
                    value: isBroadcast,
                    onChanged: (v) =>
                        setState(() => isBroadcast = v),
                  ),
                  if (!isBroadcast) ...[
                    const SizedBox(height: 8),
                    Text('Select Members:',
                        style: GoogleFonts.poppins(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: autoMembers.length,
                        itemBuilder: (ctx, i) {
                          final m = autoMembers[i];
                          return CheckboxListTile(
                            title: Text(m.name, style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                                '${m.gender} - ${MinistryAssignment.getAge(m)} yrs',
                                style: const TextStyle(fontSize: 11)),
                            value: selectedIds.contains(m.id),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selectedIds.add(m.id);
                                } else {
                                  selectedIds.remove(m.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
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
              onPressed: () async {
                if (titleCtrl.text.isEmpty || msgCtrl.text.isEmpty) {
                  return;
                }
                if (!isBroadcast && selectedIds.isEmpty) {
                  return;
                }
                final user = ref.read(appStateProvider).user!;
                final appState = ref.read(appStateProvider);
                final ann = MinistryAnnouncement(
                  id: _uuid.v4(),
                  churchId: appState.church?.id ?? '',
                  branchId: user.branchId,
                  ministryType: widget.ministryType,
                  title: titleCtrl.text,
                  message: msgCtrl.text,
                  fromId: user.id,
                  fromName: user.name,
                  createdAt: DateTime.now(),
                  targetMemberIds:
                      isBroadcast ? [] : selectedIds.toList(),
                  isBroadcast: isBroadcast,
                  organizationId: user.organizationId,
                  regionId: user.regionId,
                  districtId: user.districtId,
                  areaId: user.areaId,
                );
                await ref
                    .read(ministryAnnouncementProvider.notifier)
                    .add(ann);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }
}
