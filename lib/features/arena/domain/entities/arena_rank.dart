import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Competitive rank tiers in 1v1 Arena, computed client-side from [duelWins].
enum ArenaRank {
  recruit,
  contender,
  gladiator,
  champion,
  legend,
}

extension ArenaRankIntExt on int {
  /// Converts lifetime [duelWins] into the corresponding [ArenaRank].
  ArenaRank get arenaRank {
    if (this >= 50) return ArenaRank.legend;
    if (this >= 30) return ArenaRank.champion;
    if (this >= 15) return ArenaRank.gladiator;
    if (this >= 5) return ArenaRank.contender;
    return ArenaRank.recruit;
  }
}

extension ArenaRankExt on ArenaRank {
  String get key => name;

  String get label {
    switch (this) {
      case ArenaRank.recruit:
        return 'Recruit';
      case ArenaRank.contender:
        return 'Contender';
      case ArenaRank.gladiator:
        return 'Gladiator';
      case ArenaRank.champion:
        return 'Champion';
      case ArenaRank.legend:
        return 'Legend';
    }
  }

  String get emoji {
    switch (this) {
      case ArenaRank.recruit:
        return '🥉';
      case ArenaRank.contender:
        return '🥈';
      case ArenaRank.gladiator:
        return '🥇';
      case ArenaRank.champion:
        return '💎';
      case ArenaRank.legend:
        return '👑';
    }
  }

  IconData get icon {
    switch (this) {
      case ArenaRank.recruit:
        return LucideIcons.shield;
      case ArenaRank.contender:
        return LucideIcons.swords;
      case ArenaRank.gladiator:
        return LucideIcons.crown;
      case ArenaRank.champion:
        return LucideIcons.gem;
      case ArenaRank.legend:
        return LucideIcons.flame;
    }
  }

  Color get color {
    switch (this) {
      case ArenaRank.recruit:
        return AppColors.slate500;
      case ArenaRank.contender:
        return AppColors.blue500;
      case ArenaRank.gladiator:
        return AppColors.violet500;
      case ArenaRank.champion:
        return AppColors.amber500;
      case ArenaRank.legend:
        return AppColors.rose500;
    }
  }

  List<Color> get gradientColors {
    switch (this) {
      case ArenaRank.recruit:
        return const [AppColors.slate500, AppColors.slate600];
      case ArenaRank.contender:
        return const [AppColors.blue500, AppColors.indigo500];
      case ArenaRank.gladiator:
        return const [AppColors.violet500, AppColors.indigo600];
      case ArenaRank.champion:
        return const [AppColors.amber400, AppColors.amber600];
      case ArenaRank.legend:
        return const [AppColors.rose500, AppColors.amber500];
    }
  }

  int get minWins {
    switch (this) {
      case ArenaRank.recruit:
        return 0;
      case ArenaRank.contender:
        return 5;
      case ArenaRank.gladiator:
        return 15;
      case ArenaRank.champion:
        return 30;
      case ArenaRank.legend:
        return 50;
    }
  }

  ArenaRank? get nextRank {
    switch (this) {
      case ArenaRank.recruit:
        return ArenaRank.contender;
      case ArenaRank.contender:
        return ArenaRank.gladiator;
      case ArenaRank.gladiator:
        return ArenaRank.champion;
      case ArenaRank.champion:
        return ArenaRank.legend;
      case ArenaRank.legend:
        return null;
    }
  }

  /// Fractional progress toward the next rank tier (0.0 to 1.0).
  double progressToNext(int wins) {
    final next = nextRank;
    if (next == null) return 1.0;
    final span = next.minWins - minWins;
    if (span <= 0) return 1.0;
    return ((wins - minWins) / span).clamp(0.0, 1.0);
  }

  static ArenaRank fromKey(String? key) {
    for (final rank in ArenaRank.values) {
      if (rank.key == key) return rank;
    }
    return ArenaRank.recruit;
  }
}
