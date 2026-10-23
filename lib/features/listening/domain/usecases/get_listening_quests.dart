import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/listening_quest.dart';
import '../repositories/listening_repository.dart';

/// Parameters for loading listening quests.
class GetListeningQuestsParams extends Equatable {
  /// Listening subgame variant identifier.
  final GameSubtype gameType;

  /// Target progression difficulty level.
  final int level;

  /// Creates a [GetListeningQuestsParams] container.
  const GetListeningQuestsParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

/// Use case for retrieving auditory comprehension quests.
class GetListeningQuests
    implements UseCase<List<ListeningQuest>, GetListeningQuestsParams> {
  /// Repository providing quest access.
  final ListeningRepository repository;

  /// Creates a [GetListeningQuests] use case with [repository].
  const GetListeningQuests(this.repository);

  @override
  Future<Either<Failure, List<ListeningQuest>>> call(
    GetListeningQuestsParams params,
  ) {
    return repository.getListeningQuests(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
