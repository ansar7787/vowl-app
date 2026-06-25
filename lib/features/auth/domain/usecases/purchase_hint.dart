import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Deducts [PurchaseHintParams.cost] from the user's coin balance and
/// increments [hintCount] by [PurchaseHintParams.hintAmount].
///
/// Runs inside a Firestore transaction, so the balance check and deduction
/// are atomic — concurrent purchases cannot cause the balance to go negative.
///
/// Returns [ServerFailure('Not enough coins')] when the user's current balance
/// is less than [PurchaseHintParams.cost].
class PurchaseHint extends UseCase<void, PurchaseHintParams> {
  final ShopRepository repository;

  const PurchaseHint(this.repository);

  @override
  Future<Either<Failure, void>> call(PurchaseHintParams params) =>
      repository.purchaseHint(params.cost, params.hintAmount);
}

/// Immutable value object carrying the purchase parameters for [PurchaseHint].
@immutable
class PurchaseHintParams extends Equatable {
  final int cost;
  final int hintAmount;

  const PurchaseHintParams({required this.cost, required this.hintAmount});

  @override
  List<Object?> get props => [cost, hintAmount];
}
