import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/features/vocabulary/data/models/vocabulary_quest_model.dart';

abstract class VocabularyRemoteDataSource {
  Future<List<VocabularyQuestModel>> getVocabularyQuests(
    String gameType,
    int level,
  );
}

class VocabularyRemoteDataSourceImpl implements VocabularyRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  VocabularyRemoteDataSourceImpl(this.firestore, this.assetQuestService);

  @override
  Future<List<VocabularyQuestModel>> getVocabularyQuests(
    String gameType,
    int level,
  ) async {
    try {
      // 1. Try to load from Local Assets (Free & Fast)
      final localData = await assetQuestService.getQuests(gameType, level);
      if (localData.isNotEmpty) {
        return localData.asMap().entries.map((entry) {
          final json = entry.value;
          final index = entry.key;
          return VocabularyQuestModel.fromJson(
            json,
            '${gameType}_L${level}_$index',
          );
        }).toList();
      }

      // 2. Fallback to Firestore (Cloud)
      final snapshot = await firestore
          .collection('quests')
          .doc(gameType)
          .collection('levels')
          .doc(level.toString())
          .get();

      if (snapshot.exists) {
        final questsData = snapshot.data()?['quests'] ?? [];
        return questsData.asMap().entries.map((entry) {
          final json = entry.value as Map<String, dynamic>;
          final index = entry.key;
          return VocabularyQuestModel.fromJson(json, '${snapshot.id}_$index');
        }).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
