import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/sermon.dart';
import '../../models/attendance_record.dart';
import '../../providers/auth_provider.dart';
import '../../providers/data_provider.dart';
import '../../widgets/responsive_scaffold.dart';

class SermonsScreen extends ConsumerStatefulWidget {
  const SermonsScreen({super.key});

  @override
  ConsumerState<SermonsScreen> createState() => _SermonsScreenState();
}

class _SermonsScreenState extends ConsumerState<SermonsScreen> {
  String _search = '';
  String? _serviceFilter;
  String? _branchFilter;

  @override
  Widget build(BuildContext context) {
    final sermons = ref.watch(sermonProvider);
    final user = ref.watch(appStateProvider).user!;
    final branches = ref.watch(branchProvider);
    final isSuperAdmin = AppRoles.crossBranchRoles.contains(user.role);
    final canAdd = AppRoles.sermonManagerRoles.contains(user.role);

    final filtered = sermons.where((s) {
      final q = _search.toLowerCase();
      final matchSearch = s.title.toLowerCase().contains(q) ||
          s.speaker.toLowerCase().contains(q) ||
          s.series.toLowerCase().contains(q) ||
          s.scriptureReference.toLowerCase().contains(q);
      final matchService =
          _serviceFilter == null || s.serviceType == _serviceFilter;
      final matchBranch =
          _branchFilter == null || s.branchId == _branchFilter;
      return matchSearch && matchService && matchBranch;
    }).toList();

    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('Sermons'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              (_serviceFilter != null || _branchFilter != null)
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
              color: (_serviceFilter != null || _branchFilter != null)
                  ? AppColors.accent
                  : Colors.white,
            ),
            tooltip: 'Filter',
            itemBuilder: (_) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('Service Type',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ),
              const PopupMenuItem(
                  value: 'svc:all', child: Text('All services')),
              ...ServiceTypes.all.map(
                  (s) => PopupMenuItem(value: 'svc:$s', child: Text(s))),
              if (isSuperAdmin && branches.isNotEmpty) ...[
                const PopupMenuDivider(),
                const PopupMenuItem(
                  enabled: false,
                  child: Text('Branch',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey)),
                ),
                const PopupMenuItem(
                    value: 'br:all', child: Text('All branches')),
                ...branches.map((b) =>
                    PopupMenuItem(value: 'br:${b.id}', child: Text(b.name))),
              ],
            ],
            onSelected: (v) => setState(() {
              if (v.startsWith('svc:')) {
                _serviceFilter = v == 'svc:all' ? null : v.substring(4);
              } else if (v.startsWith('br:')) {
                _branchFilter = v == 'br:all' ? null : v.substring(3);
              }
            }),
          ),
        ],
      ),
      floatingActionButton: canAdd
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/sermons/add'),
              icon: const Icon(Icons.mic),
              label: const Text('Add Sermon'),
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
                hintText: 'Search title, speaker, series, scripture…',
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
          if (_serviceFilter != null || _branchFilter != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: Row(children: [
                if (_serviceFilter != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(_serviceFilter!,
                          style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () =>
                          setState(() => _serviceFilter = null),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          AppColors.primary.withValues(alpha: 0.1),
                    ),
                  ),
                if (_branchFilter != null)
                  Chip(
                    label: Text(
                      branches
                              .where((b) => b.id == _branchFilter)
                              .firstOrNull
                              ?.name ??
                          '',
                      style: const TextStyle(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 14),
                    onDeleted: () => setState(() => _branchFilter = null),
                    visualDensity: VisualDensity.compact,
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                  ),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: Row(children: [
              Text(
                '${filtered.length} sermon${filtered.length == 1 ? '' : 's'}',
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
                        const Icon(Icons.video_library_outlined,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          _search.isEmpty
                              ? 'No sermons recorded yet'
                              : 'No results for "$_search"',
                          style: GoogleFonts.poppins(
                              color: AppColors.textSecondary),
                        ),
                        if (_search.isEmpty && canAdd) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => context.push('/sermons/add'),
                            icon: const Icon(Icons.mic),
                            label: const Text('Add First Sermon'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _SermonCard(
                      sermon: filtered[i],
                      showBranch: isSuperAdmin,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SermonCard extends ConsumerWidget {
  final Sermon sermon;
  final bool showBranch;

  const _SermonCard({required this.sermon, required this.showBranch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branches = ref.watch(branchProvider);
    final branchName = branches
        .where((b) => b.id == sermon.branchId)
        .firstOrNull
        ?.name;
    final user = ref.watch(appStateProvider).user!;
    final canManage = AppRoles.sermonManagerRoles.contains(user.role);

    return Card(
      child: InkWell(
        onTap: () => context.push('/sermons/${sermon.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.mic,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sermon.title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sermon.speaker,
                        style: GoogleFonts.poppins(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Colors.grey),
                    onSelected: (action) async {
                      if (action == 'edit') {
                        context.push('/sermons/edit/${sermon.id}');
                      } else if (action == 'delete') {
                        final ok = await _confirmDelete(context, sermon.title);
                        if (ok) {
                          await ref
                              .read(sermonProvider.notifier)
                              .delete(sermon.id);
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
                          Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 6, children: [
                _Tag(Icons.calendar_today,
                    DateFormat('MMM d, yyyy').format(sermon.date),
                    Colors.grey.shade600),
                if (sermon.serviceType.isNotEmpty)
                  _Tag(Icons.church, sermon.serviceType, AppColors.primary),
                if (sermon.scriptureReference.isNotEmpty)
                  _Tag(Icons.menu_book, sermon.scriptureReference,
                      Colors.deepPurple),
                if (sermon.series.isNotEmpty)
                  _Tag(Icons.layers, sermon.series, Colors.teal),
                if (showBranch && branchName != null)
                  _Tag(Icons.account_tree, branchName, Colors.grey.shade600),
              ]),
              if (sermon.audioUrl.isNotEmpty || sermon.videoUrl.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(children: [
                  if (sermon.audioUrl.isNotEmpty)
                    _LinkBadge(Icons.headphones, 'Audio', Colors.orange),
                  if (sermon.videoUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _LinkBadge(
                          Icons.play_circle_outline, 'Video', Colors.red),
                    ),
                ]),
              ],
              if (sermon.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  sermon.notes,
                  style: GoogleFonts.poppins(
                      fontSize: 12, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
        title: const Text('Delete Sermon'),
        content: Text('Remove "$title"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
  final Color color;

  const _Tag(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: GoogleFonts.poppins(fontSize: 11, color: color)),
    ]);
  }
}

class _LinkBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _LinkBadge(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}
