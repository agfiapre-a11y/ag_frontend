import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/sunday_school_book.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../widgets/responsive_scaffold.dart';

class SundaySchoolChapterReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String chapterId;

  const SundaySchoolChapterReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  @override
  ConsumerState<SundaySchoolChapterReaderScreen> createState() =>
      _SundaySchoolChapterReaderScreenState();
}

class _SundaySchoolChapterReaderScreenState
    extends ConsumerState<SundaySchoolChapterReaderScreen> {
  SundaySchoolChapter? _chapter;
  SundaySchoolBook? _book;
  double _fontSize = 16;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chapter = LocalDb.getSundaySchoolChapterById(widget.chapterId);
    _book = LocalDb.getSundaySchoolBookById(widget.bookId);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _openDiscussion() async {
    final chapter = _chapter;
    final book = _book;
    if (chapter == null || book == null) return;

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
    if (mounted) {
      setState(() {
        _chapter = updated;
      });
      context.push('/community/feed/${post.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chapter == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Chapter not found')),
      );
    }

    final chapter = _chapter!;
    final book = _book;
    final fmt = DateFormat.yMMMd();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(
          book != null
              ? '${book.title} — Ch. ${chapter.chapterNumber}'
              : 'Chapter ${chapter.chapterNumber}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _fontSize =
                (_fontSize - 2).clamp(12.0, 28.0)),
            icon: const Icon(Icons.text_decrease),
            tooltip: 'Smaller text',
          ),
          Text('${_fontSize.toInt()}',
              style: GoogleFonts.poppins(fontSize: 13)),
          IconButton(
            onPressed: () => setState(() => _fontSize =
                (_fontSize + 2).clamp(12.0, 28.0)),
            icon: const Icon(Icons.text_increase),
            tooltip: 'Larger text',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openDiscussion,
        icon: const Icon(Icons.chat_bubble_outline),
        label: Text(chapter.discussionPostId.isEmpty
            ? 'Discuss'
            : 'Join Discussion'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          // Chapter header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chapter ${chapter.chapterNumber}',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  chapter.title,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    'Sunday, ${fmt.format(chapter.sundayDate)}',
                    style: GoogleFonts.poppins(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Chapter content
          if (chapter.content.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.article_outlined,
                        size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text(
                      'Text content not available for this chapter.',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    if (book != null && book.url.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push(
                            '/library/sunday-school/${book.id}'),
                        icon: const Icon(Icons.download_outlined, size: 18),
                        label: const Text('Download full PDF'),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            SelectableText(
              chapter.content,
              style: GoogleFonts.poppins(
                fontSize: _fontSize,
                height: 1.6,
                color: AppColors.emeraldTextPrimary,
              ),
            ),
        ],
      ),
    );
  }
}
