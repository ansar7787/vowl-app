import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/word_formation/data/services/word_formation_curriculum_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WordFormationCurriculumService service;

  setUp(() {
    service = WordFormationCurriculumService();
    service.clearCache();
  });

  group('WordFormationCurriculumService', () {
    test('getLearnQuests returns quests for level 1 and caches in memory', () async {
      final quests = await service.getLearnQuests(1);
      expect(quests, isNotEmpty);
      expect(quests.first.rawExtra['rootWord'], isNotNull);

      // Verify second call retrieves from cache instantly
      final cachedQuests = await service.getLearnQuests(1);
      expect(identical(quests, cachedQuests), isTrue);
    });

    test('getPracticeQuests returns quests with direction and target role', () async {
      final quests = await service.getPracticeQuests(1);
      expect(quests, isNotEmpty);
      final extra = quests.first.rawExtra;
      expect(extra['correctDirection'], isNotNull);
      expect(extra['targetRole'], isNotNull);
    });

    test('clearCache empties in-memory cache successfully', () async {
      final quests = await service.getLearnQuests(1);
      expect(quests, isNotEmpty);
      service.clearCache();
      // Should reload without error
      final questsAfterClear = await service.getLearnQuests(1);
      expect(questsAfterClear, isNotEmpty);
    });
  });
}
