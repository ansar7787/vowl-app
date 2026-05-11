import 'package:vowl/core/domain/entities/game_quest.dart';

class GameContentGenerator {
  static List<Map<String, dynamic>> generateLevels({
    required GameSubtype subtype,
    required QuestType category,
    int startLevel = 1,
    int endLevel = 30,
    int itemsPerLevel = 3,
  }) {
    List<Map<String, dynamic>> allQuests = [];

    for (int level = startLevel; level <= endLevel; level++) {
      for (int item = 1; item <= itemsPerLevel; item++) {
        Map<String, dynamic> quest = {
          'id': '${subtype.name}_L${level}_$item',
          'instruction': _getInstruction(subtype, item),
          'type': category.name,
          'subtype': subtype.name,
          'difficulty': level,
          'xpReward': 10 + (level ~/ 5) * 5,
          'coinReward': 5 + (level ~/ 10) * 2,
          'livesAllowed': 3,
        };

        // Add subtype-specific fields
        quest.addAll(_getSubtypeSpecificFields(subtype, level, item));

        allQuests.add(quest);
      }
    }

    return allQuests;
  }

  static String _getInstruction(GameSubtype subtype, int item) {
    switch (subtype) {
      case GameSubtype.repeatSentence:
        return 'Listen carefully and repeat the sentence exactly as you hear it.';
      case GameSubtype.readAndAnswer:
        return 'Read the passage and choose the best answer for the question.';
      case GameSubtype.sentenceBuilder:
        return 'Arrange the words in the correct order to form a meaningful sentence.';
      case GameSubtype.grammarQuest:
        return 'Identify the grammatical error or choose the correct form to complete the sentence.';
      case GameSubtype.minimalPairs:
        return 'Listen to the two words and identify which one you hear.';
      case GameSubtype.flashcards:
        return 'Review the word and its definition. Try to use it in a sentence.';
      case GameSubtype.branchingDialogue:
        return 'Participate in the conversation and choose your responses carefully.';
      case GameSubtype.audioFillBlanks:
        return 'Listen to the audio and fill in the missing words in the transcript.';
      case GameSubtype.essayDrafting:
        return 'Write a structured essay based on the provided topic, following the outline.';
      default:
        return 'Complete the challenge to improve your English skills.';
    }
  }

  static Map<String, dynamic> _getSubtypeSpecificFields(
    GameSubtype subtype,
    int level,
    int item,
  ) {
    switch (subtype) {
      // 1. Speaking
      case GameSubtype.repeatSentence:
        return {
          'textToSpeak':
              'This is a sample sentence for level $level, item $item.',
        };
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

      // 2. Listening
      case GameSubtype.audioFillBlanks:
        return {
          'audioUrl': 'https://example.com/audio/L${level}_$item.mp3',
          'textWithBlanks': 'I went to the ___ to buy some ___',
          'answers': ['store', 'milk'],
        };
      case GameSubtype.audioMultipleChoice:
        return {
          'audioUrl': 'https://example.com/audio/L${level}_$item.mp3',
          'question': 'Where does the speaker want to go?',
          'options': ['Park', 'Library', 'Cinema'],
          'correctIndex': 1,
        };

      // 3. Reading
      case GameSubtype.readAndAnswer:
        return {
          'passage':
              'Sample passage for level $level. English is a fascinating language with a rich history.',
          'question': 'What is the topic of the passage?',
          'options': ['Math', 'History', 'English'],
          'correctIndex': 2,
        };
      case GameSubtype.findWordMeaning:
        return {
          'word': 'Fascinating',
          'passage': 'English is a fascinating language...',
          'options': ['Boring', 'Very interesting'],
          'correctIndex': 1,
        };

      // 4. Writing
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

      // 5. Grammar
      case GameSubtype.grammarQuest:
        return {
          'sentence': 'He ___ to the gym every day.',
          'options': ['go', 'goes'],
          'correctIndex': 1,
        };
      case GameSubtype.sentenceCorrection:
        return {
          'incorrect': 'She don\'t know the answer.',
          'correct': 'She doesn\'t know the answer.',
        };
      case GameSubtype.wordReorder:
        return {
          'shuffled': ['movie', 'watched', 'we', 'the'],
          'correct': [2, 1, 3, 0],
        };

      // 6. Vocabulary
      case GameSubtype.flashcards:
        return {
          'word': 'Diligent',
          'definition':
              'Having or showing care and conscientiousness in one\'s work or duties.',
          'example':
              'She is a diligent student who always finishes her homework on time.',
        };
      case GameSubtype.synonymSearch:
        return {
          'word': 'Happy',
          'options': ['Sad', 'Joyful', 'Angry'],
          'correctIndex': 1,
        };

      // 7. Accent
      case GameSubtype.minimalPairs:
        return {
          'words': ['Bit', 'Beat'],
          'audio': 'https://example.com/audio/minimal_pairs_$item.mp3',
          'correctIndex': 0,
        };
      case GameSubtype.intonationMimic:
        return {
          'audioUrl': 'https://example.com/audio/intonation_$item.mp3',
          'intonationMap': [0.1, 0.5, 0.9, 0.4],
        };

      // 8. Roleplay
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
          'responses': ['I\'m sorry to hear that.', 'It\'s not a big deal.'],
          'correctIndex': 0,
        };

      default:
        return {
          'sampleField': 'Sample data for level $level',
          'content': 'Placeholder content for ${subtype.name}',
        };
    }
  }
}
