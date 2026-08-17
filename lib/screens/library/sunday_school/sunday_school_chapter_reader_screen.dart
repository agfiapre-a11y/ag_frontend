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
import '../../../services/verse_lookup_service.dart';
import '../../../utils/verse_extractor.dart';
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
  MemoryVerse? _memoryVerse;
  double _fontSize = 16;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chapter = LocalDb.getSundaySchoolChapterById(widget.chapterId);
    _book = LocalDb.getSundaySchoolBookById(widget.bookId);
    if (_chapter != null) {
      _memoryVerse = VerseExtractor.extractMemoryVerse(_chapter!.content);
    }
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

    if (chapter.discussionPostId.isNotEmpty) {
      final post = LocalDb.getCommunityPostById(chapter.discussionPostId);
      if (post != null) {
        context.push('/community/feed/${chapter.discussionPostId}');
        return;
      }
    }

    final appState = ref.read(appStateProvider);
    final user = appState.user!;
    final fmt = DateFormat.yMMMd();
    final text =
        'Sunday School Discussion: "${book.title}" — Lesson ${chapter.chapterNumber}: ${chapter.title}\n'
        'Scheduled for ${fmt.format(chapter.sundayDate)}. Share your thoughts and reflections!';

    final post = await ref.read(communityPostProvider.notifier).createPost(
          authorId: user.id,
          authorName: user.name,
          authorRole: user.role,
          text: text,
        );

    final updated = chapter.copyWith(discussionPostId: post.id);
    await LocalDb.saveSundaySchoolChapter(updated);
    if (mounted) {
      setState(() => _chapter = updated);
      context.push('/community/feed/${post.id}');
    }
  }

  void _showVerseLookup(MemoryVerse verse) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VerseLookupSheet(
        memoryVerse: verse,
        chapterTitle: _chapter?.title ?? '',
      ),
    );
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
    final mv = _memoryVerse;

    return ResponsiveScaffold(
      appBar: AppBar(
        title: Text(
          book != null
              ? '${book.title} — Lesson ${chapter.chapterNumber}'
              : 'Lesson ${chapter.chapterNumber}',
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
          // Lesson header
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
                  'Lesson ${chapter.chapterNumber}',
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
          const SizedBox(height: 16),

          // Memory Verse card — tappable to search library
          if (mv != null) ...[
            _MemoryVerseCard(
              memoryVerse: mv,
              onTap: () => _showVerseLookup(mv),
            ),
            const SizedBox(height: 20),
          ],

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
                      'Text content not available for this lesson.',
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

/// Tappable memory verse card. When tapped, opens the verse lookup sheet.
class _MemoryVerseCard extends StatelessWidget {
  final MemoryVerse memoryVerse;
  final VoidCallback onTap;

  const _MemoryVerseCard({required this.memoryVerse, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.auto_stories,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  'Memory Verse',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      'Look up',
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ]),
              if (memoryVerse.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '"${memoryVerse.text}"',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: AppColors.emeraldTextPrimary,
                    height: 1.5,
                  ),
                ),
              ],
              if (memoryVerse.hasReference) ...[
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.bookmark, size: 14, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    memoryVerse.reference,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 8),
              Text(
                'Tap to search Bibles & commentaries in your library for this verse',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet that shows verse lookup results from library books.
class VerseLookupSheet extends StatefulWidget {
  final MemoryVerse memoryVerse;
  final String chapterTitle;

  const VerseLookupSheet({
    super.key,
    required this.memoryVerse,
    required this.chapterTitle,
  });

  @override
  State<VerseLookupSheet> createState() => _VerseLookupSheetState();
}

class _VerseLookupSheetState extends State<VerseLookupSheet> {
  List<VerseLookupResult> _results = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _performLookup();
  }

  void _performLookup() {
    // Run in next frame to allow sheet to render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _loading = true);
      // Use compute or just run synchronously (content is already in memory)
      final results = VerseLookupService.lookup(widget.memoryVerse.reference);
      if (mounted) {
        setState(() {
          _results = results;
          _loading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mv = widget.memoryVerse;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.3,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.auto_stories,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verse Lookup',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 20),
                      ),
                    ]),
                    if (mv.hasReference)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          mv.reference,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (mv.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '"${mv.text}"',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Results
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? _buildNoResults()
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                            itemCount: _results.length,
                            itemBuilder: (_, i) => _ResultCard(
                                result: _results[i], isExpanded: i == 0),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No matches found',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'No library books contain this verse reference.\nUpload Bibles and commentaries to the library for verse lookups.',
              style: GoogleFonts.poppins(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A single result card showing matches from one book.
class _ResultCard extends StatefulWidget {
  final VerseLookupResult result;
  final bool isExpanded;

  const _ResultCard({required this.result, this.isExpanded = false});

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final categoryLabel = switch (result.category) {
      BookCategory.bible => 'Bible',
      BookCategory.commentary => 'Commentary',
      BookCategory.other => 'Reference',
    };
    final categoryColor = switch (result.category) {
      BookCategory.bible => AppColors.primary,
      BookCategory.commentary => Colors.deepPurple,
      BookCategory.other => Colors.teal,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book header
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    categoryLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    result.book.title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${result.matches.length} match${result.matches.length == 1 ? '' : 'es'}',
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.grey,
                  size: 20,
                ),
              ]),
              // Match content (expandable)
              if (_expanded) ...[
                const SizedBox(height: 10),
                ...result.matches.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(Icons.format_quote,
                                  size: 12, color: categoryColor),
                              const SizedBox(width: 4),
                              Text(
                                m.reference,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: categoryColor,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            SelectableText(
                              m.context,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                height: 1.5,
                                color: AppColors.emeraldTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
