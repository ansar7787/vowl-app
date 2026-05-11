import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/elite_mastery_repository.dart';
import '../entities/elite_mastery_quest.dart';

class GetEliteMasteryQuests {
  final EliteMasteryRepository repository;

  GetEliteMasteryQuests(this.repository);

  Future<Either<Failure, List<EliteMasteryQuest>>> call(
    GetEliteMasteryQuestParams params,
  ) async {
    return await repository.getEliteMasteryQuests(
      gameType: params.gameType,
      level: params.level,
    );
  }
}

class GetEliteMasteryQuestParams {
  final GameSubtype gameType;
  final int level;

  const GetEliteMasteryQuestParams({required this.gameType, required this.level});
}
