import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/domain/entities/word_progress.dart';
import 'package:vowl/features/daily_words/presentation/bloc/daily_words_bloc.dart';
import 'package:vowl/features/daily_words/presentation/widgets/daily_words_widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleWord1 = DailyWord(
    id: 'dw_0001',
    word: 'resilient',
    phonetic: '/rɪˈzɪl.jənt/',
    partOfSpeech: 'adjective',
    definition: 'Able to quickly recover from difficulties.',
    example: 'She is remarkably resilient in difficult situations.',
    difficulty: 3,
    frequencyRank: 1420,
  );

  final sampleWord2 = DailyWord(
    id: 'dw_0002',
    word: 'serene',
    phonetic: '/səˈriːn/',
    partOfSpeech: 'adjective',
    definition: 'Calm and peaceful.',
    example: 'The lake was serene at sunrise.',
    difficulty: 2,
    frequencyRank: 2100,
  );

  group('DailyWord Entity & Parsing', () {
    test('parses from JSON correctly with all curriculum fields', () {
      final json = {
        'word': 'resilient',
        'phonetic': '/rɪˈzɪl.jənt/',
        'partOfSpeech': 'adjective',
        'definition': 'Able to quickly recover from difficulties.',
        'example': 'She is remarkably resilient in difficult situations.',
        'difficulty': 3,
        'frequencyRank': 1420,
      };

      final word = DailyWord.fromJson(json);
      expect(word.word, 'resilient');
      expect(word.phonetic, '/rɪˈzɪl.jənt/');
      expect(word.partOfSpeech, 'adjective');
      expect(word.definition, 'Able to quickly recover from difficulties.');
      expect(word.example, 'She is remarkably resilient in difficult situations.');
      expect(word.difficulty, 3);
      expect(word.frequencyRank, 1420);
    });

    test('supports value equality via Equatable', () {
      final word1 = DailyWord(
        id: 'dw_0002',
        word: 'serene',
        phonetic: '/səˈriːn/',
        partOfSpeech: 'adjective',
        definition: 'Calm and peaceful.',
        example: 'The lake was serene at sunrise.',
        difficulty: 2,
        frequencyRank: 2100,
      );

      final word2 = DailyWord(
        id: 'dw_0002',
        word: 'serene',
        phonetic: '/səˈriːn/',
        partOfSpeech: 'adjective',
        definition: 'Calm and peaceful.',
        example: 'The lake was serene at sunrise.',
        difficulty: 2,
        frequencyRank: 2100,
      );

      expect(word1, equals(word2));
      expect(word1.hashCode, equals(word2.hashCode));
    });

    test('WordSet parses correctly from curriculum JSON format', () {
      final json = {
        'day': 42,
        'theme': 'Emotions & Feelings',
        'words': [
          {
            'word': 'ecstatic',
            'phonetic': '/ekˈstæt.ɪk/',
            'partOfSpeech': 'adjective',
            'definition': 'Feeling great enthusiasm or happiness.',
            'example': 'They were ecstatic about the new opportunity.',
            'difficulty': 3,
            'frequencyRank': 3500,
          }
        ],
      };

      final wordSet = DailyWordSet.fromJson(json);
      expect(wordSet.day, 42);
      expect(wordSet.theme, 'Emotions & Feelings');
      expect(wordSet.words.length, 1);
      expect(wordSet.words.first.word, 'ecstatic');
    });
  });

  group('WordProgress Entity & Serialization', () {
    test('initializes and serializes to/from JSON round-trip correctly', () {
      const original = WordProgress(
        wordId: 'dw_0001',
        word: 'meticulous',
        box: 4,
        nextReviewDate: '2026-10-25',
        learnedDate: '2026-10-01',
        reviewCount: 3,
        lastScore: 5,
      );

      final json = original.toJson();
      final reconstructed = WordProgress.fromJson(json);

      expect(reconstructed, equals(original));
      expect(reconstructed.wordId, 'dw_0001');
      expect(reconstructed.word, 'meticulous');
      expect(reconstructed.box, 4);
      expect(reconstructed.lastScore, 5);
    });

    test('copyWith updates properties immutably', () {
      const original = WordProgress(
        wordId: 'dw_0002',
        word: 'tenacious',
        learnedDate: '2026-10-01',
        box: 1,
      );

      final updated = original.copyWith(box: 2, reviewCount: 1);
      expect(updated.box, 2);
      expect(updated.reviewCount, 1);
      expect(updated.wordId, 'dw_0002');
      expect(original.box, 1); // original unchanged
    });
  });

  group('DailyWordsService Logic & Streak Math', () {
    late DailyWordsService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      service = DailyWordsService();
      await service.init();
    });

    test('calculates safe effectiveDay wrapping at 750 days', () {
      // Within range 1-750
      expect(DailyWordsService.calculateEffectiveDay(1), 1);
      expect(DailyWordsService.calculateEffectiveDay(42), 42);
      expect(DailyWordsService.calculateEffectiveDay(750), 750);

      // Day 751 wraps to Day 1
      expect(DailyWordsService.calculateEffectiveDay(751), 1);
      // Day 752 wraps to Day 2
      expect(DailyWordsService.calculateEffectiveDay(752), 2);
      // Day 1500 wraps to Day 750
      expect(DailyWordsService.calculateEffectiveDay(1500), 750);
      // Day 1501 wraps to Day 1
      expect(DailyWordsService.calculateEffectiveDay(1501), 1);
    });

    test('completeDailySession advances past day 750 into cycle 2 without artificial cap', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_words_current_day', 750);

      final cycleService = DailyWordsService();
      await cycleService.init();
      expect(cycleService.currentDay, 750);
      expect(cycleService.effectiveDay, 750);

      await cycleService.completeDailySession();
      expect(cycleService.currentDay, 751);
      expect(cycleService.effectiveDay, 1); // Wraps to lesson 1 of cycle 2
    });

    test('resolves calendar streak across consecutive calendar days', () async {
      final prefs = await SharedPreferences.getInstance();

      // Case 1: Yesterday learned at 23:30, today at 07:30 (only 8 hours difference)
      // DateTime.difference().inDays is 0, but calendar difference is exactly 1!
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayDateStr =
          "${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}";

      await prefs.setString('daily_words_last_open_date', yesterdayDateStr);
      await prefs.setInt('daily_words_streak', 5);

      // Re-init service with stored values
      final testService = DailyWordsService();
      await testService.init();

      // On consecutive calendar day, init() detects diff == 1 and increments streak to 6
      expect(testService.streak, 6);

      // Marking a word learned today maintains the streak at 6 without double-incrementing
      await testService.markWordLearned(sampleWord1);
      expect(testService.streak, 6);
    });

    test('streak resets after missing more than 1 calendar day', () async {
      final prefs = await SharedPreferences.getInstance();

      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final threeDaysAgoStr =
          "${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}";

      await prefs.setString('daily_words_last_open_date', threeDaysAgoStr);
      await prefs.setInt('daily_words_streak', 10);

      final testService = DailyWordsService();
      await testService.init();

      // Service reloads and handles rollover; streak resets to 1 (starting fresh today)
      expect(testService.streak, 1);
    });

    test('differentiates markWordLearned (Box 1) vs markWordNeedsReview (Box 0)', () async {
      await service.markWordLearned(sampleWord1);
      expect(service.isWordLearned(sampleWord1.id), isTrue);
      expect(service.totalWordsLearned, 1);

      await service.markWordNeedsReview(sampleWord2);
      // Sample 2 is in word bank for review, but not yet learned/mastered
      expect(service.hasWordEntry(sampleWord2.id), isTrue);
      expect(service.isWordLearned(sampleWord2.id), isFalse);
      expect(service.totalWordsLearned, 1); // Not incremented

      final wordBank = service.wordBankEntries;
      final sample2Entry = wordBank.firstWhere((w) => w.word == sampleWord2.word);
      expect(sample2Entry.box, 0);

      final sample1Entry = wordBank.firstWhere((w) => w.word == sampleWord1.word);
      expect(sample1Entry.box, 1);
    });

    test('mastery stats accurately counts learning, reviewing, mastered', () async {
      await service.markWordLearned(sampleWord1); // Box 1 -> Learning
      await service.markWordNeedsReview(sampleWord2); // Box 0 -> New/Review

      // Promote sampleWord1 to Box 2
      await service.recordReview(sampleWord1.id, correct: true);
      // Promote sampleWord1 to Box 3 (reviewing)
      await service.recordReview(sampleWord1.id, correct: true);

      final stats = service.masteryStats;
      expect(stats['new'], 1); // sampleWord2 (Box 0)
      expect(stats['reviewing'], 1); // sampleWord1 (Box 3)
      expect(stats['total'], 2);
    });
  });

  group('DailyWordsBloc State Transitions', () {
    late DailyWordsService mockService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      mockService = DailyWordsService();
      await mockService.init();
    });

    test('navigates next and previous words correctly in state', () async {
      final bloc = DailyWordsBloc(service: mockService);

      // Simulate a loaded word set state directly
      final testWordSet = DailyWordSet(
        day: 1,
        theme: 'Essential Foundations',
        words: [sampleWord1, sampleWord2],
      );

      bloc.emit(DailyWordsState(
        status: DailyWordsStatus.loaded,
        wordSet: testWordSet,
        currentIndex: 0,
        totalWordsLearned: 0,
        currentDay: 1,
      ));

      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.canGoPrevious, isFalse);
      expect(bloc.state.currentWord?.word, 'resilient');

      // Advance to next word
      bloc.add(const DailyWordNextRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.currentIndex, 1);
      expect(bloc.state.canGoPrevious, isTrue);
      expect(bloc.state.currentWord?.word, 'serene');

      // Go back to previous word
      bloc.add(const DailyWordPreviousRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.canGoPrevious, isFalse);
      expect(bloc.state.currentWord?.word, 'resilient');

      await bloc.close();
    });

    test('restarting session resets currentIndex to 0', () async {
      final bloc = DailyWordsBloc(service: mockService);

      final testWordSet = DailyWordSet(
        day: 1,
        theme: 'Essential Foundations',
        words: [sampleWord1, sampleWord2],
      );

      bloc.emit(DailyWordsState(
        status: DailyWordsStatus.sessionComplete,
        wordSet: testWordSet,
        currentIndex: 1,
        totalWordsLearned: 2,
        currentDay: 1,
      ));

      bloc.add(const DailySessionRestartRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.currentIndex, 0);
      expect(bloc.state.status, DailyWordsStatus.loaded);

      await bloc.close();
    });
  });

  group('DailyWords Widget Rendering', () {
    testWidgets('renders WordCardFront with frequency rank badge and difficulty badge', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: WordCardFront(
                word: sampleWord1,
                isDark: false,
                onSpeak: () {},
                onTranslate: () {},
                isTranslating: false,
                difficulty: sampleWord1.difficulty,
                theme: 'Emotions',
                showFlipHint: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('/rɪˈzɪl.jənt/'), findsOneWidget);
      expect(find.text('Top 2,000'), findsOneWidget);
      expect(find.text('Intermediate (B1)'), findsOneWidget);
    });

    testWidgets('renders WordCardBack with definition, example and safe scroll handling', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(393, 852),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: WordCardBack(
                word: sampleWord1,
                isDark: false,
                onSpeak: () {},
                onTranslate: () {},
                isTranslating: false,
              ),
            ),
          ),
        ),
      );

      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('Able to quickly recover from difficulties.'), findsOneWidget);
      expect(find.text('"She is remarkably resilient in difficult situations."'), findsOneWidget);
    });
  });
}
