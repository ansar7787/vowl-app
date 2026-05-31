import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

class UpdateKidsMascot extends UseCase<void, String> {
  final ShopRepository repository;

  UpdateKidsMascot(this.repository);

  @override
  Future<Either<Failure, void>> call(String mascotId) async {
    return await repository.updateKidsMascot(mascotId);
  }
}
