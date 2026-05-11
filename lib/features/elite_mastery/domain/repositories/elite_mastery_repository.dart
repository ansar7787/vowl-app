import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import '../entities/elite_mastery_quest.dart';

abstract class EliteMasteryRepository {
  Future<Either<Failure, List<EliteMasteryQuest>>> getEliteMasteryQuests({
    required GameSubtype gameType,
    required int level,
  });
}
