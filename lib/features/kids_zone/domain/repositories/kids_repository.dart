import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';

abstract class KidsRepository {
  Future<Either<Failure, List<KidsQuest>>> getQuestsByLevel(
    String gameType,
    int level,
  );
}
