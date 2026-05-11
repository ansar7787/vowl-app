import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

abstract class VocabularyRepository {
  Future<List<VocabularyQuest>> getVocabularyQuests(String gameType, int level);
}
