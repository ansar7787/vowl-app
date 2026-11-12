import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/utils/category_games_logic.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Sliver rendering the 9 Curriculum Overworld Realms in a clean, responsive layout.
/// Replaces the overwhelming flat 100-card grid with high-retention RPG Realm portals.
class OverworldRealmsSliver extends StatelessWidget {
  final UserEntity user;
  final bool isDark;
  final bool isMidnight;
  final ValueChanged<QuestType> onRealmSelected;

  const OverworldRealmsSliver({
    super.key,
    required this.user,
    required this.isDark,
    required this.isMidnight,
    required this.onRealmSelected,
  });

  static const Map<QuestType, String> _realmSubtitles = {
    QuestType.speaking: 'Pronunciation, Fluency & Voice Challenges',
    QuestType.listening: 'Auditory Decoding & Audio Comprehension',
    QuestType.reading: 'Text Analysis, Speed Reading & Inference',
    QuestType.writing: 'Sentence Structure, Syntax & Composition',
    QuestType.grammar: 'Tenses, Modals, Connectors & Mechanics',
    QuestType.vocabulary: 'Idioms, Collocations & Wordcraft',
    QuestType.accent: 'Cadence, Intonation, Stress & Minimal Pairs',
    QuestType.roleplay: 'Conversational Dialogues & Immersion',
    QuestType.eliteMastery: 'Fluency Gauntlet & Speed Challenges',
  };

  @override
  Widget build(BuildContext context) {
    final categories = QuestType.values;

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        6.h,
        AppSpacing.screen,
        120.h + MediaQuery.paddingOf(context).bottom,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final category = categories[index];
            final stats = CategoryGamesLogic.getCategoryStats(
              user,
              category.name,
            );
            final theme = LevelThemeHelper.getCategoryTheme(
              category.name,
              isDark: isDark,
              isMidnight: isMidnight,
            );
            final subtitle = _realmSubtitles[category] ?? 'Curriculum Quests';

            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: OverworldRealmCard(
                category: category,
                stats: stats,
                theme: theme,
                subtitle: subtitle,
                isDark: isDark,
                isMidnight: isMidnight,
                onTap: () => onRealmSelected(category),
              ),
            );
          },
          childCount: categories.length,
        ),
      ),
    );
  }
}

/// Interactive Realm Portal Card featuring live mastery progress, star counts,
/// rank tier badges, and 1-tap deep dive into the serpentine overworld map.
class OverworldRealmCard extends StatelessWidget {
  final QuestType category;
  final CategoryProgressStats stats;
  final ThemeResult theme;
  final String subtitle;
  final bool isDark;
  final bool isMidnight;
  final VoidCallback onTap;

  const OverworldRealmCard({
    super.key,
    required this.category,
    required this.stats,
    required this.theme,
    required this.subtitle,
    required this.isDark,
    required this.isMidnight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = theme.primaryColor;
    final isMastered = stats.totalGames > 0 && stats.masteredGames >= stats.totalGames;
    final rankTitle = CategoryGamesLogic.getRank(context, stats.progress);

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);

    final borderColor = isMastered
        ? const Color(0xFFFFB300).withValues(alpha: 0.55)
        : (isDark
            ? displayColor.withValues(alpha: 0.25)
            : displayColor.withValues(alpha: 0.20));

    final titleText = context.tr(
      'games.${category.serializedName}.title',
      fallback: theme.title,
    );

    return Semantics(
      button: true,
      label: '$titleText Realm, ${stats.masteredGames} of ${stats.totalGames} mastered, ${stats.earnedStars} stars',
      child: ScaleButton(
        scaleDown: 0.98,
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(22.r),
            border: Border.all(
              color: borderColor,
              width: isMastered ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                // 1. Subtle Thematic Corner Radial Glow
                Positioned(
                  right: -16.w,
                  top: -16.h,
                  child: Container(
                    width: 90.r,
                    height: 90.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: displayColor.withValues(
                        alpha: isDark ? 0.12 : 0.08,
                      ),
                    ),
                  ),
                ),

                // 2. Main Card Content
                Padding(
                  padding: EdgeInsets.all(14.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row: Emblem + Titles + Rank Badge
                      Row(
                        children: [
                          Container(
                            width: 44.r,
                            height: 44.r,
                            decoration: BoxDecoration(
                              color: displayColor.withValues(alpha: 0.14),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: displayColor.withValues(alpha: 0.30),
                                width: 1.0,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                theme.icon,
                                color: displayColor,
                                size: 22.r,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        '${titleText.toUpperCase()} REALM',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 13.5.sp,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate900,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 6.w,
                                        vertical: 2.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isMastered
                                            ? const Color(0xFFFFB300).withValues(alpha: 0.16)
                                            : displayColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6.r),
                                      ),
                                      child: Text(
                                        isMastered ? 'MASTERED' : rankTitle,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w900,
                                          color: isMastered
                                              ? const Color(0xFFFFB300)
                                              : displayColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.slate400
                                        : AppColors.slate600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 12.h),

                      // Progress Bar Row
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: stats.progress,
                          minHeight: 5.h,
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isMastered ? const Color(0xFFFFB300) : displayColor,
                          ),
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Footer Row: Metrics + Call to Action Chip
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${stats.masteredGames}/${stats.totalGames} Quests',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.slate700,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Container(
                                width: 3.r,
                                height: 3.r,
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white30 : AppColors.slate400,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Icon(
                                Icons.star_rounded,
                                size: 14.r,
                                color: const Color(0xFFFFB300),
                              ),
                              SizedBox(width: 2.w),
                              Text(
                                '${stats.earnedStars}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFB300),
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'EXPLORE',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.5.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: displayColor,
                                ),
                              ),
                              SizedBox(width: 3.w),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 10.r,
                                color: displayColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
