import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/writing/data/models/writing_quest_model.dart';

abstract class WritingRemoteDataSource {
  Future<List<WritingQuestModel>> getWritingQuest({
    required GameSubtype gameType,
    required int level,
  });
}

class WritingRemoteDataSourceImpl implements WritingRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  WritingRemoteDataSourceImpl(this.firestore, this.assetQuestService);

  @override
  Future<List<WritingQuestModel>> getWritingQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final String typeString = gameType.name;

      // 1. Try Local Assets first (Centralized Service)
      final localData = await assetQuestService.getQuests(typeString, level);
      if (localData.isNotEmpty) {
        final List<WritingQuestModel> quests = [];
        for (final q in localData) {
          try {
            quests.add(WritingQuestModel.fromJson(q, q['id'] ?? ''));
          } catch (e) {
            debugPrint('Error parsing writing quest ${q['id']}: $e');
          }
        }
        if (quests.isNotEmpty) return quests;
      }

      // 2. Fallback to Firestore
      final snapshot = await firestore
          .collection('curriculum')
          .doc('writing')
          .collection(typeString)
          .where('level', isEqualTo: level)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final questsData = snapshot.docs.first.data()['quests'] as List;
        return questsData
            .map((q) => WritingQuestModel.fromJson(q, q['id'] ?? ''))
            .toList();
      }

      throw ServerException("We're having trouble loading this writing exercise. Please try again in a moment.");
    } catch (e) {
      debugPrint('Error in getWritingQuest: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
