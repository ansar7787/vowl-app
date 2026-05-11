import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class ClaimVipGift extends UseCase<void, NoParams> {
  final AuthRepository repository;

  ClaimVipGift(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.claimVipGift();
  }
}
