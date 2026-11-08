import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/profile/domain/models/trophy_metadata.dart';

/// Filter categories for badges in the trophy room.
enum TrophyFilter {
  /// Standard progression badges.
  standard,

  /// Rare and prestigious mastery achievements.
  legendary,
}

/// State representing badges, sub-filters, showcase pins, and goal acceleration in the trophy room.
class TrophyRoomState {
  /// Master list of all earned badge identifiers.
  final List<String> allEarnedBadges;

  /// Subset of earned badges matching the active [currentFilter] and [activeCategory].
  final List<String> filteredEarnedBadges;

  /// Subset of locked badges matching the active [currentFilter] and [activeCategory].
  final List<String> filteredLockedBadges;

  /// Currently selected primary filter tab (Standard vs Legendary).
  final TrophyFilter currentFilter;

  /// Active sub-category filter ('all', 'skills', 'streaks', 'milestones').
  final String activeCategory;

  /// Total count of badges achievable across the application (exactly 50).
  final int totalPossibleBadges;

  /// Authenticated user entity for real-time progress calculations.
  final UserEntity? user;

  /// Top 3 pinned trophy IDs displayed on the Hero Showcase Pedestals.
  final List<String> pinnedBadgeIds;

  /// The single closest locked achievement badge ID for the "Next in Reach" radar.
  final String? nextInReachBadgeId;

  /// Progress ratio (0.0 to 1.0) of the closest achievement.
  final double nextInReachProgress;

  /// Creates a [TrophyRoomState] snapshot.
  const TrophyRoomState({
    required this.allEarnedBadges,
    required this.filteredEarnedBadges,
    required this.filteredLockedBadges,
    required this.currentFilter,
    required this.totalPossibleBadges,
    this.activeCategory = 'all',
    this.user,
    this.pinnedBadgeIds = const [],
    this.nextInReachBadgeId,
    this.nextInReachProgress = 0.0,
  });

  /// Factory constructing the initial trophy state from earned badge IDs and user progression.
  factory TrophyRoomState.initial(
    List<String> earnedBadges, {
    UserEntity? user,
  }) {
    final canonicalEarned = earnedBadges
        .map(TrophyRoomCubit.canonicalizeBadgeId)
        .toList();

    final earnedStandard = canonicalEarned
        .where((b) => !TrophyRoomCubit.isLegendary(b))
        .toList();

    final lockedStandard = _calculateLocked(
      canonicalEarned,
      TrophyFilter.standard,
      'all',
    );

    final pinned = _computeDefaultPinned(canonicalEarned);
    final (nextBadge, nextProgress) = _computeNextInReach(
      user,
      canonicalEarned,
    );

    return TrophyRoomState(
      allEarnedBadges: canonicalEarned,
      filteredEarnedBadges: earnedStandard,
      filteredLockedBadges: lockedStandard,
      currentFilter: TrophyFilter.standard,
      activeCategory: 'all',
      totalPossibleBadges: TrophyRoomCubit.allAppBadges.length,
      user: user,
      pinnedBadgeIds: pinned,
      nextInReachBadgeId: nextBadge,
      nextInReachProgress: nextProgress,
    );
  }

  TrophyRoomState copyWith({
    List<String>? allEarnedBadges,
    List<String>? filteredEarnedBadges,
    List<String>? filteredLockedBadges,
    TrophyFilter? currentFilter,
    String? activeCategory,
    int? totalPossibleBadges,
    UserEntity? user,
    List<String>? pinnedBadgeIds,
    String? nextInReachBadgeId,
    double? nextInReachProgress,
  }) {
    return TrophyRoomState(
      allEarnedBadges: allEarnedBadges ?? this.allEarnedBadges,
      filteredEarnedBadges: filteredEarnedBadges ?? this.filteredEarnedBadges,
      filteredLockedBadges: filteredLockedBadges ?? this.filteredLockedBadges,
      currentFilter: currentFilter ?? this.currentFilter,
      activeCategory: activeCategory ?? this.activeCategory,
      totalPossibleBadges: totalPossibleBadges ?? this.totalPossibleBadges,
      user: user ?? this.user,
      pinnedBadgeIds: pinnedBadgeIds ?? this.pinnedBadgeIds,
      nextInReachBadgeId: nextInReachBadgeId ?? this.nextInReachBadgeId,
      nextInReachProgress: nextInReachProgress ?? this.nextInReachProgress,
    );
  }

  static List<String> _calculateLocked(
    List<String> earned,
    TrophyFilter filter,
    String category,
  ) {
    final earnedCanonicalSet = earned
        .map(TrophyRoomCubit.canonicalizeBadgeId)
        .toSet();

    final unearned = TrophyRoomCubit.allAppBadges
        .where((b) => !earnedCanonicalSet.contains(b))
        .toList();

    List<String> pool;
    if (filter == TrophyFilter.legendary) {
      pool = unearned.where((b) => TrophyRoomCubit.isLegendary(b)).toList();
    } else {
      pool = unearned.where((b) => !TrophyRoomCubit.isLegendary(b)).toList();
    }

    if (category == 'all' || filter == TrophyFilter.legendary) {
      return pool;
    }

    return pool
        .where((badgeId) => _matchesCategory(badgeId, category))
        .toList();
  }

  static bool _matchesCategory(String badgeId, String category) {
    if (category == 'all') return true;
    if (category == 'skills') {
      return !badgeId.startsWith('streak_') &&
          badgeId != 'perfect_week' &&
          !TrophyRoomCubit._generalMilestoneIds.contains(badgeId);
    }
    if (category == 'streaks') {
      return badgeId.startsWith('streak_') || badgeId == 'perfect_week';
    }
    if (category == 'milestones') {
      return TrophyRoomCubit._generalMilestoneIds.contains(badgeId);
    }
    return badgeId.contains(category);
  }

  static List<String> _computeDefaultPinned(List<String> earned) {
    if (earned.isEmpty) return const [];

    // Sort by prestige: Legendary -> Expert -> Scholar -> Novice -> Milestones
    final sorted = List<String>.from(earned)
      ..sort((a, b) {
        final scoreA = _prestigeScore(a);
        final scoreB = _prestigeScore(b);
        return scoreB.compareTo(scoreA);
      });

    return sorted.take(3).toList();
  }

  static int _prestigeScore(String id) {
    final lower = id.toLowerCase();
    if (lower.startsWith('master_') || lower == 'streak_100') return 100;
    if (lower.startsWith('expert_')) return 75;
    if (lower.startsWith('scholar_')) return 50;
    if (lower.startsWith('streak_30')) return 40;
    if (lower.startsWith('novice_')) return 25;
    if (lower.startsWith('streak_7') || lower == 'perfect_week') return 20;
    return 10;
  }

  static (String?, double) _computeNextInReach(
    UserEntity? user,
    List<String> earned,
  ) {
    final earnedSet = earned.toSet();
    String? bestBadge;
    double highestProgress = -1.0;

    for (final badgeId in TrophyRoomCubit.allAppBadges) {
      if (earnedSet.contains(badgeId)) continue;

      final meta = TrophyMetadata.forId(badgeId);
      final progress = meta.calculateProgress(user, earned);

      if (progress < 1.0 && progress > highestProgress) {
        highestProgress = progress;
        bestBadge = badgeId;
      }
    }

    if (bestBadge != null && highestProgress > 0.0) {
      return (bestBadge, highestProgress);
    }

    // Default recommendation if user has 0% progress across all locked:
    // Suggest first standard skill milestone
    final fallback = TrophyRoomCubit.allAppBadges.firstWhere(
      (b) => !earnedSet.contains(b),
      orElse: () => 'novice_speaking',
    );
    return (fallback, 0.0);
  }
}

/// Cubit managing trophy room badge categorization, filtering, and real-time progress.
class TrophyRoomCubit extends Cubit<TrophyRoomState> {
  static const String _kPinnedBadgesKey = 'trophy_pinned_badge_ids';

  /// Creates a [TrophyRoomCubit] initialized with [initialBadges] and optional [user].
  TrophyRoomCubit(List<String> initialBadges, {UserEntity? user})
    : super(TrophyRoomState.initial(initialBadges, user: user)) {
    _loadSavedPins();
  }

  Future<void> _loadSavedPins() async {
    try {
      final prefs = di.sl.isRegistered<SharedPreferences>()
          ? di.sl<SharedPreferences>()
          : await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_kPinnedBadgesKey);
      if (saved != null && saved.isNotEmpty) {
        final validSaved = saved
            .map(canonicalizeBadgeId)
            .where((b) => state.allEarnedBadges.contains(b))
            .take(3)
            .toList();
        if (validSaved.isNotEmpty) {
          emit(state.copyWith(pinnedBadgeIds: validSaved));
        }
      }
    } catch (_) {}
  }

  static const Set<String> _generalMilestoneIds = {
    'first_blood',
    'night_owl',
    'early_bird',
    'speed_demon',
    'flawless_victory',
    'weekend_warrior',
    'unstoppable',
    'social_butterfly',
    'knowledge_sponge',
    'comeback_kid',
  };

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
    _applyFilter(filter: filter, category: state.activeCategory);
  }

  /// Updates sub-category filter within standard mode ('all', 'skills', 'streaks', 'milestones').
  void updateCategory(String category) {
    _applyFilter(filter: state.currentFilter, category: category);
  }

  void _applyFilter({required TrophyFilter filter, required String category}) {
    List<String> earnedPool;
    switch (filter) {
      case TrophyFilter.legendary:
        earnedPool = state.allEarnedBadges
            .where((b) => isLegendary(b))
            .toList();
        break;
      case TrophyFilter.standard:
        earnedPool = state.allEarnedBadges
            .where((b) => !isLegendary(b))
            .toList();
        break;
    }

    final earnedFiltered = filter == TrophyFilter.legendary || category == 'all'
        ? earnedPool
        : earnedPool
              .where((b) => TrophyRoomState._matchesCategory(b, category))
              .toList();

    final lockedFiltered = TrophyRoomState._calculateLocked(
      state.allEarnedBadges,
      filter,
      category,
    );

    emit(
      state.copyWith(
        currentFilter: filter,
        activeCategory: category,
        filteredEarnedBadges: earnedFiltered,
        filteredLockedBadges: lockedFiltered,
      ),
    );
  }

  /// Reactively syncs state when [AuthBloc] updates badges or user levels.
  void updateUser({required List<String> badges, UserEntity? user}) {
    final canonicalEarned = badges.map(canonicalizeBadgeId).toList();

    final (nextBadge, nextProgress) = TrophyRoomState._computeNextInReach(
      user,
      canonicalEarned,
    );

    final pinned = state.pinnedBadgeIds.isNotEmpty
        ? state.pinnedBadgeIds
              .where((b) => canonicalEarned.contains(b))
              .toList()
        : TrophyRoomState._computeDefaultPinned(canonicalEarned);

    emit(
      state.copyWith(
        allEarnedBadges: canonicalEarned,
        user: user,
        pinnedBadgeIds: pinned,
        nextInReachBadgeId: nextBadge,
        nextInReachProgress: nextProgress,
      ),
    );

    _applyFilter(filter: state.currentFilter, category: state.activeCategory);
  }

  /// Pins [badgeId] into the top 3 showcase slots (or unpins if already pinned).
  void togglePin(String badgeId) {
    final canonical = canonicalizeBadgeId(badgeId);
    if (!state.allEarnedBadges.contains(canonical)) return;

    final current = List<String>.from(state.pinnedBadgeIds);
    if (current.contains(canonical)) {
      current.remove(canonical);
    } else {
      if (current.length >= 3) {
        current.removeLast();
      }
      current.insert(0, canonical);
    }

    emit(state.copyWith(pinnedBadgeIds: current));
    _persistPins(current);
  }

  Future<void> _persistPins(List<String> pins) async {
    try {
      final prefs = di.sl.isRegistered<SharedPreferences>()
          ? di.sl<SharedPreferences>()
          : await SharedPreferences.getInstance();
      await prefs.setStringList(_kPinnedBadgesKey, pins);
    } catch (_) {}
  }

  /// Canonicalizes a badge ID to its primary registry key representation
  /// (e.g. 'vocabulary_master' -> 'master_vocabulary').
  static String canonicalizeBadgeId(String badgeId) {
    final lower = badgeId.toLowerCase().trim();
    final parts = lower.split('_');
    if (parts.length == 2 && parts[1] == 'master') {
      return 'master_${parts[0]}';
    }
    return lower;
  }

  /// Returns whether a given [badgeId] corresponds to a legendary badge.
  static bool isLegendary(String badgeId) {
    final canonical = canonicalizeBadgeId(badgeId);
    if (canonical.startsWith('novice_') ||
        canonical.startsWith('scholar_') ||
        canonical.startsWith('expert_')) {
      return false;
    }
    return canonical.startsWith('master_') ||
        canonical.contains('legend') ||
        canonical.contains('100');
  }

  /// Returns the achievement badge ID earned for completing [level] in [category],
  /// or null if the level does not trigger a milestone badge.
  ///
  /// Milestones:
  /// - Level 1: `first_blood` (First level completion milestone)
  /// - Level 5: `novice_<category>` (Novice rank)
  /// - Level 25: `scholar_<category>` (Scholar rank)
  /// - Level 100: `expert_<category>` (Expert rank)
  /// - Level 200: `master_<category>` (Legendary Master grand milestone)
  static String? getMilestoneBadge(String category, int level) {
    if (level == 1) return 'first_blood';
    if (level == 5) return 'novice_$category';
    if (level == 25) return 'scholar_$category';
    if (level == 100) return 'expert_$category';
    if (level >= 200) return 'master_$category';
    return null;
  }
}
