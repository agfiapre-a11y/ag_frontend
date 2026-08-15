import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';

class BibleStudyDetailScreen extends ConsumerWidget {
  final String studyId;

  const BibleStudyDetailScreen({super.key, required this.studyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final study = LocalDb.getBibleStudyResourceById(studyId);

    if (study == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Bible Study')),
        body: const Center(child: Text('Bible study not found')),
      );
    }

    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Study'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/library/bible-study/edit/$studyId');
                } else if (action == 'delete') {
                  final ok = await _confirmDelete(context, study.title);
                  if (ok && context.mounted) {
                    await ref
                        .read(bibleStudyResourceProvider.notifier)
                        .delete(studyId);
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
                  colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
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
                    child: const Icon(Icons.import_contacts,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    study.title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    _InfoChip(Icons.category_outlined, study.category),
                    if (study.scriptureReferences.isNotEmpty)
                      _InfoChip(Icons.menu_book, study.scriptureReferences),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (study.description.isNotEmpty) ...[
                    Text('Overview',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text(
                      study.description,
                      style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (study.content.isNotEmpty) ...[
                    Text('Study Content',
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
                        study.content,
                        style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  if (study.discussionQuestions.isNotEmpty) ...[
                    Text('Discussion Questions',
                        style: GoogleFonts.poppins(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    ...study.discussionQuestions.asMap().entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0891B2)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Text('${e.key + 1}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0891B2))),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(e.value,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, height: 1.5)),
                              ),
                            ],
                          ),
                        )),
                  ],
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
        title: const Text('Delete Bible Study'),
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
