import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProgressDashboardScreen extends StatelessWidget {
  const ProgressDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              const MeshGradientBackground(showLetters: false),
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 16.h),
                            // Section 1: Weekly XP Trend
                            _WeeklyXpChart(user: user, isDark: isDark),
                            SizedBox(height: 24.h),
                            // Section 2: Cross-Category Mastery
                            _CategoryMasteryOverview(
                              user: user,
                              isDark: isDark,
                            ),
                            SizedBox(height: 24.h),
                            // Section 3: Continue Learning
                            _ContinueLearningSection(
                              user: user,
                              isDark: isDark,
                            ),
                            SizedBox(height: 48.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 16.h),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              context.tr(
                'profile.learning_report',
                fallback: 'Learning Report',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Section 1: Weekly XP Bar Chart
// =============================================================================

class _WeeklyXpChart extends StatelessWidget {
  final UserEntity user;
  final bool isDark;

  const _WeeklyXpChart({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final history = user.dailyXpHistory;

    // Build 7-day data
    final days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      final key = DateFormat('yyyy-MM-dd').format(day);
      return _DayXp(
        day: day,
        xp: history[key] ?? 0,
        label: DateFormat('E', locale).format(day),
        isToday: i == 6,
      );
    });

    final maxXp = days.map((d) => d.xp).reduce(math.max);
    final totalXp = days.fold<int>(0, (sum, d) => sum + d.xp);
    final activeDays = days.where((d) => d.xp > 0).length;

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.insights_rounded,
                  size: 14.r,
                  color: const Color(0xFF6366F1),
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: AutoSizeText(
                  context.tr(
                    'report.weekly_xp_trend',
                    fallback: 'WEEKLY XP TREND',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  minFontSize: 6,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: AutoSizeText(
                  '$totalXp XP',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF10B981),
                  ),
                  maxLines: 1,
                  minFontSize: 8,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(
              'report.weekly_xp_description',
              fallback: '$activeDays of 7 days active this week.',
              args: [activeDays.toString()],
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 20.h),
          // Bar Chart
          SizedBox(
            height: 120.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: days.map((day) {
                final fraction =
                    maxXp > 0 ? (day.xp / maxXp).clamp(0.0, 1.0) : 0.0;
                final barHeight =
                    (fraction * 80.h).clamp(day.xp > 0 ? 8.h : 4.h, 80.h);

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (day.xp > 0)
                          Padding(
                            padding: EdgeInsets.only(bottom: 4.h),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${day.xp}',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  color: day.isToday
                                      ? const Color(0xFF6366F1)
                                      : (isDark
                                            ? Colors.white54
                                            : Colors.black45),
                                ),
                              ),
                            ),
                          ),
                        AnimatedContainer(
                          duration: 600.ms,
                          height: barHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: day.xp > 0
                                ? LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: day.isToday
                                        ? [
                                            const Color(0xFF6366F1),
                                            const Color(0xFF818CF8),
                                          ]
                                        : [
                                            const Color(0xFF6366F1)
                                                .withValues(alpha: 0.6),
                                            const Color(0xFF818CF8)
                                                .withValues(alpha: 0.4),
                                          ],
                                  )
                                : null,
                            color: day.xp == 0
                                ? (isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.black.withValues(alpha: 0.05))
                                : null,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            day.label,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight:
                                  day.isToday
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                              color: day.isToday
                                  ? const Color(0xFF6366F1)
                                  : (isDark
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.black.withValues(alpha: 0.4)),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05);
  }
}

class _DayXp {
  final DateTime day;
  final int xp;
  final String label;
  final bool isToday;
  const _DayXp({
    required this.day,
    required this.xp,
    required this.label,
    required this.isToday,
  });
}

// =============================================================================
// Section 2: Cross-Category Mastery Overview
// =============================================================================

class _CategoryMasteryOverview extends StatelessWidget {
  final UserEntity user;
  final bool isDark;

  const _CategoryMasteryOverview({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final categories = QuestType.values.toList();

    int totalCleared = 0;
    int totalMax = 0;
    final categoryData = <_CategoryProgress>[];

    for (final cat in categories) {
      int cleared = 0;
      for (final subtype in cat.subtypes) {
        cleared += user.completedLevels[subtype.name]?.length ?? 0;
      }
      final max = user.getMaxCategoryLevels(cat);
      totalCleared += cleared;
      totalMax += max;
      final progress = max > 0 ? (cleared / max).clamp(0.0, 1.0) : 0.0;
      categoryData.add(_CategoryProgress(
        type: cat,
        cleared: cleared,
        max: max,
        progress: progress,
        color: LevelThemeHelper.getCategoryBaseColor(cat.name),
        icon: LevelThemeHelper.getCategoryTheme(cat.name).icon,
      ));
    }

    final overallProgress =
        totalMax > 0 ? (totalCleared / totalMax).clamp(0.0, 1.0) : 0.0;
    final overallPercent = (overallProgress * 100).toStringAsFixed(1);

    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.donut_large_rounded,
                  size: 14.r,
                  color: const Color(0xFF10B981),
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: AutoSizeText(
                  context.tr(
                    'report.total_mastery',
                    fallback: 'TOTAL MASTERY',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  minFontSize: 6,
                ),
              ),
              const Spacer(),
              AutoSizeText(
                '$overallPercent%',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10B981),
                ),
                maxLines: 1,
                minFontSize: 12,
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(
              'report.mastery_description',
              fallback:
                  '$totalCleared levels cleared across all categories.',
              args: [totalCleared.toString()],
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 16.h),
          // Overall progress bar
          Container(
            height: 10.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: overallProgress.clamp(0.02, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF34D399)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 20.h),
          // Category chips grid
          Wrap(
            spacing: 8.w,
            runSpacing: 10.h,
            children: categoryData.map((cat) {
              return _buildCategoryChip(context, cat);
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildCategoryChip(BuildContext context, _CategoryProgress cat) {
    final percent = (cat.progress * 100).toInt();
    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().selection();
        context.push(
          '${AppRouter.categoryGamesRoute}?category=${Uri.encodeQueryComponent(cat.type.name)}',
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: cat.color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: cat.color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(cat.icon, color: cat.color, size: 14.r),
            SizedBox(width: 6.w),
            Text(
              _formatTitle(
                LevelThemeHelper.getCategoryTheme(cat.type.name).title,
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(width: 6.w),
            Text(
              '$percent%',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: cat.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Converts "ELITE MASTERY" → "Elite Mastery"
  String _formatTitle(String upper) {
    return upper
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}

class _CategoryProgress {
  final QuestType type;
  final int cleared;
  final int max;
  final double progress;
  final Color color;
  final IconData icon;
  const _CategoryProgress({
    required this.type,
    required this.cleared,
    required this.max,
    required this.progress,
    required this.color,
    required this.icon,
  });
}

// =============================================================================
// Section 3: Continue Learning Quick Actions
// =============================================================================

class _ContinueLearningSection extends StatelessWidget {
  final UserEntity user;
  final bool isDark;

  const _ContinueLearningSection({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Find recently played games (games with progress > 0, sorted by level desc)
    final recentGames = <_RecentGame>[];

    for (final subtype in GameSubtype.values) {

      final completedCount = user.completedLevels[subtype.name]?.length ?? 0;
      if (completedCount > 0) {
        final currentLevel = completedCount + 1;
        final color = LevelThemeHelper.getCategoryBaseColor(
          subtype.category.name,
        );
        final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
        recentGames.add(_RecentGame(
          subtype: subtype,
          currentLevel: currentLevel,
          completedCount: completedCount,
          color: color,
          icon: theme.icon,
          title: theme.title,
          categoryName: subtype.category.name,
        ));
      }
    }

    // Find chronological order of games from recent activities
    final recentGameTypes = <String>[];
    for (final activity in user.recentActivities) {
      if (activity['type'] == 'quest') {
        final gameType = activity['gameType'] as String?;
        if (gameType != null && !recentGameTypes.contains(gameType)) {
          recentGameTypes.add(gameType);
        }
      }
    }

    // Sort by recency first, then fallback to most progress
    recentGames.sort((a, b) {
      final aIndex = recentGameTypes.indexOf(a.subtype.name);
      final bIndex = recentGameTypes.indexOf(b.subtype.name);

      if (aIndex != -1 && bIndex != -1) {
        return aIndex.compareTo(bIndex);
      } else if (aIndex != -1) {
        return -1;
      } else if (bIndex != -1) {
        return 1;
      } else {
        return b.completedCount.compareTo(a.completedCount);
      }
    });

    final topGames = recentGames.take(4).toList();

    if (topGames.isEmpty) {
      return GlassTile(
        padding: EdgeInsets.all(20.r),
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: [
            Icon(
              Icons.play_circle_outline_rounded,
              size: 48.r,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
            ),
            SizedBox(height: 12.h),
            Text(
              context.tr(
                'report.no_games_yet',
                fallback: 'Start playing to see your progress here!',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                size: 14.r,
                color: const Color(0xFFF59E0B),
              ),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: AutoSizeText(
                context.tr(
                  'report.continue_learning',
                  fallback: 'CONTINUE LEARNING',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
                maxLines: 1,
                minFontSize: 6,
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        ...topGames.asMap().entries.map((entry) {
          final index = entry.key;
          final game = entry.value;
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildGameResumeCard(context, game)
                .animate()
                .fadeIn(delay: (300 + index * 100).ms)
                .slideX(begin: 0.05),
          );
        }),
      ],
    );
  }

  Widget _buildGameResumeCard(BuildContext context, _RecentGame game) {
    final missionPercent =
        ((game.completedCount.clamp(0, 200)) / 200 * 100).toInt();
    final displayColor = isDark
        ? game.color
        : HSLColor.fromColor(game.color).withLightness(0.4).toColor();

    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().selection();
        context.push(
          '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(game.categoryName)}&gameType=${Uri.encodeQueryComponent(game.subtype.name)}',
        );
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(16.r),
        child: Row(
          children: [
            // Game icon
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    displayColor,
                    displayColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: displayColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(game.icon, color: Colors.white, size: 24.r),
            ),
            SizedBox(width: 14.w),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    game.title,
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  // Mini progress bar
                  Container(
                    height: 6.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: displayColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor:
                          (game.completedCount / 200).clamp(0.02, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              displayColor,
                              displayColor.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      context.tr(
                        'report.level_progress',
                        fallback: 'Level ${game.currentLevel} · $missionPercent% complete',
                        args: [
                          game.currentLevel.toString(),
                          missionPercent.toString(),
                        ],
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: displayColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            // Play arrow
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: displayColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: displayColor,
                size: 18.r,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentGame {
  final GameSubtype subtype;
  final int currentLevel;
  final int completedCount;
  final Color color;
  final IconData icon;
  final String title;
  final String categoryName;
  const _RecentGame({
    required this.subtype,
    required this.currentLevel,
    required this.completedCount,
    required this.color,
    required this.icon,
    required this.title,
    required this.categoryName,
  });
}
