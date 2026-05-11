import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/reading/data/models/reading_quest_model.dart';

abstract class ReadingRemoteDataSource {
  Future<List<ReadingQuestModel>> getReadingQuest({
    required GameSubtype gameType,
    required int level,
  });
}

class ReadingRemoteDataSourceImpl implements ReadingRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  ReadingRemoteDataSourceImpl(this.firestore, this.assetQuestService);

  @override
  Future<List<ReadingQuestModel>> getReadingQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      // 1. Try to load from Local Assets (Free & Fast)
      final localData = await assetQuestService.getQuests(gameType.name, level);
      debugPrint('ReadingRemoteDataSourceImpl: Found ${localData.length} quests for ${gameType.name} at level $level');

      if (localData.isNotEmpty) {
        final List<ReadingQuestModel> quests = [];
        for (final q in localData) {
          try {
            quests.add(ReadingQuestModel.fromJson(q, q['id'] ?? ''));
          } catch (e) {
            debugPrint('Error parsing reading quest ${q['id']}: $e');
          }
        }
        if (quests.isNotEmpty) return quests;
      }

      // 2. Fallback to Firestore (Cloud)
      var doc = await firestore
          .collection('quests')
          .doc(gameType.name)
          .collection('levels')
          .doc(level.toString())
          .get();

      // Fallback to old structure for backward compatibility
      if (!doc.exists) {
        final docId = 'reading_$level';
        doc = await firestore.collection('reading_quests').doc(docId).get();
      }

      // Final fallback: get any quest from the collection
      if (!doc.exists) {
        final snapshot = await firestore
            .collection('quests')
            .doc(gameType.name)
            .collection('levels')
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          doc = snapshot.docs.first;
        }
      }

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;

        // Check if new structure with 'quests' array exists
        if (data.containsKey('quests') && data['quests'] is List) {
          final questsList = data['quests'] as List;
          return questsList.map((q) {
            final questMap = q as Map<String, dynamic>;
            questMap['id'] ??= doc.id;
            return ReadingQuestModel.fromJson(
              questMap,
              questMap['id'] ?? doc.id,
            );
          }).toList();
        }

        // Fallback for old single-quest structure
        data['id'] = doc.id;
        data['difficulty'] = level;
        data['subtype'] = gameType.name;
        return [ReadingQuestModel.fromJson(data, data['id'] ?? doc.id)];
      } else {
        throw ServerException("We're having trouble loading this level. Please check your internet or try again later.");
      }
    } catch (e) {
      debugPrint('Error in getReadingQuest: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
