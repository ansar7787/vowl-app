import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/services/error_journal_collector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ErrorJournalCollector.updateNotifier.value = 0;
  });

  tearDown(() {
    ErrorJournalCollector.updateNotifier.value = 0;
  });

  // =========================================================================
  // GROUP 1: ErrorJournalEntry Entity & JSON Serialization
  // =========================================================================
  group('Group 1: ErrorJournalEntry Entity & JSON Serialization', () {
    test('serializes to JSON map and deserializes back faithfully', () {
      final now = DateTime.now();
      final entry = ErrorJournalEntry(
        id: 'entry_123',
        gameType: 'repeatSentence',
        question: 'The quick brown fox jumps over the lazy dog.',
        userAnswer: 'The quick brown fox jumped over the dog.',
        correctAnswer: 'The quick brown fox jumps over the lazy dog.',
        level: 3,
        timestamp: now,
        options: const ['jumps', 'jumped', 'jumping'],
      );

      final jsonMap = entry.toJson();
      expect(jsonMap['id'], 'entry_123');
      expect(jsonMap['gameType'], 'repeatSentence');
      expect(jsonMap['question'], 'The quick brown fox jumps over the lazy dog.');
      expect(jsonMap['userAnswer'], 'The quick brown fox jumped over the dog.');
      expect(jsonMap['correctAnswer'], 'The quick brown fox jumps over the lazy dog.');
      expect(jsonMap['level'], 3);
      expect(jsonMap['timestamp'], now.toIso8601String());
      expect(jsonMap['options'], ['jumps', 'jumped', 'jumping']);

      final reconstituted = ErrorJournalEntry.fromJson(jsonMap);
      expect(reconstituted.id, entry.id);
      expect(reconstituted.gameType, entry.gameType);
      expect(reconstituted.question, entry.question);
      expect(reconstituted.userAnswer, entry.userAnswer);
      expect(reconstituted.correctAnswer, entry.correctAnswer);
      expect(reconstituted.level, entry.level);
      expect(reconstituted.timestamp?.millisecondsSinceEpoch, now.millisecondsSinceEpoch);
      expect(reconstituted.options, entry.options);
    });

    test('handles null optional fields in JSON map with safe defaults', () {
      final jsonMap = <String, dynamic>{
        'id': 'entry_minimal',
        'gameType': 'tenses',
        'question': 'She ___ to the market.',
        'userAnswer': 'go',
        'correctAnswer': 'went',
        'level': 2,
      };

      final entry = ErrorJournalEntry.fromJson(jsonMap);
      expect(entry.id, 'entry_minimal');
      expect(entry.gameType, 'tenses');
      expect(entry.question, 'She ___ to the market.');
      expect(entry.userAnswer, 'go');
      expect(entry.correctAnswer, 'went');
      expect(entry.level, 2);
      expect(entry.timestamp, isNull);
      expect(entry.options, isNull);
    });

    test('toJson excludes options key when options is null', () {
      const entry = ErrorJournalEntry(
        id: 'entry_no_opt',
        gameType: 'accent',
        question: 'accent test',
        userAnswer: 'ans',
        correctAnswer: 'cor',
        level: 1,
      );

      final jsonMap = entry.toJson();
      expect(jsonMap.containsKey('options'), isFalse);
    });
  });

  // =========================================================================
  // GROUP 2: Human-Readable Game Names Converter
  // =========================================================================
  group('Group 2: Human-Readable Game Names Converter', () {
    test('converts camelCase game types into titled space-separated names', () {
      expect(ErrorJournalCollector.humanReadableName('syllableStress'), 'Syllable Stress');
      expect(ErrorJournalCollector.humanReadableName('readAndAnswer'), 'Read And Answer');
      expect(ErrorJournalCollector.humanReadableName('fastSpeechDecoder'), 'Fast Speech Decoder');
      expect(ErrorJournalCollector.humanReadableName('minimalPairs'), 'Minimal Pairs');
      expect(ErrorJournalCollector.humanReadableName('sentenceBuilder'), 'Sentence Builder');
    });

    test('handles single-word, lowercase, and empty strings gracefully', () {
      expect(ErrorJournalCollector.humanReadableName('speaking'), 'Speaking');
      expect(ErrorJournalCollector.humanReadableName('grammar'), 'Grammar');
      expect(ErrorJournalCollector.humanReadableName(''), '');
    });
  });

  // =========================================================================
  // GROUP 3: Local / Guest Recording & Deduplication
  // =========================================================================
  group('Group 3: Local / Guest Recording & Deduplication', () {
    test('ignores records with empty userId or question', () async {
      await ErrorJournalCollector.record(
        userId: '',
        gameType: 'grammar',
        question: 'Valid question',
        userAnswer: 'a',
        correctAnswer: 'b',
        level: 1,
      );

      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'grammar',
        question: '',
        userAnswer: 'a',
        correctAnswer: 'b',
        level: 1,
      );

      expect(ErrorJournalCollector.updateNotifier.value, 0);
      final count = await ErrorJournalCollector.count(userId: 'local');
      expect(count, 0);
    });

    test('records a new mistake to SharedPreferences and increments notifier', () async {
      var notifiedCount = 0;
      ErrorJournalCollector.updateNotifier.addListener(() => notifiedCount++);

      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'repeatSentence',
        question: 'Repeat this sentence',
        userAnswer: 'Wrong answer',
        correctAnswer: 'Right answer',
        level: 1,
        options: const ['A', 'B'],
      );

      expect(notifiedCount, 1);
      final entries = await ErrorJournalCollector.fetch(userId: 'local');
      expect(entries.length, 1);
      expect(entries.first.question, 'Repeat this sentence');
      expect(entries.first.userAnswer, 'Wrong answer');
      expect(entries.first.correctAnswer, 'Right answer');
      expect(entries.first.options, ['A', 'B']);
    });

    test('deduplicates identical question and replaces with latest timestamp', () async {
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'repeatSentence',
        question: 'Deduplicate question',
        userAnswer: 'First wrong attempt',
        correctAnswer: 'Correct answer',
        level: 1,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'repeatSentence',
        question: 'Deduplicate question',
        userAnswer: 'Second wrong attempt',
        correctAnswer: 'Correct answer',
        level: 1,
      );

      final entries = await ErrorJournalCollector.fetch(userId: 'local');
      expect(entries.length, 1);
      expect(entries.first.userAnswer, 'Second wrong attempt');
    });

    test('enforces maxEntries limit (200) by pruning oldest entries', () async {
      final initialLogs = <String>[];
      for (var i = 0; i < ErrorJournalCollector.maxEntries; i++) {
        final entry = ErrorJournalEntry(
          id: 'old_$i',
          gameType: 'grammar',
          question: 'Question $i',
          userAnswer: 'Wrong',
          correctAnswer: 'Right',
          level: 1,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000 + i),
        );
        initialLogs.add(jsonEncode(entry.toJson()));
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('vowl_local_error_journal', initialLogs);

      expect(await ErrorJournalCollector.count(userId: 'local'), 200);

      // Record 201st entry
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'grammar',
        question: 'Question 201',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 1,
      );

      final entries = await ErrorJournalCollector.fetch(userId: 'local', limit: 250);
      expect(entries.length, 200);
      // The oldest question 'Question 0' was pruned
      expect(entries.any((e) => e.question == 'Question 0'), isFalse);
      expect(entries.any((e) => e.question == 'Question 201'), isTrue);
    });
  });

  // =========================================================================
  // GROUP 4: Local / Guest Fetching & Filtering
  // =========================================================================
  group('Group 4: Local / Guest Fetching & Filtering', () {
    setUp(() async {
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'grammar',
        question: 'Grammar Q1',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 1,
      );
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'vocabulary',
        question: 'Vocab Q1',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 2,
      );
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'grammar',
        question: 'Grammar Q2',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 3,
      );
    });

    test('fetches all entries sorted descending by timestamp', () async {
      final entries = await ErrorJournalCollector.fetch(userId: 'local');
      expect(entries.length, 3);
    });

    test('respects limit parameter', () async {
      final entries = await ErrorJournalCollector.fetch(userId: 'local', limit: 2);
      expect(entries.length, 2);
    });

    test('filters by filterGameType correctly', () async {
      final grammarEntries = await ErrorJournalCollector.fetch(
        userId: 'local',
        filterGameType: 'grammar',
      );
      expect(grammarEntries.length, 2);
      expect(grammarEntries.every((e) => e.gameType == 'grammar'), isTrue);

      final vocabEntries = await ErrorJournalCollector.fetch(
        userId: 'local',
        filterGameType: 'vocabulary',
      );
      expect(vocabEntries.length, 1);
      expect(vocabEntries.first.gameType, 'vocabulary');
    });

    test('returns empty list for non-matching filterGameType', () async {
      final emptyEntries = await ErrorJournalCollector.fetch(
        userId: 'local',
        filterGameType: 'speaking',
      );
      expect(emptyEntries, isEmpty);
    });
  });

  // =========================================================================
  // GROUP 5: Dismiss, Clear Level Mistakes & Clear All
  // =========================================================================
  group('Group 5: Dismiss, Clear Level Mistakes & Clear All', () {
    setUp(() async {
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'reading',
        question: 'Reading Q1',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 1,
      );
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'reading',
        question: 'Reading Q2',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 1,
      );
      await ErrorJournalCollector.record(
        userId: 'local',
        gameType: 'reading',
        question: 'Reading L2',
        userAnswer: 'Wrong',
        correctAnswer: 'Right',
        level: 2,
      );
    });

    test('dismiss removes a single entry by entryId', () async {
      final before = await ErrorJournalCollector.fetch(userId: 'local');
      expect(before.length, 3);
      final targetId = before.first.id;

      await ErrorJournalCollector.dismiss(userId: 'local', entryId: targetId);

      final after = await ErrorJournalCollector.fetch(userId: 'local');
      expect(after.length, 2);
      expect(after.any((e) => e.id == targetId), isFalse);
    });

    test('clearLevelMistakes clears entries for specific gameType and level', () async {
      await ErrorJournalCollector.clearLevelMistakes(
        userId: 'local',
        gameType: 'reading',
        level: 1,
      );

      final remaining = await ErrorJournalCollector.fetch(userId: 'local');
      expect(remaining.length, 1);
      expect(remaining.first.level, 2);
    });

    test('clearAll removes all error journal entries completely', () async {
      expect(await ErrorJournalCollector.count(userId: 'local'), 3);

      await ErrorJournalCollector.clearAll(userId: 'local');

      expect(await ErrorJournalCollector.count(userId: 'local'), 0);
      expect(await ErrorJournalCollector.fetch(userId: 'local'), isEmpty);
    });
  });

  // =========================================================================
  // GROUP 6: Error Resilience & Graceful Fallbacks
  // =========================================================================
  group('Group 6: Error Resilience & Graceful Fallbacks', () {
    test('unauthenticated or uninitialized cloud calls return safe fallbacks without throwing', () async {
      // Calling cloud methods without Firebase initialized must catch and return safe defaults
      final entries = await ErrorJournalCollector.fetch(userId: 'cloud_user_123');
      expect(entries, isEmpty);

      final count = await ErrorJournalCollector.count(userId: 'cloud_user_123');
      expect(count, 0);

      // Mutative calls must not throw uncaught exceptions
      expect(
        ErrorJournalCollector.record(
          userId: 'cloud_user_123',
          gameType: 'grammar',
          question: 'Cloud Q',
          userAnswer: 'Wrong',
          correctAnswer: 'Right',
          level: 1,
        ),
        completes,
      );

      expect(
        ErrorJournalCollector.dismiss(
          userId: 'cloud_user_123',
          entryId: 'entry_1',
        ),
        completes,
      );

      expect(
        ErrorJournalCollector.clearLevelMistakes(
          userId: 'cloud_user_123',
          gameType: 'grammar',
          level: 1,
        ),
        completes,
      );

      expect(
        ErrorJournalCollector.clearAll(userId: 'cloud_user_123'),
        completes,
      );
    });
  });
}
