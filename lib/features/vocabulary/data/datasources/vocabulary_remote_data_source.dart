import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/features/vocabulary/data/models/vocabulary_quest_model.dart';

/// Contract for remote and asset-backed retrieval of vocabulary quest models.
abstract class VocabularyRemoteDataSource {
  /// Fetches raw quest models for the specified [gameType] and difficulty [level].
  Future<List<VocabularyQuestModel>> getVocabularyQuests(
    String gameType,
    int level,
  );
}

/// Implementation of [VocabularyRemoteDataSource] supporting asset-first caching and Firestore fallbacks.
class VocabularyRemoteDataSourceImpl implements VocabularyRemoteDataSource {
  /// Firestore client instance for cloud retrieval.
  final FirebaseFirestore firestore;

  /// Local asset loader for bundled offline-first quests.
  final AssetQuestService assetQuestService;

  /// Creates a [VocabularyRemoteDataSourceImpl] with [firestore] and [assetQuestService].
  VocabularyRemoteDataSourceImpl(this.firestore, this.assetQuestService);

  @override
  Future<List<VocabularyQuestModel>> getVocabularyQuests(
    String gameType,
    int level,
  ) async {
    try {
      // 1. Try to load from Local Assets (Free, Instant & Offline-First)
      try {
        final localData = await assetQuestService.getQuests(gameType, level);
        if (localData.isNotEmpty) {
          // Preload next batch in background for seamless progression
          unawaited(assetQuestService.preloadBatch(gameType, level));

          return localData.asMap().entries.map((entry) {
            final json = entry.value;
            final index = entry.key;
            return VocabularyQuestModel.fromJson(
              json,
              '${gameType}_L${level}_$index',
            );
          }).toList();
        }
      } catch (assetError) {
        if (kDebugMode) {
          debugPrint(
            'VocabularyRemoteDataSource: Local asset fetch failed: $assetError',
          );
        }
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
    } catch (e, stackTrace) {
      if (kDebugMode) debugPrint('VocabularyRemoteDataSource Error: $e');
      if (kDebugMode) {
        debugPrint('Stacktrace: $stackTrace');
      }
      rethrow;
    }
  }
}
