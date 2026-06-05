import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/error/exceptions.dart';
import '../models/accent_quest_model.dart';
import '../../../../core/domain/entities/game_quest.dart';

abstract class AccentDataSource {
  Future<List<AccentQuestModel>> getAccentQuest({
    required GameSubtype gameType,
    required int level,
  });

  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  });

  Future<void> clearQuestCache();
}

class AccentDataSourceImpl implements AccentDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  AccentDataSourceImpl({
    required this.firestore,
    required this.assetQuestService,
  });

  @override
  Future<List<AccentQuestModel>> getAccentQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      // 1. Try to load from Local Assets (Priority)
      final localData = await assetQuestService.getQuests(gameType.name, level);
      if (localData.isNotEmpty) {
        return localData.map((q) {
          final questMap = Map<String, dynamic>.from(q);
          return AccentQuestModel.fromJson(questMap, questMap['id']?.toString() ?? '');
        }).toList();
      }

      // 2. Fallback to Firestore
      final doc = await firestore
          .collection('quests')
          .doc(gameType.name)
          .collection('levels')
          .doc(level.toString())
          .get();

      if (doc.exists && doc.data() != null) {
        // Clone Firestore map to prevent unmodifiable map mutation crash
        final data = Map<String, dynamic>.from(doc.data()!);
        if (data.containsKey('quests') && data['quests'] is List) {
          final questsList = data['quests'] as List;
          return questsList.map((q) {
            final questMap = Map<String, dynamic>.from(q as Map);
            questMap['subtype'] = gameType.name;
            return AccentQuestModel.fromJson(questMap, doc.id);
          }).toList();
        }
        data['subtype'] = gameType.name;
        return [AccentQuestModel.fromJson(data, doc.id)];
      } else {
        throw ServerException('Level $level not found for ${gameType.name}');
      }
    } on FirebaseException catch (e) {
      throw ServerException(e.message ?? 'Firestore operation failed', e.code);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> preloadNextBatch({
    required GameSubtype gameType,
    required int currentLevel,
  }) async {
    try {
      // Determine the next batch level
      // Batch size is 10, so if level is 1-10 (batch 1), next batch starts at 11
      final nextBatchStart = (((currentLevel - 1) ~/ 10) + 1) * 10 + 1;
      if (nextBatchStart <= 200) {
        await assetQuestService.preloadBatch(gameType.name, nextBatchStart);
      }
    } catch (e) {
      // Background operation fail-safe: suppress preload errors to protect calling isolate
    }
  }

  @override
  Future<void> clearQuestCache() async {
    try {
      assetQuestService.clearCache();
    } catch (_) {
      // Background operation fail-safe: suppress cache clearing errors
    }
  }
}
