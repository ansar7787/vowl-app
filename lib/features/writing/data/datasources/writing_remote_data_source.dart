import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:voxai_quest/core/data/services/asset_quest_service.dart';
import 'package:voxai_quest/core/error/exceptions.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/features/writing/data/models/writing_quest_model.dart';

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

      // 1. Try Local Assets first
      final String assetPath =
          'assets/curriculum/writing/${typeString}_1_10.json';
      try {
        final String jsonString = await rootBundle.loadString(assetPath);
        final List<dynamic> jsonList = json.decode(jsonString);

        // Filter by level (day)
        final levelData = jsonList.firstWhere(
          (item) => item['day'] == level,
          orElse: () => null,
        );

        if (levelData != null && levelData['quests'] != null) {
          return (levelData['quests'] as List)
              .map((q) => WritingQuestModel.fromJson(q, q['id'] ?? ''))
              .toList();
        }
      } catch (e) {
        debugPrint(
          'Local asset not found or error for $typeString level $level: $e',
        );
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

      throw ServerException('No quests found for $typeString level $level');
    } catch (e) {
      debugPrint('Error in getWritingQuest: $e');
      throw ServerException(e.toString());
    }
  }
}
