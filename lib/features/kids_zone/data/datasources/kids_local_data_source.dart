import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vowl/features/kids_zone/data/models/kids_quest_model.dart';

abstract class KidsLocalDataSource {
  Future<List<KidsQuestModel>> getQuestsByLevel(String gameType, int level);
}

class KidsLocalDataSourceImpl implements KidsLocalDataSource {
  @override
  Future<List<KidsQuestModel>> getQuestsByLevel(String gameType, int level) async {
    try {
      // Calculate batch (10 levels per batch)
      final batchIndex = ((level - 1) / 10).floor() + 1;
      
      // Use the new naming convention: [gameType]_batch_[batchIndex].json
      final path = 'assets/curriculum/kids/$gameType/${gameType}_batch_$batchIndex.json';
      
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
      debugPrint("KIDS_LOCAL_ERROR: $e");
      return [];
    }
  }
}
