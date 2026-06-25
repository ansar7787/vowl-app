import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

/// Updates the user's display name in both Firebase Auth and Firestore
/// atomically via [Future.wait].
///
/// The updated name is broadcast via [GetUserStream] after Firestore confirms
/// the write. Trimming or validating [displayName] (e.g., minimum length)
/// is the responsibility of the presentation/BLoC layer before calling this.
class UpdateDisplayName extends UseCase<void, String> {
  final UserRepository repository;

  const UpdateDisplayName(this.repository);

  @override
  Future<Either<Failure, void>> call(String displayName) =>
      repository.updateDisplayName(displayName);
}
