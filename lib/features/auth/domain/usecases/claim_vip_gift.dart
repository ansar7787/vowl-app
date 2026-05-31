import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

class ClaimVipGift extends UseCase<void, NoParams> {
  final UserRepository repository;

  ClaimVipGift(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.claimVipGift();
  }
}
