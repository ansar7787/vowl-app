import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/listening/data/models/listening_quest_model.dart';

abstract class ListeningRemoteDataSource {
  Future<List<ListeningQuestModel>> getListeningQuest({
    required GameSubtype gameType,
    required int level,
  });
}

class ListeningRemoteDataSourceImpl implements ListeningRemoteDataSource {
  final FirebaseFirestore firestore;
  final AssetQuestService assetQuestService;

  ListeningRemoteDataSourceImpl({
    required this.firestore,
    required this.assetQuestService,
  });

  @override
  Future<List<ListeningQuestModel>> getListeningQuest({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      // 1. Try to load from Local Assets (Free & Fast)
      final localData = await assetQuestService.getQuests(gameType.name, level);
      if (localData.isNotEmpty) {
        return localData.map((q) {
          final questMap = q;
          return ListeningQuestModel.fromJson(questMap, questMap['id'] ?? '');
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
            final questMap = q as Map<String, dynamic>;
            questMap['id'] ??= doc.id;
            questMap['subtype'] = gameType.name;
            questMap['difficulty'] ??= level;
            return ListeningQuestModel.fromJson(
              questMap,
              questMap['id'] ?? doc.id,
            );
          }).toList();
        }
        return [ListeningQuestModel.fromJson(data, doc.id)];
      } else {
        throw Exception('Level $level not found for ${gameType.name}');
      }
    } catch (e) {
      // Return empty or throw based on preference, here we throw to let repository handle
      rethrow;
    }
  }
}
