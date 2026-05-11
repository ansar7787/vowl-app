import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class AwardKidsSticker extends UseCase<void, String> {
  final AuthRepository repository;

  AwardKidsSticker(this.repository);

  @override
  Future<Either<Failure, void>> call(String stickerId) async {
    return await repository.awardKidsSticker(stickerId);
  }
}
