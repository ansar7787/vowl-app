import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/elite_mastery_repository.dart';
import '../entities/elite_mastery_quest.dart';

class GetEliteMasteryQuests {
  final EliteMasteryRepository repository;

  const GetEliteMasteryQuests(this.repository);

  Future<Either<Failure, List<EliteMasteryQuest>>> call(
    GetEliteMasteryQuestParams params,
  ) {
    return repository.getEliteMasteryQuests(
      gameType: params.gameType,
      level: params.level,
    );
  }
}

// FIX: previously a plain class with no value equality, unlike every
// event/state class elsewhere in this feature (all of which extend
// Equatable). Without it, two `GetEliteMasteryQuestParams` built with
// identical field values compare unequal (identity equality), which makes
// unit tests that construct an expected params object to compare against —
// a standard use-case testing pattern — awkward or unreliable.
class GetEliteMasteryQuestParams extends Equatable {
  final GameSubtype gameType;
  final int level;

  const GetEliteMasteryQuestParams({
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [gameType, level];
}
