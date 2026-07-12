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
            final questMap = Map<String, dynamic>.from(q);
            quests.add(
              SpeakingQuestModel.fromJson(
                questMap,
                questMap['id']?.toString() ?? '',
              ),
            );
          } catch (e, stack) {
            debugPrint('Error parsing speaking quest from local assets: $e');
            debugPrint(stack.toString());
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
        final questsObj = data['quests'];
        if (questsObj is List) {
          final List<SpeakingQuestModel> results = [];
          for (final q in questsObj) {
            if (q is Map) {
              final questMap = Map<String, dynamic>.from(q);
              questMap['id'] ??= doc.id;
              questMap['subtype'] = gameType.name;
              questMap['difficulty'] ??= level;
              try {
                results.add(
                  SpeakingQuestModel.fromJson(
                    questMap,
                    questMap['id']?.toString() ?? doc.id,
                  ),
                );
              } catch (e, stack) {
                debugPrint(
                  'Error parsing speaking quest item from Firestore list: $e',
                );
                debugPrint(stack.toString());
              }
            }
          }
          if (results.isNotEmpty) return results;
        }

        // Single quest fallback
        final questMap = Map<String, dynamic>.from(data);
        questMap['id'] = doc.id;
        questMap['difficulty'] = level;
        questMap['subtype'] = gameType.name;
        return [
          SpeakingQuestModel.fromJson(
            questMap,
            questMap['id']?.toString() ?? doc.id,
          ),
        ];
      } else {
        throw const ServerException(
          "We're having trouble loading this speaking quest. Please check your microphone or try again.",
          'DOC_NOT_FOUND',
        );
      }
    } on FirebaseException catch (e, stack) {
      debugPrint('Firestore error in getSpeakingQuest: $e');
      debugPrint(stack.toString());
      throw ServerException(
        e.message ?? 'Firestore database query failed.',
        e.code,
        null,
        e,
      );
    } catch (e, stack) {
      debugPrint('Unexpected error in getSpeakingQuest: $e');
      debugPrint(stack.toString());
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
