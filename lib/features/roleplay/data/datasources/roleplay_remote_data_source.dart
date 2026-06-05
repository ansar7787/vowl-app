import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/features/roleplay/data/models/roleplay_quest_model.dart';

abstract class RoleplayRemoteDataSource {
  Future<List<RoleplayQuestModel>> getRoleplayQuest({
    required GameSubtype gameType,
    required int level,
  });

  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int level,
  });
}

class RoleplayRemoteDataSourceImpl implements RoleplayRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  RoleplayRemoteDataSourceImpl({
    required this.firestore,
    required this.assetQuestService,
  });

  @override
  Future<List<RoleplayQuestModel>> getRoleplayQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      // 1. Try to load from Local Assets (Free & Fast)
      final localData = await assetQuestService.getQuests(gameType.name, level);
      if (localData.isNotEmpty) {
        return localData.map((q) {
          final questMap = Map<String, dynamic>.from(q);
          return RoleplayQuestModel.fromJson(questMap, questMap['id'] ?? '');
        }).toList();
      }

      // 2. Fallback to Firestore (Cloud)
      final doc = await firestore
          .collection('quests')
          .doc(gameType.name)
          .collection('levels')
          .doc(level.toString())
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('quests') && data['quests'] is List) {
          final questsList = data['quests'] as List;
          return questsList.map((q) {
            final questMap = Map<String, dynamic>.from(q as Map);
            questMap['id'] ??= doc.id;
            questMap['subtype'] = gameType.name;
            questMap['difficulty'] ??= level;
            return RoleplayQuestModel.fromJson(
              questMap,
              questMap['id'] ?? doc.id,
            );
          }).toList();
        }
        final mutableData = Map<String, dynamic>.from(data);
        return [RoleplayQuestModel.fromJson(mutableData, doc.id)];
      } else {
        throw ServerException('Level $level not found for ${gameType.name}');
      }
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore database error',
        e.code,
        null,
        e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int level,
  }) async {
    await assetQuestService.preloadBatch(gameType.name, level);
  }
}
