import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../models/library_book.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/responsive_scaffold.dart';

class LibraryBooksScreen extends ConsumerStatefulWidget {
  const LibraryBooksScreen({super.key});

  @override
  ConsumerState<LibraryBooksScreen> createState() =>
      _LibraryBooksScreenState();
}

class _LibraryBooksScreenState extends ConsumerState<LibraryBooksScreen> {
  String _search = '';
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(libraryBookProvider);
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    final filtered = books.where((b) {
      final q = _search.toLowerCase();
      final matchSearch = b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          b.category.toLowerCase().contains(q);
      final matchCategory =
          _categoryFilter == null || b.category == _categoryFilter;
      return matchSearch && matchCategory;
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Digital Books'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _categoryFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _categoryFilter != null
                  ? AppColors.accent
                  : Colors.white,
            ),
            tooltip: 'Filter by category',
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cat:all', child: Text('All categories')),
              ...LibraryBookCategory.all.map(
                  (c) => PopupMenuItem(value: 'cat:$c', child: Text(c))),
            ],
            onSelected: (v) => setState(() {
              _categoryFilter = v == 'cat:all' ? null : v.substring(4);
            }),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/library/books/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Book'),
              backgroundColor: AppColors.primary,
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search title, author, category…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _search = ''),
                      )
                    : null,
              ),
            ),
          ),
          if (_categoryFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(children: [
                Chip(
                  label: Text(_categoryFilter!,
                      style: const TextStyle(fontSize: 11)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () => setState(() => _categoryFilter = null),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(children: [
              Text(
                '${filtered.length} book${filtered.length == 1 ? '' : 's'}',
                style: GoogleFonts.poppins(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ]),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.menu_book_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No books in the library yet'
                              : 'No results for "$_search"',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _BookCard(book: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends ConsumerWidget {
  final LibraryBook book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    return Card(
      child: InkWell(
        onTap: () => context.push('/library/books/${book.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.author.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'by ${book.author}',
                        style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _Tag(Icons.category_outlined, book.category,
                          Colors.deepPurple),
                      if (book.source.isNotEmpty)
                        _Tag(Icons.public, book.source, Colors.teal),
                    ]),
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: Colors.grey),
                  onSelected: (action) async {
                    if (action == 'edit') {
                      context.push('/library/books/edit/${book.id}');
                    } else if (action == 'delete') {
                      final ok = await _confirmDelete(context, book.title);
                      if (ok) {
                        await ref
                            .read(libraryBookProvider.notifier)
                            .delete(book.id);
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(children: [
                        Icon(Icons.edit_outlined,
                            size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ]),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
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
}

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Tag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label, style: GoogleFonts.poppins(fontSize: 11, color: color)),
    ]);
  }
}
