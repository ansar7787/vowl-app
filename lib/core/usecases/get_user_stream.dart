import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// StreamUseCase contract
// ---------------------------------------------------------------------------

/// Abstract base for parameterless stream-based use cases.
///
/// Stream use cases cannot conform to the standard [UseCase<R, P>] contract
/// because they emit a continuous sequence of values rather than a single
/// [Future<Either<Failure, R>>]. This base class mirrors the [UseCase]
/// convention while making the continuous-emission intent explicit.
///
/// ### Usage
/// ```dart
/// class WatchSomething extends StreamUseCase<SomeEntity> {
///   WatchSomething(this.repository);
///   final SomeRepository repository;
///   @override
///   Stream<SomeEntity?> call() => repository.someStream;
/// }
/// ```
///
/// Consider promoting this class to `core/usecases/stream_use_case.dart` as
/// more stream-based use cases are added to the codebase.
abstract class StreamUseCase<T> {
  const StreamUseCase();

  /// Returns the underlying [Stream<T>].
  Stream<T> call();
}

// ---------------------------------------------------------------------------
// GetUserStream
// ---------------------------------------------------------------------------

/// Exposes the real-time [UserEntity] broadcast stream from [AuthRepository].
///
/// Emits the current [UserEntity] immediately on subscription and then on
/// every Firebase Auth state change or Firestore profile update. Emits [null]
/// when no user is signed in or when a sign-out is in progress.
///
/// ### Lifecycle
/// The stream is backed by a long-lived broadcast [StreamController] in
/// [AuthRepositoryImpl]. BLoCs subscribing to this stream must cancel their
/// [StreamSubscription] in their [close] method to prevent memory leaks.
///
/// ### Example (in a BLoC)
/// ```dart
/// _subscription = getUserStream().listen(
///   (user) => add(AuthUserChanged(user)),
///   onError: (e) => add(AuthErrorOccurred(e)),
/// );
/// ```
class GetUserStream extends StreamUseCase<UserEntity?> {
  final AuthRepository repository;

  const GetUserStream(this.repository);

  @override
  Stream<UserEntity?> call() => repository.user;
}
