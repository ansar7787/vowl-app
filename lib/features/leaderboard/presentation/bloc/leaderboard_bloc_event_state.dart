import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

/// Base event class for the [LeaderboardBloc].
abstract class LeaderboardEvent extends Equatable {
  const LeaderboardEvent();

  @override
  List<Object?> get props => [];
}

/// Triggers a leaderboard fetch. An optional [completer] allows callers (e.g.
/// RefreshIndicator) to await the round-trip and dismiss their loading UI
/// as soon as the BLoC emits a new state.
///
/// NOTE: [completer] is intentionally excluded from [props]. Because BLoC does
/// NOT deduplicate events (every event is enqueued regardless of equality),
/// including it would add no runtime benefit and could confuse equality-based
/// testing assertions.
class LoadLeaderboard extends LeaderboardEvent {
  final Completer<void>? completer;
  final bool isKids;

  const LoadLeaderboard({this.completer, this.isKids = false});

  @override
  List<Object?> get props => [isKids];
}

// ---------------------------------------------------------------------------
// States
// ---------------------------------------------------------------------------

/// Base state class for the [LeaderboardBloc].
abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

/// Initial idle state before leaderboard ranks have been queried.
class LeaderboardInitial extends LeaderboardState {
  /// Creates a [LeaderboardInitial] state.
  const LeaderboardInitial();
}

/// Loading state indicating an in-flight leaderboard network query.
class LeaderboardLoading extends LeaderboardState {
  /// Creates a [LeaderboardLoading] state.
  const LeaderboardLoading();
}

/// Loaded state containing ranked players and timestamp metadata.
class LeaderboardLoaded extends LeaderboardState {
  /// The ranked list of users.
  final List<UserEntity> users;

  /// The timestamp of the last successful rank cache update.
  final DateTime lastUpdated;

  /// Whether this ranking represents the young learners leaderboard.
  final bool isKids;

  /// Creates a [LeaderboardLoaded] state.
  const LeaderboardLoaded(this.users, this.lastUpdated, {this.isKids = false});

  @override
  List<Object?> get props => [users, lastUpdated, isKids];
}

/// Failure state containing a diagnostic error message.
class LeaderboardError extends LeaderboardState {
  /// The diagnostic failure or network error message.
  final String message;

  /// Creates a [LeaderboardError] state.
  const LeaderboardError(this.message);

  @override
  List<Object?> get props => [message];
}
