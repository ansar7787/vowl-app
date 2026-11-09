import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/daily_words/data/services/daily_words_service.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';

/// Bridge service providing one-tap saving of real-world scanned words and
/// visual objects into Vowl's persistent [DailyWordsService] Word Bank.
class WordBankBridge {
  const WordBankBridge();

  /// Saves an individual vocabulary word into the user's permanent Word Bank.
  Future<bool> saveWord({
    required String word,
    String? phonetic,
    String? partOfSpeech,
    String? definition,
    String? example,
    int difficulty = 1,
  }) async {
    final clean = word.trim();
    if (clean.isEmpty) return false;

    try {
      if (!di.sl.isRegistered<DailyWordsService>()) {
        return false;
      }

      final service = di.sl<DailyWordsService>();
      final wordId =
          'lens_${clean.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';

      final dailyWord = DailyWord(
        id: wordId,
        word: clean,
        phonetic: phonetic ?? '',
        partOfSpeech: partOfSpeech ?? 'noun',
        definition:
            definition ?? 'Real-world vocabulary captured with Smart Lens.',
        example: example ?? 'I encountered "$clean" in real-world context.',
        difficulty: difficulty,
        frequencyRank: 100,
      );

      await service.markWordLearned(dailyWord);
      return true;
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().error(
          'WordBankBridge: Failed to save word "$word"',
          error: e,
        );
      }
      return false;
    }
  }

  /// Checks whether a given word is already saved in the active Word Bank.
  bool isWordSaved(String word) {
    if (!di.sl.isRegistered<DailyWordsService>()) return false;
    final clean = word.trim().toLowerCase();
    final wordId = 'lens_${clean.replaceAll(RegExp(r'\s+'), '_')}';
    final service = di.sl<DailyWordsService>();
    return service.hasWordEntry(wordId) ||
        service.wordBankEntries.any((p) => p.word.toLowerCase() == clean);
  }
}
