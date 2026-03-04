import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voxai_quest/core/data/services/asset_quest_service.dart';
import 'package:voxai_quest/core/error/exceptions.dart';
import 'package:voxai_quest/core/domain/entities/game_quest.dart';
import 'package:voxai_quest/features/grammar/data/models/grammar_quest_model.dart';

abstract class GrammarRemoteDataSource {
  Future<List<GrammarQuestModel>> getGrammarQuest({
    required GameSubtype gameType,
    required int level,
  });

  Future<void> preloadBatch({
    required GameSubtype gameType,
    required int level,
  });
}

class GrammarRemoteDataSourceImpl implements GrammarRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  GrammarRemoteDataSourceImpl(this.firestore, this.assetQuestService);

  @override
  Future<List<GrammarQuestModel>> getGrammarQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      // 1. Try to load from Local Assets (Free & Fast)
      final localData = await assetQuestService.getQuests(gameType.name, level);
      if (localData.isNotEmpty) {
        return localData
            .map((q) => GrammarQuestModel.fromJson(q, q['id'] ?? ''))
            .toList();
      }

      // 2. Fallback to Firestore (Cloud) - Only if not found in assets
      // This part remains as is for cloud backup
      var doc = await firestore
          .collection('quests')
          .doc(gameType.name)
          .collection('levels')
          .doc(level.toString())
          .get();

      // Fallback to old structure for backward compatibility
      if (!doc.exists) {
        final docId = 'grammar_$level';
        doc = await firestore.collection('grammar_quests').doc(docId).get();
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
            return GrammarQuestModel.fromJson(
              questMap,
              questMap['id'] ?? doc.id,
            );
          }).toList();
        }

        // Single quest fallback
        data['id'] = doc.id;
        data['difficulty'] = level;
        data['subtype'] = gameType.name;
        return [GrammarQuestModel.fromJson(data, data['id'] ?? doc.id)];
      } else {
        throw ServerException();
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> preloadBatch({
    required GameSubtype gameType,
    required int level,
  }) async {
    await assetQuestService.preloadBatch(gameType.name, level);
  }
}
