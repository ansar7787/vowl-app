import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/data/services/asset_quest_service.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/exceptions.dart';
import '../models/listening_quest_model.dart';

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
          final questMap = Map<String, dynamic>.from(q as Map);
          return ListeningQuestModel.fromJson(questMap, (questMap['id'] ?? '').toString());
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
        final data = Map<String, dynamic>.from(doc.data()!);
        if (data.containsKey('quests') && data['quests'] is List) {
          final questsList = data['quests'] as List;
          return questsList.map((q) {
            final questMap = Map<String, dynamic>.from(q as Map);
            questMap['id'] ??= doc.id;
            questMap['subtype'] = gameType.name;
            questMap['difficulty'] ??= level;
            return ListeningQuestModel.fromJson(
              questMap,
              (questMap['id'] ?? doc.id).toString(),
            );
          }).toList();
        }
        data['id'] = doc.id;
        data['subtype'] = gameType.name;
        data['difficulty'] ??= level;
        return [ListeningQuestModel.fromJson(data, doc.id)];
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
}
