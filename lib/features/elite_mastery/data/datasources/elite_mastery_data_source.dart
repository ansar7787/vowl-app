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

      // FIX (critical): previously a single `.map(...).toList()` — if *any
      // one* quest entry across the whole curriculum failed to parse (e.g.
      // one field with an unexpected type in one of the 20 curriculum
      // files), the exception propagated out of the whole batch and the
      // *entire level* — all of its other, perfectly valid quests — failed
      // to load. At the scale this app is built for (200 levels / 600
      // questions, authored across many files), a single content typo
      // should never be able to take down an entire level for every
      // player. Parsing each quest individually and skipping only the
      // one(s) that fail keeps the rest of the level playable.
      final quests = <EliteMasteryQuestModel>[];
      for (final json in questsData) {
        try {
          quests.add(EliteMasteryQuestModel.fromJson(json));
        } catch (e, stackTrace) {
          dev.log(
            'Skipping unparsable quest in $gameType level $level',
            name: 'EliteMasteryDataSource',
            error: e,
            stackTrace: stackTrace,
          );
        }
      }

      if (quests.isEmpty) {
        // Whether the source had no entries for this level, or every entry
        // in it failed to parse, the outcome is the same: no playable
        // content. Surface it as an explicit failure rather than letting an
        // empty list reach the BLoC/UI, where there is no valid quest to
        // show.
        throw ServerException(
          'We couldn\'t load this level right now. Please try again.',
          'PARSE_ERROR',
        );
      }

      return quests;
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
