import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/usecases/usecase.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

/// Persists a complete [UserEntity] snapshot to Firestore using a merge write.
///
/// This is a full-document update — every field in [UpdateUserParams.user]
/// is written. Prefer targeted use cases ([UpdateDisplayName],
/// [UpdateProfilePicture]) for single-field changes to minimize Firestore
/// write bandwidth, especially for the large [unlockedLevels] map.
///
/// Null fields in the entity explicitly overwrite corresponding server values
/// when using merge mode; this is intentional for fields that the caller wants
/// to clear (e.g., clearing a feature flag).
class UpdateUser extends UseCase<void, UpdateUserParams> {
  final UserRepository repository;

  const UpdateUser(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserParams params) =>
      repository.updateUser(params.user);
}

/// Immutable value object carrying the full [UserEntity] for [UpdateUser].
///
/// Equality is delegated to [UserEntity.operator==], which performs deep
/// collection comparison across all fields.
@immutable
class UpdateUserParams extends Equatable {
  final UserEntity user;

  const UpdateUserParams({required this.user});

  @override
  List<Object?> get props => [user];
}
