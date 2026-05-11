import 'package:dartz/dartz.dart';
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
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
