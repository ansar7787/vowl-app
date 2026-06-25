import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Sets the currently equipped Kids Zone accessory to [accessoryId].
///
/// Pass [null] to unequip the active accessory without selecting a replacement.
/// The write is a simple field update — no coin deduction occurs here; see
/// [BuyKidsAccessory] for the purchase flow.
class EquipKidsAccessory extends UseCase<void, String?> {
  final ShopRepository repository;

  const EquipKidsAccessory(this.repository);

  @override
  Future<Either<Failure, void>> call(String? accessoryId) =>
      repository.equipKidsAccessory(accessoryId);
}
