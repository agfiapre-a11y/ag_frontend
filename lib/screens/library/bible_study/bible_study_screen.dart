import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../models/bible_study_resource.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/responsive_scaffold.dart';

class BibleStudyScreen extends ConsumerStatefulWidget {
  const BibleStudyScreen({super.key});

  @override
  ConsumerState<BibleStudyScreen> createState() => _BibleStudyScreenState();
}

class _BibleStudyScreenState extends ConsumerState<BibleStudyScreen> {
  String _search = '';
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final studies = ref.watch(bibleStudyResourceProvider);
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    final filtered = studies.where((s) {
      final q = _search.toLowerCase();
      final matchSearch = s.title.toLowerCase().contains(q) ||
          s.scriptureReferences.toLowerCase().contains(q);
      final matchCategory =
          _categoryFilter == null || s.category == _categoryFilter;
      return matchSearch && matchCategory;
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Bible Study'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _categoryFilter != null
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: _categoryFilter != null ? AppColors.accent : Colors.white,
            ),
            tooltip: 'Filter by category',
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'cat:all', child: Text('All categories')),
              ...BibleStudyCategory.all.map(
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
              onPressed: () => context.push('/library/bible-study/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Study'),
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
                hintText: 'Search title or scripture…',
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
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.import_contacts_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No Bible studies available yet'
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
                    itemBuilder: (_, i) => _StudyCard(study: filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudyCard extends ConsumerWidget {
  final BibleStudyResource study;

  const _StudyCard({required this.study});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    return Card(
      child: InkWell(
        onTap: () => context.push('/library/bible-study/${study.id}'),
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
                  color: const Color(0xFF0891B2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.import_contacts,
                    color: Color(0xFF0891B2), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      study.title,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700, fontSize: 15),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _Tag(Icons.category_outlined, study.category),
                      if (study.scriptureReferences.isNotEmpty)
                        _Tag(Icons.menu_book, study.scriptureReferences),
                    ]),
                    if (study.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        study.description,
                        style: GoogleFonts.poppins(
                            fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              if (canManage)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 18, color: Colors.grey),
                  onSelected: (action) async {
                    if (action == 'edit') {
                      context.push('/library/bible-study/edit/${study.id}');
                    } else if (action == 'delete') {
                      final ok = await _confirmDelete(context, study.title);
                      if (ok) {
                        await ref
                            .read(bibleStudyResourceProvider.notifier)
                            .delete(study.id);
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

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.deepPurple),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.poppins(fontSize: 11, color: Colors.deepPurple)),
    ]);
  }
}
