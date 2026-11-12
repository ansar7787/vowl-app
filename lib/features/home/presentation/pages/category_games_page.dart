import 'dart:math' as math;
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/category_games_logic.dart';
import 'package:vowl/features/home/presentation/widgets/category_overworld/category_overworld_map.dart';

/// Category-specific hub screen displaying games, mastery progress, and level roadmaps.
class CategoryGamesPage extends StatefulWidget {
  /// Category identifier (e.g., 'speaking', 'vocabulary', 'grammar').
  final String categoryId;

  /// Creates a [CategoryGamesPage] for [categoryId].
  const CategoryGamesPage({super.key, required this.categoryId});

  @override
  State<CategoryGamesPage> createState() => _CategoryGamesPageState();
}

class _CategoryGamesPageState extends State<CategoryGamesPage> {
  late List<GameSubtype> _games;
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<double> _scrollOffset = ValueNotifier(0.0);

  List<Widget>? _cachedBackgroundIcons;
  GameCategory? _cachedBackgroundCategory;
  bool? _cachedBackgroundDark;


  @override
  void initState() {
    super.initState();
    _initData();
    _scrollController.addListener(_onScroll);
  }


  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
  }


  @override
  void didUpdateWidget(CategoryGamesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _initData();
    }
  }

  void _initData() {
    _games = CategoryGamesLogic.getGamesForCategory(widget.categoryId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CurriculumService.prewarmCache(_games.map((g) => g.name).toList());
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // 10/10 Optimization: Select precise state slices instead of watching entire objects
    // This prevents the page from rebuilding entirely if an unrelated state property changes.
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final user = context.select((AuthBloc bloc) => bloc.state.user);

    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: isDark,
      isMidnight: isMidnight,
    );

    if (user == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate900 : AppColors.white,
        body: SafeArea(
          child: GameShimmerLoading(primaryColor: theme.primaryColor),
        ),
      );
    }

    final contentColor = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: theme.backgroundColors[1],
      // 10/10 UI Polish: Ensure the system status bar icons (battery, wifi) have correct
      // contrast over our custom MeshBackground and Glass Appbar regardless of app theme.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // 1. 120 FPS Cached Thematic Background Layer
            _buildBackground(theme, isDark),

            // 2. Scrollable Content
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Responsive spacer matching the dynamic floating App Bar
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.top + 64.h,
                  ),
                ),

                // 3. Mastery Dashboard Header
                SliverToBoxAdapter(
                  child: _buildMasteryDashboard(theme, user, _games, isDark),
                ),

                // 4. Category Overworld Adventure Map
                CategoryOverworldMap(
                  games: _games,
                  user: user,
                  categoryId: widget.categoryId,
                  themeColor: theme.primaryColor,
                  isDark: isDark,
                  isMidnight: isMidnight,
                ),
              ],
            ),

            // 5. Scroll-Reactive Floating Glass Island AppBar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildReactiveGlassAppBar(theme, isDark, contentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReactiveGlassAppBar(
    ThemeResult theme,
    bool isDark,
    Color contentColor,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final displayColor = theme.primaryColor;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return ValueListenableBuilder<double>(
      valueListenable: _scrollOffset,
      builder: (context, offset, child) {
        // High-Performance 120 FPS Pseudo-Glass:
        // Pure hardware alpha-composited surface with zero GPU BackdropFilter pipeline stalls.
        final double scrollProgress = (offset / 100).clamp(0.0, 1.0);
        final double bgAlpha = isMidnight
            ? (scrollProgress > 0 ? 0.95 : 0.0)
            : (isDark
                  ? (scrollProgress > 0 ? 0.92 : 0.0)
                  : (scrollProgress > 0 ? 0.95 : 0.0));
        final double borderAlpha = isDark
            ? (0.12 * scrollProgress)
            : (0.15 * scrollProgress);

        return Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12.h,
            bottom: 16.h,
            left: 20.w,
            right: 20.w,
          ),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface.withValues(alpha: bgAlpha)
                : (isDark ? const Color(0xFF0B101D) : Colors.white).withValues(
                    alpha: bgAlpha,
                  ),
            border: Border(
              bottom: BorderSide(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: borderAlpha,
                ),
                width: 1.0,
              ),
            ),
            boxShadow: [
              if (scrollProgress > 0.05)
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: (isDark ? 0.45 : 0.08) * scrollProgress,
                  ),
                  blurRadius: 12 * scrollProgress,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Semantics(
            button: true,
            label: context.tr('common.back', fallback: 'Back'),
            child: ScaleButton(
              onTap: () {
                HapticFeedback.lightImpact();
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRouter.homeRoute);
                }
              },
              child: Container(
                constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
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
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
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
                  Icon(theme.icon, color: displayColor, size: 16.r),
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

          // Symmetrical spacer matching the back button (48.r) to keep title centered
          SizedBox(width: 48.r, height: 48.r),
        ],
      ),
    );
  }

  Widget _buildMasteryDashboard(
    ThemeResult theme,
    UserEntity user,
    List<GameSubtype> games,
    bool isDark,
  ) {
    final contentColor = Theme.of(context).colorScheme.onSurface;
    final displayColor = theme.primaryColor;

    // Calculate Progress dynamically using real per-game level counts
    int clearedLevels = 0;
    int totalLevels = 0;
    for (var g in games) {
      final gameLevels = CurriculumManifest.getLevels(g.name);
      final completed = user.completedLevels[g.name]?.length ?? 0;
      clearedLevels += completed.clamp(0, gameLevels);
      totalLevels += gameLevels;
    }
    // 10/10 Safeguard: Prevents NaN crashes if a category has no mapped games
    final targetProgress = totalLevels > 0
        ? (clearedLevels / totalLevels)
        : 0.0;
    final rankText = CategoryGamesLogic.getRank(context, targetProgress);

    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);
    final cardBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);

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
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.card),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: cardBorder, width: 1.0),
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
                                    fallback: 'OVERALL MASTERY',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    color: displayColor,
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
                                  duration: const Duration(milliseconds: 1200),
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
                                duration: const Duration(milliseconds: 1200),
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
                                      color: displayColor,
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
                    SizedBox(height: 10.h),
                    _buildLiquidProgressBar(
                      color: displayColor,
                      progress: targetProgress,
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatMini(
                            icon: Icons.bolt_rounded,
                            label: context.tr(
                              'category_games.power',
                              fallback: 'POWER',
                            ),
                            value:
                                '${clearedLevels * 10} ${context.tr('common.xp_suffix', fallback: 'XP')}',
                            color: displayColor,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: _buildStatMini(
                              icon: Icons.sports_esports_rounded,
                              label: context.tr(
                                'category_games.games',
                                fallback: 'GAMES',
                              ),
                              value: '${games.length}',
                              color: displayColor,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: _buildStatMini(
                              icon: Icons.stars_rounded,
                              label: context.tr('home.rank', fallback: 'RANK'),
                              value: rankText,
                              color: displayColor,
                              isDark: isDark,
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

  Widget _buildStatMini({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12.r),
            SizedBox(width: 4.w),
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
              color: Theme.of(context).colorScheme.onSurface,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }
  Widget _buildLiquidProgressBar({
    required Color color,
    required double progress,
  }) {
    return Container(
      height: 8.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: TweenAnimationBuilder<double>(
        // Avoid clamping to 0.05 at the start so empty bars look empty,
        // but ensure a tiny minimum if progress > 0
        tween: Tween<double>(
          begin: 0.0,
          end: progress <= 0.0 ? 0.0 : progress.clamp(0.02, 1.0),
        ),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutExpo,
        builder: (context, value, child) {
          if (value == 0) return const SizedBox.shrink();
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
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBackgroundIconsCached(ThemeResult theme, bool isDark) {
    if (_cachedBackgroundIcons != null &&
        _cachedBackgroundCategory == theme.category &&
        _cachedBackgroundDark == isDark) {
      return _cachedBackgroundIcons!;
    }

    final rng = math.Random(theme.category.index * 1337 + 42);
    final icons = <Widget>[];

    // 1. Thematic category runes & glyphs
    final List<IconData> categoryIcons;
    switch (theme.category) {
      case GameCategory.reading:
        categoryIcons = const [
          Icons.menu_book_rounded,
          Icons.auto_stories_rounded,
          Icons.chrome_reader_mode_rounded,
          Icons.library_books_rounded,
          Icons.book_rounded,
        ];
        break;
      case GameCategory.writing:
        categoryIcons = const [
          Icons.edit_note_rounded,
          Icons.history_edu_rounded,
          Icons.draw_rounded,
          Icons.create_rounded,
          Icons.article_rounded,
        ];
        break;
      case GameCategory.speaking:
        categoryIcons = const [
          Icons.mic_external_on_rounded,
          Icons.record_voice_over_rounded,
          Icons.mic_rounded,
          Icons.campaign_rounded,
          Icons.interpreter_mode_rounded,
        ];
        break;
      case GameCategory.listening:
        categoryIcons = const [
          Icons.headset_rounded,
          Icons.graphic_eq_rounded,
          Icons.hearing_rounded,
          Icons.music_note_rounded,
          Icons.volume_up_rounded,
        ];
        break;
      case GameCategory.grammar:
        categoryIcons = const [
          Icons.architecture_rounded,
          Icons.account_tree_rounded,
          Icons.hub_rounded,
          Icons.schema_rounded,
          Icons.lan_rounded,
        ];
        break;
      case GameCategory.vocabulary:
        categoryIcons = const [
          Icons.bubble_chart_rounded,
          Icons.category_rounded,
          Icons.extension_rounded,
          Icons.widgets_rounded,
          Icons.apps_rounded,
        ];
        break;
      case GameCategory.accent:
        categoryIcons = const [
          Icons.waves_rounded,
          Icons.record_voice_over_rounded,
          Icons.graphic_eq_rounded,
          Icons.vibration_rounded,
          Icons.tune_rounded,
        ];
        break;
      case GameCategory.roleplay:
        categoryIcons = const [
          Icons.theater_comedy_rounded,
          Icons.forum_rounded,
          Icons.alt_route_rounded,
          Icons.groups_rounded,
          Icons.chat_bubble_outline_rounded,
        ];
        break;
      case GameCategory.eliteMastery:
        categoryIcons = const [
          Icons.workspace_premium_rounded,
          Icons.military_tech_rounded,
          Icons.diamond_rounded,
          Icons.emoji_events_rounded,
          Icons.star_rounded,
        ];
        break;
    }

    // 2. Scattered thematic glyphs across the screen
    for (int i = 0; i < categoryIcons.length; i++) {
      final double leftFraction = (0.08 + rng.nextDouble() * 0.84);
      final double topFraction =
          (0.08 + (i * 0.17) + rng.nextDouble() * 0.08).clamp(0.05, 0.92);
      final double iconSize = (16.0 + rng.nextInt(12)).r;
      final double alpha = isDark ? 0.11 : 0.07;

      icons.add(
        Positioned(
          left: leftFraction * 1.sw,
          top: topFraction * 1.sh,
          child: Icon(
            categoryIcons[i],
            size: iconSize,
            color: theme.primaryColor.withValues(alpha: alpha),
          ),
        ),
      );
    }

    // 3. Subtle ambient stardust sparkles
    for (int j = 0; j < 4; j++) {
      final double leftFraction = (0.05 + rng.nextDouble() * 0.9);
      final double topFraction =
          (0.12 + j * 0.22 + rng.nextDouble() * 0.06).clamp(0.05, 0.92);
      final double starSize = (10.0 + rng.nextInt(6)).r;

      icons.add(
        Positioned(
          left: leftFraction * 1.sw,
          top: topFraction * 1.sh,
          child: Icon(
            Icons.auto_awesome,
            size: starSize,
            color: theme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.05),
          ),
        ),
      );
    }

    _cachedBackgroundIcons = icons;
    _cachedBackgroundCategory = theme.category;
    _cachedBackgroundDark = isDark;
    return icons;
  }

  Widget _buildBackground(ThemeResult theme, bool isDark) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          children: [
            // 1. Dynamic category gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.backgroundColors[0], theme.backgroundColors[1]],
                ),
              ),
            ),

            // 2. Ambient Mesh Gradient
            const MeshGradientBackground(showLetters: false),

            // 3. Static cached thematic category glyphs & stardust (zero per-frame alloc)
            ..._buildBackgroundIconsCached(theme, isDark),
          ],
        ),
      ),
    );
  }
}
