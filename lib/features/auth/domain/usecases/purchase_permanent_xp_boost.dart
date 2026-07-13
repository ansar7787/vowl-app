import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Deducts [cost] coins and permanently enables the 10% XP boost
/// (`hasPermanentXPBoost`).
///
/// Silently succeeds with no charge if already enabled. Returns
/// [AuthFailure('insufficient-coins')] when the balance is insufficient.
/// Runs atomically inside a Firestore transaction — replaces
/// `ProgressionBloc._onPurchasePermanentXPBoost`'s previous client-side
/// implementation, flagged in that method's own doc comment as needing
/// exactly this.
class PurchasePermanentXPBoost extends UseCase<void, int> {
  final GamificationRepository repository;

  const PurchasePermanentXPBoost(this.repository);

  @override
  Future<Either<Failure, void>> call(int cost) =>
      repository.purchasePermanentXPBoost(cost);
}
