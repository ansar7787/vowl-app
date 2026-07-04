import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/accent_repository.dart';
import '../entities/accent_quest.dart';

class GetAccentQuest {
  final AccentRepository repository;

  const GetAccentQuest(this.repository);

  Future<Either<Failure, List<AccentQuest>>> call(GetAccentQuestParams params) {
    return repository.getAccentQuests(
      gameType: params.gameType,
      level: params.level,
    );
  }
}

class GetAccentQuestParams {
  final GameSubtype gameType;
  final int level;

  const GetAccentQuestParams({required this.gameType, required this.level});
}
