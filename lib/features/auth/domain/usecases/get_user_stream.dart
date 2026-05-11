import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class GetUserStream {
  final AuthRepository repository;

  GetUserStream(this.repository);

  Stream<UserEntity?> call() {
    return repository.user;
  }
}
