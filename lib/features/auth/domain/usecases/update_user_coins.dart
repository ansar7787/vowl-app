import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UpdateUserCoins implements UseCase<void, UpdateUserCoinsParams> {
  final AuthRepository repository;

  UpdateUserCoins(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserCoinsParams params) async {
    return await repository.updateUserCoins(
      params.amountChange,
      title: params.title,
      isEarned: params.isEarned,
    );
  }
}

class UpdateUserCoinsParams {
  final int amountChange;
  final String? title;
  final bool? isEarned;

  UpdateUserCoinsParams({
    required this.amountChange,
    this.title,
    this.isEarned,
  });
}
