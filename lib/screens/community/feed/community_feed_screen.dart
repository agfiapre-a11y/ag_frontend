import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/community_post.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/responsive_scaffold.dart';

/// Public social feed — posts, photos, videos, and status updates from
/// everyone in the user's church (or all churches for above-church roles).
class CommunityFeedScreen extends ConsumerWidget {
  const CommunityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(communityPostProvider);

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Community Feed')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/community/feed/new'),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('New Post'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: posts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.article_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(
                    'No posts yet',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to share something with your church.',
                    style: GoogleFonts.poppins(
                        color: AppColors.textTertiary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, i) => _PostCard(post: posts[i]),
            ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  final CommunityPost post;

  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).user!;
    final canModerate =
        AppRoles.communityModeratorRoles.contains(user.role);
    final isAuthor = post.authorId == user.id;
    final liked = post.likedBy(user.id);

    return Card(
      color: AppColors.cardWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.emeraldCardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/community/feed/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Author row
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    post.authorName.isNotEmpty
                        ? post.authorName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName,
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      if (post.authorRole.isNotEmpty)
                        Text(AppRoles.label(post.authorRole),
                            style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: AppColors.emeraldTextSecondary)),
                    ],
                  ),
                ),
                Text(
                  DateFormat('MMM d, h:mm a').format(post.createdAt.toLocal()),
                  style: GoogleFonts.poppins(
                      fontSize: 11, color: AppColors.emeraldTextMuted),
                ),
                if (isAuthor || canModerate)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Colors.grey),
                    onSelected: (action) async {
                      if (action == 'delete') {
                        final ok = await _confirmDelete(context);
                        if (ok) {
                          await ref
                              .read(communityPostProvider.notifier)
                              .deletePost(post.id);
                        }
                      }
                    },
                    itemBuilder: (_) => [
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
              const SizedBox(height: 12),
              // Text content
              if (post.text.isNotEmpty)
                Text(post.text,
                    style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.emeraldTextPrimary,
                        height: 1.4)),
              // Media
              if (post.isImage && post.mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(post.mediaUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                            height: 200,
                            color: AppColors.emeraldCardBorder,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 40, color: Colors.grey),
                            ),
                          )),
                ),
              ],
              if (post.isVideo && post.mediaUrl.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.play_circle_outline,
                            size: 48, color: AppColors.primary),
                        const SizedBox(height: 4),
                        Text('Video post',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.emeraldTextSecondary)),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Actions row
              Row(children: [
                _ActionButton(
                  icon: liked
                      ? Icons.favorite
                      : Icons.favorite_border_outlined,
                  label: '${post.likeCount}',
                  color: liked ? Colors.red : AppColors.emeraldTextSecondary,
                  onTap: () => ref
                      .read(communityPostProvider.notifier)
                      .toggleLike(post, user.id),
                ),
                const SizedBox(width: 16),
                _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Comment',
                  color: AppColors.emeraldTextSecondary,
                  onTap: () => context.push('/community/feed/${post.id}'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('Delete this post? This cannot be undone.'),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.poppins(
                  fontSize: 13, fontWeight: FontWeight.w500, color: color)),
        ]),
      ),
    );
  }
}
