import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

abstract class ReadingRepository {
  Future<Either<Failure, List<ReadingQuest>>> getReadingQuest({
    required GameSubtype gameType,
    required int level,
  });
}
