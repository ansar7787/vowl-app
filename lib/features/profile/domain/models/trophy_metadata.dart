import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Achievement tier classification for badges in VOWL.
enum TrophyTier {
  /// Tier 1: Level 5 completion or entry milestone.
  novice,

  /// Tier 2: Level 25 completion or intermediate milestone.
  scholar,

  /// Tier 3: Level 100 completion or advanced milestone.
  expert,

  /// Tier 4: Level 200 grand mastery milestone (Legendary).
  master,

  /// Habit streak milestones (7, 30, 100 days).
  streak,

  /// Special gameplay milestones and accomplishments.
  milestone,
}

/// Visual presentation tokens and metallic hues for an achievement tier.
@immutable
class TierVisuals {
  /// Primary ring & metallic bezel color.
  final Color ringColor;

  /// Secondary inner border accent.
  final Color innerRingColor;

  /// Concentric outer filled disc background.
  final Color fillColor;

  /// Inner filled disc background.
  final Color centerFillColor;

  /// High-contrast icon heraldry color.
  final Color iconColor;

  /// Ambient glow color for drop shadows.
  final Color glowColor;

  /// Tier label typography color.
  final Color tierBadgeColor;

  const TierVisuals({
    required this.ringColor,
    required this.innerRingColor,
    required this.fillColor,
    required this.centerFillColor,
    required this.iconColor,
    required this.glowColor,
    required this.tierBadgeColor,
  });

  /// Resolves the authentic tier presentation tokens for [tier] and [isDark] theme mode.
  static TierVisuals forTier(TrophyTier tier, bool isDark) {
    switch (tier) {
      case TrophyTier.novice:
        return TierVisuals(
          ringColor: const Color(0xFFD97706), // Warm Bronze / Amber
          innerRingColor: isDark ? const Color(0xFFB45309) : const Color(0xFFF59E0B),
          fillColor: isDark ? const Color(0xFF23160D) : const Color(0xFFFFF7ED),
          centerFillColor: isDark ? const Color(0xFF351F10) : const Color(0xFFFED7AA),
          iconColor: isDark ? const Color(0xFFFFD1A4) : const Color(0xFF9A3412),
          glowColor: const Color(0xFFD97706),
          tierBadgeColor: isDark ? const Color(0xFFFB923C) : const Color(0xFFC2410C),
        );
      case TrophyTier.scholar:
        return TierVisuals(
          ringColor: const Color(0xFF94A3B8), // Platinum / Sterling Silver
          innerRingColor: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
          fillColor: isDark ? const Color(0xFF131D2E) : const Color(0xFFF8FAFC),
          centerFillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          iconColor: isDark ? Colors.white : const Color(0xFF1E293B),
          glowColor: const Color(0xFF94A3B8),
          tierBadgeColor: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
        );
      case TrophyTier.expert:
        return TierVisuals(
          ringColor: const Color(0xFFFFD700), // Radiant Gold
          innerRingColor: const Color(0xFFD97706),
          fillColor: isDark ? const Color(0xFF261D08) : const Color(0xFFFEF3C7),
          centerFillColor: isDark ? const Color(0xFF382909) : const Color(0xFFFDE68A),
          iconColor: isDark ? const Color(0xFFFFF9C4) : const Color(0xFFB45309),
          glowColor: const Color(0xFFFFD700),
          tierBadgeColor: const Color(0xFFFFD700),
        );
      case TrophyTier.master:
        return TierVisuals(
          ringColor: const Color(0xFFFFD700), // Imperial Crown Gold
          innerRingColor: const Color(0xFFB45309),
          fillColor: isDark ? const Color(0xFF2E1A05) : const Color(0xFFFEF3C7),
          centerFillColor: isDark ? const Color(0xFF452408) : const Color(0xFFFDE68A),
          iconColor: isDark ? const Color(0xFFFFF9C4) : const Color(0xFF78350F),
          glowColor: const Color(0xFFFFD700),
          tierBadgeColor: const Color(0xFFFFD700),
        );
      case TrophyTier.streak:
        return TierVisuals(
          ringColor: const Color(0xFFFF5722), // Blazing Flame
          innerRingColor: const Color(0xFFEA580C),
          fillColor: isDark ? const Color(0xFF281106) : const Color(0xFFFFF1EB),
          centerFillColor: isDark ? const Color(0xFF3D1808) : const Color(0xFFFFD8CC),
          iconColor: isDark ? const Color(0xFFFFCC80) : const Color(0xFFC2410C),
          glowColor: const Color(0xFFFF5722),
          tierBadgeColor: const Color(0xFFFF7043),
        );
      case TrophyTier.milestone:
        return TierVisuals(
          ringColor: const Color(0xFF6366F1), // Royal Amethyst / Brand Indigo
          innerRingColor: isDark ? const Color(0xFF818CF8) : const Color(0xFFA5B4FC),
          fillColor: isDark ? const Color(0xFF16153B) : const Color(0xFFEEF2FF),
          centerFillColor: isDark ? const Color(0xFF231F5C) : const Color(0xFFDDD6FE),
          iconColor: isDark ? const Color(0xFFDDD6FE) : const Color(0xFF4338CA),
          glowColor: const Color(0xFF6366F1),
          tierBadgeColor: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
        );
    }
  }
}

/// Rich metadata, lore, and unlock criteria for a Trophy Room achievement.
@immutable
class TrophyMetadata {
  /// Canonical registry identifier (e.g. 'novice_speaking', 'streak_7').
  final String id;

  /// Display name of the achievement.
  final String name;

  /// Primary category key (e.g. 'speaking', 'streak', 'milestones').
  final String category;

  /// Achievement tier.
  final TrophyTier tier;

  /// Lucide vector icon representing this achievement.
  final IconData icon;

  /// Detailed unlock requirement / description.
  final String description;

  /// Target value required to unlock (level count, streak count, etc.).
  final int targetValue;

  /// XP bounty awarded upon unlocking.
  final int xpReward;

  /// Coin bounty awarded upon unlocking.
  final int coinReward;

  /// Whether this is a rare Legendary achievement.
  final bool isLegendary;

  const TrophyMetadata({
    required this.id,
    required this.name,
    required this.category,
    required this.tier,
    required this.icon,
    required this.description,
    required this.targetValue,
    this.xpReward = 20,
    this.coinReward = 10,
    this.isLegendary = false,
  });

  /// Calculates real-time progress ratio (0.0 to 1.0) against [user] progression.
  double calculateProgress(UserEntity? user, List<String> earnedBadges) {
    if (earnedBadges.contains(id)) return 1.0;
    if (user == null || targetValue <= 0) return 0.0;

    // 1. Skill category progression (speaking, writing, etc.)
    final skillCategories = [
      'speaking',
      'listening',
      'reading',
      'writing',
      'grammar',
      'vocabulary',
      'accent',
      'roleplay',
      'elitemastery',
    ];

    if (skillCategories.contains(category)) {
      final currentLevel = user.unlockedLevels[category] ??
          (user.completedLevels[category]?.length ?? 0);
      return (currentLevel / targetValue).clamp(0.0, 1.0);
    }

    // 2. Streaks
    if (category == 'streak' || id.startsWith('streak_')) {
      return (user.currentStreak / targetValue).clamp(0.0, 1.0);
    }

    if (id == 'perfect_week') {
      return (user.currentStreak / 7).clamp(0.0, 1.0);
    }

    // 3. Milestones
    if (id == 'first_blood') {
      final totalCompleted = user.completedLevels.values
          .fold<int>(0, (sum, list) => sum + list.length);
      return totalCompleted >= 1 ? 1.0 : 0.0;
    }

    if (id == 'unstoppable') {
      final todayXP = user.dailyXpHistory.values.isNotEmpty
          ? user.dailyXpHistory.values.last
          : 0;
      return (todayXP / 300).clamp(0.0, 1.0);
    }

    if (id == 'flawless_victory') {
      int threeStars = 0;
      for (final catMap in user.starRatings.values) {
        for (final stars in catMap.values) {
          if (stars >= 3) threeStars++;
        }
      }
      return (threeStars / 10).clamp(0.0, 1.0);
    }

    return 0.0;
  }

  /// Formats human-readable progress string (e.g. '18 / 25 Lvl' or '4 / 7 Days').
  String getProgressLabel(UserEntity? user, List<String> earnedBadges) {
    if (earnedBadges.contains(id)) return 'Completed';
    if (user == null) return '0 / $targetValue';

    final skillCategories = [
      'speaking',
      'listening',
      'reading',
      'writing',
      'grammar',
      'vocabulary',
      'accent',
      'roleplay',
      'elitemastery',
    ];

    if (skillCategories.contains(category)) {
      final currentLevel = user.unlockedLevels[category] ??
          (user.completedLevels[category]?.length ?? 0);
      return '$currentLevel / $targetValue Lvl';
    }

    if (category == 'streak' || id.startsWith('streak_')) {
      return '${user.currentStreak} / $targetValue Days';
    }

    if (id == 'perfect_week') {
      return '${user.currentStreak.clamp(0, 7)} / 7 Days';
    }

    if (id == 'flawless_victory') {
      int threeStars = 0;
      for (final catMap in user.starRatings.values) {
        for (final stars in catMap.values) {
          if (stars >= 3) threeStars++;
        }
      }
      return '${threeStars.clamp(0, 10)} / 10 Levels';
    }

    return 'In Progress';
  }

  /// Static master registry for all 50 achievements in VOWL.
  static final Map<String, TrophyMetadata> registry = _buildRegistry();

  /// Looks up metadata by [badgeId] (with safe fallback for unknown keys).
  static TrophyMetadata forId(String badgeId) {
    final lower = badgeId.toLowerCase().trim();
    if (registry.containsKey(lower)) {
      return registry[lower]!;
    }

    // Auto-generate fallback metadata for unmapped custom badges
    final parts = lower.split('_');
    final tier = parts.isNotEmpty ? parts[0] : 'novice';
    final name = parts.map((p) => p.isEmpty ? '' : '${p[0].toUpperCase()}${p.substring(1)}').join(' ');

    return TrophyMetadata(
      id: lower,
      name: name,
      category: parts.length > 1 ? parts.sublist(1).join('_') : 'general',
      tier: tier == 'master'
          ? TrophyTier.master
          : (tier == 'expert'
              ? TrophyTier.expert
              : (tier == 'scholar' ? TrophyTier.scholar : TrophyTier.novice)),
      icon: LucideIcons.award,
      description: 'Master lessons in $name to unlock.',
      targetValue: tier == 'master' ? 200 : (tier == 'expert' ? 100 : 25),
      isLegendary: tier == 'master',
    );
  }

  static Map<String, TrophyMetadata> _buildRegistry() {
    final map = <String, TrophyMetadata>{};

    void addSkillSet({
      required String cat,
      required String catName,
      required IconData icon,
    }) {
      map['novice_$cat'] = TrophyMetadata(
        id: 'novice_$cat',
        name: 'Novice $catName',
        category: cat,
        tier: TrophyTier.novice,
        icon: icon,
        description: 'Complete Level 5 in $catName.',
        targetValue: 5,
        xpReward: 15,
        coinReward: 10,
      );
      map['scholar_$cat'] = TrophyMetadata(
        id: 'scholar_$cat',
        name: 'Scholar $catName',
        category: cat,
        tier: TrophyTier.scholar,
        icon: icon,
        description: 'Complete Level 25 in $catName.',
        targetValue: 25,
        xpReward: 30,
        coinReward: 20,
      );
      map['expert_$cat'] = TrophyMetadata(
        id: 'expert_$cat',
        name: 'Expert $catName',
        category: cat,
        tier: TrophyTier.expert,
        icon: icon,
        description: 'Complete Level 100 in $catName.',
        targetValue: 100,
        xpReward: 50,
        coinReward: 35,
      );
      map['master_$cat'] = TrophyMetadata(
        id: 'master_$cat',
        name: 'Master $catName',
        category: cat,
        tier: TrophyTier.master,
        icon: icon,
        description: 'Reach Level 200 to master $catName.',
        targetValue: 200,
        xpReward: 100,
        coinReward: 50,
        isLegendary: true,
      );
    }

    // 9 Core Categories (36 Badges)
    addSkillSet(cat: 'speaking', catName: 'Speaking', icon: LucideIcons.mic);
    addSkillSet(cat: 'listening', catName: 'Listening', icon: LucideIcons.headphones);
    addSkillSet(cat: 'reading', catName: 'Reading', icon: LucideIcons.bookOpen);
    addSkillSet(cat: 'writing', catName: 'Writing', icon: LucideIcons.penTool);
    addSkillSet(cat: 'grammar', catName: 'Grammar', icon: LucideIcons.puzzle);
    addSkillSet(cat: 'vocabulary', catName: 'Vocabulary', icon: LucideIcons.book);
    addSkillSet(cat: 'accent', catName: 'Accent', icon: LucideIcons.radio);
    addSkillSet(cat: 'roleplay', catName: 'Roleplay', icon: LucideIcons.messageSquare);
    addSkillSet(cat: 'elitemastery', catName: 'Elite Mastery', icon: LucideIcons.gem);

    // Consistency & Streak Badges (4 Badges)
    map['streak_7'] = const TrophyMetadata(
      id: 'streak_7',
      name: '7-Day Streak',
      category: 'streak',
      tier: TrophyTier.streak,
      icon: LucideIcons.flame,
      description: 'Practice consistently for 7 consecutive days.',
      targetValue: 7,
      xpReward: 20,
      coinReward: 15,
    );
    map['streak_30'] = const TrophyMetadata(
      id: 'streak_30',
      name: '30-Day Flame',
      category: 'streak',
      tier: TrophyTier.streak,
      icon: LucideIcons.flame,
      description: 'Maintain your practice streak for 30 consecutive days.',
      targetValue: 30,
      xpReward: 50,
      coinReward: 30,
    );
    map['perfect_week'] = const TrophyMetadata(
      id: 'perfect_week',
      name: 'Perfect Week',
      category: 'streak',
      tier: TrophyTier.streak,
      icon: LucideIcons.calendar,
      description: 'Hit 100% of your daily XP goal every day from Monday to Sunday.',
      targetValue: 7,
      xpReward: 30,
      coinReward: 20,
    );
    map['streak_100'] = const TrophyMetadata(
      id: 'streak_100',
      name: 'Century Flame',
      category: 'streak',
      tier: TrophyTier.master,
      icon: LucideIcons.flame,
      description: 'Reach an incredible 100-day practice streak.',
      targetValue: 100,
      xpReward: 100,
      coinReward: 50,
      isLegendary: true,
    );

    // 10 General Milestones
    map['first_blood'] = const TrophyMetadata(
      id: 'first_blood',
      name: 'First Step',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.sparkles,
      description: 'Complete your first lesson in any category.',
      targetValue: 1,
      xpReward: 10,
      coinReward: 10,
    );
    map['night_owl'] = const TrophyMetadata(
      id: 'night_owl',
      name: 'Night Owl',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.moon,
      description: 'Complete a practice lesson between 10 PM and 4 AM.',
      targetValue: 1,
      xpReward: 15,
      coinReward: 15,
    );
    map['early_bird'] = const TrophyMetadata(
      id: 'early_bird',
      name: 'Early Bird',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.sun,
      description: 'Complete a practice lesson before 7 AM.',
      targetValue: 1,
      xpReward: 15,
      coinReward: 15,
    );
    map['speed_demon'] = const TrophyMetadata(
      id: 'speed_demon',
      name: 'Speed Demon',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.zap,
      description: 'Complete a speed challenge with 100% accuracy in under 60 seconds.',
      targetValue: 1,
      xpReward: 25,
      coinReward: 20,
    );
    map['flawless_victory'] = const TrophyMetadata(
      id: 'flawless_victory',
      name: 'Flawless Victory',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.award,
      description: 'Earn a perfect 3-star rating across 10 levels.',
      targetValue: 10,
      xpReward: 40,
      coinReward: 25,
    );
    map['weekend_warrior'] = const TrophyMetadata(
      id: 'weekend_warrior',
      name: 'Weekend Warrior',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.shield,
      description: 'Complete at least 5 lessons on both Saturday and Sunday.',
      targetValue: 2,
      xpReward: 25,
      coinReward: 20,
    );
    map['unstoppable'] = const TrophyMetadata(
      id: 'unstoppable',
      name: 'Unstoppable Force',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.target,
      description: 'Earn 300 XP in a single day.',
      targetValue: 300,
      xpReward: 50,
      coinReward: 30,
    );
    map['social_butterfly'] = const TrophyMetadata(
      id: 'social_butterfly',
      name: 'Social Butterfly',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.share2,
      description: 'Share an achievement or leaderboard rank with friends.',
      targetValue: 1,
      xpReward: 15,
      coinReward: 15,
    );
    map['knowledge_sponge'] = const TrophyMetadata(
      id: 'knowledge_sponge',
      name: 'Knowledge Sponge',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.brain,
      description: 'Add 100 new mastered words to your vocabulary bank.',
      targetValue: 100,
      xpReward: 50,
      coinReward: 30,
    );
    map['comeback_kid'] = const TrophyMetadata(
      id: 'comeback_kid',
      name: 'Comeback Legend',
      category: 'milestones',
      tier: TrophyTier.milestone,
      icon: LucideIcons.refreshCw,
      description: 'Use a streak freeze to protect your streak.',
      targetValue: 1,
      xpReward: 20,
      coinReward: 15,
    );

    return map;
  }
}
