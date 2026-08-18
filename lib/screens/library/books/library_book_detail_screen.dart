import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../models/library_book.dart';
import '../../../services/supabase_config.dart';
import '../../../services/sync_service.dart';
import 'book_reader_screen.dart';

class LibraryBookDetailScreen extends ConsumerStatefulWidget {
  final String bookId;

  const LibraryBookDetailScreen({super.key, required this.bookId});

  @override
  ConsumerState<LibraryBookDetailScreen> createState() =>
      _LibraryBookDetailScreenState();
}

class _LibraryBookDetailScreenState
    extends ConsumerState<LibraryBookDetailScreen> {
  bool _loadingContent = false;
  String? _fetchedContent;

  @override
  void initState() {
    super.initState();
    _loadContentIfNeeded();
  }

  /// Fetches the book's text content from Supabase if not already cached locally.
  /// Content is excluded from the list query for performance (some books are 4MB+).
  Future<void> _loadContentIfNeeded() async {
    final book = LocalDb.getLibraryBookById(widget.bookId);
    if (book == null) return;
    if (book.content.isNotEmpty) return; // Already have content

    if (!SupabaseConfig.isConfigured) return;
    final client = SupabaseConfig.client;
    if (client == null) return;

    setState(() => _loadingContent = true);

    try {
      final tenantId = await SyncService.resolveTenantId(book.churchId);
      final result = await client
          .from('library_books')
          .select('content')
          .eq('id', book.id)
          .eq('tenant_id', tenantId)
          .limit(1)
          .timeout(const Duration(seconds: 15));

      if (result.isNotEmpty) {
        final content = (result[0] as Map<String, dynamic>)['content'] as String? ?? '';
        if (content.isNotEmpty) {
          // Save to local DB for offline access
          final updated = LibraryBook(
            id: book.id,
            churchId: book.churchId,
            title: book.title,
            author: book.author,
            category: book.category,
            description: book.description,
            url: book.url,
            coverColor: book.coverColor,
            source: book.source,
            addedById: book.addedById,
            content: content,
            pageCount: book.pageCount,
            wordCount: book.wordCount,
            createdAt: book.createdAt,
          );
          await LocalDb.saveLibraryBook(updated);
          if (mounted) {
            setState(() {
              _fetchedContent = content;
              _loadingContent = false;
            });
          }
          return;
        }
      }
    } catch (_) {
      // Network error — user can still download PDF
    }

    if (mounted) setState(() => _loadingContent = false);
  }

  @override
  Widget build(BuildContext context) {
    final book = LocalDb.getLibraryBookById(widget.bookId);

    if (book == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Book')),
        body: const Center(child: Text('Book not found')),
      );
    }

    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.canManageBook(user.role, user.id, book.addedById);
    final effectiveContent = _fetchedContent ?? book.content;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book'),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (action) async {
                if (action == 'edit') {
                  context.push('/library/books/edit/${widget.bookId}');
                } else if (action == 'delete') {
                  final ok = await _confirmDelete(context, book.title);
                  if (ok && context.mounted) {
                    await ref.read(libraryBookProvider.notifier).delete(widget.bookId);
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
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
                    child: const Icon(Icons.menu_book,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    book.title,
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  if (book.author.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.person, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(book.author,
                          style: GoogleFonts.poppins(
                              color: Colors.white70, fontSize: 13)),
                    ]),
                  ],
                  const SizedBox(height: 10),
                  Wrap(spacing: 10, runSpacing: 6, children: [
                    _InfoChip(Icons.category_outlined, book.category),
                    if (book.source.isNotEmpty)
                      _InfoChip(Icons.public, book.source),
                  ]),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.description.isNotEmpty) ...[
                    Text('About this book',
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
                        book.description,
                        style: GoogleFonts.poppins(fontSize: 14, height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Digital reader (extracted text)
                  if (effectiveContent.isNotEmpty) ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        final bookWithContent = book.copyWith(content: effectiveContent);
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => BookReaderScreen(book: bookWithContent),
                          ),
                        );
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Read Book'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${book.pageCount} pages · ${_formatWords(book.wordCount)} words',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ] else if (_loadingContent) ...[
                    // Content is being fetched from Supabase
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                            SizedBox(height: 12),
                            Text('Loading book content...',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ] else if (book.pageCount > 0 || book.wordCount > 0) ...[
                    // Content exists but couldn't be loaded — show read button that fetches on tap
                    OutlinedButton.icon(
                      onPressed: () async {
                        setState(() => _loadingContent = true);
                        await _loadContentIfNeeded();
                      },
                      icon: const Icon(Icons.menu_book),
                      label: const Text('Read Book'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8B5CF6),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            size: 14, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          '${book.pageCount} pages · ${_formatWords(book.wordCount)} words',
                          style: GoogleFonts.poppins(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  // PDF download (fallback)
                  if (book.url.isNotEmpty) ...[
                    if (effectiveContent.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () => _openLink(context, book.url),
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('Download PDF'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () => _openLink(context, book.url),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Read / Download Free'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      book.url,
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open link')),
        );
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext context, String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Book'),
        content: Text('Remove "$title" from the library?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _formatWords(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
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
