import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/devotion_guide.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/responsive_scaffold.dart';

class DevotionScreen extends ConsumerStatefulWidget {
  const DevotionScreen({super.key});

  @override
  ConsumerState<DevotionScreen> createState() => _DevotionScreenState();
}

class _DevotionScreenState extends ConsumerState<DevotionScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final devotions = ref.watch(devotionGuideProvider);
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    final filtered = devotions.where((d) {
      final q = _search.toLowerCase();
      return d.title.toLowerCase().contains(q) ||
          d.scriptureReference.toLowerCase().contains(q);
    }).toList();

    final now = DateTime.now();
    final today = filtered.where((d) =>
        d.date.year == now.year &&
        d.date.month == now.month &&
        d.date.day == now.day).firstOrNull;

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Daily Devotion & Prayer Guide')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/library/devotion/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add Devotion'),
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
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.self_improvement_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No devotions available yet'
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
                    itemBuilder: (_, i) => _DevotionCard(
                      devotion: filtered[i],
                      isToday: today != null && filtered[i].id == today.id,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _DevotionCard extends ConsumerWidget {
  final DevotionGuide devotion;
  final bool isToday;

  const _DevotionCard({required this.devotion, required this.isToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.libraryManagerRoles.contains(user.role);

    return Card(
      color: isToday ? const Color(0xFFFFF7ED) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? const BorderSide(color: Color(0xFFD97706), width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => context.push('/library/devotion/${devotion.id}'),
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
                  color: const Color(0xFFD97706).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.self_improvement,
                    color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      if (isToday)
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD97706),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('TODAY',
                                style: GoogleFonts.poppins(
                                    fontSize: 9,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          devotion.title,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      _Tag(Icons.calendar_today,
                          DateFormat('MMM d, yyyy').format(devotion.date)),
                      if (devotion.scriptureReference.isNotEmpty)
                        _Tag(Icons.menu_book, devotion.scriptureReference),
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
                      context.push('/library/devotion/edit/${devotion.id}');
                    } else if (action == 'delete') {
                      final ok = await _confirmDelete(context, devotion.title);
                      if (ok) {
                        await ref
                            .read(devotionGuideProvider.notifier)
                            .delete(devotion.id);
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

class _Tag extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Tag(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: Colors.grey.shade600),
      const SizedBox(width: 3),
      Text(label,
          style:
              GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade600)),
    ]);
  }
}
