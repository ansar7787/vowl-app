import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/domain/repositories/kids_repository.dart';

class GetKidsQuests {
  final KidsRepository repository;

  GetKidsQuests(this.repository);

  Future<Either<Failure, List<KidsQuest>>> call(
    String gameType,
    int level,
  ) async {
    return await repository.getQuestsByLevel(gameType, level);
  }
}
