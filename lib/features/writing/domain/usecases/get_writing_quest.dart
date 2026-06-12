import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/domain/repositories/writing_repository.dart';

class GetWritingQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetWritingQuestParams({required this.gameType, required this.level});

  @override
  List<Object?> get props => [gameType, level];
}

class GetWritingQuest implements UseCase<List<WritingQuest>, GetWritingQuestParams> {
  final WritingRepository repository;

  GetWritingQuest(this.repository);

  @override
  Future<Either<Failure, List<WritingQuest>>> call(GetWritingQuestParams params) async {
    return await repository.getWritingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
