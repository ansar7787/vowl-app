import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/domain/repositories/reading_repository.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart'; // For QuestParams

class GetReadingQuest implements UseCase<List<ReadingQuest>, QuestParams> {
  final ReadingRepository repository;

  GetReadingQuest(this.repository);

  @override
  Future<Either<Failure, List<ReadingQuest>>> call(QuestParams params) async {
    return await repository.getReadingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
