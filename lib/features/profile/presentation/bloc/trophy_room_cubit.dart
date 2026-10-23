import 'package:flutter_bloc/flutter_bloc.dart';

/// Filter categories for badges in the trophy room.
enum TrophyFilter {
  /// Standard progression badges.
  standard,

  /// Rare and prestigious mastery achievements.
  legendary,
}

/// State representing badges and filters in the trophy room.
class TrophyRoomState {
  /// Master list of all earned badge identifiers.
  final List<String> allEarnedBadges;

  /// Subset of earned badges matching the active [currentFilter].
  final List<String> filteredEarnedBadges;

  /// Subset of locked badges matching the active [currentFilter].
  final List<String> filteredLockedBadges;

  /// Currently selected category filter.
  final TrophyFilter currentFilter;

  /// Total count of badges achievable across the application.
  final int totalPossibleBadges;

  /// Creates a [TrophyRoomState] snapshot.
  const TrophyRoomState({
    required this.allEarnedBadges,
    required this.filteredEarnedBadges,
    required this.filteredLockedBadges,
    required this.currentFilter,
    required this.totalPossibleBadges,
  });

  /// Factory constructing the initial trophy state from earned badge IDs.
  factory TrophyRoomState.initial(List<String> earnedBadges) {
    return TrophyRoomState(
      allEarnedBadges: earnedBadges,
      filteredEarnedBadges: earnedBadges
          .where((b) => !TrophyRoomCubit.isLegendary(b))
          .toList(),
      filteredLockedBadges: _calculateLocked(
        earnedBadges,
        TrophyFilter.standard,
      ),
      currentFilter: TrophyFilter.standard,
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
    return unearned.where((b) => !TrophyRoomCubit.isLegendary(b)).toList();
  }
}

/// Cubit managing trophy room badge categorization and filtering.
class TrophyRoomCubit extends Cubit<TrophyRoomState> {
  /// Creates a [TrophyRoomCubit] initialized with [initialBadges].
  TrophyRoomCubit(List<String> initialBadges)
    : super(TrophyRoomState.initial(initialBadges));

  /// Master registry of all 50 possible achievements in VOWL.
  static const List<String> allAppBadges = [
    // Standard Badges (40)
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
    // 10 General Milestones
    'first_blood', 'night_owl', 'early_bird', 'speed_demon', 'flawless_victory',
    'weekend_warrior',
    'unstoppable',
    'social_butterfly',
    'knowledge_sponge',
    'comeback_kid',
    // Legendary Badges (10)
    'master_speaking', 'master_listening', 'master_reading',
    'master_writing', 'master_grammar', 'master_vocabulary',
    'master_accent', 'master_roleplay', 'master_elitemastery',
    'streak_100',
  ];

  /// Updates the active [filter] and recalculates earned and locked badges.
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

  /// Returns whether a given [badgeId] corresponds to a legendary badge.
  static bool isLegendary(String badgeId) {
    return badgeId.contains('master') ||
        badgeId.contains('legend') ||
        badgeId.contains('100');
  }
}
