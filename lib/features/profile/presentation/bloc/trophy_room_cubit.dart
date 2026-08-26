import 'package:flutter_bloc/flutter_bloc.dart';

enum TrophyFilter { all, standard, legendary }

class TrophyRoomState {
  final List<String> allEarnedBadges;
  final List<String> filteredEarnedBadges;
  final List<String> filteredLockedBadges;
  final TrophyFilter currentFilter;
  final int totalPossibleBadges;

  const TrophyRoomState({
    required this.allEarnedBadges,
    required this.filteredEarnedBadges,
    required this.filteredLockedBadges,
    required this.currentFilter,
    required this.totalPossibleBadges,
  });

  factory TrophyRoomState.initial(List<String> earnedBadges) {
    return TrophyRoomState(
      allEarnedBadges: earnedBadges,
      filteredEarnedBadges: earnedBadges,
      filteredLockedBadges: _calculateLocked(earnedBadges, TrophyFilter.all),
      currentFilter: TrophyFilter.all,
      totalPossibleBadges: TrophyRoomCubit.allAppBadges.length,
    );
  }

  TrophyRoomState copyWith({
    List<String>? allEarnedBadges,
    List<String>? filteredEarnedBadges,
    List<String>? filteredLockedBadges,
    TrophyFilter? currentFilter,
    int? totalPossibleBadges,
  }) {
    return TrophyRoomState(
      allEarnedBadges: allEarnedBadges ?? this.allEarnedBadges,
      filteredEarnedBadges: filteredEarnedBadges ?? this.filteredEarnedBadges,
      filteredLockedBadges: filteredLockedBadges ?? this.filteredLockedBadges,
      currentFilter: currentFilter ?? this.currentFilter,
      totalPossibleBadges: totalPossibleBadges ?? this.totalPossibleBadges,
    );
  }

  static List<String> _calculateLocked(
    List<String> earned,
    TrophyFilter filter,
  ) {
    final unearned = TrophyRoomCubit.allAppBadges
        .where((b) => !earned.contains(b))
        .toList();
    if (filter == TrophyFilter.legendary) {
      return unearned.where((b) => TrophyRoomCubit.isLegendary(b)).toList();
    }
    if (filter == TrophyFilter.standard) {
      return unearned.where((b) => !TrophyRoomCubit.isLegendary(b)).toList();
    }
    return unearned;
  }
}

class TrophyRoomCubit extends Cubit<TrophyRoomState> {
  TrophyRoomCubit(List<String> initialBadges)
    : super(TrophyRoomState.initial(initialBadges));

  // The real master list of 40 possible achievements in VOWL
  static const List<String> allAppBadges = [
    // Standard Badges (30)
    'novice_speaking', 'scholar_speaking', 'expert_speaking',
    'novice_listening', 'scholar_listening', 'expert_listening',
    'novice_reading', 'scholar_reading', 'expert_reading',
    'novice_writing', 'scholar_writing', 'expert_writing',
    'novice_grammar', 'scholar_grammar', 'expert_grammar',
    'novice_vocabulary', 'scholar_vocabulary', 'expert_vocabulary',
    'novice_accent', 'scholar_accent', 'expert_accent',
    'novice_roleplay', 'scholar_roleplay', 'expert_roleplay',
    'novice_elitemastery', 'scholar_elitemastery', 'expert_elitemastery',
    'streak_7', 'streak_30', 'perfect_week',
    // Legendary Badges (10)
    'master_speaking', 'master_listening', 'master_reading',
    'master_writing', 'master_grammar', 'master_vocabulary',
    'master_accent', 'master_roleplay', 'master_elitemastery', 
    'streak_100',
  ];

  void updateFilter(TrophyFilter filter) {
    List<String> earnedFiltered;
    switch (filter) {
      case TrophyFilter.legendary:
        earnedFiltered = state.allEarnedBadges
            .where((b) => isLegendary(b))
            .toList();
        break;
      case TrophyFilter.standard:
        earnedFiltered = state.allEarnedBadges
            .where((b) => !isLegendary(b))
            .toList();
        break;
      case TrophyFilter.all:
        earnedFiltered = List.from(state.allEarnedBadges);
        break;
    }

    final lockedFiltered = TrophyRoomState._calculateLocked(
      state.allEarnedBadges,
      filter,
    );

    emit(
      state.copyWith(
        currentFilter: filter,
        filteredEarnedBadges: earnedFiltered,
        filteredLockedBadges: lockedFiltered,
      ),
    );
  }

  static bool isLegendary(String badgeId) {
    return badgeId.contains('master') ||
        badgeId.contains('legend') ||
        badgeId.contains('100');
  }
}
