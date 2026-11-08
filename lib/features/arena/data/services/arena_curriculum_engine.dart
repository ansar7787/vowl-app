import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

/// Production curriculum engine orchestrating authentic 1v1 Arena questions.
///
/// Features:
/// 1. Primary dedicated 1v1 batch sampler (`assets/curriculum/arena/`).
/// 2. 5,600+ authentic multi-discipline vocabulary curriculum fallback.
/// 3. Deterministic room seeding ensuring both dueling players receive the identical challenge.
class ArenaCurriculumEngine {
  ArenaCurriculumEngine._();

  /// Primary curriculum games containing rich multiple-choice questions
  /// spanning 200 levels each (~1,000 authentic questions per discipline).
  static const List<String> kSupportedGameTypes = [
    'synonymSearch', // Word Clash: Synonyms
    'antonymSearch', // Word Clash: Antonyms
    'collocations', // Phrase Duel: Natural word pairs
    'idioms', // Phrase Duel: Idioms & expressions
    'academicWord', // Sentence Strike: Academic vocabulary
    'contextClues', // Context Blitz: Deductive sentence reasoning
    'phrasalVerbs', // Phrase Duel: Particles & phrasal verbs
  ];

  static const List<Map<String, dynamic>> _kQuestionBank = [
    // ⚡ WORD CLASH: Speed Synonyms & Antonyms
    {
      'question': 'Which word is closest in meaning to "enormous"?',
      'options': ['Tiny', 'Huge', 'Quiet', 'Narrow'],
      'correctIndex': 1,
      'explanation':
          'Enormous means extremely large in scale or size; "huge" is its closest direct synonym.',
      'discipline': 'word_clash',
      'difficulty': 'medium',
    },
    {
      'question': 'What is the exact opposite of "ancient"?',
      'options': ['Historic', 'Old-fashioned', 'Fragile', 'Modern'],
      'correctIndex': 3,
      'explanation':
          'Ancient refers to times long past; modern describes present or contemporary times.',
      'discipline': 'word_clash',
      'difficulty': 'medium',
    },
    {
      'question': 'Which word is closest in meaning to "resilient"?',
      'options': ['Fragile', 'Enduring', 'Hesitant', 'Trivial'],
      'correctIndex': 1,
      'explanation':
          'Resilient means able to withstand or recover quickly from challenging conditions.',
      'discipline': 'word_clash',
      'difficulty': 'medium',
    },
    {
      'question': 'What is the exact opposite of "authentic"?',
      'options': ['Genuine', 'Spurious', 'Credible', 'Legitimate'],
      'correctIndex': 1,
      'explanation':
          'Spurious means deceitful, fake, or counterfeit — the opposite of authentic.',
      'discipline': 'word_clash',
      'difficulty': 'medium',
    },
    {
      'question': 'Which word is closest in meaning to "meticulous"?',
      'options': ['Careless', 'Thorough', 'Impatient', 'Slapdash'],
      'correctIndex': 1,
      'explanation':
          'Meticulous means displaying rigorous attention to fine detail and high precision.',
      'discipline': 'word_clash',
      'difficulty': 'medium',
    },

    // 🎯 PHRASE DUEL: Natural Collocations & Idioms
    {
      'question':
          'Please ______ close attention to the safety instructions before departure.',
      'options': ['make', 'do', 'pay', 'hold'],
      'correctIndex': 2,
      'explanation':
          'In natural English collocation, we "pay attention", never "make" or "do" it.',
      'discipline': 'phrase_duel',
      'difficulty': 'medium',
    },
    {
      'question':
          'The committee struggled to ______ a final decision on the budget proposal.',
      'options': ['make', 'do', 'have', 'put'],
      'correctIndex': 0,
      'explanation':
          '"Make a decision" is the standard native collocation for reaching a choice.',
      'discipline': 'phrase_duel',
      'difficulty': 'medium',
    },
    {
      'question': 'Could you ______ me a quick favour and hold the door open?',
      'options': ['make', 'give', 'do', 'take'],
      'correctIndex': 2,
      'explanation':
          '"Do someone a favour" is the standard idiomatic expression for requesting assistance.',
      'discipline': 'phrase_duel',
      'difficulty': 'medium',
    },
    {
      'question':
          'The manager decided to bite the ______ and deliver the difficult report directly.',
      'options': ['bullet', 'apple', 'tongue', 'dust'],
      'correctIndex': 0,
      'explanation':
          '"Bite the bullet" means facing an unavoidable hardship with composure and resolve.',
      'discipline': 'phrase_duel',
      'difficulty': 'medium',
    },
    {
      'question':
          'Marta opened the workshop with a lighthearted joke to break the ______.',
      'options': ['glass', 'ice', 'silence', 'wall'],
      'correctIndex': 1,
      'explanation':
          '"Break the ice" means easing social tension and making unfamiliar people comfortable.',
      'discipline': 'phrase_duel',
      'difficulty': 'medium',
    },
    {
      'question':
          'She stayed up late burning the midnight ______ to finish her thesis on time.',
      'options': ['candle', 'oil', 'wood', 'paper'],
      'correctIndex': 1,
      'explanation':
          '"Burn the midnight oil" originates from late-night oil lamps and means studying or working late.',
      'discipline': 'phrase_duel',
      'difficulty': 'medium',
    },

    // 💥 SENTENCE STRIKE: Academic Vocabulary & Sentence Precision
    {
      'question':
          'The researcher\'s breakthrough theory was thoroughly ______ by empirical laboratory evidence.',
      'options': ['contradicted', 'validated', 'neglected', 'delayed'],
      'correctIndex': 1,
      'explanation':
          'Validated means confirmed or substantiated with rigorous factual proof.',
      'discipline': 'sentence_strike',
      'difficulty': 'medium',
    },
    {
      'question':
          'The board reached a unanimous ______ after reviewing the financial audit.',
      'options': ['consensus', 'dispute', 'dilemma', 'hesitation'],
      'correctIndex': 0,
      'explanation':
          'Consensus represents collective, widespread agreement across members of a governing body.',
      'discipline': 'sentence_strike',
      'difficulty': 'medium',
    },
    {
      'question':
          'The department enforced ______ security protocols to safeguard confidential client data.',
      'options': ['stringent', 'lenient', 'fragile', 'careless'],
      'correctIndex': 0,
      'explanation':
          'Stringent describes rigorous, strict, and tightly binding rules or requirements.',
      'discipline': 'sentence_strike',
      'difficulty': 'medium',
    },
    {
      'question':
          'Her explanation was both ______ and insightful, leaving no ambiguity for the team.',
      'options': ['ambiguous', 'lucid', 'repetitive', 'vague'],
      'correctIndex': 1,
      'explanation':
          'Lucid means expressed clearly and transparently; easy to perceive and comprehend.',
      'discipline': 'sentence_strike',
      'difficulty': 'medium',
    },
    {
      'question':
          'The sudden policy revision provoked ______ debate across international trade symposiums.',
      'options': ['heated', 'silent', 'lukewarm', 'mild'],
      'correctIndex': 0,
      'explanation':
          'Heated debate signifies intense, animated, and passionate discussion on contentious topics.',
      'discipline': 'sentence_strike',
      'difficulty': 'medium',
    },

    // 🧠 CONTEXT BLITZ: Deductive Reasoning & Situational Clues
    {
      'question':
          'After three hours on the tarmac with no updates from the flight crew, passengers grew increasingly ______, sighing and checking watches.',
      'options': ['generous', 'restless', 'relieved', 'curious'],
      'correctIndex': 1,
      'explanation':
          'Sighing and constantly checking watches are textbook behavioral clues indicating restlessness and impatience.',
      'discipline': 'context_blitz',
      'difficulty': 'medium',
    },
    {
      'question':
          'Maya\'s presentation was so ______ that even complete newcomers followed each phase of the plan without hesitation.',
      'options': [
        'straightforward',
        'overcomplicated',
        'impenetrable',
        'long-winded',
      ],
      'correctIndex': 0,
      'explanation':
          'When beginners follow complex material without confusion, the delivery is straightforward and clear.',
      'discipline': 'context_blitz',
      'difficulty': 'medium',
    },
    {
      'question':
          'Despite managing the entire division, Julian never boasts and thanks every staff member by name; he is remarkably ______.',
      'options': ['ambitious', 'humble', 'impatient', 'stubborn'],
      'correctIndex': 1,
      'explanation':
          'Expressing quiet gratitude without self-promotion denotes a genuinely humble character.',
      'discipline': 'context_blitz',
      'difficulty': 'medium',
    },
    {
      'question':
          'When the vendor suggested a cheaper alternative, the lead engineer was ______ to accept it without strict quality testing.',
      'options': ['grateful', 'reluctant', 'delighted', 'eager'],
      'correctIndex': 1,
      'explanation':
          'Insisting on quality verification before accepting an untested substitute demonstrates hesitation or reluctance.',
      'discipline': 'context_blitz',
      'difficulty': 'medium',
    },
    {
      'question':
          'The ancient inscription was so ______ that archaeologists required ultraviolet imaging to decipher the eroded lettering.',
      'options': ['fragile', 'obscure', 'ordinary', 'vibrant'],
      'correctIndex': 1,
      'explanation':
          'Eroded script requiring specialized ultraviolet equipment points directly to obscure, hard-to-distinguish text.',
      'discipline': 'context_blitz',
      'difficulty': 'medium',
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

  /// Generates dynamic questions sampled from dedicated 1v1 Arena batches
  /// (`assets/curriculum/arena/`) and across Vowl's 200 curriculum levels
  /// in 7 distinct disciplines (`assets/curriculum/vocabulary/`).
  static Future<List<ArenaQuestion>> generateQuestionsAsync({
    int count = 5,
    int? seed,
    QuestService? questService,
  }) async {
    final rand = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
    final service =
        questService ??
        (di.sl.isRegistered<AssetQuestService>()
            ? di.sl<AssetQuestService>()
            : null);

    final questions = <ArenaQuestion>[];

    // 1. Dedicated 1v1 Arena Batches (assets/curriculum/arena/)
    try {
      final arenaBatches = await _loadDedicatedArenaBatches(rand, count: count);
      for (final q in arenaBatches) {
        if (!questions.any((existing) => existing.question == q.question)) {
          questions.add(q);
          if (questions.length >= count) break;
        }
      }
    } catch (_) {}

    // 2. Expanded 5,600+ Curriculum Questions (assets/curriculum/vocabulary/)
    if (service != null && questions.length < count) {
      try {
        // Shuffle disciplines to ensure cross-discipline blitz
        final shuffledGameTypes = List<String>.from(kSupportedGameTypes)
          ..shuffle(rand);

        for (final gameType in shuffledGameTypes) {
          if (questions.length >= count) break;
          // True random sampling across all 200 levels
          final level = rand.nextInt(200) + 1;
          try {
            final quests = await service.getQuests(gameType, level);
            if (quests.isEmpty) continue;
            final shuffledQuests = List<Map<String, dynamic>>.from(quests)
              ..shuffle(rand);
            for (final q in shuffledQuests) {
              final converted = _tryConvertCurriculumQuest(q, gameType, rand);
              if (converted != null &&
                  !questions.any(
                    (existing) => existing.question == converted.question,
                  )) {
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
          for (
            int attempt = 0;
            attempt < 15 && questions.length < count;
            attempt++
          ) {
            final randomType =
                kSupportedGameTypes[rand.nextInt(kSupportedGameTypes.length)];
            final randomLevel = rand.nextInt(200) + 1;
            try {
              final quests = await service.getQuests(randomType, randomLevel);
              final shuffledQuests = List<Map<String, dynamic>>.from(quests)
                ..shuffle(rand);
              for (final q in shuffledQuests) {
                final converted = _tryConvertCurriculumQuest(
                  q,
                  randomType,
                  rand,
                );
                if (converted != null &&
                    !questions.any(
                      (existing) => existing.question == converted.question,
                    )) {
                  questions.add(converted);
                  if (questions.length >= count) break;
                }
              }
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint(
          '[ArenaCurriculumEngine] Curriculum quest load fallback: $e',
        );
      }
    }

    // 3. Fill any remaining shortfall with deterministic curated bank
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

    // Deterministic fallback to verified question bank if offline or testing
    return generateQuestions(count: count, seed: seed);
  }

  /// Generates questions with a progressive difficulty curve:
  /// Round 1-2: Easy (or untagged fallback)
  /// Round 3-4: Medium
  /// Round 5: Hard
  static Future<List<ArenaQuestion>> generateProgressiveQuestionsAsync({
    int count = 5,
    int? seed,
    QuestService? questService,
  }) async {
    final questions = await generateQuestionsAsync(
      count: count * 2, // Get extra to have selection pool
      seed: seed,
      questService: questService,
    );

    if (questions.length < count) return questions;

    // Sort by difficulty: easy first, then medium, then hard
    final easy = questions.where((q) => q.difficulty == 'easy').toList();
    final medium = questions.where((q) => q.difficulty == 'medium').toList();
    final hard = questions.where((q) => q.difficulty == 'hard').toList();
    final untagged = questions.where((q) => q.difficulty == null).toList();

    // Progressive curve: easy, easy, medium, medium, hard
    final progressive = <ArenaQuestion>[];
    // Round 1-2: easy (or untagged fallback)
    final easyPool = [...easy, ...untagged];
    for (int i = 0; i < 2 && easyPool.isNotEmpty; i++) {
      progressive.add(easyPool.removeAt(0));
    }
    // Round 3-4: medium (or remaining easy/untagged)
    final medPool = [...medium, ...easyPool];
    for (
      int i = 0;
      i < 2 && medPool.isNotEmpty && progressive.length < 4;
      i++
    ) {
      final q = medPool.removeAt(0);
      if (!progressive.any((p) => p.question == q.question)) {
        progressive.add(q);
      }
    }
    // Round 5: hard (or remaining medium)
    final hardPool = [...hard, ...medPool];
    for (final q in hardPool) {
      if (progressive.length >= count) break;
      if (!progressive.any((p) => p.question == q.question)) {
        progressive.add(q);
        break;
      }
    }

    // Fill any remaining with whatever's available
    for (final q in questions) {
      if (progressive.length >= count) break;
      if (!progressive.any((p) => p.question == q.question)) {
        progressive.add(q);
      }
    }

    return progressive.take(count).toList();
  }

  /// Loads dedicated 1v1 Arena batches from `assets/curriculum/arena/`
  /// supporting up to 20 batches per discipline, aiming for [count] questions.
  static Future<List<ArenaQuestion>> _loadDedicatedArenaBatches(
    Random rand, {
    int count = 5,
  }) async {
    try {
      const modes = [
        'word_clash',
        'phrase_duel',
        'sentence_strike',
        'context_blitz',
      ];
      final dedicated = <ArenaQuestion>[];
      final shuffledModes = List<String>.from(modes)..shuffle(rand);

      // Pass 1: 1 question per discipline for true cross-discipline balance
      for (final mode in shuffledModes) {
        if (dedicated.length >= count) break;
        await _pickQuestionFromMode(mode, rand, dedicated);
      }

      // Pass 2: If we still need questions to reach target count (e.g. 5th question),
      // sample from random disciplines
      for (int i = 0; i < 5 && dedicated.length < count; i++) {
        final mode = modes[rand.nextInt(modes.length)];
        await _pickQuestionFromMode(mode, rand, dedicated);
      }

      return dedicated;
    } catch (_) {
      return [];
    }
  }

  static String resolveDiscipline(String gameType) {
    switch (gameType) {
      case 'word_clash':
      case 'synonymSearch':
      case 'antonymSearch':
        return 'word_clash';
      case 'phrase_duel':
      case 'collocations':
      case 'idioms':
      case 'phrasalVerbs':
        return 'phrase_duel';
      case 'sentence_strike':
      case 'academicWord':
        return 'sentence_strike';
      case 'context_blitz':
      case 'contextClues':
      default:
        return 'context_blitz';
    }
  }

  static Future<void> _pickQuestionFromMode(
    String mode,
    Random rand,
    List<ArenaQuestion> destination,
  ) async {
    try {
      final batchNum = rand.nextInt(20) + 1;
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(
          'assets/curriculum/arena/$mode/${mode}_batch_$batchNum.json',
        );
      } catch (_) {
        try {
          jsonString = await rootBundle.loadString(
            'assets/curriculum/arena/$mode/batch_$batchNum.json',
          );
        } catch (_) {
          try {
            jsonString = await rootBundle.loadString(
              'assets/curriculum/arena/$mode/${mode}_batch_1.json',
            );
          } catch (_) {
            jsonString = await rootBundle.loadString(
              'assets/curriculum/arena/$mode/batch_1.json',
            );
          }
        }
      }

      final Map<String, dynamic> data = jsonDecode(jsonString);
      final rawQuests = data['quests'] as List<dynamic>? ?? [];
      final discipline = data['discipline'] as String? ?? mode;
      if (rawQuests.isNotEmpty) {
        final shuffled = List<dynamic>.from(rawQuests)..shuffle(rand);
        for (final item in shuffled) {
          final qMap = Map<String, dynamic>.from(item as Map);
          final q = _tryConvertCurriculumQuest(qMap, discipline, rand);
          if (q != null &&
              !destination.any((existing) => existing.question == q.question)) {
            destination.add(q);
            break;
          }
        }
      }
    } catch (_) {}
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

      final correctAnswer = (quest['correctAnswer'] ?? quest['answer'] ?? '')
          .toString()
          .trim();
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

      if (quest.containsKey('question') &&
          quest['question'] != null &&
          quest['question'].toString().trim().isNotEmpty) {
        questionText = quest['question'].toString().trim();
      } else if (quest.containsKey('prompt') &&
          quest['prompt'] != null &&
          quest['prompt'].toString().trim().isNotEmpty) {
        questionText = quest['prompt'].toString().trim();
      } else if (gameType == 'synonymSearch' &&
          word != null &&
          word.isNotEmpty) {
        questionText = 'What is the closest synonym for "$word"?';
      } else if (gameType == 'antonymSearch' &&
          word != null &&
          word.isNotEmpty) {
        questionText = 'What is the opposite of "$word"?';
      } else if (gameType == 'idioms') {
        if (instruction != null && instruction.contains('___')) {
          questionText = instruction;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'What does the idiom "$word" mean?';
        } else if (hint != null &&
            hint.toUpperCase().startsWith('DEFINITION:')) {
          questionText = hint
              .replaceFirst(RegExp(r'DEFINITION:\s*', caseSensitive: false), '')
              .trim();
        } else {
          questionText = instruction ?? 'Select the correct idiom:';
        }
      } else if (gameType == 'collocations') {
        if (contextSentence != null && contextSentence.contains('___')) {
          questionText = contextSentence;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'Complete the natural collocation with "$word":';
        } else {
          questionText =
              instruction ?? 'Choose the word that forms a natural pair:';
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
          questionText =
              instruction ?? 'Select the best word to complete the sentence:';
        }
      } else if (gameType == 'context_blitz' || gameType == 'contextClues') {
        if (sentence != null && sentence.contains('[TARGET]')) {
          questionText = sentence.replaceAll('[TARGET]', '_____');
        } else if (contextSentence != null && contextSentence.contains('___')) {
          questionText = contextSentence;
        } else if (word != null && word.isNotEmpty) {
          questionText = 'Infer the contextual meaning of "$word":';
        } else {
          questionText =
              instruction ?? 'Analyze the sentence to deduce the meaning:';
        }
      } else {
        questionText = (instruction != null && instruction.isNotEmpty)
            ? (word != null ? '$instruction ("$word")' : instruction)
            : 'Choose the correct answer:';
      }

      final explanation =
          (quest['explanation'] ??
                  quest['detail'] ??
                  quest['hint'] ??
                  'Vowl authentic curriculum challenge.')
              .toString();

      // Deterministically shuffle options using rand to eliminate positional bias
      final shuffledOptions = List<String>.from(options)..shuffle(rand);
      final newCorrectIndex = shuffledOptions.indexWhere(
        (opt) => opt.toLowerCase() == correctAnswer.toLowerCase(),
      );

      final difficulty = (quest['difficulty'] as String?)?.toLowerCase();

      return ArenaQuestion(
        question: questionText,
        options: shuffledOptions,
        correctIndex: newCorrectIndex != -1
            ? newCorrectIndex
            : originalCorrectIndex,
        explanation: explanation,
        discipline: resolveDiscipline(gameType),
        difficulty: difficulty,
      );
    } catch (_) {
      return null;
    }
  }
}
