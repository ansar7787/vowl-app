import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/domain/entities/game_quest.dart';
import '../repositories/elite_mastery_repository.dart';
import '../entities/elite_mastery_quest.dart';

/// Use case for retrieving elite mastery quests for a given game subtype and level.
class GetEliteMasteryQuests {
  /// Repository providing quest access.
  final EliteMasteryRepository repository;

  /// Creates a [GetEliteMasteryQuests] use case with [repository].
  const GetEliteMasteryQuests(this.repository);

  /// Executes the use case with specified [params].
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
/// Parameters for loading elite mastery quests.
class GetEliteMasteryQuestParams extends Equatable {
  /// Subtype variant of the challenge (e.g. speed spelling, idiom match).
  final GameSubtype gameType;

  /// Target progression difficulty level.
  final int level;

  /// Creates parameters with [gameType] and [level].
  const GetEliteMasteryQuestParams({
    required this.gameType,
    required this.level,
  });

  @override
  List<Object?> get props => [gameType, level];
}
