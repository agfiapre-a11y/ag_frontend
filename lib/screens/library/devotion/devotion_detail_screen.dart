import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';

class DevotionDetailScreen extends ConsumerWidget {
  final String devotionId;

  const DevotionDetailScreen({super.key, required this.devotionId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devotion = LocalDb.getDevotionGuideById(devotionId);

    if (devotion == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Devotion')),
        body: const Center(child: Text('Devotion not found')),
      );
    }

    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Devotion'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/library/devotion/edit/$devotionId');
                } else if (action == 'delete') {
                  final ok = await _confirmDelete(context, devotion.title);
                  if (ok && context.mounted) {
                    await ref
                        .read(devotionGuideProvider.notifier)
                        .delete(devotionId);
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD97706), Color(0xFFB45309)],
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
                    child: const Icon(Icons.self_improvement,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    devotion.title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    _InfoChip(Icons.calendar_today,
                        DateFormat('EEE, MMM d, yyyy').format(devotion.date)),
                    if (devotion.scriptureReference.isNotEmpty)
                      _InfoChip(Icons.menu_book, devotion.scriptureReference),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (devotion.scriptureText.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE4C4)),
                      ),
                      child: Text(
                        '"${devotion.scriptureText}"',
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF92400E)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (devotion.content.isNotEmpty) ...[
                    Text('Devotional',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(
                      devotion.content,
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (devotion.prayerPoints.isNotEmpty) ...[
                    Text('Prayer Points',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...devotion.prayerPoints.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.church,
                                  size: 16, color: Color(0xFFD97706)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(p,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, height: 1.5)),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 12),
                  ],
                  if (devotion.author.isNotEmpty)
                    Text(
                      '— ${devotion.author}',
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                    ),
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
        title: const Text('Delete Devotion'),
        content: Text('Remove "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }
}
