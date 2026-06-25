import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

/// Uploads a new profile picture from [filePath] to Firebase Storage,
/// then updates [photoUrl] in both Firebase Auth and Firestore.
///
/// [filePath] must be an absolute path to a locally accessible file (e.g., a
/// path returned by an image-picker plugin). The existing file at
/// `profile_pics/<uid>.jpg` in Storage is overwritten on success.
///
/// Returns the public download URL as the [Right] value on success so the
/// presentation layer can update the UI immediately without waiting for the
/// [GetUserStream] to re-emit.
class UpdateProfilePicture extends UseCase<String, String> {
  final UserRepository repository;

  const UpdateProfilePicture(this.repository);

  @override
  Future<Either<Failure, String>> call(String filePath) =>
      repository.updateProfilePicture(filePath);
}
