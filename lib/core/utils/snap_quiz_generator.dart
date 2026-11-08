import 'dart:math';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/photo_vocabulary/utils/photo_vocabulary_dictionary.dart';

/// Algorithmic generator that builds an instant, high-retention 3-question
/// active recall [GameQuest] level based on recognized real-world camera inputs.
class SnapQuizGenerator {
  static final Random _random = Random();

  static const List<String> _distractorPool = [
    'Book',
    'Chair',
    'Door',
    'Window',
    'Phone',
    'Table',
    'Computer',
    'Bottle',
    'Paper',
    'Pen',
    'Bag',
    'Clock',
    'Key',
    'Light',
    'Card',
  ];

  /// Generates a complete 3-question level for the provided [targetWord].
  static List<GameQuest> generate3QuestionLevel({
    required String targetWord,
    String? definition,
    String? exampleSentence,
    String? nativeTranslation,
    String? ipa,
    List<String>? alternativeDetectedWords,
  }) {
    final entry = PhotoVocabularyDictionary.getEntry(targetWord);
    final String cleanWord = targetWord.trim();
    final String resolvedDef = definition ?? entry.definition;
    final String resolvedExample = exampleSentence ?? entry.example;
    final String resolvedIpa =
        ipa ?? (entry.ipa ?? '/${cleanWord.toLowerCase()}/');

    // Gather 3 unique distractors that do not match the target word
    final Set<String> distractors = {};
    if (alternativeDetectedWords != null) {
      for (final alt in alternativeDetectedWords) {
        if (alt.toLowerCase() != cleanWord.toLowerCase() &&
            distractors.length < 3) {
          distractors.add(alt);
        }
      }
    }
    final pool = List<String>.from(_distractorPool)..shuffle(_random);
    for (final word in pool) {
      if (distractors.length >= 3) break;
      if (word.toLowerCase() != cleanWord.toLowerCase()) {
        distractors.add(word);
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // Question 1: Word Recognition & Meaning (Multiple Choice)
    // ─────────────────────────────────────────────────────────────────────────
    final List<String> q1DistractorDefs = [];
    for (final d in distractors) {
      final dEntry = PhotoVocabularyDictionary.getEntry(d);
      if (dEntry.definition != resolvedDef &&
          !q1DistractorDefs.contains(dEntry.definition)) {
        q1DistractorDefs.add(dEntry.definition);
      }
    }
    final fallbackWords = ['Chair', 'Clock', 'Pen', 'Window', 'Book', 'Laptop'];
    for (final f in fallbackWords) {
      if (q1DistractorDefs.length >= 3) break;
      if (f.toLowerCase() != cleanWord.toLowerCase()) {
        final fDef = PhotoVocabularyDictionary.getEntry(f).definition;
        if (fDef != resolvedDef && !q1DistractorDefs.contains(fDef)) {
          q1DistractorDefs.add(fDef);
        }
      }
    }
    final q1Options = [resolvedDef, ...q1DistractorDefs.take(3)]
      ..shuffle(_random);
    final q1CorrectIndex = q1Options.indexOf(resolvedDef);

    final quest1 = GameQuest(
      id: 'snap_${cleanWord}_q1',
      instruction: 'Select the correct definition for "$cleanWord":',
      difficulty: 1,
      targetWord: cleanWord,
      question: 'What does "$cleanWord" mean?',
      options: q1Options,
      correctAnswerIndex: q1CorrectIndex,
      correctAnswer: resolvedDef,
      explanation: resolvedDef,
      xpReward: 10,
      coinReward: 10,
      livesAllowed: 3,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Question 2: Phonetics & Syllable Stress
    // ─────────────────────────────────────────────────────────────────────────
    final syllables = _splitSyllables(cleanWord);
    final String correctStressOption = syllables.length > 1
        ? 'Stressed on first syllable ("${syllables.first.toUpperCase()}-${syllables.sublist(1).join('-')}")'
        : 'Single syllable with pronunciation $resolvedIpa';

    final q2Options = [
      correctStressOption,
      'Silent initial consonant sound',
      'Flat monotone pitch with zero vowel elongation',
      'Unstressed schwa sound throughout the entire word',
    ]..shuffle(_random);
    final q2CorrectIndex = q2Options.indexOf(correctStressOption);

    final quest2 = GameQuest(
      id: 'snap_${cleanWord}_q2',
      instruction: 'Verify pronunciation & phonetics for "$cleanWord":',
      difficulty: 1,
      targetWord: cleanWord,
      question: 'Which phonetic trait applies to "$cleanWord"? ($resolvedIpa)',
      options: q2Options,
      correctAnswerIndex: q2CorrectIndex,
      correctAnswer: correctStressOption,
      explanation: 'Phonetic transcription: $resolvedIpa.',
      textToSpeak: cleanWord,
      xpReward: 10,
      coinReward: 10,
      livesAllowed: 3,
    );

    // ─────────────────────────────────────────────────────────────────────────
    // Question 3: Real-World Sentence Placement (Active Fill-in)
    // ─────────────────────────────────────────────────────────────────────────
    final clozeSentence = resolvedExample.replaceAll(
      RegExp(
        r'\b' + RegExp.escape(cleanWord) + r'(s|es|d|ed|ing)?\b',
        caseSensitive: false,
      ),
      '______',
    );
    final effectiveSentence = clozeSentence.contains('______')
        ? clozeSentence
        : 'I saw a ______ in the room.';

    final q3Options = [cleanWord, ...distractors.take(3)]..shuffle(_random);
    final q3CorrectIndex = q3Options.indexOf(cleanWord);

    final quest3 = GameQuest(
      id: 'snap_${cleanWord}_q3',
      instruction: 'Complete the sentence with the correct word:',
      difficulty: 1,
      targetWord: cleanWord,
      sentence: effectiveSentence,
      question: 'Fill in the blank:',
      options: q3Options,
      correctAnswerIndex: q3CorrectIndex,
      correctAnswer: cleanWord,
      explanation: 'Full sentence: "$resolvedExample".',
      xpReward: 10,
      coinReward: 10,
      livesAllowed: 3,
    );

    return [quest1, quest2, quest3];
  }

  static List<String> _splitSyllables(String word) {
    if (word.length <= 4) return [word];
    final mid = word.length ~/ 2;
    return [word.substring(0, mid), word.substring(mid)];
  }
}
