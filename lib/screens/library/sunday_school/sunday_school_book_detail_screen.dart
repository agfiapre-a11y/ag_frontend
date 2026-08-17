import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../models/sunday_school_book.dart' as ss;
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../widgets/responsive_scaffold.dart';

class SundaySchoolBookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const SundaySchoolBookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<SundaySchoolBookDetailScreen> createState() =>
      _SundaySchoolBookDetailScreenState();
}

class _SundaySchoolBookDetailScreenState
    extends ConsumerState<SundaySchoolBookDetailScreen> {
  ss.SundaySchoolBook? _book;
  List<ss.SundaySchoolChapter> _chapters = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _book = LocalDb.getSundaySchoolBookById(widget.bookId);
    _chapters = LocalDb.getSundaySchoolChaptersForBook(widget.bookId);
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_book == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Book not found')),
      );
    }

    final book = _book!;
    final user = ref.watch(appStateProvider).user!;
    final canManage =
        AppRoles.canManageBook(user.role, user.id, book.addedById);
    final fmt = DateFormat.yMMMd();
    final now = DateTime.now();

    // Group chapters by month for the timeline view
    final byMonth = <String, List<ss.SundaySchoolChapter>>{};
    for (final c in _chapters) {
      final key = DateFormat.yMMMM().format(c.sundayDate);
      byMonth.putIfAbsent(key, () => []).add(c);
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (action) {
                if (action == 'edit') {
                  context.push('/library/sunday-school/edit/${book.id}');
                } else if (action == 'delete') {
                  _confirmDelete(book);
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Book header card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.church,
                          color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(book.title,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700, fontSize: 17)),
                          if (book.author.isNotEmpty)
                            Text('by ${book.author}',
                                style: GoogleFonts.poppins(
                                    color: AppColors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ]),
                  if (book.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(book.description,
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    _infoChip(Icons.calendar_today_outlined,
                        '${fmt.format(book.startDate)} → ${fmt.format(book.endDate)}'),
                    _infoChip(Icons.list_alt_outlined,
                        '${book.totalChapters} chapters'),
                  ]),
                  const SizedBox(height: 12),
                  if (book.url.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => _downloadPdf(book.url),
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Download PDF'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Timeline header
          Text('Sunday Timeline',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 4),
          Text('Each chapter is mapped to a Sunday for reading and discussion.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),

          if (_chapters.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No chapters yet. Re-upload the PDF from Edit to extract chapters.',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ...byMonth.entries.map((entry) => _MonthGroup(
                  monthLabel: entry.key,
                  chapters: entry.value,
                  now: now,
                  onRead: (c) => context.push(
                      '/library/sunday-school/${book.id}/chapter/${c.id}'),
                  onDiscuss: (c) => _openDiscussion(c, book),
                )),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open PDF')),
      );
    }
  }

  Future<void> _openDiscussion(
      ss.SundaySchoolChapter chapter, ss.SundaySchoolBook book) async {
    // If a discussion post already exists, navigate to it
    if (chapter.discussionPostId.isNotEmpty) {
      final post = LocalDb.getCommunityPostById(chapter.discussionPostId);
      if (post != null) {
        context.push('/community/feed/${chapter.discussionPostId}');
        return;
      }
    }

    // Otherwise, create a discussion post and link it to the chapter
    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final fmt = DateFormat.yMMMd();
    final text =
        'Sunday School Discussion: "${book.title}" — Chapter ${chapter.chapterNumber}: ${chapter.title}\n'
        'Scheduled for ${fmt.format(chapter.sundayDate)}. Share your thoughts and reflections!';

    final post = await ref.read(communityPostProvider.notifier).createPost(
          authorId: user.id,
          authorName: user.name,
          authorRole: user.role,
          text: text,
        );

    // Link the post id back to the chapter
    final updated = chapter.copyWith(discussionPostId: post.id);
    await LocalDb.saveSundaySchoolChapter(updated);
    setState(() => _chapters = LocalDb.getSundaySchoolChaptersForBook(book.id));

    if (mounted) {
      context.push('/community/feed/${post.id}');
    }
  }

  Future<void> _confirmDelete(ss.SundaySchoolBook book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Sunday School Book'),
        content: Text(
            'Remove "${book.title}" and all its chapters? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(sundaySchoolBookProvider.notifier).delete(book.id);
      if (mounted) context.pop();
    }
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: AppColors.primary),
      const SizedBox(width: 4),
      Text(label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppColors.primary)),
    ]);
  }
}

class _MonthGroup extends StatelessWidget {
  final String monthLabel;
  final List<ss.SundaySchoolChapter> chapters;
  final DateTime now;
  final void Function(ss.SundaySchoolChapter) onRead;
  final void Function(ss.SundaySchoolChapter) onDiscuss;

  const _MonthGroup({
    required this.monthLabel,
    required this.chapters,
    required this.now,
    required this.onRead,
    required this.onDiscuss,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.MMMd();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 6),
          child: Text(monthLabel,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textSecondary)),
        ),
        ...chapters.map((c) {
          final isPast = c.sundayDate.isBefore(now);
          final isToday = c.sundayDate.year == now.year &&
              c.sundayDate.month == now.month &&
              c.sundayDate.day == now.day;
          final isUpcoming = !isPast && !isToday;

          final statusColor = isToday
              ? AppColors.primary
              : isUpcoming
                  ? Colors.grey
                  : Colors.green;
          final statusLabel = isToday
              ? 'Today'
              : isUpcoming
                  ? 'Upcoming'
                  : 'Past';

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date column
                  SizedBox(
                    width: 56,
                    child: Column(
                      children: [
                        Text(fmt.format(c.sundayDate),
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: statusColor)),
                        const SizedBox(height: 2),
                        Text('Ch. ${c.chapterNumber}',
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(statusLabel,
                                style: GoogleFonts.poppins(
                                    fontSize: 10, color: statusColor)),
                          ),
                          if (c.discussionPostId.isNotEmpty) ...[
                            const SizedBox(width: 6),
                          ],
                        ]),
                        const SizedBox(height: 8),
                        Wrap(spacing: 8, runSpacing: 6, children: [
                          OutlinedButton.icon(
                            onPressed: () => onRead(c),
                            icon: const Icon(Icons.menu_book_outlined, size: 16),
                            label: const Text('Read',
                                style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => onDiscuss(c),
                            icon: const Icon(Icons.chat_bubble_outline,
                                size: 16),
                            label: Text(
                                c.discussionPostId.isEmpty
                                    ? 'Discuss'
                                    : 'Join Discussion',
                                style: const TextStyle(fontSize: 12)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
