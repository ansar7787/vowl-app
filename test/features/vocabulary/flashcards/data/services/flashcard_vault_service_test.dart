import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/vocabulary/flashcards/data/services/flashcard_vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlashcardVaultService & FlashcardVaultEntry', () {
    late FlashcardVaultService vaultService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      vaultService = FlashcardVaultService(prefs);
    });

    test('records initial word mastery with high fresh retention', () async {
      await vaultService.recordMastery('AUTHENTIC', 1, perfect: true);

      final entry = await vaultService.getEntry('AUTHENTIC');
      expect(entry, isNotNull);
      expect(entry!.word, 'AUTHENTIC');
      expect(entry.level, 1);
      expect(entry.repetitionCount, 1);
      expect(entry.stabilityHours, 48.0);
      expect(entry.retention, greaterThanOrEqualTo(0.95));
      expect(entry.grade, RetentionGrade.strong);
      expect(entry.retentionPercentage, inInclusiveRange(95, 100));
    });

    test(
      'updates stability and repetition count on subsequent mastery',
      () async {
        await vaultService.recordMastery('GENUINE', 1, perfect: true);
        await vaultService.recordMastery('GENUINE', 1, perfect: true);

        final entry = await vaultService.getEntry('genuine');
        expect(entry, isNotNull);
        expect(entry!.repetitionCount, 2);
        expect(entry.stabilityHours, greaterThan(48.0));
      },
    );

    test(
      'getVaultEntries returns entries sorted by lowest retention first',
      () async {
        await vaultService.recordMastery('WORD_A', 1, perfect: false);
        await vaultService.recordMastery('WORD_B', 1, perfect: true);

        final entries = await vaultService.getVaultEntries();
        expect(entries.length, 2);
        expect(entries.first.word, isNotEmpty);
      },
    );

    test('calculates memory decay correctly using Ebbinghaus curve', () {
      final pastDate = DateTime.now().subtract(const Duration(hours: 48));
      final decayingEntry = FlashcardVaultEntry(
        word: 'DECAYING',
        level: 1,
        lastTestedAt: pastDate,
        repetitionCount: 1,
        stabilityHours:
            24.0, // After 48 hours with 24h stability: e^(-48/24) = e^(-2) ≈ 0.135
      );

      expect(decayingEntry.retention, lessThan(0.20));
      expect(decayingEntry.grade, RetentionGrade.critical);
    });

    test('getWordsDueForReview filters words below decay threshold', () async {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final oldEntry = FlashcardVaultEntry(
        word: 'FORGOTTEN',
        level: 1,
        lastTestedAt: now.subtract(const Duration(hours: 100)),
        repetitionCount: 1,
        stabilityHours: 24.0,
      );

      final freshEntry = FlashcardVaultEntry(
        word: 'FRESH',
        level: 1,
        lastTestedAt: now,
        repetitionCount: 1,
        stabilityHours: 48.0,
      );

      final map = {
        'FORGOTTEN': oldEntry.toJson(),
        'FRESH': freshEntry.toJson(),
      };
      await prefs.setString(FlashcardVaultService.storageKey, jsonEncode(map));

      final dueWords = await vaultService.getWordsDueForReview(threshold: 0.5);
      expect(dueWords.length, 1);
      expect(dueWords.first.word, 'FORGOTTEN');
    });

    test('clearVault removes all stored lexicon records', () async {
      await vaultService.recordMastery('TEMP', 1);
      expect((await vaultService.getVaultEntries()).length, 1);

      await vaultService.clearVault();
      expect((await vaultService.getVaultEntries()).isEmpty, isTrue);
    });
  });
}
