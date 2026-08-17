import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdf_text/flutter_pdf_text.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'supabase_config.dart';
import '../utils/verse_extractor.dart';

/// Handles picking a Sunday School PDF, extracting text, splitting it into
/// lessons by "Memory Verse" markers, extracting each lesson's memory verse,
/// and mapping each lesson to a Sunday within the date range.
///
/// Everything is done automatically when a book is uploaded — no manual
/// steps required.
class SundaySchoolService {
  static const _bucket = 'library-books';
  static const _folder = 'sunday-school';
  static const _uuid = Uuid();

  /// Picks a PDF, extracts text, splits into lessons by Memory Verse markers,
  /// extracts the memory verse from each lesson, uploads the PDF to Supabase,
  /// and returns everything needed to create the book + chapter records.
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

    // Extract text and split into lessons
    List<LessonContent> lessons = [];
    if (file.path != null) {
      try {
        final pdfDoc = await PDFDoc.fromPath(file.path!);
        final fullText = await pdfDoc.text;
        lessons = _splitIntoLessons(fullText);
        pdfDoc.deleteFile();
      } catch (_) {
        // If extraction fails, create a single lesson with empty content
        lessons = [LessonContent(number: 1, title: 'Full Book', content: '', memoryVerse: null)];
      }
    } else {
      // Web platform — can't extract
      lessons = [LessonContent(number: 1, title: 'Full Book', content: '', memoryVerse: null)];
    }

    // Map lessons to Sundays
    final sundays = _getSundaysBetween(startDate, endDate);
    final mappedChapters = <MappedChapter>[];
    for (int i = 0; i < lessons.length; i++) {
      final sundayIndex = i < sundays.length ? i : sundays.length - 1;
      final lesson = lessons[i];
      mappedChapters.add(MappedChapter(
        chapterNumber: lesson.number,
        title: lesson.title,
        content: lesson.content,
        sundayDate: sundays[sundayIndex],
        memoryVerseRef: lesson.memoryVerse?.reference ?? '',
        memoryVerseText: lesson.memoryVerse?.text ?? '',
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

  /// Splits extracted PDF text into lessons by finding "Memory Verse" markers.
  ///
  /// Each lesson in the Adult Teacher PDF has exactly one "Memory Verse" section.
  /// The lesson header ("Lesson N") can appear either before or after the
  /// Memory Verse. We find all Memory Verse positions, then look both directions
  /// for the lesson number, and split the text at each lesson boundary.
  ///
  /// Falls back to "Lesson N" / "Chapter N" heading patterns if no Memory Verse
  /// markers are found (for non-standard PDFs).
  static List<LessonContent> _splitIntoLessons(String fullText) {
    if (fullText.trim().isEmpty) {
      return [LessonContent(number: 1, title: 'Full Book', content: '', memoryVerse: null)];
    }

    // ── Strategy 1: Split by "Memory Verse" markers ──────────────────────
    final mvRegex = RegExp(r'Memory\s*Verse', caseSensitive: false);
    final mvPositions = mvRegex.allMatches(fullText).map((m) => m.start).toList();

    if (mvPositions.length >= 2) {
      return _splitByMemoryVerseMarkers(fullText, mvPositions);
    }

    // ── Strategy 2: Fall back to "Lesson N" / "Chapter N" headings ───────
    return _splitByLessonHeadings(fullText);
  }

  /// Split by Memory Verse markers — the primary strategy for Adult Teacher PDFs.
  static List<LessonContent> _splitByMemoryVerseMarkers(
    String fullText,
    List<int> mvPositions,
  ) {
    final lessons = <LessonContent>[];

    for (int i = 0; i < mvPositions.length; i++) {
      final mvStart = mvPositions[i];
      final nextMvStart = i + 1 < mvPositions.length ? mvPositions[i + 1] : fullText.length;

      // Look BOTH before and after Memory Verse for "Lesson N" header
      final lookBeforeStart = (mvStart - 3000).clamp(0, fullText.length);
      final lookBefore = fullText.substring(lookBeforeStart, mvStart);
      final lookAfter = fullText.substring(mvStart, (mvStart + 3000).clamp(0, fullText.length));

      final lessonNumRegex = RegExp(r'Lesson\s*(\d+)', caseSensitive: false);
      final beforeMatches = lessonNumRegex.allMatches(lookBefore).toList();
      final afterMatches = lessonNumRegex.allMatches(lookAfter).toList();

      int? lessonNum;
      int lessonHeaderPos = mvStart;

      if (beforeMatches.isNotEmpty && afterMatches.isNotEmpty) {
        final beforeDist = lookBefore.length - beforeMatches.last.start;
        final afterDist = afterMatches.first.start;
        if (beforeDist <= afterDist) {
          lessonNum = int.tryParse(beforeMatches.last.group(1)!) ?? 0;
          lessonHeaderPos = lookBeforeStart + beforeMatches.last.start;
        } else {
          lessonNum = int.tryParse(afterMatches.first.group(1)!) ?? 0;
          lessonHeaderPos = mvStart + afterMatches.first.start;
        }
      } else if (beforeMatches.isNotEmpty) {
        lessonNum = int.tryParse(beforeMatches.last.group(1)!) ?? 0;
        lessonHeaderPos = lookBeforeStart + beforeMatches.last.start;
      } else if (afterMatches.isNotEmpty) {
        lessonNum = int.tryParse(afterMatches.first.group(1)!) ?? 0;
        lessonHeaderPos = mvStart + afterMatches.first.start;
      }

      if (lessonNum == null || lessonNum == 0) continue;

      // Lesson content: from the lesson header (or MV start if header is after) to next MV
      final contentStart = lessonHeaderPos < mvStart ? lessonHeaderPos : mvStart;
      final chunk = fullText.substring(contentStart, nextMvStart).trim();

      // Extract title — look for ALL CAPS text
      String title = 'Lesson $lessonNum';
      final capsMatch = RegExp(r'\n([A-Z][A-Z\s]{4,60})\n').firstMatch(chunk);
      if (capsMatch != null) {
        title = capsMatch.group(1)!.trim().replaceAll(RegExp(r'\s+'), ' ');
      }

      // Extract memory verse from the chunk
      final memoryVerse = VerseExtractor.extractMemoryVerse(chunk);

      lessons.add(LessonContent(
        number: lessonNum,
        title: title,
        content: chunk,
        memoryVerse: memoryVerse,
      ));
    }

    // Sort by lesson number and deduplicate (keep the one with more content)
    lessons.sort((a, b) => a.number.compareTo(b.number));
    final seen = <int, LessonContent>{};
    for (final l in lessons) {
      if (!seen.containsKey(l.number) || seen[l.number]!.content.length < l.content.length) {
        seen[l.number] = l;
      }
    }

    final result = seen.values.toList()..sort((a, b) => a.number.compareTo(b.number));
    return result.isNotEmpty ? result : _splitByLessonHeadings(fullText);
  }

  /// Fallback: split by "Lesson N" / "Chapter N" heading patterns.
  static List<LessonContent> _splitByLessonHeadings(String fullText) {
    final chapterRegex = RegExp(
      r'(?:^|\n)\s*(?:CHAPTER|Chapter|LESSON|Lesson|WEEK|Week|STUDY|Study|UNIT|Unit|SESSION|Session)\s*(\d+)[\s:.\-]*',
      multiLine: true,
    );

    final matches = chapterRegex.allMatches(fullText).toList();
    if (matches.length < 2) {
      // No clear headings — treat the whole thing as one lesson
      final mv = VerseExtractor.extractMemoryVerse(fullText);
      return [LessonContent(number: 1, title: 'Lesson 1', content: fullText.trim(), memoryVerse: mv)];
    }

    final lessons = <LessonContent>[];
    for (int i = 0; i < matches.length; i++) {
      final start = matches[i].start;
      final end = i + 1 < matches.length ? matches[i + 1].start : fullText.length;
      final chunk = fullText.substring(start, end).trim();
      final lessonNum = int.tryParse(matches[i].group(1)!) ?? (i + 1);
      final firstLine = chunk.split('\n').first.trim();
      final mv = VerseExtractor.extractMemoryVerse(chunk);
      lessons.add(LessonContent(
        number: lessonNum,
        title: firstLine,
        content: chunk,
        memoryVerse: mv,
      ));
    }

    return lessons;
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

/// A lesson's extracted content with its memory verse.
class LessonContent {
  final int number;
  final String title;
  final String content;
  final MemoryVerse? memoryVerse;

  LessonContent({
    required this.number,
    required this.title,
    required this.content,
    required this.memoryVerse,
  });
}

/// A lesson mapped to a specific Sunday, with its memory verse.
class MappedChapter {
  final int chapterNumber;
  final String title;
  final String content;
  final DateTime sundayDate;
  final String memoryVerseRef;
  final String memoryVerseText;

  MappedChapter({
    required this.chapterNumber,
    required this.title,
    required this.content,
    required this.sundayDate,
    required this.memoryVerseRef,
    required this.memoryVerseText,
  });
}

/// Result of picking and processing a Sunday School book.
class SundaySchoolUploadResult {
  final String downloadUrl;
  final List<MappedChapter> chapters;

  SundaySchoolUploadResult({required this.downloadUrl, required this.chapters});
}
