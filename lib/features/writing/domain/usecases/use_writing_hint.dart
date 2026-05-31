import 'package:vowl/features/auth/domain/repositories/shop_repository.dart';

class UseWritingHint {
  final ShopRepository repository;

  UseWritingHint(this.repository);

  Future<bool> call() async {
    final result = await repository.useHint();
    return result.isRight();
  }
}
