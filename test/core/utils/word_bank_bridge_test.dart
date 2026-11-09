import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/word_bank_bridge.dart';
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/domain/entities/word_progress.dart';

class MockDailyWordsService extends Mock implements DailyWordsService {
  final List<DailyWord> savedWords = [];

  @override
  Future<void> markWordLearned(DailyWord word, {bool mastered = false}) async {
    savedWords.add(word);
  }

  @override
  bool hasWordEntry(String wordId) {
    return savedWords.any((w) => w.id == wordId);
  }

  @override
  List<WordProgress> get wordBankEntries => [];
}

void main() {
  late WordBankBridge bridge;
  late MockDailyWordsService mockService;
  final sl = GetIt.instance;

  setUp(() {
    sl.reset();
    mockService = MockDailyWordsService();
    bridge = const WordBankBridge();
  });

  tearDown(() {
    sl.reset();
  });

  group('WordBankBridge Tests', () {
    test('returns false when DailyWordsService is not registered', () async {
      final result = await bridge.saveWord(word: 'bicycle');
      expect(result, isFalse);
      expect(bridge.isWordSaved('bicycle'), isFalse);
    });

    test('returns false for empty or whitespace-only words', () async {
      sl.registerSingleton<DailyWordsService>(mockService);
      final result = await bridge.saveWord(word: '   ');
      expect(result, isFalse);
    });

    test('successfully saves word and checks persistence status', () async {
      sl.registerSingleton<DailyWordsService>(mockService);

      expect(bridge.isWordSaved('espresso'), isFalse);

      final result = await bridge.saveWord(
        word: 'espresso',
        phonetic: '/eˈspres.əʊ/',
        partOfSpeech: 'noun',
        definition:
            'Strong black coffee made by forcing steam through ground beans.',
        example: 'He ordered a double espresso.',
      );

      expect(result, isTrue);
      expect(mockService.savedWords.length, equals(1));
      expect(mockService.savedWords.first.word, equals('espresso'));
      expect(mockService.savedWords.first.id, equals('lens_espresso'));
      expect(bridge.isWordSaved('espresso'), isTrue);
    });

    test('handles compound words in ID generation', () async {
      sl.registerSingleton<DailyWordsService>(mockService);

      await bridge.saveWord(word: 'coffee shop');
      expect(mockService.savedWords.first.id, equals('lens_coffee_shop'));
      expect(bridge.isWordSaved('coffee shop'), isTrue);
    });
  });
}
