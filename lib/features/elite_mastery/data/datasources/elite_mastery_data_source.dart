import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import '../models/elite_mastery_quest_model.dart';

abstract class EliteMasteryDataSource {
  Future<List<EliteMasteryQuestModel>> getQuests({
    required String gameType,
    required int level,
  });
}

class EliteMasteryDataSourceImpl implements EliteMasteryDataSource {
  final AssetQuestService assetQuestService;

  const EliteMasteryDataSourceImpl({required this.assetQuestService});

  @override
  Future<List<EliteMasteryQuestModel>> getQuests({
    required String gameType,
    required int level,
  }) async {
    try {
      final questsData = await assetQuestService.getQuests(gameType, level);
      return questsData.map((json) => EliteMasteryQuestModel.fromJson(json)).toList();
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to parse Elite Mastery quests: $e',
        'PARSE_ERROR',
      );
    }
  }
}
