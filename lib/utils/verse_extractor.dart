/// Extracts Bible verse references and memory verses from Sunday School
/// chapter text. Also provides utilities for parsing verse references.
class VerseExtractor {
  /// Bible book names for reference matching.
  static const _bibleBooks = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
    'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
    '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
    'Psalm', 'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon',
    'Song of Songs', 'Isaiah', 'Jeremiah', 'Lamentations', 'Ezekiel',
    'Daniel', 'Hosea', 'Joel', 'Amos', 'Obadiah', 'Jonah', 'Micah',
    'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai', 'Zechariah', 'Malachi',
    'Matthew', 'Mark', 'Luke', 'John', 'Acts', 'Romans',
    '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
    '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude',
    'Revelation',
  ];

  /// Regex pattern for matching Bible references like "John 3:16" or "1 Samuel 15:22-25"
  static final _refPattern = RegExp(
    r'((?:1\s?|2\s?|3\s?)?(?:' +
        _bibleBooks.map((b) => b.replaceAll(' ', r'\s*')).join('|') +
        r'))\s+(\d+)(?::(\d+)(?:[-–](\d+))?)?',
    caseSensitive: false,
  );

  /// Extract the memory verse from a chapter's text content.
  /// Returns the verse text and reference, or null if not found.
  static MemoryVerse? extractMemoryVerse(String chapterContent) {
    if (chapterContent.isEmpty) return null;

    // Find "Memory Verse" section
    final mvRegex = RegExp(
      r'Memory\s*Verse\s*\n([\s\S]*?)(?=\n(?:Lesson\s|LESSON\s|I\.\s|Lesson\s*Text|Lesson\s*Objectives|--\s*\d|Central\s))',
      caseSensitive: false,
    );
    final match = mvRegex.firstMatch(chapterContent);
    if (match == null) return null;

    final section = match.group(1)!.trim();
    final lines = section
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;

    String reference = '';
    String verseText = '';

    // Search from last line backwards for a Bible reference
    for (int i = lines.length - 1; i >= 0; i--) {
      final cleaned = lines[i]
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .replaceAll(RegExp(r'[.…]+$'), '');
      if (_isBibleReference(cleaned)) {
        reference = cleaned;
        verseText = lines.sublist(0, i).join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
        break;
      }
    }

    if (reference.isEmpty) {
      // Try finding reference anywhere in the section
      for (int i = 0; i < lines.length; i++) {
        final cleaned = lines[i]
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim()
            .replaceAll(RegExp(r'[.…]+$'), '');
        if (_isBibleReference(cleaned)) {
          reference = cleaned;
          verseText = lines
              .asMap()
              .entries
              .where((e) => e.key != i)
              .map((e) => e.value)
              .join(' ')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          break;
        }
      }
    }

    if (reference.isEmpty) {
      verseText = section.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    if (verseText.isEmpty && reference.isEmpty) return null;

    return MemoryVerse(reference: reference, text: verseText);
  }

  /// Extract all Bible references mentioned in a text.
  /// Returns a list of unique references found.
  static List<String> extractAllReferences(String text) {
    final refs = <String>{};
    for (final match in _refPattern.allMatches(text)) {
      refs.add(match.group(0)!.trim());
    }
    return refs.toList();
  }

  /// Check if a string is a valid Bible reference.
  static bool _isBibleReference(String text) {
    return _refPattern.hasMatch(text) &&
        text.length < 50 &&
        !text.contains(',');
  }

  /// Parse a Bible reference into its components.
  /// e.g., "1 Samuel 15:22-25" → (book: "1 Samuel", chapter: 15, verseStart: 22, verseEnd: 25)
  static BibleRef? parseReference(String ref) {
    final match = _refPattern.firstMatch(ref);
    if (match == null) return null;

    return BibleRef(
      book: match.group(1)!.trim(),
      chapter: int.tryParse(match.group(2)!) ?? 0,
      verseStart: int.tryParse(match.group(3) ?? '') ?? 0,
      verseEnd: int.tryParse(match.group(4) ?? '') ?? 0,
    );
  }

  /// Normalize a Bible reference for searching.
  /// e.g., "1 Samuel 15:22-25" → "1 Samuel 15"
  /// e.g., "John 3:16" → "John 3"
  static String normalizeForSearch(String ref) {
    final parsed = parseReference(ref);
    if (parsed == null) return ref;
    return '${parsed.book} ${parsed.chapter}';
  }
}

/// A memory verse with its text and Bible reference.
class MemoryVerse {
  final String reference; // e.g., "Jude 1:3" (may be empty if not found)
  final String text; // The verse text

  const MemoryVerse({required this.reference, required this.text});

  bool get hasReference => reference.isNotEmpty;
}

/// Parsed Bible reference components.
class BibleRef {
  final String book; // e.g., "1 Samuel"
  final int chapter; // e.g., 15
  final int verseStart; // e.g., 22 (0 if no verse specified)
  final int verseEnd; // e.g., 25 (0 if single verse or no verse)

  const BibleRef({
    required this.book,
    required this.chapter,
    required this.verseStart,
    required this.verseEnd,
  });

  bool get hasVerseRange => verseStart > 0;
  bool get isMultiVerse => verseEnd > verseStart;

  @override
  String toString() {
    if (hasVerseRange) {
      if (isMultiVerse) {
        return '$book $chapter:$verseStart-$verseEnd';
      }
      return '$book $chapter:$verseStart';
    }
    return '$book $chapter';
  }
}
