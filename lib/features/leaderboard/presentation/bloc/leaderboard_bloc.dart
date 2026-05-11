import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/leaderboard/domain/repositories/leaderboard_repository.dart';
import 'package:vowl/features/leaderboard/presentation/bloc/leaderboard_bloc_event_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRepository repository;

  LeaderboardBloc({required this.repository}) : super(LeaderboardInitial()) {
    on<LoadLeaderboard>(_onLoadLeaderboard);
  }

  Future<void> _onLoadLeaderboard(
    LoadLeaderboard event,
    Emitter<LeaderboardState> emit,
  ) async {
    emit(LeaderboardLoading());
    final result = await repository.getTopUsers();
    result.fold((failure) => emit(LeaderboardError(failure.message)), (data) {
      // Sort: totalLevelsCompleted (desc) -> totalExp (desc) -> streak (desc) -> coins (desc)
      final sortedUsers = List<UserEntity>.from(data.users)
        ..sort((a, b) {
          final aLevels = a.totalLevelsCompleted;
          final bLevels = b.totalLevelsCompleted;
          if (bLevels != aLevels) return bLevels.compareTo(aLevels);
          if (b.totalExp != a.totalExp) return b.totalExp.compareTo(a.totalExp);
          if (b.currentStreak != a.currentStreak) {
            return b.currentStreak.compareTo(a.currentStreak);
          }
          return b.coins.compareTo(a.coins);
        });
      emit(LeaderboardLoaded(sortedUsers, data.lastUpdated));
    });
  }
}
