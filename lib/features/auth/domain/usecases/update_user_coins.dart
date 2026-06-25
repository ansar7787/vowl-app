import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Adjusts the authenticated user's coin balance by [UpdateUserCoinsParams.amountChange]
/// inside an atomic Firestore transaction.
///
/// When [UpdateUserCoinsParams.title] is supplied, a corresponding coin-history
/// ledger entry is appended in the same transaction. When omitted, only the
/// balance is updated.
class UpdateUserCoins extends UseCase<void, UpdateUserCoinsParams> {
  final ShopRepository repository;

  const UpdateUserCoins(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserCoinsParams params) =>
      repository.updateUserCoins(
        params.amountChange,
        title: params.title,
        isEarned: params.isEarned,
      );
}

/// Immutable value object carrying the parameters for [UpdateUserCoins].
@immutable
class UpdateUserCoinsParams extends Equatable {
  /// Signed coin delta: positive = earn, negative = spend.
  final int amountChange;

  /// Optional label for the coin-history ledger entry.
  final String? title;

  /// Whether this change is an earned reward or a purchase deduction.
  /// Inferred from the sign of [amountChange] when [null].
  final bool? isEarned;

  const UpdateUserCoinsParams({
    required this.amountChange,
    this.title,
    this.isEarned,
  });

  @override
  List<Object?> get props => [amountChange, title, isEarned];
}
