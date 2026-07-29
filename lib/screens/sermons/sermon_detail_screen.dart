import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../services/local_db.dart';

class SermonDetailScreen extends ConsumerWidget {
  final String sermonId;

  const SermonDetailScreen({super.key, required this.sermonId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sermon = LocalDb.getSermonById(sermonId);

    if (sermon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sermon')),
        body: const Center(child: Text('Sermon not found')),
      );
    }

    final branches = ref.watch(branchProvider);
    final user = ref.watch(appStateProvider).user!;
    final branchName =
        branches.where((b) => b.id == sermon.branchId).firstOrNull?.name;
    final recorder = LocalDb.getUserById(sermon.recordedById);
    final canManage = AppRoles.sermonManagerRoles.contains(user.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sermon'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/sermons/edit/$sermonId');
                } else if (action == 'delete') {
                  final ok = await _confirmDelete(context, sermon.title);
                  if (ok && context.mounted) {
                    await ref.read(sermonProvider.notifier).delete(sermonId);
                    if (context.mounted) context.pop();
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
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.mic,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    sermon.title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.person, size: 14, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(sermon.speaker,
                        style: GoogleFonts.poppins(
                            color: Colors.white70, fontSize: 13)),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    _InfoChip(Icons.calendar_today,
                        DateFormat('EEE, MMM d, yyyy').format(sermon.date)),
                    if (sermon.serviceType.isNotEmpty)
                      _InfoChip(Icons.church, sermon.serviceType),
                    if (branchName != null)
                      _InfoChip(Icons.account_tree, branchName),
                  ]),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Key info row
                  if (sermon.scriptureReference.isNotEmpty ||
                      sermon.series.isNotEmpty) ...[
                    _DetailSection(
                      children: [
                        if (sermon.scriptureReference.isNotEmpty)
                          _DetailRow(
                            icon: Icons.menu_book,
                            label: 'Scripture',
                            value: sermon.scriptureReference,
                            color: Colors.deepPurple,
                          ),
                        if (sermon.series.isNotEmpty)
                          _DetailRow(
                            icon: Icons.layers,
                            label: 'Series',
                            value: sermon.series,
                            color: Colors.teal,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Notes
                  if (sermon.notes.isNotEmpty) ...[
                    Text('Notes',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        sermon.notes,
                        style: GoogleFonts.poppins(
                            fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Media links
                  if (sermon.audioUrl.isNotEmpty ||
                      sermon.videoUrl.isNotEmpty) ...[
                    Text('Media',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    if (sermon.audioUrl.isNotEmpty)
                      _MediaButton(
                        icon: Icons.headphones,
                        label: 'Listen to Audio',
                        url: sermon.audioUrl,
                        color: Colors.orange,
                      ),
                    if (sermon.videoUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _MediaButton(
                          icon: Icons.play_circle_outline,
                          label: 'Watch Video',
                          url: sermon.videoUrl,
                          color: Colors.red,
                        ),
                      ),
                    const SizedBox(height: 20),
                  ],

                  // Meta
                  if (recorder != null)
                    Row(children: [
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Recorded by ${recorder.name}',
                        style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Sermon'),
        content: Text('Remove "$title"? This cannot be undone.'),
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

  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: Colors.white70),
        const SizedBox(width: 5),
        Text(label,
            style:
                GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final List<Widget> children;

  const _DetailSection({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children
            .expand((w) => [w, const SizedBox(height: 10)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 8),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.poppins(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ]),
      ),
    ]);
  }
}

class _MediaButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  final Color color;

  const _MediaButton({
    required this.icon,
    required this.label,
    required this.url,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Link copied to clipboard')),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: color)),
                  Text(url,
                      style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ]),
          ),
          Icon(Icons.copy, size: 16, color: color.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
