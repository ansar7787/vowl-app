import 'package:vowl/core/domain/entities/game_quest.dart';

/// Performance-optimised dummy curriculum generator for the Vowl admin
/// dashboard.
///
/// Produces Firestore-ready quest maps that conform to the schema used by
/// game screen data sources. All content is intentionally in English because:
/// 1. This tool is admin-only (never shown to end users).
/// 2. The generated content serves as placeholder data for new game subtypes
///    before real curriculum is authored.
///
/// Placeholder URLs (e.g., `https://example.com/audio/...`) must be replaced
/// with production CDN URLs before the generated content goes live.
class GameContentGenerator {
  const GameContentGenerator._(); // Non-instantiable utility class.

  /// Generates a standardised list of quest maps for [startLevel]..[endLevel],
  /// with [itemsPerLevel] quests per level.
  ///
  /// ### Complexity
  /// O((endLevel − startLevel + 1) × itemsPerLevel) — linear in the number
  /// of quests generated. Memory footprint is bounded by the same factor.
  ///
  /// ### Assertions
  /// Structural requirements are enforced with `assert` so misconfigurations
  /// surface immediately in debug builds without cluttering production paths.
  static List<Map<String, dynamic>> generateLevels({
    required GameSubtype subtype,
    required QuestType category,
    int startLevel = 1,
    int endLevel = 30,
    int itemsPerLevel = 3,
  }) {
    assert(startLevel >= 1, 'startLevel must be ≥ 1');
    assert(
      endLevel >= startLevel,
      'endLevel ($endLevel) must be ≥ startLevel ($startLevel)',
    );
    assert(itemsPerLevel >= 1, 'itemsPerLevel must be ≥ 1');

    final quests = <Map<String, dynamic>>[];

    for (int level = startLevel; level <= endLevel; level++) {
      for (int item = 1; item <= itemsPerLevel; item++) {
        quests.add({
          'id': '${subtype.name}_L${level}_$item',
          'instruction': _instruction(subtype),
          'type': category.name,
          'subtype': subtype.name,
          'difficulty': level,
          'xpReward': 10 + (level ~/ 5) * 5,
          'coinReward': 5 + (level ~/ 10) * 2,
          'livesAllowed': 3,
          ..._subtypeFields(subtype, level, item),
        });
      }
    }

    return quests;
  }

  // ── Instruction text ──────────────────────────────────────────────────────

  static String _instruction(GameSubtype subtype) {
    switch (subtype) {
      case GameSubtype.repeatSentence:
        return 'Listen carefully and repeat the sentence exactly as you hear it.';
      case GameSubtype.readAndAnswer:
        return 'Read the passage and choose the best answer for the question.';
      case GameSubtype.sentenceBuilder:
        return 'Arrange the words in the correct order to form a meaningful sentence.';
      case GameSubtype.grammarQuest:
        return 'Identify the error or choose the correct form to complete the sentence.';
      case GameSubtype.minimalPairs:
        return 'Listen to the two words and identify which one you hear.';
      case GameSubtype.flashcards:
        return 'Review the word and its definition. Try to use it in a sentence.';
      case GameSubtype.branchingDialogue:
        return 'Participate in the conversation and choose your responses carefully.';
      case GameSubtype.audioFillBlanks:
        return 'Listen to the audio and fill in the missing words in the transcript.';
      case GameSubtype.essayDrafting:
        return 'Write a structured essay based on the provided topic and outline.';
      default:
        return 'Complete the challenge to improve your English skills.';
    }
  }

  // ── Subtype-specific Firestore fields ─────────────────────────────────────

  static Map<String, dynamic> _subtypeFields(
    GameSubtype subtype,
    int level,
    int item,
  ) {
    switch (subtype) {
      // ── Speaking ────────────────────────────────────────────────────────
      case GameSubtype.repeatSentence:
        return {'textToSpeak': 'Sample sentence for level $level, item $item.'};
      case GameSubtype.speakMissingWord:
        return {
          'textWithBlank': 'The ___ is very bright today.',
          'missingWord': 'sun',
          'audioClue': 'https://example.com/audio/sun.mp3',
        };
      case GameSubtype.situationSpeaking:
        return {
          'scenario': 'Ordering Food',
          'prompt': 'Order a large pizza with extra cheese.',
        };
      case GameSubtype.sceneDescriptionSpeaking:
        return {
          'imageUrl': 'https://example.com/images/park.jpg',
          'targetKeyWords': ['park', 'trees', 'bench'],
        };
      case GameSubtype.yesNoSpeaking:
        return {
          'question': 'Is it healthy to eat vegetables?',
          'expectedAnswer': 'yes',
          'explanationRequired': true,
        };
      case GameSubtype.speakSynonym:
        return {
          'word': 'Brave',
          'synonyms': ['Courageous', 'Valiant'],
        };
      case GameSubtype.dialogueRoleplay:
        return {
          'partnerLine': 'How can I help you today?',
          'yourTargetResponse': 'I would like to book a flight to London.',
        };
      case GameSubtype.pronunciationFocus:
        return {'targetWord': 'Subtle', 'phoneticGuide': '/ˈsʌt.əl/'};
      case GameSubtype.speakOpposite:
        return {
          'word': 'Generous',
          'antonyms': ['Stingy', 'Selfish'],
        };
      case GameSubtype.dailyExpression:
        return {
          'idiom': 'Break a leg',
          'context': 'Good luck with your performance tonight!',
        };

      // ── Listening ───────────────────────────────────────────────────────
      case GameSubtype.audioFillBlanks:
        return {
          'audioUrl': 'https://example.com/audio/L${level}_$item.mp3',
          'textWithBlanks': 'I went to the ___ to buy some ___.',
          'answers': ['store', 'milk'],
        };
      case GameSubtype.audioMultipleChoice:
        return {
          'audioUrl': 'https://example.com/audio/L${level}_$item.mp3',
          'question': 'Where does the speaker want to go?',
          'options': ['Park', 'Library', 'Cinema'],
          'correctAnswerIndex': 1,
        };

      // ── Reading ─────────────────────────────────────────────────────────
      case GameSubtype.readAndAnswer:
        return {
          'passage':
              'Sample passage for level $level. English is a fascinating '
              'language with a rich history.',
          'question': 'What is the topic of the passage?',
          'options': ['Math', 'History', 'English'],
          'correctAnswerIndex': 2,
        };
      case GameSubtype.findWordMeaning:
        return {
          'word': 'Fascinating',
          'passage': 'English is a fascinating language…',
          'options': ['Boring', 'Very interesting'],
          'correctAnswerIndex': 1,
        };

      // ── Writing ─────────────────────────────────────────────────────────
      case GameSubtype.sentenceBuilder:
        return {
          'words': ['I', 'love', 'learning', 'English'],
          'fixedOrder': [0, 1, 2, 3],
        };
      case GameSubtype.completeSentence:
        return {
          'prefix': 'In my free time, I like to',
          'suffix': 'to relax.',
          'placeholder': 'read books',
        };
      case GameSubtype.essayDrafting:
        return {
          'topic': 'The Impact of Technology on Education',
          'outline': [
            'Introduction',
            'Body Paragraph 1: Accessibility',
            'Body Paragraph 2: Engagement',
            'Conclusion',
          ],
          'minWords': 200,
        };

      // ── Grammar ─────────────────────────────────────────────────────────
      case GameSubtype.grammarQuest:
        return {
          'sentence': 'He ___ to the gym every day.',
          'options': ['go', 'goes'],
          'correctAnswerIndex': 1,
        };
      case GameSubtype.sentenceCorrection:
        return {
          'incorrect': "She don't know the answer.",
          'correct': "She doesn't know the answer.",
        };
      case GameSubtype.wordReorder:
        return {
          'shuffled': ['movie', 'watched', 'we', 'the'],
          'correct': [2, 1, 3, 0],
        };

      // ── Vocabulary ──────────────────────────────────────────────────────
      case GameSubtype.flashcards:
        return {
          'word': 'Diligent',
          'definition':
              'Showing care and conscientiousness in one\'s work or duties.',
          'example':
              'She is a diligent student who always finishes her homework.',
        };
      case GameSubtype.synonymSearch:
        return {
          'word': 'Happy',
          'options': ['Sad', 'Joyful', 'Angry'],
          'correctAnswerIndex': 1,
        };

      // ── Accent ──────────────────────────────────────────────────────────
      case GameSubtype.minimalPairs:
        return {
          'words': ['Bit', 'Beat'],
          'audio': 'https://example.com/audio/minimal_pairs_$item.mp3',
          'correctAnswerIndex': 0,
        };
      case GameSubtype.intonationMimic:
        return {
          'audioUrl': 'https://example.com/audio/intonation_$item.mp3',
          'intonationMap': [0.1, 0.5, 0.9, 0.4],
        };

      // ── Roleplay ────────────────────────────────────────────────────────
      case GameSubtype.branchingDialogue:
        return {
          'nodes': {
            'start': {
              'text': 'Hello! How can I help you?',
              'next': ['option1', 'option2'],
            },
          },
        };
      case GameSubtype.situationalResponse:
        return {
          'situation': 'A friend is feeling sad.',
          'responses': ["I'm sorry to hear that.", "It's not a big deal."],
          'correctAnswerIndex': 0,
        };

      default:
        return {
          'sampleField': 'Sample data for level $level',
          'content': 'Placeholder content for ${subtype.name}',
        };
    }
  }
}
