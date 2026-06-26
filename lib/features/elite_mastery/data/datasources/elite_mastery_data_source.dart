import 'dart:developer' as dev;

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
      return questsData
          .map((json) => EliteMasteryQuestModel.fromJson(json))
          .toList();
    } catch (e, stackTrace) {
      if (e is ServerException) rethrow;
      // The previous version embedded `$e` (the raw exception, e.g. a
      // FormatException with its stack-trace-flavored message) directly
      // into the exception text that ultimately reaches `EliteMasteryError.message`
      // and is rendered verbatim on screen. Log the technical detail for
      // crash diagnostics instead, and surface only a clean, user-safe,
      // localization-ready message.
      dev.log(
        'Failed to parse Elite Mastery quests for $gameType level $level',
        name: 'EliteMasteryDataSource',
        error: e,
        stackTrace: stackTrace,
      );
      throw ServerException(
        'We couldn\'t load this level right now. Please try again.',
        'PARSE_ERROR',
      );
    }
  }
}
