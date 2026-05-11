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

  EliteMasteryDataSourceImpl({required this.assetQuestService});

  @override
  Future<List<EliteMasteryQuestModel>> getQuests({
    required String gameType,
    required int level,
  }) async {
    final questsData = await assetQuestService.getQuests(gameType, level);
    return questsData.map((json) => EliteMasteryQuestModel.fromJson(json)).toList();
  }
}
