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
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/category_radar_chart.dart';
import 'package:vowl/features/home/presentation/widgets/adaptive_smart_mix_widget.dart';
import 'package:vowl/core/utils/pedagogical_blueprint.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Category-specific hub screen displaying games, radar metrics, and level roadmaps.
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

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<String> _activeFilter = ValueNotifier('all');
  final ValueNotifier<bool> _isGridView = ValueNotifier(false);
  final ValueNotifier<bool> _isSearchOpen = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _initData();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final trimmed = _searchController.text.trim().toLowerCase();
    if (trimmed != _searchQuery.value) {
      _searchQuery.value = trimmed;
    }
  }

  void _onScroll() {
    _scrollOffset.value = _scrollController.offset;
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
  }

  void _toggleSearch() {
    _isSearchOpen.value = !_isSearchOpen.value;
    if (_isSearchOpen.value) {
      _searchFocusNode.requestFocus();
    } else {
      _searchFocusNode.unfocus();
      _searchController.clear();
      _searchQuery.value = '';
    }
  }

  @override
  void didUpdateWidget(CategoryGamesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _searchController.clear();
      _searchQuery.value = '';
      _activeFilter.value = 'all';
      _initData();
    }
  }

  void _initData() {
    _games = _CategoryGamesLogic.getGamesForCategory(widget.categoryId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CurriculumService.prewarmCache(_games.map((g) => g.name).toList());
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchQuery.dispose();
    _activeFilter.dispose();
    _isGridView.dispose();
    _isSearchOpen.dispose();
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
    final hasBlueprint =
        PedagogicalBlueprintMap.getBlueprint(widget.categoryId) != null;

    return Scaffold(
      backgroundColor: theme.backgroundColors[1],
      // 10/10 UI Polish: Ensure the system status bar icons (battery, wifi) have correct
      // contrast over our custom MeshBackground and Glass Appbar regardless of app theme.
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Stack(
          children: [
            // 1. Immersive Mesh Background
            const MeshGradientBackground(showLetters: false),

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

                // 3.5 Global Adaptive Learning Dashboard
                if (hasBlueprint) ...[
                  SliverToBoxAdapter(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, query, _) {
                        if (query.trim().isNotEmpty) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 8.h),
                              child: CategoryRadarChart(
                                user: user,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                categoryId: widget.categoryId,
                              ),
                            ),
                            AdaptiveSmartMixWidget(
                              user: user,
                              categoryId: widget.categoryId,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 8.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
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
                          _buildViewModeToggle(
                            theme.primaryColor,
                            contentColor,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                if (!hasBlueprint)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildViewModeToggle(
                            theme.primaryColor,
                            contentColor,
                            isDark,
                          ),
                        ],
                      ),
                    ),
                  ),

                // 4. Edge-to-Edge Status Filter Bar (Fluid scroll, zero side clipping)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: _buildFilterBar(theme, isDark, user),
                  ),
                ),

                // 5. Game Grid/List (Dynamic Filtering & View Mode Switcher)
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _searchQuery,
                    _activeFilter,
                    _isGridView,
                  ]),
                  builder: (context, _) {
                    final filtered = _getFilteredGames(user, _games);
                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: _buildEmptyFilterState(
                          theme,
                          isDark,
                          contentColor,
                        ),
                      );
                    }

                    if (_isGridView.value) {
                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          20.w,
                          14.h,
                          20.w,
                          MediaQuery.of(context).padding.bottom + 32.h,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12.w,
                                mainAxisSpacing: 12.h,
                                childAspectRatio: 0.92,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            return _buildStudioGridCard(
                              context: context,
                              user: user,
                              subtype: filtered[index],
                              isDark: isDark,
                              index: index,
                            );
                          }, childCount: filtered.length),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        20.w,
                        // Clean 20.h clearance below filter bar for integrated cards (zero bounding box breach)
                        20.h,
                        20.w,
                        // Dynamic safe area calculations
                        MediaQuery.of(context).padding.bottom + 32.h,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return Padding(
                            padding: EdgeInsets.only(bottom: 24.h),
                            child: _buildSpatialGameCard(
                              context: context,
                              user: user,
                              subtype: filtered[index],
                              isDark: isDark,
                              index: index,
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    );
                  },
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

          // Actionable Search & Filter Trigger
          Semantics(
            button: true,
            label: context.tr(
              'category_games.search_and_filter',
              fallback: 'Search and Filter',
            ),
            child: ScaleButton(
              onTap: () {
                HapticFeedback.lightImpact();
                _toggleSearch();
              },
              child: Container(
                constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
                alignment: Alignment.center,
                child: ValueListenableBuilder<bool>(
                  valueListenable: _isSearchOpen,
                  builder: (context, isOpen, _) {
                    return Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? displayColor.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isOpen
                              ? displayColor.withValues(alpha: 0.3)
                              : (isDark ? Colors.white : Colors.black)
                                    .withValues(alpha: 0.1),
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: displayColor,
                        size: 20.r,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
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
    final rankText = _CategoryGamesLogic.getRank(context, targetProgress);

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

                    // 10/10 Apex Feature: 1-Tap Quick-Resume Hero Action
                    ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, query, _) {
                        if (query.trim().isNotEmpty) return const SizedBox.shrink();
                        final nextGame = _findNextActiveGame(games, user);
                        if (nextGame == null) return const SizedBox.shrink();
                        return Padding(
                          padding: EdgeInsets.only(top: 8.h),
                          child: _buildQuickResumeHero(
                            theme: theme,
                            user: user,
                            nextGame: nextGame,
                            isDark: isDark,
                          ),
                        );
                      },
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

  Widget _buildSpatialGameCard({
    required BuildContext context,
    required UserEntity user,
    required GameSubtype subtype,
    required bool isDark,
    required int index,
  }) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final completedCount = user.completedLevels[subtype.name]?.length ?? 0;
    final gameTotalLevels = CurriculumManifest.getLevels(subtype.name);
    final isMastered = completedCount >= gameTotalLevels;
    final currentLevel = isMastered ? gameTotalLevels : completedCount + 1;
    final isNew =
        !user.categoryStats.containsKey(subtype.name) && completedCount == 0;

    final displayColor = theme.primaryColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBorderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);

    // Abstract the math out of the widget parameters to ensure raw floats are clean
    final double cardProgress =
        (completedCount.clamp(0, gameTotalLevels)) / gameTotalLevels.toDouble();

    // Pure gameplay stars calculation (excluding Star Vault magic stars and claimed chests)
    final categoryStars = user.starRatings[subtype.name] ?? {};
    int gameplayStars = 0;
    categoryStars.forEach((key, value) {
      if (key != 'magic_stars' && key != 'claimed_chests') {
        gameplayStars += value;
      }
    });
    final maxGameplayStars = gameTotalLevels * 3;
    final isAllThreeStars = isMastered && gameplayStars >= maxGameplayStars;
    final gameStarsLabel = context.tr(
      'category_games.game_stars',
      fallback: 'GAME STARS',
    );

    return Semantics(
      button: true,
      label:
          '${theme.title}, ${isMastered ? (isAllThreeStars ? context.tr('category_games.perfect', fallback: 'PERFECT') : context.tr('category_games.mastered', fallback: 'MASTERED')) : '$gameplayStars of $maxGameplayStars Game Stars'}',
      child: RepaintBoundary(
        child: ScaleButton(
          onTap: () {
            HapticFeedback.lightImpact();
            context.push(
              '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(widget.categoryId)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
            );
          },
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main Card Body
                GlassTile(
                  borderRadius: BorderRadius.circular(24.r),
                  padding: EdgeInsets.all(AppSpacing.card),
                  glassOpacity: 1.0,
                  blur: 0,
                  showShadow: false,
                  usePremiumStyle: true,
                  borderColor: cardBorderColor,
                  borderWidth: 1.0,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 56.r + 14.w,
                      ), // Spacer for integrated spatial squircle icon
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
                              color: isAllThreeStars
                                  ? Colors.amber
                                  : displayColor,
                              progress: cardProgress,
                            ),
                            SizedBox(height: 8.h),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(
                                isMastered
                                    ? (isAllThreeStars
                                          ? '★ $gameplayStars / $maxGameplayStars • 100% PERFECT'
                                          : '★ $gameplayStars / $maxGameplayStars • REPLAY FOR 3★')
                                    : '★ $gameplayStars / $maxGameplayStars $gameStarsLabel',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: isAllThreeStars
                                      ? Colors.amber.shade700
                                      : displayColor.withValues(
                                          alpha: isMastered ? 0.9 : 0.7,
                                        ),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 12.w),
                      _buildSpatialBadge(
                        color: displayColor,
                        currentLevel: currentLevel,
                        isNew: isNew,
                        isMastered: isMastered,
                        isAllThreeStars: isAllThreeStars,
                      ),
                    ],
                  ),
                ),

                // Integrated Spatial Squircle Icon (Zero-jitter 120 FPS performance, cleanly bounded inside card)
                PositionedDirectional(
                  start: 16.w,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      width: 56.r,
                      height: 56.r,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            displayColor,
                            displayColor.withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                      ),
                      child: Icon(
                        GameHelper.getIconForSubtype(subtype),
                        color: Colors.white,
                        size: 28.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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

  Widget _buildSpatialBadge({
    required Color color,
    required int currentLevel,
    required bool isNew,
    required bool isMastered,
    required bool isAllThreeStars,
  }) {
    if (isMastered) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isAllThreeStars
                ? [Colors.amber.shade400, Colors.orange.shade500]
                : [color, color.withValues(alpha: 0.85)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          isAllThreeStars ? Icons.stars_rounded : Icons.emoji_events_rounded,
          color: Colors.white,
          size: 16.r,
        ),
      );
    }

    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            context.tr('quest_archive.new_badge', fallback: 'NEW'),
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
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        "Lv.$currentLevel",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          fontWeight: FontWeight.w900,
          color: color,
        ),
        maxLines: 1,
      ),
    );
  }

  GameSubtype? _findNextActiveGame(List<GameSubtype> games, UserEntity user) {
    if (games.isEmpty) return null;

    // 1. First game started but not mastered
    for (final game in games) {
      final completed = user.completedLevels[game.name]?.length ?? 0;
      final total = CurriculumManifest.getLevels(game.name);
      if (completed > 0 && completed < total) {
        return game;
      }
    }

    // 2. First unplayed game
    for (final game in games) {
      final completed = user.completedLevels[game.name]?.length ?? 0;
      if (completed == 0) {
        return game;
      }
    }

    // 3. First mastered game needing 3-star completion
    for (final game in games) {
      final total = CurriculumManifest.getLevels(game.name);
      final categoryStars = user.starRatings[game.name] ?? {};
      int stars = 0;
      categoryStars.forEach((k, v) {
        if (k != 'magic_stars' && k != 'claimed_chests') stars += v;
      });
      if (stars < total * 3) {
        return game;
      }
    }

    // 4. Default to first game
    return games.first;
  }

  Widget _buildQuickResumeHero({
    required ThemeResult theme,
    required UserEntity user,
    required GameSubtype nextGame,
    required bool isDark,
  }) {
    final gameTheme = LevelThemeHelper.getTheme(nextGame.name, isDark: isDark);
    final completedCount = user.completedLevels[nextGame.name]?.length ?? 0;
    final gameTotalLevels = CurriculumManifest.getLevels(nextGame.name);
    final isMastered = completedCount >= gameTotalLevels;
    final currentLevel = isMastered ? gameTotalLevels : completedCount + 1;
    final displayColor = theme.primaryColor;

    return Semantics(
      button: true,
      label:
          '${context.tr('category_games.resume_lesson', fallback: 'Resume Lesson')}: ${gameTheme.title}, ${isMastered ? 'Mastered' : 'Level $currentLevel'}',
      child: ScaleButton(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(
            '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(widget.categoryId)}&gameType=${Uri.encodeQueryComponent(nextGame.name)}',
          );
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: displayColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: displayColor.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [displayColor, displayColor.withValues(alpha: 0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  GameHelper.getIconForSubtype(nextGame),
                  color: Colors.white,
                  size: 16.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isMastered
                          ? context.tr(
                              'category_games.review_practice',
                              fallback: 'REVIEW & PRACTICE',
                            )
                          : context.tr(
                              'category_games.continue_journey',
                              fallback: 'CONTINUE PRACTICE',
                            ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w800,
                        color: displayColor,
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            gameTheme.title,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w900,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: displayColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            isMastered ? 'MAX' : 'Lv.$currentLevel',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w900,
                              color: displayColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: displayColor,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.tr('category_games.play_now', fallback: 'PLAY'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14.r,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<GameSubtype> _getFilteredGames(
    UserEntity user,
    List<GameSubtype> games,
  ) {
    final query = _searchQuery.value.trim().toLowerCase();
    final filter = _activeFilter.value;

    return games.where((game) {
      if (query.isNotEmpty) {
        final theme = LevelThemeHelper.getTheme(game.name);
        final title = theme.title.toLowerCase();
        if (!title.contains(query) &&
            !game.name.toLowerCase().contains(query)) {
          return false;
        }
      }

      if (filter == 'all') return true;

      final completed = user.completedLevels[game.name]?.length ?? 0;
      final total = CurriculumManifest.getLevels(game.name);
      final isMastered = completed >= total;

      final categoryStars = user.starRatings[game.name] ?? {};
      int gameplayStars = 0;
      categoryStars.forEach((k, v) {
        if (k != 'magic_stars' && k != 'claimed_chests') gameplayStars += v;
      });
      final maxStars = total * 3;
      final isAllThreeStars = isMastered && gameplayStars >= maxStars;

      if (filter == 'inProgress') {
        return completed > 0 && !isMastered;
      } else if (filter == 'needStars') {
        return completed > 0 && !isAllThreeStars;
      } else if (filter == 'mastered') {
        return isMastered;
      }

      return true;
    }).toList();
  }

  Widget _buildFilterBar(ThemeResult theme, bool isDark, UserEntity user) {
    final displayColor = theme.primaryColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;

    int inProgressCount = 0;
    int needStarsCount = 0;
    int masteredCount = 0;

    for (final game in _games) {
      final completed = user.completedLevels[game.name]?.length ?? 0;
      final total = CurriculumManifest.getLevels(game.name);
      final isMastered = completed >= total;

      final categoryStars = user.starRatings[game.name] ?? {};
      int gameplayStars = 0;
      categoryStars.forEach((k, v) {
        if (k != 'magic_stars' && k != 'claimed_chests') gameplayStars += v;
      });
      final maxStars = total * 3;
      final isAllThreeStars = isMastered && gameplayStars >= maxStars;

      if (completed > 0 && !isMastered) inProgressCount++;
      if (completed > 0 && !isAllThreeStars) needStarsCount++;
      if (isMastered) masteredCount++;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: _isSearchOpen,
          builder: (context, isOpen, _) {
            if (!isOpen) return const SizedBox.shrink();
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 10.h),
              child: Container(
                height: 44.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: displayColor.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    color: contentColor,
                  ),
                  decoration: InputDecoration(
                    hintText: context.tr(
                      'category_games.search_hint',
                      fallback: 'Search games...',
                    ),
                    hintStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: contentColor.withValues(alpha: 0.4),
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: displayColor,
                      size: 20.r,
                    ),
                    suffixIcon: ValueListenableBuilder<String>(
                      valueListenable: _searchQuery,
                      builder: (context, query, _) {
                        if (query.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 16.r,
                            color: contentColor.withValues(alpha: 0.6),
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery.value = '';
                          },
                        );
                      },
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Fluid Filter Chips Bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 2.h),
          clipBehavior: Clip.hardEdge,
          child: ValueListenableBuilder<String>(
            valueListenable: _activeFilter,
            builder: (context, currentFilter, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFilterChip(
                    label: context.tr('common.all', fallback: 'All'),
                    count: _games.length,
                    filterKey: 'all',
                    isSelected: currentFilter == 'all',
                    displayColor: displayColor,
                    isDark: isDark,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    label: context.tr(
                      'category_games.in_progress',
                      fallback: 'In Progress',
                    ),
                    count: inProgressCount,
                    filterKey: 'inProgress',
                    isSelected: currentFilter == 'inProgress',
                    displayColor: displayColor,
                    isDark: isDark,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    label: context.tr(
                      'category_games.needs_stars',
                      fallback: 'Need 3★',
                    ),
                    count: needStarsCount,
                    filterKey: 'needStars',
                    isSelected: currentFilter == 'needStars',
                    displayColor: displayColor,
                    isDark: isDark,
                  ),
                  SizedBox(width: 8.w),
                  _buildFilterChip(
                    label: context.tr(
                      'category_games.mastered_filter',
                      fallback: 'Mastered',
                    ),
                    count: masteredCount,
                    filterKey: 'mastered',
                    isSelected: currentFilter == 'mastered',
                    displayColor: displayColor,
                    isDark: isDark,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewModeToggle(
    Color displayColor,
    Color contentColor,
    bool isDark,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isGridView,
      builder: (context, isGrid, _) {
        return Semantics(
          button: true,
          label: isGrid ? 'Switch to List View' : 'Switch to Grid View',
          child: ScaleButton(
            onTap: () {
              HapticFeedback.lightImpact();
              _isGridView.value = !_isGridView.value;
            },
            child: Container(
              constraints: BoxConstraints(minWidth: 44.r, minHeight: 44.r),
              alignment: Alignment.center,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: isGrid
                      ? displayColor.withValues(alpha: 0.15)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03)),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: isGrid
                        ? displayColor.withValues(alpha: 0.3)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05)),
                  ),
                ),
                child: Icon(
                  isGrid ? Icons.view_agenda_rounded : Icons.grid_view_rounded,
                  size: 18.r,
                  color: isGrid
                      ? displayColor
                      : contentColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required String filterKey,
    required bool isSelected,
    required Color displayColor,
    required bool isDark,
  }) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label, $count games',
      child: ScaleButton(
        onTap: () {
          HapticFeedback.lightImpact();
          _activeFilter.value = filterKey;
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: isSelected
                ? displayColor
                : (isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.85)),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isSelected
                  ? displayColor
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.10)
                        : AppColors.slate200),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              SizedBox(width: 4.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : displayColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : displayColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudioGridCard({
    required BuildContext context,
    required UserEntity user,
    required GameSubtype subtype,
    required bool isDark,
    required int index,
  }) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final completedCount = user.completedLevels[subtype.name]?.length ?? 0;
    final gameTotalLevels = CurriculumManifest.getLevels(subtype.name);
    final isMastered = completedCount >= gameTotalLevels;
    final currentLevel = isMastered ? gameTotalLevels : completedCount + 1;
    final isNew =
        !user.categoryStats.containsKey(subtype.name) && completedCount == 0;

    final displayColor = theme.primaryColor;
    final contentColor = Theme.of(context).colorScheme.onSurface;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBorderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate100);

    final double cardProgress =
        (completedCount.clamp(0, gameTotalLevels)) / gameTotalLevels.toDouble();

    final categoryStars = user.starRatings[subtype.name] ?? {};
    int gameplayStars = 0;
    categoryStars.forEach((key, value) {
      if (key != 'magic_stars' && key != 'claimed_chests') {
        gameplayStars += value;
      }
    });
    final maxGameplayStars = gameTotalLevels * 3;
    final isAllThreeStars = isMastered && gameplayStars >= maxGameplayStars;

    return Semantics(
      button: true,
      label:
          '${theme.title}, ${isMastered ? (isAllThreeStars ? 'Perfect' : 'Mastered') : '$gameplayStars of $maxGameplayStars Game Stars'}',
      child: ScaleButton(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(
            '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(widget.categoryId)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
          );
        },
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isMidnight
                ? AppColors.midnightSurface
                : (isDark ? const Color(0xFF131A29) : Colors.white),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: cardBorderColor, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          displayColor,
                          displayColor.withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      GameHelper.getIconForSubtype(subtype),
                      color: Colors.white,
                      size: 20.r,
                    ),
                  ),
                  _buildSpatialBadge(
                    color: displayColor,
                    currentLevel: currentLevel,
                    isNew: isNew,
                    isMastered: isMastered,
                    isAllThreeStars: isAllThreeStars,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AutoSizeText(
                    theme.title.toUpperCase(),
                    maxLines: 2,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      color: contentColor,
                      letterSpacing: 0.5,
                      height: 1.15,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              _buildLiquidProgressBar(
                color: isAllThreeStars ? Colors.amber : displayColor,
                progress: cardProgress,
              ),
              SizedBox(height: 6.h),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  isMastered
                      ? (isAllThreeStars ? '★ 100% PERFECT' : '★ REPLAY FOR 3★')
                      : '★ $gameplayStars / $maxGameplayStars',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    color: isAllThreeStars
                        ? Colors.amber.shade700
                        : displayColor.withValues(
                            alpha: isMastered ? 0.9 : 0.7,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyFilterState(
    ThemeResult theme,
    bool isDark,
    Color contentColor,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 36.h),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: theme.primaryColor,
              size: 32.r,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            context.tr(
              'category_games.no_games_found',
              fallback: 'No games match your filter',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: contentColor,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(
              'category_games.try_reset_filter',
              fallback: 'Try clearing search or choosing another filter.',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              color: contentColor.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          ScaleButton(
            onTap: () {
              HapticFeedback.lightImpact();
              _searchController.clear();
              _searchQuery.value = '';
              _activeFilter.value = 'all';
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: theme.primaryColor,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                context.tr(
                  'category_games.show_all_games',
                  fallback: 'Show All Games',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Extracted Domain / Presentation Logic to keep the Widget clean
class _CategoryGamesLogic {
  static const Map<String, List<GameSubtype>> _journeyOrder = {
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

  static List<GameSubtype> getGamesForCategory(String category) {
    final List<GameSubtype> allGames = GameSubtype.values
        .where((s) => s.category.name == category && !s.isLegacy)
        .toList();

    final order = _journeyOrder[category];
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

  static String getRank(BuildContext context, double progress) {
    if (progress <= 0.0) {
      return context.tr('category_games.rank_beginner', fallback: 'BEGINNER');
    }
    if (progress < 0.15) {
      return context.tr('category_games.rank_novice', fallback: 'NOVICE');
    }
    if (progress < 0.35) {
      return context.tr('category_games.rank_scholar', fallback: 'SCHOLAR');
    }
    if (progress < 0.55) {
      return context
          .tr('home.discovery_diff_expert', fallback: 'Expert')
          .toUpperCase();
    }
    if (progress < 0.80) {
      return context.tr('category_games.rank_virtuoso', fallback: 'VIRTUOSO');
    }
    if (progress < 0.99) {
      return context.tr(
        'quest_archive.status_grandmaster',
        fallback: 'GRANDMASTER',
      );
    }
    return context.tr('quest_archive.status_legendary', fallback: 'LEGENDARY');
  }
}
