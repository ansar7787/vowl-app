import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/listening_quest.dart';
import '../repositories/listening_repository.dart';

class GetListeningQuestsParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetListeningQuestsParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class GetListeningQuests
    implements UseCase<List<ListeningQuest>, GetListeningQuestsParams> {
  final ListeningRepository repository;

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
