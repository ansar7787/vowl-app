import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

/// Use case that consumes a writing hint token via the [ShopRepository].
class UseWritingHint {
  /// The backing shop repository.
  final ShopRepository repository;

  /// Creates a [UseWritingHint] use case.
  UseWritingHint(this.repository);

  /// Executes the hint consumption and returns whether it succeeded.
  Future<bool> call() async {
    final result = await repository.useHint();
    return result.isRight();
  }
}
