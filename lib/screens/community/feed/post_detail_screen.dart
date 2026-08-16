import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/constants.dart';
import '../../../models/community_post.dart';
import '../../../models/comment.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/local_db.dart';
import '../../../widgets/community_video_player.dart';
import '../../../widgets/responsive_scaffold.dart';

/// Detail view for a single post — shows the full post, likes, and comments.
/// Users can add comments and like the post from here.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;

  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  CommunityPost? _post;
  List<Comment> _comments = [];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _refresh() {
    _post = LocalDb.getCommunityPostById(widget.postId);
    _comments = LocalDb.getCommentsForPost(widget.postId);
    if (mounted) setState(() {});
    // Mark nothing — comments are read on view
    _comments.sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _addComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final user = ref.read(appStateProvider).user!;
    await ref.read(commentProvider.notifier).addComment(
          postId: widget.postId,
          authorId: user.id,
          authorName: user.name,
          authorRole: user.role,
          text: text,
        );
    _commentController.clear();
    _refresh();
  }

  Future<void> _toggleLike() async {
    if (_post == null) return;
    final user = ref.read(appStateProvider).user!;
    await ref.read(communityPostProvider.notifier).toggleLike(_post!, user.id);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appStateProvider).user!;
    if (_post == null) {
      return ResponsiveScaffold(
        appBar: AppBar(title: const Text('Post')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final post = _post!;
    final canModerate = AppRoles.communityModeratorRoles.contains(user.role);
    final liked = post.likedBy(user.id);

    return ResponsiveScaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author
                  Row(children: [
                    CircleAvatar(
                      radius: 22,
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
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          if (post.authorRole.isNotEmpty)
                            Text(AppRoles.label(post.authorRole),
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.emeraldTextSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, y · h:mm a')
                          .format(post.createdAt.toLocal()),
                      style: GoogleFonts.poppins(
                          fontSize: 11, color: AppColors.emeraldTextMuted),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  if (post.text.isNotEmpty)
                    Text(post.text,
                        style: GoogleFonts.poppins(
                            fontSize: 15,
                            height: 1.5,
                            color: AppColors.emeraldTextPrimary)),
                  if (post.isImage && post.mediaUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(post.mediaUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                                height: 240,
                                color: AppColors.emeraldCardBorder,
                                child: const Center(
                                  child: Icon(Icons.broken_image_outlined,
                                      size: 48, color: Colors.grey),
                                ),
                              )),
                    ),
                  ],
                  if (post.isVideo && post.mediaUrl.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    CommunityVideoPlayer(url: post.mediaUrl),
                  ],
                  const SizedBox(height: 16),
                  // Like + comment count
                  Row(children: [
                    Icon(liked ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: liked ? Colors.red : AppColors.emeraldTextMuted),
                    const SizedBox(width: 6),
                    Text('${post.likeCount} like${post.likeCount == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.emeraldTextSecondary)),
                    const SizedBox(width: 16),
                    Icon(Icons.chat_bubble_outline,
                        size: 18, color: AppColors.emeraldTextMuted),
                    const SizedBox(width: 6),
                    Text('${_comments.length} comment${_comments.length == 1 ? '' : 's'}',
                        style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.emeraldTextSecondary)),
                  ]),
                  const Divider(height: 28),
                  // Action buttons
                  Row(children: [
                    TextButton.icon(
                      onPressed: _toggleLike,
                      icon: Icon(
                          liked ? Icons.favorite : Icons.favorite_border,
                          color: liked ? Colors.red : AppColors.primary),
                      label: Text(liked ? 'Liked' : 'Like',
                          style: GoogleFonts.poppins(
                              color: liked ? Colors.red : AppColors.primary,
                              fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const Divider(height: 28),
                  // Comments
                  Text('Comments',
                      style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emeraldTextPrimary)),
                  const SizedBox(height: 12),
                  if (_comments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No comments yet. Be the first to encourage!',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.emeraldTextMuted),
                      ),
                    ),
                  ..._comments.map((c) => _CommentTile(
                        comment: c,
                        canDelete: c.authorId == user.id || canModerate,
                        onDelete: () async {
                          await ref
                              .read(commentProvider.notifier)
                              .deleteComment(c.id);
                          _refresh();
                        },
                      )),
                ],
              ),
            ),
          ),
          // Comment composer
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              color: AppColors.cardWhite,
              border: Border(
                  top: BorderSide(color: AppColors.emeraldCardBorder)),
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment…',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addComment(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addComment,
                  icon: const Icon(Icons.send, color: AppColors.primary),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Comment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.primary.withValues(alpha: 0.15),
            child: Text(
              comment.authorName.isNotEmpty
                  ? comment.authorName[0].toUpperCase()
                  : '?',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ivoryLight,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.emeraldCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(comment.authorName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                    if (comment.authorRole.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text('· ${AppRoles.label(comment.authorRole)}',
                          style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: AppColors.emeraldTextMuted)),
                    ],
                    const Spacer(),
                    Text(
                      DateFormat('h:mm a').format(comment.createdAt.toLocal()),
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: AppColors.emeraldTextMuted),
                    ),
                    if (canDelete) ...[
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: onDelete,
                        child: const Icon(Icons.delete_outline,
                            size: 14, color: Colors.red),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 4),
                  Text(comment.text,
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.emeraldTextPrimary,
                          height: 1.4)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
