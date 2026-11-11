import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/domain/utils/leaderboard_ranking_helper.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc_event_state.dart';

/// BLoC component managing leaderboard rankings,
/// background caching, and pull-to-refresh completers.
class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository repository;

  LeaderboardBloc({required this.repository})
    : super(const LeaderboardInitial()) {
    on<LoadLeaderboard>(_onLoadLeaderboard);
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    // Show shimmer only on first load; preserve data during pull-to-refresh.
    if (state is! LeaderboardLoaded) {
      emit(const LeaderboardLoading());
    }

    // FIX (CRITICAL-1): The completer MUST be completed inside a `finally`
    // block. Previously, any exception thrown before or inside result.fold()
    // would leave the completer dangling, freezing the RefreshIndicator
    // spinner indefinitely with no recovery path for the user.
    try {
      final result = await repository.getTopUsers();

      result.fold((failure) => emit(LeaderboardError(failure.message)), (data) {
        final sortedUsers = LeaderboardRankingHelper.sortWeekly(data.users);

        emit(
          LeaderboardLoaded(
            sortedUsers,
            data.lastUpdated,
          ),
        );
      });
    } finally {
      // Always complete — whether the fetch succeeded, failed with a Left,
      // or threw an uncaught exception. This guarantees the RefreshIndicator
      // dismisses and the user can retry.
      event.completer?.complete();
    }
  }
}
