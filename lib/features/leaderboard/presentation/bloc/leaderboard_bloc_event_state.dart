import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

// ---------------------------------------------------------------------------
// Events
// ---------------------------------------------------------------------------

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

abstract class LeaderboardState extends Equatable {
  const LeaderboardState();

  @override
  List<Object?> get props => [];
}

class LeaderboardInitial extends LeaderboardState {
  const LeaderboardInitial();
}

class LeaderboardLoading extends LeaderboardState {
  const LeaderboardLoading();
}

class LeaderboardLoaded extends LeaderboardState {
  final List<UserEntity> users;
  final DateTime lastUpdated;
  final bool isKids;

  const LeaderboardLoaded(this.users, this.lastUpdated, {this.isKids = false});

  @override
  List<Object?> get props => [users, lastUpdated, isKids];
}

class LeaderboardError extends LeaderboardState {
  final String message;

  const LeaderboardError(this.message);

  @override
  List<Object?> get props => [message];
}
