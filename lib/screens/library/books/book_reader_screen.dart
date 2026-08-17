import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../models/library_book.dart';

/// A paginated text reader for digital library books.
///
/// Instead of downloading a PDF, the user reads the extracted text content
/// directly in the app — paginated like an e-book, with font size control
/// and a scroll position indicator.
class BookReaderScreen extends StatefulWidget {
  final LibraryBook book;

  const BookReaderScreen({super.key, required this.book});

  @override
  State<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends State<BookReaderScreen> {
  double _fontSize = 16;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateProgress);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final current = _scrollController.offset;
    setState(() {
      _scrollProgress = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.book.content;
    final hasContent = content.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.book.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.text_decrease, color: Colors.white),
            onPressed: () => setState(() {
              _fontSize = (_fontSize - 2).clamp(12.0, 28.0);
            }),
          ),
          Text('${_fontSize.round()}',
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.text_increase, color: Colors.white),
            onPressed: () => setState(() {
              _fontSize = (_fontSize + 2).clamp(12.0, 28.0);
            }),
          ),
        ],
      ),
      body: hasContent
          ? Column(
              children: [
                // Progress bar
                LinearProgressIndicator(
                  value: _scrollProgress,
                  minHeight: 3,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
                // Reading content
                Expanded(
                  child: Scrollbar(
                    controller: _scrollController,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 24),
                      child: Text(
                        content,
                        style: GoogleFonts.poppins(
                          fontSize: _fontSize,
                          height: 1.8,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                // Bottom info bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${(_scrollProgress * 100).round()}%',
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      if (widget.book.pageCount > 0)
                        Text(
                          '${widget.book.pageCount} pages',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      if (widget.book.wordCount > 0)
                        Text(
                          '${_formatWordCount(widget.book.wordCount)} words',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.article_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'Text content not available for this book.',
                      style: GoogleFonts.poppins(
                          fontSize: 16, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (widget.book.url.isNotEmpty)
                      Text(
                        'The PDF version is still available for download.',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatWordCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(0)}K';
    }
    return count.toString();
  }
}
