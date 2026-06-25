import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Sets the user's active Kids Zone mascot to [mascotId].
///
/// This is a non-transactional field update — no coin deduction occurs (mascots
/// are unlocked through gameplay). The presentation layer should verify the
/// user owns [mascotId] before invoking this use case.
class UpdateKidsMascot extends UseCase<void, String> {
  final ShopRepository repository;

  const UpdateKidsMascot(this.repository);

  @override
  Future<Either<Failure, void>> call(String mascotId) =>
      repository.updateKidsMascot(mascotId);
}
