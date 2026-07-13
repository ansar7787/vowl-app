import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Deducts [cost] coins from the user's balance and grants one streak-freeze
/// buffer item.
///
/// A streak freeze prevents the user's streak from resetting on a day they
/// miss a lesson, consuming one freeze automatically at midnight.
///
/// Returns [AuthFailure('insufficient-coins')] when the balance is
/// insufficient. Runs atomically inside a Firestore transaction.
class PurchaseStreakFreeze extends UseCase<void, int> {
  final GamificationRepository repository;

  const PurchaseStreakFreeze(this.repository);

  @override
  Future<Either<Failure, void>> call(int cost) =>
      repository.purchaseStreakFreeze(cost);
}
