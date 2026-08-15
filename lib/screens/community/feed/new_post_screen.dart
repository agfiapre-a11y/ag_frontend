import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../models/community_post.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../widgets/responsive_scaffold.dart';

/// Composer for creating a new social post (status, photo, or video).
class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _textController = TextEditingController();
  final _mediaController = TextEditingController();
  String _mediaType = CommunityMediaType.text;
  bool _posting = false;

  @override
  void dispose() {
    _textController.dispose();
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    final mediaUrl = _mediaController.text.trim();
    if (text.isEmpty && mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some text or a media URL first.')),
      );
      return;
    }
    if (_mediaType != CommunityMediaType.text && mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a media URL.')),
      );
      return;
    }

    setState(() => _posting = true);
    final user = ref.read(appStateProvider).user!;
    try {
      await ref.read(communityPostProvider.notifier).createPost(
            authorId: user.id,
            authorName: user.name,
            authorRole: user.role,
            text: text,
            mediaUrl: mediaUrl,
            mediaType: _mediaType == CommunityMediaType.text && mediaUrl.isNotEmpty
                ? (_isImageUrl(mediaUrl)
                    ? CommunityMediaType.image
                    : CommunityMediaType.video)
                : _mediaType,
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _posting ? null : _submit,
            child: _posting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text('Post',
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Media type selector
            Text('Post type',
                style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emeraldTextSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              _ChoiceChip(
                label: 'Status',
                icon: Icons.text_snippet_outlined,
                selected: _mediaType == CommunityMediaType.text,
                onSelected: () =>
                    setState(() => _mediaType = CommunityMediaType.text),
              ),
              _ChoiceChip(
                label: 'Photo',
                icon: Icons.image_outlined,
                selected: _mediaType == CommunityMediaType.image,
                onSelected: () =>
                    setState(() => _mediaType = CommunityMediaType.image),
              ),
              _ChoiceChip(
                label: 'Video',
                icon: Icons.videocam_outlined,
                selected: _mediaType == CommunityMediaType.video,
                onSelected: () =>
                    setState(() => _mediaType = CommunityMediaType.video),
              ),
            ]),
            const SizedBox(height: 20),
            // Text field
            TextField(
              controller: _textController,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: "What's on your heart? Share a verse, a thought, a prayer…",
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            if (_mediaType != CommunityMediaType.text) ...[
              TextField(
                controller: _mediaController,
                decoration: InputDecoration(
                  hintText: _mediaType == CommunityMediaType.image
                      ? 'Image URL (https://…)'
                      : 'Video URL (https://…)',
                  prefixIcon: Icon(_mediaType == CommunityMediaType.image
                      ? Icons.image_outlined
                      : Icons.videocam_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tip: paste a direct link to an image or video file. '
                'Uploaded media hosting can be added later.',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: AppColors.emeraldTextMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _ChoiceChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16,
            color: selected ? Colors.white : AppColors.emeraldTextSecondary),
        const SizedBox(width: 6),
        Text(label),
      ]),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.primary,
      labelStyle: GoogleFonts.poppins(
          color: selected ? Colors.white : AppColors.emeraldTextPrimary,
          fontWeight: FontWeight.w500,
          fontSize: 13),
      backgroundColor: AppColors.cardWhite,
      side: const BorderSide(color: AppColors.emeraldCardBorder),
    );
  }
}
