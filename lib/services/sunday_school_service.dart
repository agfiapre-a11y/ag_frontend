import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';

/// Handles picking a Sunday School PDF, extracting text, splitting it into
/// chapters, and mapping each chapter to a Sunday within the date range.
class SundaySchoolService {
  static const _bucket = 'library-books';
  static const _folder = 'sunday-school';
  static const _uuid = Uuid();

  /// Picks a PDF, extracts text, splits into chapters by "Chapter" headings,
  /// uploads the PDF to Supabase, and returns everything needed to create
  /// the book + chapter records.
  ///
  /// Returns null if the user cancels the file picker.
  static Future<SundaySchoolUploadResult?> pickAndProcessBook({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
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

    // Extract text and split into chapters
    List<ChapterContent> chapters = [];
    if (file.path != null) {
      try {
        final pdfDoc = await PDFDoc.fromPath(file.path!);
        final fullText = await pdfDoc.text;
        chapters = _splitIntoChapters(fullText);
        pdfDoc.deleteFile();
      } catch (_) {
        // If extraction fails, create a single chapter with empty content
        chapters = [ChapterContent(title: 'Full Book', content: '')];
      }
    } else {
      // Web platform — can't extract
      chapters = [ChapterContent(title: 'Full Book', content: '')];
    }

    // Map chapters to Sundays
    final sundays = _getSundaysBetween(startDate, endDate);
    final mappedChapters = <MappedChapter>[];
    for (int i = 0; i < chapters.length; i++) {
      final sundayIndex = i < sundays.length ? i : sundays.length - 1;
      mappedChapters.add(MappedChapter(
        chapterNumber: i + 1,
        title: chapters[i].title,
        content: chapters[i].content,
        sundayDate: sundays[sundayIndex],
      ));
    }

    // Upload PDF to Supabase Storage
    final client = SupabaseConfig.client;
    if (client == null) {
      throw Exception(
          'Cloud storage is not configured. Upload requires Supabase.');
    }

    final ext = _extension(file.name);
    final path = '$_folder/${_uuid.v4()}.$ext';
    await client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'application/pdf'),
        );
    final downloadUrl = client.storage.from(_bucket).getPublicUrl(path);

    return SundaySchoolUploadResult(
      downloadUrl: downloadUrl,
      chapters: mappedChapters,
    );
  }

  /// Splits extracted PDF text into chapters.
  /// Looks for common chapter heading patterns like "Chapter 1", "CHAPTER 1",
  /// "Lesson 1", "Week 1", etc.
  static List<ChapterContent> _splitIntoChapters(String fullText) {
    if (fullText.trim().isEmpty) {
      return [ChapterContent(title: 'Full Book', content: '')];
    }

    // Try splitting by common chapter heading patterns
    final chapterRegex = RegExp(
      r'(?:^|\n)\s*(?:CHAPTER|Chapter|LESSON|Lesson|WEEK|Week|STUDY|Study)\s*(\d+)[\s:.\-]*',
      multiLine: true,
    );

    final matches = chapterRegex.allMatches(fullText).toList();
    if (matches.length < 2) {
      // No clear chapter headings — treat the whole thing as one chapter
      return [ChapterContent(title: 'Chapter 1', content: fullText.trim())];
    }

    final chapters = <ChapterContent>[];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : fullText.length;
      final chunk = fullText.substring(start, end).trim();
      // Extract chapter title from the heading line
      final firstLine = chunk.split('\n').first.trim();
      chapters.add(ChapterContent(title: firstLine, content: chunk));
    }

    return chapters;
  }

  /// Returns all Sundays between [start] and [end], inclusive.
  static List<DateTime> _getSundaysBetween(DateTime start, DateTime end) {
    final sundays = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    // Move to the first Sunday
    while (current.weekday != DateTime.sunday) {
      current = current.add(const Duration(days: 1));
    }
    // If the first Sunday is before the start date, start from there
    if (current.isBefore(DateTime(start.year, start.month, start.day))) {
      current = current.add(const Duration(days: 7));
    }
    while (!current.isAfter(DateTime(end.year, end.month, end.day))) {
      sundays.add(current);
      current = current.add(const Duration(days: 7));
    }
    if (sundays.isEmpty) {
      // Fallback: if no Sundays in range, use the start date
      sundays.add(start);
    }
    return sundays;
  }

  static String _extension(String filename) {
    final dot = filename.lastIndexOf('.');
    if (dot != -1 && dot < filename.length - 1) {
      return filename.substring(dot + 1).toLowerCase();
    }
    return 'pdf';
  }
}

/// A chapter's extracted text content before Sunday mapping.
class ChapterContent {
  final String title;
  final String content;
  ChapterContent({required this.title, required this.content});
}

/// A chapter mapped to a specific Sunday.
class MappedChapter {
  final int chapterNumber;
  final String title;
  final String content;
  final DateTime sundayDate;
  MappedChapter({
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.sundayDate,
  });
}

/// Result of picking and processing a Sunday School book.
class SundaySchoolUploadResult {
  final String downloadUrl;
  final List<MappedChapter> chapters;
  SundaySchoolUploadResult({required this.downloadUrl, required this.chapters});
}
