import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

/// Handles picking and uploading media files (photos/videos) for Community
/// posts to Supabase Storage.
///
/// Reuses the existing public `library-books` bucket under a `community/`
/// subfolder so no new bucket needs to be created in the Supabase dashboard.
class CommunityMediaService {
  static const _bucket = 'library-books';
  static const _folder = 'community';
  static const _uuid = Uuid();

  /// Picks an image from the device and uploads it to Supabase Storage.
  /// Returns the public URL of the uploaded image, or null if cancelled.
  static Future<String?> pickAndUploadImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return _uploadFile(result.files.first, 'image');
  }

  /// Picks a video from the device and uploads it to Supabase Storage.
  /// Returns the public URL of the uploaded video, or null if cancelled.
  static Future<String?> pickAndUploadVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return _uploadFile(result.files.first, 'video');
  }

  /// Uploads a [PlatformFile] to Supabase Storage and returns the public URL.
  static Future<String?> _uploadFile(PlatformFile file, String kind) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception(
          'Cloud storage is not configured. Media upload requires Supabase.');
    }

    final ext = _extension(file.name, kind);
    final path = '$_folder/${_uuid.v4()}.$ext';

    // Read file bytes — works on web (bytes) and mobile (path)
    Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      throw Exception('Could not read the selected file.');
    }

    final contentType = kind == 'image' ? 'image/*' : 'video/*';

    await client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );

    return client.storage.from(_bucket).getPublicUrl(path);
  }

  static String _extension(String filename, String kind) {
    final dot = filename.lastIndexOf('.');
    if (dot != -1 && dot < filename.length - 1) {
      return filename.substring(dot + 1).toLowerCase();
    }
    return kind == 'image' ? 'jpg' : 'mp4';
  }
}
