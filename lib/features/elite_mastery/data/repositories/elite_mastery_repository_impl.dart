import 'dart:developer' as dev;

import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/exceptions.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

import '../../domain/entities/elite_mastery_quest.dart';
import '../../domain/repositories/elite_mastery_repository.dart';

import '../datasources/elite_mastery_data_source.dart';

class EliteMasteryRepositoryImpl implements EliteMasteryRepository {
  final EliteMasteryDataSource dataSource;

  EliteMasteryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<EliteMasteryQuest>>> getEliteMasteryQuests({
    required GameSubtype gameType,
    required int level,
  }) async {
    try {
      final quests = await dataSource.getQuests(
        gameType: gameType.name,
        level: level,
      );
      return Right(quests);
    } on ServerException catch (e) {
      return Left(
        ServerFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
          details: e.details,
        ),
      );
    } catch (e, stackTrace) {
      // `e.toString()` previously flowed straight into the failure message
      // shown on screen — class names, raw exception text, sometimes a
      // platform-channel error string. Log it for diagnostics instead and
      // return a clean, generic, user-safe message.
      dev.log(
        'Unexpected error fetching Elite Mastery quests',
        name: 'EliteMasteryRepositoryImpl',
        error: e,
        stackTrace: stackTrace,
      );
      return Left(ServerFailure('Something went wrong. Please try again.'));
    }
  }
}
