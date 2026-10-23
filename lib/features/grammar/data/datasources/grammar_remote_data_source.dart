import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/services/asset_quest_service.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../models/grammar_quest_model.dart';

/// Contract defining remote and local data operations for grammar quests.
abstract class GrammarRemoteDataSource {
  /// Fetches a list of [GrammarQuestModel] for the specified [gameType] and [level].
  Future<List<GrammarQuestModel>> getGrammarQuest({
    required GameSubtype gameType,
    required int level,
  });

  /// Preloads a batch of grammar quests in the background for [gameType] near [level].
  Future<void> preloadBatch({
    required GameSubtype gameType,
    required int level,
  });
}

/// Production implementation of [GrammarRemoteDataSource] utilizing local asset files with [FirebaseFirestore] fallback.
class GrammarRemoteDataSourceImpl implements GrammarRemoteDataSource {
  /// Firestore client used as cloud fallback.
  final FirebaseFirestore firestore;

  /// Asset quest service used as primary offline source.
  final AssetQuestService assetQuestService;

  /// Creates a [GrammarRemoteDataSourceImpl] with [firestore] and [assetQuestService].
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
        return localData.map((q) {
          final questMap = Map<String, dynamic>.from(q as Map);
          return GrammarQuestModel.fromJson(
            questMap,
            (questMap['id'] ?? '').toString(),
          );
        }).toList();
      }

      // 2. Fallback to Firestore (Cloud) - Only if not found in assets
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
        final data = Map<String, dynamic>.from(doc.data()!);

        // Multi-question support
        if (data.containsKey('quests') && data['quests'] is List) {
          final questsList = data['quests'] as List;
          return questsList.map((q) {
            final questMap = Map<String, dynamic>.from(q as Map);
            questMap['id'] ??= doc.id;
            questMap['subtype'] = gameType.name;
            questMap['difficulty'] ??= level;
            return GrammarQuestModel.fromJson(
              questMap,
              (questMap['id'] ?? doc.id).toString(),
            );
          }).toList();
        }

        // Single quest fallback
        data['id'] = doc.id;
        data['difficulty'] = level;
        data['subtype'] = gameType.name;
        return [
          GrammarQuestModel.fromJson(data, (data['id'] ?? doc.id).toString()),
        ];
      } else {
        throw ServerException('Level $level not found for ${gameType.name}');
      }
    } on FirebaseException catch (e) {
      throw ServerException(
        e.message ?? 'Firestore database error occurred.',
        e.code,
        null,
        e.stackTrace,
      );
    } on ServerException {
      rethrow;
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
