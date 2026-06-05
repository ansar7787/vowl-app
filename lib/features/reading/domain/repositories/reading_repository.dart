import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../entities/reading_quest.dart';

abstract class ReadingRepository {
  Future<Either<Failure, List<ReadingQuest>>> getReadingQuest({
    required GameSubtype gameType,
    required int level,
  });
}
