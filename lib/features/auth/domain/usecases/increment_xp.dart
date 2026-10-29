import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Parameters for the [IncrementXp] use case.
class IncrementXpParams extends Equatable {
  /// XP amount to add.
  final int amount;

  /// Creates an [IncrementXpParams] instance.
  const IncrementXpParams({required this.amount});

  @override
  List<Object?> get props => [amount];
}

/// Use case to atomically increment the user's XP using
/// `FieldValue.increment`, with `lastRewardTimestamp` to satisfy the
/// Firestore security-rules rate-limiter.
///
/// Replaces the old pattern of full-document `updateUser()` writes that
/// silently failed the anti-cheat guard and caused XP loss on restart.
class IncrementXp extends UseCase<void, IncrementXpParams> {
  /// Gamification repository instance.
  final GamificationRepository repository;

  /// Creates an [IncrementXp] use case instance.
  IncrementXp(this.repository);

  @override
  Future<Either<Failure, void>> call(IncrementXpParams params) async {
    return await repository.incrementXp(amount: params.amount);
  }
}

