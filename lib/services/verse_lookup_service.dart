import '../models/library_book.dart';
import 'local_db.dart';
import '../utils/verse_extractor.dart';

/// Searches through library books (Bibles, commentaries) to find content
/// related to a specific Bible verse reference.
///
/// When a user taps a memory verse in a Sunday School chapter, this service
/// looks through all library books that have extracted text content and
/// finds passages that mention the verse reference. Results are categorized
/// by book type (Bible, Commentary, Other).
class VerseLookupService {
  /// Search all library books for content related to the given Bible reference.
  ///
  /// Returns a list of [VerseLookupResult] sorted by relevance:
  /// 1. Bibles first (the actual verse text)
  /// 2. Commentaries (insights and explanations)
  /// 3. Other books (any mentions)
  static List<VerseLookupResult> lookup(String reference) {
    final parsed = VerseExtractor.parseReference(reference);
    if (parsed == null) return [];

    // Build search patterns — try multiple formats
    final patterns = <String>[
      // Full reference: "1 Samuel 15:22"
      reference,
      // Normalized: "1 Samuel 15"
      VerseExtractor.normalizeForSearch(reference),
      // Book + chapter without space variants
      '${parsed.book} ${parsed.chapter}',
      // Just the book name + chapter with colon
      '${parsed.book} ${parsed.chapter}:',
    ];

    // Get all library books with content
    final allBooks = LocalDb.getAllLibraryBooks();
    final booksWithContent =
        allBooks.where((b) => b.content.isNotEmpty).toList();

    final results = <VerseLookupResult>[];

    for (final book in booksWithContent) {
      final matches = _searchBook(book, parsed, patterns);
      if (matches.isNotEmpty) {
        results.add(VerseLookupResult(
          book: book,
          matches: matches,
          category: _categorizeBook(book),
        ));
      }
    }

    // Sort: Bibles first, then commentaries, then others
    results.sort((a, b) {
      final order = {BookCategory.bible: 0, BookCategory.commentary: 1, BookCategory.other: 2};
      final aOrder = order[a.category] ?? 3;
      final bOrder = order[b.category] ?? 3;
      if (aOrder != bOrder) return aOrder.compareTo(bOrder);
      // Within same category, more matches = higher priority
      return b.matches.length.compareTo(a.matches.length);
    });

    return results;
  }

  /// Search a single book for passages matching the verse reference.
  static List<VerseMatch> _searchBook(
    LibraryBook book,
    BibleRef ref,
    List<String> patterns,
  ) {
    final content = book.content;
    final matches = <VerseMatch>[];
    final usedPositions = <int>{};

    for (final pattern in patterns) {
      final regex = RegExp(
        RegExp.escape(pattern),
        caseSensitive: false,
      );

      for (final match in regex.allMatches(content)) {
        // Skip if we already have a match near this position
        final nearby = usedPositions.any((p) => (p - match.start).abs() < 200);
        if (nearby) continue;
        usedPositions.add(match.start);

        // Extract context around the match
        final contextStart = (match.start - 300).clamp(0, content.length);
        final contextEnd = (match.end + 500).clamp(0, content.length);
        var context = content.substring(contextStart, contextEnd);

        // Clean up context — try to start/end at sentence boundaries
        context = _cleanContext(context, ref);

        if (context.trim().isNotEmpty) {
          matches.add(VerseMatch(
            reference: pattern,
            context: context.trim(),
            position: match.start,
          ));
        }

        // Limit to 3 matches per book to avoid flooding
        if (matches.length >= 3) break;
      }
      if (matches.length >= 3) break;
    }

    return matches;
  }

  /// Clean up context text to be more readable.
  static String _cleanContext(String context, BibleRef ref) {
    // Try to find a good starting point (beginning of a sentence or verse)
    final startPatterns = [
      RegExp(r'\n\s*((?:\d+\.\s*)?[A-Z])'), // Start of sentence or numbered verse
      RegExp(r'\n\s*'), // Start of line
    ];

    for (final pattern in startPatterns) {
      final match = pattern.firstMatch(context);
      if (match != null && match.start > 0 && match.start < 100) {
        context = context.substring(match.start).trim();
        break;
      }
    }

    // Limit to reasonable length
    if (context.length > 800) {
      context = '${context.substring(0, 800)}...';
    }

    return context;
  }

  /// Categorize a library book by its category field.
  static BookCategory _categorizeBook(LibraryBook book) {
    final category = book.category.toLowerCase();
    if (category.contains('bible') || category.contains('scripture')) {
      return BookCategory.bible;
    }
    if (category.contains('commentary') || category.contains('reference')) {
      return BookCategory.commentary;
    }
    return BookCategory.other;
  }
}

/// A single match within a book.
class VerseMatch {
  final String reference; // The pattern that matched
  final String context; // The text around the match
  final int position; // Position in the book's content

  const VerseMatch({
    required this.reference,
    required this.context,
    required this.position,
  });
}

/// A lookup result from a single book.
class VerseLookupResult {
  final LibraryBook book;
  final List<VerseMatch> matches;
  final BookCategory category;

  const VerseLookupResult({
    required this.book,
    required this.matches,
    required this.category,
  });
}

/// Category of a book for sorting lookup results.
enum BookCategory { bible, commentary, other }
