import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/gamification_repository.dart';

class AddGoldenKeyParams extends Equatable {
  final int amount;

  const AddGoldenKeyParams({
    required this.amount,
  });

  @override
  List<Object?> get props => [amount];
}

class AddGoldenKey implements UseCase<void, AddGoldenKeyParams> {
  final GamificationRepository repository;

  AddGoldenKey(this.repository);

  @override
  Future<Either<Failure, void>> call(AddGoldenKeyParams params) async {
    return await repository.addGoldenKey(
      amount: params.amount,
    );
  }
}
