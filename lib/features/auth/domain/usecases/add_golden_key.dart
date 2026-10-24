import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

/// Parameters for the [AddGoldenKey] use case.
class AddGoldenKeyParams extends Equatable {
  /// Number of keys to add.
  final int amount;

  /// Creates an [AddGoldenKeyParams] instance.
  const AddGoldenKeyParams({required this.amount});

  @override
  List<Object?> get props => [amount];
}

/// Use case to credit golden keys to the user account.
class AddGoldenKey extends UseCase<void, AddGoldenKeyParams> {
  /// Gamification repository instance.
  final GamificationRepository repository;

  /// Creates an [AddGoldenKey] use case instance.
  AddGoldenKey(this.repository);

  @override
  Future<Either<Failure, void>> call(AddGoldenKeyParams params) async {
    return await repository.addGoldenKey(amount: params.amount);
  }
}
