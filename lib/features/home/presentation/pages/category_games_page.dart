import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/category_radar_chart.dart';
import 'package:vowl/core/presentation/game_mechanics/adaptive_smart_mix_widget.dart';
import 'package:vowl/core/utils/pedagogical_blueprint.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CategoryGamesPage extends StatefulWidget {
  const CategoryGamesPage({super.key, required this.categoryId});
  final String categoryId;

  @override
  State<CategoryGamesPage> createState() => _CategoryGamesPageState();
}

class _CategoryGamesPageState extends State<CategoryGamesPage> {
  late List<GameSubtype> _games;

  @override
  void initState() {
    super.initState();
    _games = _getGamesForCategory(widget.categoryId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CurriculumService.prewarmCache(_games.map((g) => g.name).toList());
    });
  }

  @override
  void didUpdateWidget(CategoryGamesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _games = _getGamesForCategory(widget.categoryId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CurriculumService.prewarmCache(_games.map((g) => g.name).toList());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: isDark,
      isMidnight: context.watch<ThemeCubit>().state.isMidnight,
    );
    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0F172A)
            : const Color(0xFFF8FAFC),
        body: SafeArea(
          child: GameShimmerLoading(primaryColor: theme.primaryColor),
        ),
      );
    }

    final games = _games;
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: theme.backgroundColors[1],
      body: Stack(
        children: [
          // 1. Immersive Mesh Background
          const MeshGradientBackground(showLetters: false),

          Builder(
            builder: (context) {
              final hasBlueprint =
                  PedagogicalBlueprintMap.getBlueprint(widget.categoryId) !=
                  null;
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Responsive spacer matching the dynamic floating App Bar
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 90.h,
                    ),
                  ),

                  // 3. Mastery Dashboard Header
                  SliverToBoxAdapter(
                    child: _buildMasteryDashboard(theme, user, games, isDark),
                  ),

                  // 3.5 Global Adaptive Learning Dashboard
                  if (hasBlueprint) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(top: 24.h),
                        child: CategoryRadarChart(
                          user: user,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          categoryId: widget.categoryId,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AdaptiveSmartMixWidget(
                        user: user,
                        isDark: isDark,
                        categoryId: widget.categoryId,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 16.h,
                        ),
                        child: Text(
                          context.tr(
                            'category.practice_library',
                            fallback: 'PRACTICE LIBRARY',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white70 : Colors.black54,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ],

                  // 4. Game Grid/List
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      24.w,
                      hasBlueprint ? 8.h : 32.h,
                      24.w,
                      100.h,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 24.h),
                          child: _buildSpatialGameCard(
                            context,
                            user,
                            games[index],
                            isDark,
                            index,
                          ),
                        );
                      }, childCount: games.length),
                    ),
                  ),
                ],
              );
            },
          ),

          // 5. Floating Glass Island AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: _buildFloatingGlassAppBar(
                context,
                theme,
                isDark,
                contentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassAppBar(
    BuildContext context,
    ThemeResult theme,
    bool isDark,
    Color contentColor,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12.h,
            bottom: 16.h,
            left: 20.w,
            right: 20.w,
          ),
          decoration: BoxDecoration(
            color: (isDark ? Colors.black : Colors.white).withValues(
              alpha: 0.1,
            ),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                button: true,
                label: context.tr('common.back', fallback: 'Back'),
                child: ScaleButton(
                  onTap: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go(AppRouter.homeRoute);
                    }
                  },
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: 48.r,
                      minHeight: 48.r,
                    ),
                    alignment: Alignment.center,
                    child: ExcludeSemantics(
                      child: Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Icon(
                          isRtl
                              ? Icons.arrow_forward_ios_rounded
                              : Icons.arrow_back_ios_new_rounded,
                          color: contentColor,
                          size: 20.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Centered Glass Capsule
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(theme.icon, color: theme.primaryColor, size: 16.r),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.categoryId.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: contentColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // User Progress/Stats Pill (decorative)
              ExcludeSemantics(
                child: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isDark ? Colors.white : Colors.black).withValues(
                        alpha: 0.1,
                      ),
                    ),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: theme.primaryColor,
                    size: 20.r,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMasteryDashboard(
    ThemeResult theme,
    UserEntity user,
    List<GameSubtype> games,
    bool isDark,
  ) {
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // Calculate Progress (200 levels per game)
    int clearedLevels = 0;
    for (var g in games) {
      final completed = user.completedLevels[g.name]?.length ?? 0;
      clearedLevels += completed.clamp(0, 200);
    }
    final totalLevels = games.length * 200;
    final targetProgress = totalLevels > 0
        ? (clearedLevels / totalLevels)
        : 0.0;

    return Semantics(
          label: context.tr(
            'category_games.mastery_summary_label',
            fallback: 'Mastery Summary',
            args: [
              (targetProgress * 100).toStringAsFixed(1),
              clearedLevels.toString(),
              totalLevels.toString(),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  context.tr(
                                    'category_games.overall_mastery',
                                    fallback: 'Overall Mastery',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: theme.primaryColor,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              SizedBox(height: 4.h),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0.0,
                                    end: targetProgress,
                                  ),
                                  duration: const Duration(milliseconds: 1000),
                                  curve: Curves.easeOutExpo,
                                  builder: (context, value, child) {
                                    final percentLabel = (value * 100)
                                        .toStringAsFixed(
                                          value < 0.01 && value > 0 ? 2 : 1,
                                        );
                                    return Text(
                                      context.tr(
                                        'category_games.percent_completed',
                                        fallback: 'Completed',
                                        args: [percentLabel],
                                      ),
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 22.sp,
                                        fontWeight: FontWeight.w900,
                                        color: contentColor,
                                      ),
                                      maxLines: 1,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: theme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: clearedLevels.toDouble(),
                                ),
                                duration: const Duration(milliseconds: 1000),
                                curve: Curves.easeOutExpo,
                                builder: (context, value, child) {
                                  return Text(
                                    context.tr(
                                      'category_games.levels_count_short',
                                      fallback: 'Levels',
                                      args: [
                                        value.toInt().toString(),
                                        totalLevels.toString(),
                                      ],
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color: theme.primaryColor,
                                    ),
                                    maxLines: 1,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    _buildLiquidProgressBar(
                      theme.primaryColor,
                      clearedLevels + 1,
                      total: totalLevels,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatMini(
                            Icons.bolt_rounded,
                            context.tr(
                              'category_games.power',
                              fallback: 'Power',
                            ),
                            '${clearedLevels * 10} ${context.tr('common.xp_suffix', fallback: 'XP')}',
                            theme.primaryColor,
                            isDark,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildStatMini(
                              Icons.sports_esports_rounded,
                              context.tr(
                                'category_games.games',
                                fallback: 'Games',
                              ),
                              '${games.length}',
                              theme.primaryColor,
                              isDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _buildStatMini(
                              Icons.stars_rounded,
                              context.tr('home.rank', fallback: 'Rank'),
                              _getRank(targetProgress),
                              theme.primaryColor,
                              isDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 600.ms)
        .slideY(begin: 0.05, end: 0, curve: Curves.easeOutCubic);
  }

  String _getRank(double progress) {
    if (progress <= 0.0) {
      return context.tr('category_games.rank_beginner', fallback: 'Beginner');
    }
    if (progress < 0.15) {
      return context.tr('category_games.rank_novice', fallback: 'Novice');
    }
    if (progress < 0.35) {
      return context.tr('category_games.rank_scholar', fallback: 'Scholar');
    }
    if (progress < 0.55) {
      return context
          .tr('home.discovery_diff_expert', fallback: 'Expert')
          .toUpperCase();
    }
    if (progress < 0.80) {
      return context.tr('category_games.rank_virtuoso', fallback: 'Virtuoso');
    }
    if (progress < 0.99) {
      return context.tr(
        'quest_archive.status_grandmaster',
        fallback: 'Grandmaster',
      );
    }
    return context.tr('quest_archive.status_legendary', fallback: 'Legendary');
  }

  Widget _buildStatMini(
    IconData icon,
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12.r),
            SizedBox(width: 4.w),
            // Flexible + maxLines/ellipsis: a longer translation of POWER /
            // GAMES / RANK (this row has 3 mini-stats sharing the available
            // width) could otherwise overflow this Row horizontally.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: (isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.4,
                    ),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSpatialGameCard(
    BuildContext context,
    UserEntity user,
    GameSubtype subtype,
    bool isDark,
    int index,
  ) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final currentLevel = (user.completedLevels[subtype.name]?.length ?? 0) + 1;
    final isNew =
        !user.categoryStats.containsKey(subtype.name) && currentLevel == 1;
    final displayColor = isDark
        ? theme.primaryColor
        : HSLColor.fromColor(theme.primaryColor).withLightness(0.4).toColor();
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final missionPercent = (((currentLevel - 1).clamp(0, 200)) / 200 * 100)
        .toInt();

    return Semantics(
          button: true,
          label:
              '${theme.title}, ${context.tr('category_games.mission_progress', fallback: 'Mission Progress', args: [missionPercent.toString()])}',
          child: RepaintBoundary(
            child: ScaleButton(
              onTap: () => context.push(
                '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(widget.categoryId)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
              ),
              child: ExcludeSemantics(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Main Card Body
                    GlassTile(
                      borderRadius: BorderRadius.circular(32.r),
                      padding: EdgeInsets.all(24.r),
                      glassOpacity: 0.15,
                      showShadow: false,
                      usePremiumStyle: true,
                      child: Row(
                        children: [
                          SizedBox(width: 60.r),
                          SizedBox(width: 20.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(
                                  theme.title.toUpperCase(),
                                  maxLines: 2,
                                  minFontSize: 12,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: contentColor,
                                    letterSpacing: 1,
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                _buildLiquidProgressBar(
                                  displayColor,
                                  currentLevel,
                                ),
                                SizedBox(height: 8.h),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    context.tr(
                                      'category_games.mission_progress',
                                      fallback: 'Mission Progress',
                                      args: [missionPercent.toString()],
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 9.sp,
                                      fontWeight: FontWeight.w800,
                                      color: displayColor.withValues(
                                        alpha: 0.6,
                                      ),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          _buildSpatialBadge(displayColor, currentLevel, isNew),
                        ],
                      ),
                    ),

                    // Floating Spatial Icon
                    PositionedDirectional(
                      start: 20.w,
                      top: -15.h,
                      child:
                          Container(
                                width: 64.r,
                                height: 64.r,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      displayColor,
                                      displayColor.withValues(alpha: 0.7),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: displayColor.withValues(
                                        alpha: 0.4,
                                      ),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  GameHelper.getIconForSubtype(subtype),
                                  color: Colors.white,
                                  size: 32.r,
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(
                                begin: 0,
                                end: -5,
                                duration: 2.seconds,
                                curve: Curves.easeInOutQuad,
                              ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(delay: (index < 5 ? index * 80 : 0).ms, duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack)
        .scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOutBack);
  }

  Widget _buildLiquidProgressBar(
    Color color,
    int currentLevel, {
    int total = 200,
  }) {
    final targetProgress =
        ((currentLevel - 1).clamp(0, total)) / total.toDouble();
    return Container(
      height: 8.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: targetProgress.clamp(0.05, 1.0)),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutExpo,
        builder: (context, value, child) {
          return FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: value,
            child: child,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4),
            ],
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
      ),
    );
  }

  Widget _buildSpatialBadge(Color color, int currentLevel, bool isNew) {
    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('quest_archive.new_badge', fallback: 'New'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        "$currentLevel",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: color,
        ),
        maxLines: 1,
      ),
    );
  }

  List<GameSubtype> _getGamesForCategory(String category) {
    final List<GameSubtype> allGames = GameSubtype.values
        .where((s) => s.category.name == category && !s.isLegacy)
        .toList();

    final Map<String, List<GameSubtype>> journeyOrder = {
      'vocabulary': [
        GameSubtype.flashcards,
        GameSubtype.topicVocab,
        GameSubtype.wordFormation,
        GameSubtype.prefixSuffix,
        GameSubtype.synonymSearch,
        GameSubtype.antonymSearch,
        GameSubtype.contextClues,
        GameSubtype.collocations,
        GameSubtype.phrasalVerbs,
        GameSubtype.idioms,
        GameSubtype.academicWord,
        GameSubtype.contextualUsage,
      ],
      'grammar': [
        GameSubtype.partsOfSpeech,
        GameSubtype.grammarQuest,
        GameSubtype.wordReorder,
        GameSubtype.sentenceCorrection,
        GameSubtype.tenseMastery,
        GameSubtype.subjectVerbAgreement,
        GameSubtype.articleInsertion,
        GameSubtype.questionFormatter,
        GameSubtype.clauseConnector,
        GameSubtype.voiceSwap,
        GameSubtype.punctuationMastery,
        GameSubtype.modifierPlacement,
        GameSubtype.modalsSelection,
        GameSubtype.prepositionChoice,
        GameSubtype.pronounResolution,
        GameSubtype.relativeClauses,
        GameSubtype.conditionals,
        GameSubtype.conjunctions,
        GameSubtype.directIndirectSpeech,
      ],
      'listening': [
        GameSubtype.audioFillBlanks,
        GameSubtype.audioMultipleChoice,
        GameSubtype.audioSentenceOrder,
        GameSubtype.audioTrueFalse,
        GameSubtype.soundImageMatch,
        GameSubtype.detailSpotlight,
        GameSubtype.emotionRecognition,
        GameSubtype.fastSpeechDecoder,
        GameSubtype.listeningInference,
        GameSubtype.ambientId,
      ],
      'reading': [
        GameSubtype.readAndAnswer,
        GameSubtype.findWordMeaning,
        GameSubtype.trueFalseReading,
        GameSubtype.sentenceOrderReading,
        GameSubtype.guessTitle,
        GameSubtype.readAndMatch,
        GameSubtype.skimmingScanning,
        GameSubtype.paragraphSummary,
        GameSubtype.readingSpeedCheck,
        GameSubtype.readingInference,
        GameSubtype.readingConclusion,
        GameSubtype.clozeTest,
      ],
      'writing': [
        GameSubtype.sentenceBuilder,
        GameSubtype.completeSentence,
        GameSubtype.fixTheSentence,
        GameSubtype.describeSituationWriting,
        GameSubtype.summarizeStoryWriting,
        GameSubtype.shortAnswerWriting,
        GameSubtype.opinionWriting,
        GameSubtype.dailyJournal,
        GameSubtype.writingEmail,
        GameSubtype.correctionWriting,
        GameSubtype.essayDrafting,
      ],
      'speaking': [
        GameSubtype.repeatSentence,
        GameSubtype.speakMissingWord,
        GameSubtype.yesNoSpeaking,
        GameSubtype.pronunciationFocus,
        GameSubtype.speakSynonym,
        GameSubtype.speakOpposite,
        GameSubtype.dailyExpression,
        GameSubtype.situationSpeaking,
        GameSubtype.sceneDescriptionSpeaking,
        GameSubtype.dialogueRoleplay,
      ],
      'accent': [
        GameSubtype.minimalPairs,
        GameSubtype.vowelDistinction,
        GameSubtype.consonantClarity,
        GameSubtype.syllableStress,
        GameSubtype.wordLinking,
        GameSubtype.connectedSpeech,
        GameSubtype.intonationMimic,
        GameSubtype.pitchModulation,
        GameSubtype.pitchPatternMatch,
        GameSubtype.speedVariance,
        GameSubtype.shadowingChallenge,
        GameSubtype.dialectDrill,
      ],
      'roleplay': [
        GameSubtype.situationalResponse,
        GameSubtype.branchingDialogue,
        GameSubtype.socialSpark,
        GameSubtype.travelDesk,
        GameSubtype.gourmetOrder,
        GameSubtype.jobInterview,
        GameSubtype.medicalConsult,
        GameSubtype.conflictResolver,
        GameSubtype.elevatorPitch,
        GameSubtype.emergencyHub,
      ],
      'elitemastery': [
        GameSubtype.storyBuilder,
        GameSubtype.idiomMatch,
        GameSubtype.speedSpelling,
        GameSubtype.accentShadowing,
      ],
    };

    final order = journeyOrder[category];
    if (order != null) {
      allGames.sort((a, b) {
        final indexA = order.indexOf(a);
        final indexB = order.indexOf(b);
        if (indexA == -1 && indexB == -1) return 0;
        if (indexA == -1) return 1;
        if (indexB == -1) return -1;
        return indexA.compareTo(indexB);
      });
    }

    return allGames;
  }
}
