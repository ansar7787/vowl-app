import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class UseWritingHint {
  final AuthRepository repository;

  UseWritingHint(this.repository);

  Future<bool> call() async {
    final result = await repository.useHint();
    return result.isRight();
  }
}
