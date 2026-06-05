import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/reading_quest.dart';
import '../repositories/reading_repository.dart';
import 'package:vowl/features/speaking/domain/usecases/get_speaking_quest.dart'; // For QuestParams

class GetReadingQuest implements UseCase<List<ReadingQuest>, QuestParams> {
  final ReadingRepository repository;

  const GetReadingQuest(this.repository);

  @override
  Future<Either<Failure, List<ReadingQuest>>> call(QuestParams params) {
    return repository.getReadingQuest(
      gameType: params.gameType,
      level: params.level,
    );
  }
}
