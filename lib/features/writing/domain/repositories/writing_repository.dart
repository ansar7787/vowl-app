import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';

abstract class WritingRepository {
  Future<Either<Failure, List<WritingQuest>>> getWritingQuest({
    required GameSubtype gameType,
    required int level,
  });
}
