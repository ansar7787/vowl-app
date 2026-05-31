import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

class EquipKidsAccessory extends UseCase<void, String?> {
  final ShopRepository repository;

  EquipKidsAccessory(this.repository);

  @override
  Future<Either<Failure, void>> call(String? accessoryId) async {
    return await repository.equipKidsAccessory(accessoryId);
  }
}
