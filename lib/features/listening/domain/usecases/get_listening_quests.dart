import 'package:dartz/dartz.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../entities/listening_quest.dart';
import '../repositories/listening_repository.dart';

class GetListeningQuests {
  final ListeningRepository repository;

  GetListeningQuests(this.repository);

  Future<Either<Failure, List<ListeningQuest>>> call(
    GameSubtype gameType,
    int level,
  ) async {
    return await repository.getListeningQuests(
      gameType: gameType,
      level: level,
    );
  }
}
