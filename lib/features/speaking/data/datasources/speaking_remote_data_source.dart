import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/data/models/speaking_quest_model.dart';

abstract class SpeakingRemoteDataSource {
  Future<List<SpeakingQuestModel>> getSpeakingQuest({
    required GameSubtype gameType,
    required int level,
  });
}

class SpeakingRemoteDataSourceImpl implements SpeakingRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  SpeakingRemoteDataSourceImpl(this.firestore, this.assetQuestService);

  @override
  Future<List<SpeakingQuestModel>> getSpeakingQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      // 1. Try to load from Local Assets (Free & Fast)
      final localData = await assetQuestService.getQuests(gameType.name, level);
      if (localData.isNotEmpty) {
        final List<SpeakingQuestModel> quests = [];
        for (final q in localData) {
          try {
            quests.add(SpeakingQuestModel.fromJson(q, q['id'] ?? ''));
          } catch (e) {
            debugPrint('Error parsing speaking quest ${q['id']}: $e');
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
        final docId = 'speaking_$level';
        doc = await firestore.collection('speaking_quests').doc(docId).get();
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

        // Multi-question support
        if (data.containsKey('quests') && data['quests'] is List) {
          final questsList = data['quests'] as List;
          return questsList.map((q) {
            final questMap = q as Map<String, dynamic>;
            questMap['id'] ??= doc.id;
            questMap['subtype'] = gameType.name;
            questMap['difficulty'] ??= level;
            return SpeakingQuestModel.fromJson(
              questMap,
              questMap['id'] ?? doc.id,
            );
          }).toList();
        }

        // Single quest fallback
        data['id'] = doc.id;
        data['difficulty'] = level;
        data['subtype'] = gameType.name;
        return [SpeakingQuestModel.fromJson(data, data['id'] ?? doc.id)];
      } else {
        throw ServerException("We're having trouble loading this speaking quest. Please check your microphone or try again.");
      }
    } catch (e) {
      debugPrint('Error in getSpeakingQuest: $e');
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
