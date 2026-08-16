import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants.dart';
import '../../../models/community_post.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/data_provider.dart';
import '../../../services/community_media_service.dart';
import '../../../widgets/responsive_scaffold.dart';

/// Composer for creating a new social post (status, photo, or video).
/// Photos and videos are picked from the device and uploaded to Supabase
/// Storage — no manual URL entry required.
class NewPostScreen extends ConsumerStatefulWidget {
  const NewPostScreen({super.key});

  @override
  ConsumerState<NewPostScreen> createState() => _NewPostScreenState();
}

class _NewPostScreenState extends ConsumerState<NewPostScreen> {
  final _textController = TextEditingController();
  String _mediaType = CommunityMediaType.text;
  String _mediaUrl = '';
  bool _posting = false;
  bool _uploading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _uploading = true);
    try {
      final url = await CommunityMediaService.pickAndUploadImage();
      if (url != null) {
        setState(() {
          _mediaUrl = url;
          _mediaType = CommunityMediaType.image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickVideo() async {
    setState(() => _uploading = true);
    try {
      final url = await CommunityMediaService.pickAndUploadVideo();
      if (url != null) {
        setState(() {
          _mediaUrl = url;
          _mediaType = CommunityMediaType.video;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _clearMedia() {
    setState(() {
      _mediaUrl = '';
      _mediaType = CommunityMediaType.text;
    });
  }

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _mediaUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add some text or a photo/video first.')),
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
            mediaUrl: _mediaUrl,
            mediaType: _mediaType,
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

  @override
  Widget build(BuildContext context) {
    return ResponsiveScaffold(
      appBar: AppBar(
        title: const Text('New Post'),
        actions: [
          TextButton(
            onPressed: _posting || _uploading ? null : _submit,
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
            // Author preview
            Row(children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                child: Text(
                  ref.watch(appStateProvider).user!.name[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  ref.watch(appStateProvider).user!.name,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ]),
            const SizedBox(height: 16),
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
            // Media preview or picker buttons
            if (_mediaUrl.isNotEmpty && _mediaType == CommunityMediaType.image) ...[
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(_mediaUrl,
                      height: 240,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                            height: 240,
                            color: AppColors.emeraldCardBorder,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 40, color: Colors.grey),
                            ),
                          )),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filled(
                    onPressed: _clearMedia,
                    icon: const Icon(Icons.close, size: 18),
                    style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6)),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
            ] else if (_mediaUrl.isNotEmpty && _mediaType == CommunityMediaType.video) ...[
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emeraldCardBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.video_library, color: AppColors.primary, size: 28),
                    const SizedBox(width: 8),
                    Text('Video attached',
                        style: GoogleFonts.poppins(
                            fontSize: 13, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    TextButton(onPressed: _clearMedia, child: const Text('Remove')),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ] else if (_uploading) ...[
              Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Uploading…'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ] else ...[
              // Media picker buttons
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_outlined),
                    label: const Text('Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Video'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              Text(
                'Pick a photo or video from your device to share.',
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
