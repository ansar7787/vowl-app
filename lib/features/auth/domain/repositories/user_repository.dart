import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Domain contract for user profile management and VIP reward operations.
abstract class UserRepository {
  /// Persists a complete [UserEntity] snapshot to Firestore using a merge
  /// write, so existing server-side fields not present in [user] are preserved.
  Future<Either<Failure, void>> updateUser(UserEntity user);

  /// Updates only the [displayName] field in both Firebase Auth and Firestore.
  Future<Either<Failure, void>> updateDisplayName(String displayName);

  /// Uploads a new profile picture from [filePath] to Firebase Storage and
  /// updates [photoUrl] in both Firebase Auth and Firestore.
  ///
  /// Returns the public download URL on success.
  Future<Either<Failure, String>> updateProfilePicture(String filePath);

  /// Claims today's VIP daily gift (100 coins). Enforces a once-per-calendar-day
  /// limit and validates premium status inside a Firestore transaction.
  Future<Either<Failure, void>> claimVipGift();
}
