import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

/// Handles picking a PDF, extracting its text content, and uploading both
/// the PDF file and its extracted text to Supabase.
///
/// When a user uploads a book through the app, the flow is:
/// 1. Pick a PDF file from the device
/// 2. Extract text content from the PDF (page count, word count, full text)
/// 3. Upload the PDF to the `library-books` Supabase bucket
/// 4. Return the download URL + extracted metadata so it can be saved
///    in the `library_books` table
class LibraryBookService {
  static const _bucket = 'library-books';
  static const _folder = 'books';
  static const _uuid = Uuid();

  /// Picks a PDF from the device, extracts its text, uploads it to Supabase
  /// Storage, and returns the download URL + extracted text content.
  ///
  /// Returns null if the user cancels the file picker.
  static Future<BookUploadResult?> pickAndUploadBook() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;

    // Read file bytes (works on web + mobile)
    Uint8List bytes;
    if (file.bytes != null) {
      bytes = file.bytes!;
    } else if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else {
      throw Exception('Could not read the selected file.');
    }

    // Extract text content from the PDF (mobile only — on web this is a no-op)
    String content = '';
    int pageCount = 0;
    int wordCount = 0;

    if (file.path != null) {
      try {
        final pdfDoc = await PDFDoc.fromPath(file.path!);
        final text = await pdfDoc.text;
        content = text.trim();
        pageCount = pdfDoc.length;
        wordCount = content.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
        pdfDoc.deleteFile();
      } catch (_) {
        // Text extraction failed (e.g. scanned PDF, web platform) —
        // continue without content; the PDF download will still work.
      }
    }

    // Upload PDF to Supabase Storage
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception(
          'Cloud storage is not configured. Book upload requires Supabase.');
    }

    final ext = _extension(file.name);
    final path = '$_folder/${_uuid.v4()}.$ext';

    await client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'application/pdf'),
        );

    final downloadUrl = client.storage.from(_bucket).getPublicUrl(path);

    return BookUploadResult(
      downloadUrl: downloadUrl,
      content: content,
      pageCount: pageCount,
      wordCount: wordCount,
    );
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot != -1 && dot < filename.length - 1) {
      return filename.substring(dot + 1).toLowerCase();
    }
    return 'pdf';
  }
}

/// Holds the result of picking, extracting, and uploading a book PDF.
class BookUploadResult {
  final String downloadUrl;
  final String content;
  final int pageCount;
  final int wordCount;

  const BookUploadResult({
    required this.downloadUrl,
    required this.content,
    required this.pageCount,
    required this.wordCount,
  });

  bool get isEmpty => downloadUrl.isEmpty;
}
