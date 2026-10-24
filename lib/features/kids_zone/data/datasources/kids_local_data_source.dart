import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/features/kids_zone/data/models/kids_quest_model.dart';

/// Local asset data source contract for loading Kids Zone quests from bundled JSON files.
abstract class KidsLocalDataSource {
  /// Retrieves kids quests for a given [gameType] and [level] from bundled asset files.
  Future<List<KidsQuestModel>> getQuestsByLevel(String gameType, int level);
}

/// Default implementation of [KidsLocalDataSource] reading from root asset bundles.
class KidsLocalDataSourceImpl implements KidsLocalDataSource {
  /// Creates a [KidsLocalDataSourceImpl] instance.
  const KidsLocalDataSourceImpl();

  @override
  Future<List<KidsQuestModel>> getQuestsByLevel(
    String gameType,
    int level,
  ) async {
    final maxLevels = CurriculumManifest.getKidsLevels(gameType);
    if (level > maxLevels || level < 1) {
      return [];
    }

    try {
      // Calculate batch (10 levels per batch)
      final batchIndex = ((level - 1) / 10).floor() + 1;

      // Use the naming convention: [gameType]_batch_[batchIndex].json
      final path =
          'assets/curriculum/kids/$gameType/${gameType}_batch_$batchIndex.json';

      final String response = await rootBundle.loadString(path);
      final List<dynamic> data = json.decode(response);

      // Find the specific level in the batch
      final levelData = data.firstWhere(
        (item) => item['level'] == level,
        orElse: () => null,
      );

      if (levelData != null) {
        return (levelData['quests'] as List)
            .map((q) => KidsQuestModel.fromJson(q))
            .toList();
      }

      return [];
    } catch (e) {
      di.sl<AppLogger>().warning("KIDS_LOCAL_ERROR: $e", tag: 'KidsZone');
      return [];
    }
  }
}
