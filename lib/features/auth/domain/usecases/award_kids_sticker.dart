import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Appends [stickerId] to the authenticated user's [kidsStickers] collection.
///
/// Idempotent — awarding a sticker the user already owns produces no change.
class AwardKidsSticker extends UseCase<void, String> {
  final ShopRepository repository;

  AwardKidsSticker(this.repository);

  @override
  Future<Either<Failure, void>> call(String stickerId) =>
      repository.awardKidsSticker(stickerId);
}
