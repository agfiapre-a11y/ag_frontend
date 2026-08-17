import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../models/sunday_school_book.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/responsive_scaffold.dart';

class SundaySchoolScreen extends ConsumerStatefulWidget {
  const SundaySchoolScreen({super.key});

  @override
  ConsumerState<SundaySchoolScreen> createState() =>
      _SundaySchoolScreenState();
}

class _SundaySchoolScreenState extends ConsumerState<SundaySchoolScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(sundaySchoolBookProvider);

    final filtered = books.where((b) {
      final q = _search.toLowerCase();
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q);
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Sunday School')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/library/sunday-school/add'),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search Sunday School books…',
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
                        const Icon(Icons.church_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No Sunday School books yet'
                              : 'No results for "$_search"',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap "Add Book" to upload a PDF and map chapters to Sundays',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SundaySchoolBookCard(book: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SundaySchoolBookCard extends ConsumerWidget {
  final SundaySchoolBook book;

  const _SundaySchoolBookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final canManage =
        AppRoles.canManageBook(user.role, user.id, book.addedById);

    final now = DateTime.now();
    final isActive =
        now.isAfter(book.startDate) && now.isBefore(book.endDate);
    final fmt = _dateFmt;

    return Card(
      child: InkWell(
        onTap: () => context.push('/library/sunday-school/${book.id}'),
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
                child: const Icon(Icons.church,
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
                      _Tag(
                        Icons.calendar_today_outlined,
                        '${fmt.format(book.startDate)} → ${fmt.format(book.endDate)}',
                        Colors.teal,
                      ),
                      _Tag(
                        Icons.list_alt_outlined,
                        '${book.totalChapters} chapter${book.totalChapters == 1 ? '' : 's'}',
                        Colors.deepPurple,
                      ),
                      if (isActive)
                        _Tag(Icons.play_circle_outline, 'Active now',
                            AppColors.primary),
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
                      context.push('/library/sunday-school/edit/${book.id}');
                    } else if (action == 'delete') {
                      final ok = await _confirmDelete(context, book.title);
                      if (ok) {
                        await ref
                            .read(sundaySchoolBookProvider.notifier)
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
        title: const Text('Remove Sunday School Book'),
        content: Text(
            'Remove "$title" and all its chapters? This cannot be undone.'),
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

final _dateFmt = DateFormat.yMMMd();
