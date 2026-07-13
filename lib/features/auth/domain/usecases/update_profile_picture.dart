import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

/// Uploads a new profile picture from [filePath] to Firebase Storage,
/// then updates [photoUrl] in both Firebase Auth and Firestore.
///
/// [filePath] must be an absolute path to a locally accessible file (e.g., a
/// path returned by an image-picker plugin). The existing Storage object at
/// `profile_pics/<uid>` — a stable, extension-less path so re-uploading a
/// different image format never orphans the previous object — is
/// overwritten on success. The `Content-Type` written to Storage is derived
/// from [filePath]'s actual extension rather than assumed to be JPEG (see
/// `UserRepositoryImpl.updateProfilePicture`).
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
