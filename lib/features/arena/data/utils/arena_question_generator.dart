import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

class ArenaQuestionGenerator {
  ArenaQuestionGenerator._();

  /// Primary curriculum games containing rich multiple-choice questions
  /// spanning 200 levels each (~1,000 authentic questions per discipline).
  static const List<String> kSupportedGameTypes = [
    'synonymSearch', // Word Clash: Synonyms
    'antonymSearch', // Word Clash: Antonyms
    'collocations',  // Phrase Duel: Natural word pairs
    'idioms',        // Phrase Duel: Idioms & expressions
    'academicWord',  // Sentence Strike: Academic vocabulary
    'contextClues',  // Context Clues: Deductive sentence reasoning
    'phrasalVerbs',  // Phrase Duel: Particles & phrasal verbs
  ];

  static const List<Map<String, dynamic>> _kQuestionBank = [
    {
      'question': 'What is the closest synonym for "Resilient"?',
      'options': ['Fragile', 'Enduring', 'Hesitant', 'Trivial'],
      'correctIndex': 1,
      'explanation': 'Resilient means able to withstand or recover quickly from difficult conditions.',
    },
    {
      'question': 'Choose the word that means "Brief and clearly expressed":',
      'options': ['Verbose', 'Ambiguous', 'Concise', 'Prolix'],
      'correctIndex': 2,
      'explanation': 'Concise means expressing much in few words; succinct and clear.',
    },
    {
      'question': 'What is the opposite of "Authentic"?',
      'options': ['Genuine', 'Spurious', 'Credible', 'Legitimate'],
      'correctIndex': 1,
      'explanation': 'Spurious means not being what it purports to be; fake or counterfeit.',
    },
    {
      'question': 'Complete the idiom: "Bite the ______"',
      'options': ['Apple', 'Bullet', 'Tongue', 'Dust'],
      'correctIndex': 1,
      'explanation': '"Bite the bullet" means to face a difficult situation with courage.',
    },
    {
      'question': 'Select the word that means "Excessively talkative":',
      'options': ['Taciturn', 'Garrulous', 'Reticent', 'Laconic'],
      'correctIndex': 1,
      'explanation': 'Garrulous means excessively talkative, especially on trivial matters.',
    },
    {
      'question': 'What does the idiom "Spill the beans" mean?',
      'options': ['Make a mess', 'Reveal a secret', 'Cook dinner', 'Lose patience'],
      'correctIndex': 1,
      'explanation': '"Spill the beans" is an informal idiom meaning to disclose secret information.',
    },
    {
      'question': 'Choose the closest synonym for "Meticulous":',
      'options': ['Careless', 'Thorough', 'Impatient', 'Slapdash'],
      'correctIndex': 1,
      'explanation': 'Meticulous means showing great attention to detail; very careful and precise.',
    },
    {
      'question': 'What is the opposite of "Obscure"?',
      'options': ['Enigmatic', 'Prominent', 'Cryptic', 'Vague'],
      'correctIndex': 1,
      'explanation': 'Obscure means not discovered or known about; its opposite is prominent or famous.',
    },
    {
      'question': 'Select the word that means "A sudden, powerful forward movement":',
      'options': ['Ebb', 'Surge', 'Halt', 'Retreat'],
      'correctIndex': 1,
      'explanation': 'Surge means a sudden powerful forward or upward movement.',
    },
    {
      'question': 'Complete the phrase: "Burn the midnight ______"',
      'options': ['Candle', 'Oil', 'Wood', 'Paper'],
      'correctIndex': 1,
      'explanation': '"Burn the midnight oil" means to work or study late into the night.',
    },
    {
      'question': 'Which word describes someone who is "Fluent and persuasive in speech"?',
      'options': ['Incoherent', 'Eloquent', 'Hesitant', 'Muddled'],
      'correctIndex': 1,
      'explanation': 'Eloquent means fluent or persuasive in speaking or writing.',
    },
    {
      'question': 'What is the closest antonym for "Arrogant"?',
      'options': ['Proud', 'Humble', 'Haughty', 'Boastful'],
      'correctIndex': 1,
      'explanation': 'Arrogant means having an exaggerated sense of one\'s own importance; opposite is humble.',
    },
    {
      'question': 'Select the correct meaning of "Pragmatic":',
      'options': ['Impractical', 'Dealing with things sensibly and realistically', 'Overly idealistic', 'Careless'],
      'correctIndex': 1,
      'explanation': 'Pragmatic means dealing with things sensibly and realistically based on practical considerations.',
    },
    {
      'question': 'Complete the idiom: "Actions speak louder than ______"',
      'options': ['Echoes', 'Words', 'Speeches', 'Promises'],
      'correctIndex': 1,
      'explanation': '"Actions speak louder than words" emphasizes that what someone does is more meaningful than what they say.',
    },
    {
      'question': 'What is the synonym for "Exemplary"?',
      'options': ['Commendable', 'Mediocre', 'Flawed', 'Questionable'],
      'correctIndex': 0,
      'explanation': 'Exemplary means representing the best of its kind; commendable or worthy of imitation.',
    },
  ];

  /// Generates a list of [count] questions (default 5) deterministically based on [seed].
  static List<ArenaQuestion> generateQuestions({int count = 5, int? seed}) {
    final rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final bank = List<Map<String, dynamic>>.from(_kQuestionBank);
    bank.shuffle(rand);

    final selected = bank.take(count).toList();
    return selected.map((q) => ArenaQuestion.fromMap(q)).toList();
  }

  /// Generates dynamic questions sampled truly randomly across Vowl's 200 curriculum levels
  /// and 7 distinct language disciplines (synonyms, antonyms, collocations, idioms,
  /// academic words, context clues, and phrasal verbs).
  ///
  /// Across 7 games * 200 levels * 4 quests/level = ~5,600 authentic questions!
  /// Falls back to the curated bank if offline or in headless test environments.
  static Future<List<ArenaQuestion>> generateQuestionsAsync({
    int count = 5,
    int? seed,
    QuestService? questService,
  }) async {
    final rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final service = questService ??
        (di.sl.isRegistered<AssetQuestService>()
            ? di.sl<AssetQuestService>()
            : null);

    if (service != null) {
      try {
        final questions = <ArenaQuestion>[];
        // Shuffle disciplines to ensure cross-discipline blitz
        final shuffledGameTypes = List<String>.from(kSupportedGameTypes)..shuffle(rand);

        for (final gameType in shuffledGameTypes) {
          if (questions.length >= count) break;
          // True random sampling across all 200 levels
          final level = rand.nextInt(200) + 1;
          try {
            final quests = await service.getQuests(gameType, level);
            if (quests.isEmpty) continue;
            final shuffledQuests = List<Map<String, dynamic>>.from(quests)..shuffle(rand);
            for (final q in shuffledQuests) {
              final converted = _tryConvertCurriculumQuest(q, gameType, rand);
              if (converted != null &&
                  !questions.any((existing) => existing.question == converted.question)) {
                questions.add(converted);
                if (questions.length >= count) break;
              }
            }
          } catch (_) {
            // Silently continue if level not yet accessible
          }
        }

        // If we still need more questions, sample additional random levels
        if (questions.length < count) {
          for (int attempt = 0; attempt < 15 && questions.length < count; attempt++) {
            final randomType = kSupportedGameTypes[rand.nextInt(kSupportedGameTypes.length)];
            final randomLevel = rand.nextInt(200) + 1;
            try {
              final quests = await service.getQuests(randomType, randomLevel);
              final shuffledQuests = List<Map<String, dynamic>>.from(quests)..shuffle(rand);
              for (final q in shuffledQuests) {
                final converted = _tryConvertCurriculumQuest(q, randomType, rand);
                if (converted != null &&
                    !questions.any((existing) => existing.question == converted.question)) {
                  questions.add(converted);
                  if (questions.length >= count) break;
                }
              }
            } catch (_) {}
          }
        }

        // Fill any remaining shortfall with deterministic curated bank
        if (questions.length < count) {
          final fallback = generateQuestions(count: count, seed: seed);
          for (final q in fallback) {
            if (!questions.any((existing) => existing.question == q.question)) {
              questions.add(q);
              if (questions.length >= count) break;
            }
          }
        }

        if (questions.isNotEmpty) {
          return questions.take(count).toList();
        }
      } catch (e) {
        debugPrint('[ArenaQuestionGenerator] Curriculum quest load fallback: $e');
      }
    }

    // Deterministic fallback to verified question bank if offline or testing
    return generateQuestions(count: count, seed: seed);
  }

  static ArenaQuestion? _tryConvertCurriculumQuest(
    Map<String, dynamic> quest,
    String gameType,
    Random rand,
  ) {
    try {
      final optionsRaw = quest['options'];
      if (optionsRaw is! List || optionsRaw.length < 2) return null;
      final options = optionsRaw.map((e) => e.toString().trim()).toList();

      final correctAnswer =
          (quest['correctAnswer'] ?? quest['answer'] ?? '').toString().trim();
      if (correctAnswer.isEmpty) return null;

      final originalCorrectIndex = options.indexWhere(
        (opt) => opt.toLowerCase() == correctAnswer.toLowerCase(),
      );
      if (originalCorrectIndex == -1) return null;

      String questionText;
      final word = quest['word']?.toString().trim();
      final instruction = quest['instruction']?.toString().trim();
      final contextSentence = quest['contextSentence']?.toString().trim();
      final passage = quest['passage']?.toString().trim();
      final sentence = quest['sentence']?.toString().trim();
      final hint = quest['hint']?.toString().trim();

      if (gameType == 'synonymSearch' && word != null && word.isNotEmpty) {
        questionText = 'What is the closest synonym for "$word"?';
      } else if (gameType == 'antonymSearch' && word != null && word.isNotEmpty) {
        questionText = 'What is the opposite of "$word"?';
      } else if (gameType == 'idioms') {
        if (instruction != null && instruction.contains('___')) {
          questionText = instruction;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'What does the idiom "$word" mean?';
        } else if (hint != null && hint.toUpperCase().startsWith('DEFINITION:')) {
          questionText = hint.replaceFirst(RegExp(r'DEFINITION:\s*', caseSensitive: false), '').trim();
        } else {
          questionText = instruction ?? 'Select the correct idiom:';
        }
      } else if (gameType == 'collocations') {
        if (contextSentence != null && contextSentence.contains('___')) {
          questionText = contextSentence;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'Complete the natural collocation with "$word":';
        } else {
          questionText = instruction ?? 'Choose the word that forms a natural pair:';
        }
      } else if (gameType == 'phrasalVerbs') {
        if (contextSentence != null && contextSentence.contains('___')) {
          questionText = contextSentence;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'Select the correct particle for "$word":';
        } else {
          questionText = instruction ?? 'Complete the phrasal verb:';
        }
      } else if (gameType == 'academicWord') {
        if (passage != null && passage.contains('[TARGET]')) {
          questionText = passage.replaceAll('[TARGET]', '_____');
        } else if (contextSentence != null && contextSentence.contains('___')) {
          questionText = contextSentence;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'Choose the academic definition for "$word":';
        } else {
          questionText = instruction ?? 'Select the best word to complete the sentence:';
        }
      } else if (gameType == 'contextClues') {
        if (sentence != null && sentence.contains('[TARGET]')) {
          questionText = sentence.replaceAll('[TARGET]', '_____');
        } else if (contextSentence != null && contextSentence.contains('___')) {
          questionText = contextSentence;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'Infer the contextual meaning of "$word":';
        } else {
          questionText = instruction ?? 'Analyze the sentence to deduce the meaning:';
        }
      } else {
        questionText = (instruction != null && instruction.isNotEmpty)
            ? (word != null ? '$instruction ("$word")' : instruction)
            : 'Choose the correct answer:';
      }

      final explanation = (quest['explanation'] ??
              quest['hint'] ??
              'Vowl authentic curriculum challenge.')
          .toString();

      // Deterministically shuffle options using rand to eliminate positional bias
      final shuffledOptions = List<String>.from(options)..shuffle(rand);
      final newCorrectIndex = shuffledOptions.indexWhere(
        (opt) => opt.toLowerCase() == correctAnswer.toLowerCase(),
      );

      return ArenaQuestion(
        question: questionText,
        options: shuffledOptions,
        correctIndex: newCorrectIndex != -1 ? newCorrectIndex : originalCorrectIndex,
        explanation: explanation,
      );
    } catch (_) {
      return null;
    }
  }
}
