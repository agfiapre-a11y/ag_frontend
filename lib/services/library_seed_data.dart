import 'package:uuid/uuid.dart';
import '../models/bible_study_resource.dart';
import '../models/devotion_guide.dart';
import '../models/library_book.dart';
import 'local_db.dart';

const _uuid = Uuid();

/// Seeds the Library with a curated starter catalog: free/public-domain
/// Christian books (from legitimate sources such as the Christian Classics
/// Ethereal Library and the Internet Archive), a week of sample daily
/// devotions, and a couple of Bible study guides. Runs once per church —
/// admins can add, edit, or remove entries afterwards.
class LibrarySeedData {
  /// Base URL for the public Supabase Storage bucket holding the larger
  /// scanned/curated PDF collection (Bibles, commentaries, reference works).
  static const _storageBase =
      'https://dbmbkevspcozcnhcsyii.supabase.co/storage/v1/object/public/library-books';

  static Future<void> seedForChurch(String churchId) async {
    await _seedBooks(churchId);
    await _seedDownloadedBooks(churchId);
    await _seedDevotions(churchId);
    await _seedBibleStudies(churchId);
  }

  static Future<void> _seedBooks(String churchId) async {
    final now = DateTime.now();
    final books = <LibraryBook>[
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: "Pilgrim's Progress",
        author: 'John Bunyan',
        category: LibraryBookCategory.christianClassic,
        description:
            "A spiritual allegory following Christian's journey from the City of Destruction to the Celestial City — one of the most published Christian books of all time.",
        url: 'https://ccel.org/ccel/bunyan/pilgrim',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Confessions',
        author: 'Augustine of Hippo',
        category: LibraryBookCategory.christianClassic,
        description:
            "Augustine's account of his conversion to Christianity, one of the most influential works of Christian theology and autobiography ever written.",
        url: 'https://ccel.org/ccel/augustine/confessions/confessions.html',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Imitation of Christ',
        author: 'Thomas à Kempis',
        category: LibraryBookCategory.devotional,
        description:
            'Meditations on the life and teachings of Jesus. Second only to the Bible in translations, it has guided personal prayer for over 500 years.',
        url: 'https://www.ccel.org/ccel/kempis/imitation',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Institutes of the Christian Religion',
        author: 'John Calvin',
        category: LibraryBookCategory.theology,
        description:
            "Calvin's foundational systematic theology, a cornerstone of Reformed Christian doctrine.",
        url: 'https://www.ccel.org/institutes',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Morning and Evening: Daily Readings',
        author: 'Charles H. Spurgeon',
        category: LibraryBookCategory.devotional,
        description:
            'A morning and evening meditation for every day of the year, drawing deep meaning from Scripture in just a few sentences.',
        url: 'https://ccel.org/ccel/spurgeon/morneve.toc.html',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Absolute Surrender',
        author: 'Andrew Murray',
        category: LibraryBookCategory.discipleship,
        description:
            "A series of sermons calling believers to complete surrender to God and a deeper walk in the Holy Spirit.",
        url: 'https://ccel.org/ccel/murray/surrender',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'With Christ in the School of Prayer',
        author: 'Andrew Murray',
        category: LibraryBookCategory.prayer,
        description:
            'Thoughts on training for the ministry of intercession — a classic guide to a deeper prayer life.',
        url: 'https://www.ccel.org/ccel/murray/prayer',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Sermons on Several Occasions',
        author: 'John Wesley',
        category: LibraryBookCategory.theology,
        description:
            "A collection of 141 sermons on the way to heaven, Christian doctrine, and practical holy living.",
        url: 'https://ccel.org/ccel/wesley/sermons',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Power Through Prayer',
        author: 'E. M. Bounds',
        category: LibraryBookCategory.prayer,
        description:
            'A classic on the necessity of a vital prayer life for every preacher and believer.',
        url: 'https://ccel.org/ccel/bounds/power/power.toc.html',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: "Foxe's Book of Martyrs",
        author: 'John Foxe',
        category: LibraryBookCategory.churchHistory,
        description:
            'An account of Christian martyrs throughout church history, from the early church through the Reformation.',
        url: 'https://www.ccel.org/ccel/foxe/martyrs/index.html',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Practice of the Presence of God',
        author: 'Brother Lawrence',
        category: LibraryBookCategory.devotional,
        description:
            'A short, timeless classic on cultivating constant awareness of God in everyday life and work.',
        url: 'https://ccel.org/ccel/lawrence/practice.html',
        source: 'Christian Classics Ethereal Library (public domain)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Ever Increasing Faith',
        author: 'Smith Wigglesworth',
        category: LibraryBookCategory.pentecostalFaith,
        description:
            'Sermons and testimonies on faith, healing, and the power of the Holy Spirit from the early Pentecostal evangelist Smith Wigglesworth.',
        url: 'https://archive.org/details/EverIncreasingFaith',
        source: 'Internet Archive (public domain, 1924)',
        addedById: 'system',
        createdAt: now,
      ),
    ];

    for (final book in books) {
      await LocalDb.saveLibraryBook(book);
    }
  }

  /// Books hosted in the project's Supabase Storage bucket ("library-books")
  /// plus two large reference works linked directly to their Internet
  /// Archive source pages (too large for the storage plan's per-file limit).
  static Future<void> _seedDownloadedBooks(String churchId) async {
    final now = DateTime.now();
    final books = <LibraryBook>[
      // ── Full Bible translations ─────────────────────────────────────────
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Holy Bible (King James Version)',
        author: 'Various translators (1611)',
        category: LibraryBookCategory.scripture,
        description: 'The classic King James Version of the Holy Bible, complete Old and New Testaments.',
        url: '$_storageBase/holy_bible_king_james_version.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Holy Bible (American Standard Version, Large Print)',
        author: 'Various translators (1901)',
        category: LibraryBookCategory.scripture,
        description: 'The American Standard Version of 1901, in a large-print edition.',
        url: '$_storageBase/asv1901_large_print.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Holy Bible (World English Bible)',
        author: 'World English Bible translation committee',
        category: LibraryBookCategory.scripture,
        description: 'A modern English translation created specifically to be in the public domain, based on the American Standard Version.',
        url: '$_storageBase/engwebp_all.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The New Testament (World English Bible)',
        author: 'World English Bible translation committee',
        category: LibraryBookCategory.scripture,
        description: 'The New Testament only, from the World English Bible.',
        url: '$_storageBase/engwebp_nt.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Holy Bible (Free Bible Version)',
        author: 'Free Bible Ministry translation team',
        category: LibraryBookCategory.scripture,
        description: 'A clear, modern English Bible translation released for free use and distribution.',
        url: '$_storageBase/engfbv_all.pdf',
        source: 'Free Bible Version (freely licensed)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Holy Bible (Geneva Bible, 1599)',
        author: 'Geneva Bible translators',
        category: LibraryBookCategory.scripture,
        description: 'The historic 1599 Geneva Bible, the Bible of the Reformation and the Pilgrims (HTML edition, zipped).',
        url: '$_storageBase/enggnv_html.zip',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Holy Bible (New Living Translation)',
        author: 'Tyndale House translation team',
        category: LibraryBookCategory.scripture,
        description: 'The New Living Translation of the Holy Bible.',
        url: '$_storageBase/the-holy-bible-new-living-translation.pdf',
        source: 'Tyndale House Foundation',
        addedById: 'system',
        createdAt: now,
      ),

      // ── Commentaries & reference works ──────────────────────────────────
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: "Barnes' Notes on the New Testament",
        author: 'Albert Barnes',
        category: LibraryBookCategory.commentary,
        description: 'A classic verse-by-verse explanatory commentary on the New Testament.',
        url: '$_storageBase/barnes_new_testament_notes.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'A Commentary, Critical and Explanatory, on the Whole Bible',
        author: 'Robert Jamieson, A. R. Fausset & David Brown',
        category: LibraryBookCategory.commentary,
        description: 'The widely used Jamieson-Fausset-Brown (JFB) Bible Commentary, covering both Old and New Testaments.',
        url: '$_storageBase/jamieson-fausset-brown-commentary-on-bible.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'A Commentary, Critical, Experimental, and Practical, on the Old and New Testaments (Vol. 4)',
        author: 'Robert Jamieson, A. R. Fausset & David Brown',
        category: LibraryBookCategory.commentary,
        description: 'Volume 4 (Jeremiah-Malachi) of the full multi-volume JFB commentary set, digitized by the Internet Archive.',
        url: 'https://archive.org/details/commentarycritic04jami',
        source: 'Internet Archive (public domain, 1866)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: "Explanatory Notes Upon the Bible",
        author: 'John Wesley',
        category: LibraryBookCategory.commentary,
        description: "John Wesley's explanatory notes on the whole Bible.",
        url: '$_storageBase/john_wesley-wesleys_notes_on_the_bible.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: "Strong's Exhaustive Concordance of the Bible",
        author: 'James Strong',
        category: LibraryBookCategory.commentary,
        description: 'A complete concordance of every word in the King James Bible, with Hebrew and Greek dictionaries.',
        url: '$_storageBase/Strongs-Exhaustive-Concordance.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The International Standard Bible Encyclopedia',
        author: 'James Orr (General Editor)',
        category: LibraryBookCategory.commentary,
        description: 'An exhaustive Bible encyclopedia explaining significant words, people, and places of Scripture.',
        url: 'https://archive.org/details/internationalst01orrgoog',
        source: 'Internet Archive (public domain, 1915)',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'BridgeWay Bible Commentary',
        author: 'BridgeWay Publications',
        category: LibraryBookCategory.commentary,
        description: 'A concise, readable modern commentary covering every book of the Bible.',
        url: '$_storageBase/bible-commentary-bridgeway.pdf',
        source: 'BridgeWay Publications',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Bible Atlas',
        category: LibraryBookCategory.commentary,
        description: 'A geographical atlas illustrating the lands and journeys of the Bible.',
        url: '$_storageBase/the-bible-atlas.pdf',
        addedById: 'system',
        createdAt: now,
      ),

      // ── Devotional & practical ministry resources ───────────────────────
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Sermons on Proverbs',
        author: 'Charles H. Spurgeon',
        category: LibraryBookCategory.devotional,
        description: 'A collection of sermons on the book of Proverbs by the "Prince of Preachers."',
        url: '$_storageBase/spurgeon-sermons-on-proverbs.pdf',
        source: 'Public domain',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'Prayer 101',
        category: LibraryBookCategory.prayer,
        description: 'A short practical guide to a life of prayer.',
        url: '$_storageBase/prayer-101.pdf',
        addedById: 'system',
        createdAt: now,
      ),
      LibraryBook(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'How to Study and Teach the Bible',
        category: LibraryBookCategory.discipleship,
        description: 'A practical guide to personal Bible study methods and teaching Scripture to others.',
        url: '$_storageBase/how-to-study-and-teach-the-bible.pdf',
        addedById: 'system',
        createdAt: now,
      ),
    ];

    for (final book in books) {
      await LocalDb.saveLibraryBook(book);
    }
  }

  static Future<void> _seedDevotions(String churchId) async {
    final today = DateTime.now();

    final titles = [
      'Trust in the Lord',
      'The Lord is My Shepherd',
      'Strength in Weakness',
      'Be Still and Know',
      'Rejoice Always',
      "God's Perfect Peace",
      'Renewed Strength',
    ];

    final refs = [
      'Proverbs 3:5-6',
      'Psalm 23:1-3',
      '2 Corinthians 12:9',
      'Psalm 46:10',
      '1 Thessalonians 5:16-18',
      'Isaiah 26:3',
      'Isaiah 40:31',
    ];

    final texts = [
      'Trust in the Lord with all your heart, and do not lean on your own understanding. In all your ways acknowledge him, and he will make straight your paths.',
      'The Lord is my shepherd; I shall not want. He makes me lie down in green pastures. He leads me beside still waters. He restores my soul.',
      'My grace is sufficient for you, for my power is made perfect in weakness.',
      'Be still, and know that I am God. I will be exalted among the nations, I will be exalted in the earth!',
      'Rejoice always, pray without ceasing, give thanks in all circumstances; for this is the will of God in Christ Jesus for you.',
      'You keep him in perfect peace whose mind is stayed on you, because he trusts in you.',
      'But they who wait for the Lord shall renew their strength; they shall mount up with wings like eagles; they shall run and not be weary; they shall walk and not faint.',
    ];

    final bodies = [
      'When life feels uncertain, it is tempting to lean on our own plans and understanding. But God calls us to trust Him fully — not partially — with every area of our lives. Trusting God means surrendering our need to control the outcome and believing that His ways are higher than ours. Today, bring your worries to Him in prayer and choose to walk by faith, not by sight.',
      'David describes God as a shepherd who provides rest, guidance, and restoration. No matter what season you are in, God is leading you gently and providing exactly what your soul needs today. Let Him lead you beside still waters and quiet your anxious heart.',
      "Paul learned that God's grace is enough even in his greatest weakness. We often think we need to be strong to be useful to God, but He delights in showing His power through our weakness. Whatever you are facing today, surrender it to Him and let His strength carry you through.",
      'In the busyness of life, we can forget to simply be still before God. This verse reminds us that stillness is not passive — it is an act of faith, declaring that God is sovereign over every situation. Take a few quiet moments today to still your heart before Him.',
      "Paul's instruction to rejoice always, pray continually, and give thanks in every circumstance is not about ignoring hardship, but about anchoring our hope in God regardless of our circumstances. Choose gratitude today, even in the small things.",
      'Perfect peace is not the absence of trouble, but the presence of God in the midst of it. When our minds are fixed on Him rather than our circumstances, His peace guards our hearts and minds beyond understanding.',
      'Waiting on God is not wasted time — it is where our strength is renewed. If you feel weary today, take heart: as you wait on the Lord in prayer and trust, He promises to renew your strength for the road ahead.',
    ];

    final prayerPointSets = [
      ["Lord, help me to trust You fully today, even when I don't understand my circumstances.", 'Give me wisdom to seek Your will above my own plans.'],
      ['Thank You, Lord, for being my Shepherd who provides for every need.', 'Restore my soul and give me rest today.'],
      ['Lord, show me Your strength in the areas where I feel weak.', 'Help me to boast in my weakness so Your power may rest on me.'],
      ['Help me to be still before You today and trust Your sovereignty.', 'Quiet the noise in my heart and mind, Lord.'],
      ['Give me a heart of gratitude in every circumstance today.', 'Teach me to pray without ceasing.'],
      ['Fix my mind on You, Lord, and guard my heart with Your peace.', 'Replace my anxiety with trust in You.'],
      ['Renew my strength today as I wait on You, Lord.', 'Help me to run this race without growing weary.'],
    ];

    for (var i = 0; i < titles.length; i++) {
      final devotion = DevotionGuide(
        id: _uuid.v4(),
        churchId: churchId,
        title: titles[i],
        scriptureReference: refs[i],
        scriptureText: texts[i],
        content: bodies[i],
        prayerPoints: prayerPointSets[i],
        author: 'Paradise AG Devotional Team',
        date: today.subtract(Duration(days: today.weekday - 1 - i)),
        addedById: 'system',
        createdAt: today,
      );
      await LocalDb.saveDevotionGuide(devotion);
    }
  }

  static Future<void> _seedBibleStudies(String churchId) async {
    final now = DateTime.now();
    final studies = <BibleStudyResource>[
      BibleStudyResource(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Foundations of Salvation',
        category: BibleStudyCategory.foundations,
        description:
            'A foundational study on what it means to be saved by grace through faith in Jesus Christ.',
        scriptureReferences: 'Ephesians 2:1-10; Romans 10:9-13',
        content:
            'Salvation is the free gift of God, received by grace through faith, not by works, so that no one may boast (Ephesians 2:8-9). Before Christ, we were dead in our sins, but God, being rich in mercy, made us alive together with Christ. This study explores what it means to move from spiritual death to new life in Christ, the assurance of salvation, and how grace transforms the way we live.\n\nKey truths:\n1. Salvation is by grace, not by works (Eph 2:8-9).\n2. Confessing Jesus as Lord and believing in His resurrection brings salvation (Rom 10:9).\n3. We are God\'s workmanship, created for good works (Eph 2:10).',
        discussionQuestions: [
          'What does it mean that salvation is "not a result of works"?',
          'How does understanding grace change the way you relate to God?',
          'What "good works" is God calling you to walk in as a result of your salvation?',
        ],
        addedById: 'system',
        createdAt: now,
      ),
      BibleStudyResource(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Fruit of the Spirit',
        category: BibleStudyCategory.topical,
        description:
            'An in-depth look at the nine expressions of the Spirit-filled life described by Paul in Galatians.',
        scriptureReferences: 'Galatians 5:16-25',
        content:
            'Paul contrasts the "works of the flesh" with the "fruit of the Spirit" — love, joy, peace, patience, kindness, goodness, faithfulness, gentleness, and self-control. Unlike the works of the flesh, the fruit of the Spirit is singular, showing that these qualities grow together as one integrated character, produced by the Holy Spirit as we walk in step with Him (Gal 5:25).\n\nThis study examines each fruit individually, and how walking by the Spirit — not by the flesh — produces lasting transformation of character.',
        discussionQuestions: [
          'Which fruit of the Spirit do you see growing most in your life right now?',
          'Which fruit is the most challenging for you to walk in, and why?',
          'What practical steps can you take this week to "walk by the Spirit" (Gal 5:16)?',
        ],
        addedById: 'system',
        createdAt: now,
      ),
      BibleStudyResource(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'The Book of Romans: An Overview',
        category: BibleStudyCategory.newTestament,
        description:
            "Paul's letter to the Romans lays out the gospel systematically — sin, righteousness, grace, and the transformed Christian life.",
        scriptureReferences: 'Romans 1-8 (overview)',
        content:
            'Romans is often considered Paul\'s masterwork of theology. Chapters 1-3 establish humanity\'s universal need for salvation. Chapters 3-5 explain justification by faith. Chapters 6-8 describe sanctification — the process of being set apart and transformed by the Holy Spirit. Chapters 9-11 address God\'s faithfulness to Israel, and chapters 12-16 apply these truths to practical Christian living.\n\nThis study walks through the major themes of the first eight chapters as a foundation for understanding the rest of the letter.',
        discussionQuestions: [
          'According to Romans 3:23, why does every person need the gospel?',
          'How does Romans 8:1 describe the standing of those who are "in Christ Jesus"?',
          'What does it mean to be led by the Spirit (Romans 8:14)?',
        ],
        addedById: 'system',
        createdAt: now,
      ),
      BibleStudyResource(
        id: _uuid.v4(),
        churchId: churchId,
        title: 'David: A Man After God\'s Own Heart',
        category: BibleStudyCategory.characterStudy,
        description:
            'Examining the life of David — his faith, failures, and repentance — as a model of a heart fully devoted to God.',
        scriptureReferences: '1 Samuel 16-17; 2 Samuel 11-12; Psalm 51',
        content:
            'David was anointed king while still a shepherd boy, defeated Goliath through faith in God rather than military might, and later fell into serious sin with Bathsheba. What sets David apart is not perfection, but a heart that consistently turned back to God in genuine repentance (Psalm 51). This study looks at both David\'s victories and failures to understand what it truly means to have a heart after God.',
        discussionQuestions: [
          'What gave David the confidence to face Goliath (1 Samuel 17:45-47)?',
          'How did David respond when confronted with his sin (2 Samuel 12; Psalm 51)?',
          'What can we learn from David about genuine repentance versus mere regret?',
        ],
        addedById: 'system',
        createdAt: now,
      ),
    ];

    for (final study in studies) {
      await LocalDb.saveBibleStudyResource(study);
    }
  }
}
