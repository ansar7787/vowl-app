import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/utils/app_logger.dart';

class SeedingService {
  final FirebaseFirestore firestore;

  SeedingService(this.firestore);

  Future<void> seedData() async {
    final batch = firestore.batch();

    // ==========================================
    // 1. Reading Quests (Level 1 Example)
    // ==========================================
    final readingLvl1 = {
      'id': 'level_1',
      'levelNumber': 1,
      'skill': 'reading',
      'gameType': 'readAndAnswer',
      'quests': [
        {
          'id': 'r1_q1',
          'instruction': 'What color is the sky?',
          'difficulty': 1,
          'subtype': 'readAndAnswer',
          'passage': 'The sun is hot. The sky is blue.',
          'options': ['Blue', 'Red', 'Green', 'Yellow'],
          'correctAnswerIndex': 0,
        },
        {
          'id': 'r1_q2',
          'instruction': 'What temperature is the sun?',
          'difficulty': 1,
          'subtype': 'readAndAnswer',
          'passage': 'The sun is hot. The sky is blue.',
          'options': ['Cold', 'Warm', 'Hot', 'Freezing'],
          'correctAnswerIndex': 2,
        },
        {
          'id': 'r1_q3',
          'instruction': 'Is the sun hot?',
          'difficulty': 1,
          'subtype': 'readAndAnswer',
          'passage': 'The sun is hot. The sky is blue.',
          'options': ['Yes', 'No'],
          'correctAnswerIndex': 0,
        },
      ],
    };

    batch.set(
      firestore
          .collection('quests')
          .doc('readAndAnswer')
          .collection('levels')
          .doc('1'),
      readingLvl1,
    );

    // ==========================================
    // 2. Writing Quests (Level 1 Example)
    // ==========================================
    final writingLvl1 = {
      'id': 'level_1',
      'levelNumber': 1,
      'skill': 'writing',
      'gameType': 'completeSentence',
      'quests': [
        {
          'id': 'w1_q1',
          'instruction': 'Type the correct answer',
          'difficulty': 1,
          'subtype': 'completeSentence',
          'prompt': 'Write the word "Apple"',
          'correctAnswer': 'Apple',
        },
        {
          'id': 'w1_q2',
          'instruction': 'Type the correct answer',
          'difficulty': 1,
          'subtype': 'completeSentence',
          'prompt': 'Write the word "Banana"',
          'correctAnswer': 'Banana',
        },
        {
          'id': 'w1_q3',
          'instruction': 'Type the correct answer',
          'difficulty': 1,
          'subtype': 'completeSentence',
          'prompt': 'Write the word "Orange"',
          'correctAnswer': 'Orange',
        },
      ],
    };

    batch.set(
      firestore
          .collection('quests')
          .doc('completeSentence')
          .collection('levels')
          .doc('1'),
      writingLvl1,
    );

    // ==========================================
    // 3. Speaking Quests (Level 1 Example)
    // ==========================================
    final speakingLvl1 = {
      'id': 'level_1',
      'levelNumber': 1,
      'skill': 'speaking',
      'gameType': 'repeatSentence',
      'quests': [
        {
          'id': 's1_q1',
          'instruction': 'Speak the answer clearly',
          'difficulty': 1,
          'subtype': 'repeatSentence',
          'textToSpeak': 'Hello world',
          'correctAnswer': 'Hello world',
          'xpReward': 20,
          'coinReward': 10,
          'livesAllowed': 3,
        },
        {
          'id': 's1_q2',
          'instruction': 'Speak the answer clearly',
          'difficulty': 1,
          'subtype': 'repeatSentence',
          'textToSpeak': 'Good morning',
          'correctAnswer': 'Good morning',
          'xpReward': 20,
          'coinReward': 10,
          'livesAllowed': 3,
        },
        {
          'id': 's1_q3',
          'instruction': 'Speak the answer clearly',
          'difficulty': 1,
          'subtype': 'repeatSentence',
          'textToSpeak': 'How are you?',
          'correctAnswer': 'How are you?',
          'xpReward': 20,
          'coinReward': 10,
          'livesAllowed': 3,
        },
      ],
    };

    batch.set(
      firestore
          .collection('quests')
          .doc('repeatSentence')
          .collection('levels')
          .doc('1'),
      speakingLvl1,
    );

    // ==========================================
    // 4. Grammar Quests (Level 1 Example)
    // ==========================================
    final grammarLvl1 = {
      'id': 'level_1',
      'levelNumber': 1,
      'skill': 'grammar',
      'gameType': 'grammarQuest',
      'quests': [
        {
          'id': 'g1_q1',
          'instruction': 'Choose the correct option',
          'difficulty': 1,
          'subtype': 'grammarQuest',
          'question': 'She ___ to school.',
          'options': ['go', 'goes', 'going', 'gone'],
          'correctAnswerIndex': 1,
          'explanation': '"She" is third-person singular, so we use "goes".',
        },
        {
          'id': 'g1_q2',
          'instruction': 'Choose the correct option',
          'difficulty': 1,
          'subtype': 'grammarQuest',
          'question': 'They ___ happy today.',
          'options': ['is', 'am', 'are', 'was'],
          'correctAnswerIndex': 2,
          'explanation': '"They" is plural, so we use "are".',
        },
        {
          'id': 'g1_q3',
          'instruction': 'Choose the correct option',
          'difficulty': 1,
          'subtype': 'grammarQuest',
          'question': 'I ___ a student.',
          'options': ['is', 'am', 'are', 'be'],
          'correctAnswerIndex': 1,
          'explanation': '"I" always takes "am" in present tense.',
        },
      ],
    };

    batch.set(
      firestore
          .collection('quests')
          .doc('grammarQuest')
          .collection('levels')
          .doc('1'),
      grammarLvl1,
    );

    // ==========================================
    // 5. Roleplay Quests (Level 1 Example)
    // ==========================================
    final roleplayLvl1 = {
      'id': 'level_1',
      'levelNumber': 1,
      'skill': 'roleplay',
      'gameType': 'dialogueRoleplay',
      'quests': [
        {
          'id': 'rp1_q1',
          'instruction': 'Roleplay with the AI',
          'difficulty': 1,
          'subtype': 'dialogueRoleplay',
          'roleName': 'Store Clerk',
          'aiPrompt': 'Welcome! How can I help you today?',
          'targetKeyPhrases': ['buy', 'price', 'cost', 'looking for'],
        },
        {
          'id': 'rp1_q2',
          'instruction': 'Roleplay with the AI',
          'difficulty': 1,
          'subtype': 'dialogueRoleplay',
          'roleName': 'Waiter',
          'aiPrompt': 'Are you ready to order?',
          'targetKeyPhrases': ['menu', 'order', 'coffee', 'latte'],
        },
        {
          'id': 'rp1_q3',
          'instruction': 'Roleplay with the AI',
          'difficulty': 1,
          'subtype': 'dialogueRoleplay',
          'roleName': 'Friend',
          'aiPrompt': 'Do you want to see a movie tonight?',
          'targetKeyPhrases': ['yes', 'sure', 'time', 'cinema'],
        },
      ],
    };

    batch.set(
      firestore
          .collection('quests')
          .doc('dialogueRoleplay')
          .collection('levels')
          .doc('1'),
      roleplayLvl1,
    );

    // ==========================================
    // 6. Accent Quests (Level 1 Example)
    // ==========================================
    final accentLvl1 = {
      'id': 'level_1',
      'levelNumber': 1,
      'skill': 'accent',
      'gameType': 'pronunciationFocus',
      'quests': [
        {
          'id': 'a1_q1',
          'instruction': 'Pronounce the word correctly',
          'difficulty': 1,
          'subtype': 'pronunciationFocus',
          'word': 'Phenomenon',
          'phonetic': '/fəˈnɒmɪnən/',
        },
        {
          'id': 'a1_q2',
          'instruction': 'Pronounce the word correctly',
          'difficulty': 1,
          'subtype': 'pronunciationFocus',
          'word': 'Schedule',
          'phonetic': '/ˈʃɛdjuːl/',
        },
        {
          'id': 'a1_q3',
          'instruction': 'Pronounce the word correctly',
          'difficulty': 1,
          'subtype': 'pronunciationFocus',
          'word': 'Library',
          'phonetic': '/ˈlaɪbrəri/',
        },
      ],
    };

    batch.set(
      firestore
          .collection('quests')
          .doc('pronunciationFocus')
          .collection('levels')
          .doc('1'),
      accentLvl1,
    );

    try {
      await batch.commit();
      AppLogger.info(
        'SeedingService: Curriculum sample data seeded successfully',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'SeedingService: Failed to seed curriculum data',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
