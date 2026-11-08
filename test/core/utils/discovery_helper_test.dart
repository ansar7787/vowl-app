import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/discovery_helper.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

void main() {
  setUp(() {
    DiscoveryHelper.clearTrackCache();
  });

  const baseUser = UserEntity(
    id: 'test_user_discovery',
    email: 'test@vowl.app',
    displayName: 'Aria',
    unlockedLevels: {
      'repeatSentence': 5,
      'readAndAnswer': 12,
      'readingSpeedCheck': 8,
      'fastSpeechDecoder': 3,
      'minimalPairs': 4,
      'wordReorder': 6,
      'tenseMastery': 9,
      'clauseConnector': 2,
    },
    completedLevels: {
      'repeatSentence': [1, 2, 3, 4],
      'readAndAnswer': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
    },
  );

  group('DiscoveryHelper Sequence Generation Tests', () {
    test('resolves daily_duo with exact user unlocked levels', () {
      final quests = DiscoveryHelper.getQuestsForSequence('daily_duo', baseUser);
      expect(quests.length, 2);
      expect(quests[0].subtype, GameSubtype.repeatSentence);
      expect(quests[0].difficulty, 5);
      expect(quests[1].subtype, GameSubtype.readAndAnswer);
      expect(quests[1].difficulty, 12);
    });

    test('resolves speed_blitz with 3 drill games', () {
      final quests = DiscoveryHelper.getQuestsForSequence('speed_blitz', baseUser);
      expect(quests.length, 3);
      expect(quests[0].subtype, GameSubtype.readingSpeedCheck);
      expect(quests[0].difficulty, 8);
      expect(quests[1].subtype, GameSubtype.fastSpeechDecoder);
      expect(quests[1].difficulty, 3);
      expect(quests[2].subtype, GameSubtype.minimalPairs);
      expect(quests[2].difficulty, 4);
    });

    test('resolves grammar_pro with 3 syntax & mechanics games', () {
      final quests = DiscoveryHelper.getQuestsForSequence('grammar_pro', baseUser);
      expect(quests.length, 3);
      expect(quests[0].subtype, GameSubtype.wordReorder);
      expect(quests[0].difficulty, 6);
      expect(quests[1].subtype, GameSubtype.tenseMastery);
      expect(quests[1].difficulty, 9);
      expect(quests[2].subtype, GameSubtype.clauseConnector);
      expect(quests[2].difficulty, 2);
    });

    test('resolves smart_recommendation with 3 distinct game categories for zero progress', () {
      const freshUser = UserEntity(
        id: 'fresh_user',
        email: 'fresh@vowl.app',
      );
      final quests = DiscoveryHelper.getQuestsForSequence('smart_recommendation', freshUser);
      expect(quests.length, 3);
      // Ensure all 3 are distinct
      final types = quests.map((q) => q.type).toSet();
      expect(types.length, 3);
    });

    test('resolves smart_recommendation targeting lowest and highest categories', () {
      final variedUser = baseUser.copyWith(
        completedLevels: {
          'repeatSentence': [1, 2], // 2 levels in speaking
          'flashcards': List.generate(20, (i) => i + 1), // 20 levels in vocabulary (favorite)
        },
      );
      final quests = DiscoveryHelper.getQuestsForSequence('smart_recommendation', variedUser);
      expect(quests.length, 3);
      final types = quests.map((q) => q.type).toSet();
      expect(types.length, 3);
    });
  });

  group('DiscoveryHelper Max Level & Subtype Rotation Tests', () {
    test('serves Level 50 when unlocked at 50 but not yet completed', () {
      final maxLevels = CurriculumManifest.getLevels(GameSubtype.repeatSentence.name);
      final userAt50 = baseUser.copyWith(
        unlockedLevels: {
          ...baseUser.unlockedLevels,
          'repeatSentence': maxLevels,
        },
        completedLevels: {
          ...baseUser.completedLevels,
          'repeatSentence': List.generate(maxLevels - 1, (i) => i + 1), // 1..49 completed, 50 not yet
        },
      );

      final quests = DiscoveryHelper.getQuestsForSequence('daily_duo', userAt50);
      expect(quests[0].subtype, GameSubtype.repeatSentence);
      expect(quests[0].difficulty, maxLevels);
    });

    test('rotates to next uncompleted subtype in category when current subtype is completely mastered', () {
      final maxLevels = CurriculumManifest.getLevels(GameSubtype.repeatSentence.name);
      final masteredUser = baseUser.copyWith(
        unlockedLevels: {
          ...baseUser.unlockedLevels,
          'repeatSentence': maxLevels,
          'speakMissingWord': 7,
        },
        completedLevels: {
          ...baseUser.completedLevels,
          // Level 50 is marked completed
          'repeatSentence': List.generate(maxLevels, (i) => i + 1),
          'speakMissingWord': [1, 2, 3, 4, 5, 6],
        },
      );

      final quests = DiscoveryHelper.getQuestsForSequence('daily_duo', masteredUser);
      // Should automatically rotate from mastered repeatSentence to speakMissingWord at level 7
      expect(quests[0].subtype, GameSubtype.speakMissingWord);
      expect(quests[0].difficulty, 7);
    });
  });

  group('DiscoveryHelper Canonical & Legacy ID Mapping Tests', () {
    test('maps legacy codenames to modern canonical sequence IDs', () {
      expect(DiscoveryHelper.canonicalSequenceId('daily_duo'), equals('daily_workout'));
      expect(DiscoveryHelper.canonicalSequenceId('speed_blitz'), equals('rapid_recall'));
      expect(DiscoveryHelper.canonicalSequenceId('grammar_pro'), equals('sentence_lab'));
      expect(DiscoveryHelper.canonicalSequenceId('smart_recommendation'), equals('smart_focus'));
      expect(DiscoveryHelper.canonicalSequenceId('daily_workout'), equals('daily_workout'));
      expect(DiscoveryHelper.canonicalSequenceId('rapid_recall'), equals('rapid_recall'));
      expect(DiscoveryHelper.canonicalSequenceId('sentence_lab'), equals('sentence_lab'));
      expect(DiscoveryHelper.canonicalSequenceId('smart_focus'), equals('smart_focus'));
    });

    test('maps modern canonical IDs back to legacy development codenames', () {
      expect(DiscoveryHelper.legacySequenceId('daily_workout'), equals('daily_duo'));
      expect(DiscoveryHelper.legacySequenceId('rapid_recall'), equals('speed_blitz'));
      expect(DiscoveryHelper.legacySequenceId('sentence_lab'), equals('grammar_pro'));
      expect(DiscoveryHelper.legacySequenceId('smart_focus'), equals('smart_recommendation'));
      expect(DiscoveryHelper.legacySequenceId('daily_duo'), equals('daily_duo'));
    });

    test('resolves quests equivalently using canonical or legacy identifiers', () {
      final modern = DiscoveryHelper.getQuestsForSequence('daily_workout', baseUser);
      final legacy = DiscoveryHelper.getQuestsForSequence('daily_duo', baseUser);
      expect(modern.length, equals(legacy.length));
      expect(modern[0].subtype, equals(legacy[0].subtype));
      expect(modern[1].subtype, equals(legacy[1].subtype));
    });
  });
}

