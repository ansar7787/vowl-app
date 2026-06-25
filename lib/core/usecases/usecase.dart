import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:vowl/core/error/failures.dart';

/// Base contract for all domain use cases.
///
/// ### Type parameters
/// - [T] — the success type returned on the Right side.
/// - [Params] — the input parameter type. Use [NoParams] for parameter-less calls.
///
/// ### Usage
/// ```dart
/// class GetLeaderboard extends UseCase<LeaderboardResult, NoParams> {
///   @override
///   Future<Either<Failure, LeaderboardResult>> call(NoParams params) { ... }
/// }
/// ```
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Sentinel parameter type for use cases that require no inputs.
///
/// Extend [Equatable] so that `NoParams() == NoParams()` returns `true`,
/// enabling correct deduplication in testing frameworks.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
