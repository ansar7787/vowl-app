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
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';

class QuestLibraryPage extends StatefulWidget {
  const QuestLibraryPage({super.key});

  @override
  State<QuestLibraryPage> createState() => _QuestLibraryPageState();
}

class _QuestLibraryPageState extends State<QuestLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  final ValueNotifier<String> _selectedCategory = ValueNotifier('all');

  // Cache list of categories and clean subtypes to avoid rebuilding lists on every frame
  late final List<String> _categories;
  late final List<GameSubtype> _allSubtypes;

  @override
  void initState() {
    super.initState();
    _categories = [
      'all',
      'vocabulary',
      'grammar',
      'speaking',
      'listening',
      'reading',
      'writing',
      'accent',
      'roleplay',
      'elite',
    ];
    _allSubtypes = GameSubtype.values.where((s) => !s.isLegacy).toList();
    _searchController.addListener(_onSearchChanged);

    // FIX: Prewarm the curriculum cache for ALL game subtypes so that when the
    // user taps any quest card, ModernCategoryMap can read the level count
    // synchronously from cache instead of doing a cold async asset probe.
    // This is exactly what CategoryGamesPage does for its subset of games —
    // without it, the Quest Library path skipped the cache warm-up entirely,
    // causing the map to show a blank loading state on entry (the "stuck/laggy"
    // transition bug).
    CurriculumService.prewarmCache(_allSubtypes.map((s) => s.name).toList());
  }

  void _onSearchChanged() {
    final trimmed = _searchController.text.trim().toLowerCase();
    if (trimmed == _searchQuery.value) return;
    _searchQuery.value = trimmed;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchQuery.dispose();
    _selectedCategory.dispose();
    super.dispose();
  }

  List<GameSubtype> _getFilteredSubtypes() {
    return _allSubtypes.where((subtype) {
      // 1. Filter by category
      if (_selectedCategory.value != 'all') {
        final catName = subtype.category.name.toLowerCase();
        final selectedLower = _selectedCategory.value.toLowerCase();
        if (selectedLower == 'elite') {
          if (catName != 'elitemastery') return false;
        } else {
          if (catName != selectedLower) return false;
        }
      }

      // 2. Filter by search query
      if (_searchQuery.value.isNotEmpty) {
        final theme = LevelThemeHelper.getTheme(subtype.name);
        final title = theme.title.toLowerCase();
        final name = subtype.name.toLowerCase();
        if (!title.contains(_searchQuery.value) &&
            !name.contains(_searchQuery.value)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// Returns the category-specific accent color for filter chips.
  Color _getCategoryChipColor(String cat) {
    switch (cat) {
      case 'all':
        return const Color(0xFF6366F1);
      case 'elite':
        return LevelThemeHelper.getCategoryBaseColor('elitemastery');
      default:
        return LevelThemeHelper.getCategoryBaseColor(cat);
    }
  }

  /// Returns the next rank label the user should aim for.
  String _getNextStatus(BuildContext context, double progress) {
    if (progress <= 0.0) return context.tr('quest_archive.status_explorer', fallback: 'Explorer');
    if (progress < 0.15) return context.tr('quest_archive.status_adventurer', fallback: 'Adventurer');
    if (progress < 0.35) return context.tr('quest_archive.status_champion', fallback: 'Champion');
    if (progress < 0.55) return context.tr('quest_archive.status_conqueror', fallback: 'Conqueror');
    if (progress < 0.80) return context.tr('quest_archive.status_grandmaster', fallback: 'Grandmaster');
    return context.tr('quest_archive.status_legendary', fallback: 'Legendary');
  }

  /// Category progress for section headers in the grouped "all" view.
  double _getCategoryProgress(UserEntity user, QuestType category) {
    final subtypes = _allSubtypes.where((s) => s.category == category);
    if (subtypes.isEmpty) return 0;
    int cleared = 0;
    for (final s in subtypes) {
      cleared += (user.completedLevels[s.name]?.length ?? 0).clamp(0, 200);
    }
    return cleared / (subtypes.length * 200);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight = context.watch<ThemeCubit>().state.isMidnight;

    final bgColor = isMidnight
        ? const Color(0xFF020617)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final authState = context.watch<AuthBloc>().state;
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const SafeArea(child: HomeShimmerLoading()),
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // 1. Immersive Mesh Gradient Background
          const MeshGradientBackground(showLetters: false),

          // 2. Dynamic Scroll Content
          RepaintBoundary(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListenableBuilder(
                  listenable: Listenable.merge([
                    _searchQuery,
                    _selectedCategory,
                  ]),
                  builder: (context, _) {
                    final filteredList = _getFilteredSubtypes();
                    return CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Safe area spacing for floating app bar
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: MediaQuery.paddingOf(context).top + 95.h,
                          ),
                        ),

                        // 3. Stats Dashboard Panel
                        SliverToBoxAdapter(
                          child: _buildLibraryStatsDashboard(user, isDark),
                        ),

                        // 4. Sticky Filters (Search & Categories)
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _StickyFilterDelegate(
                            isDark: isDark,
                            contentColor: contentColor,
                            searchField: _buildSearchField(isDark, contentColor),
                            categoriesTrack: _buildCategoriesTrack(isDark),
                            topPadding: MediaQuery.paddingOf(context).top + 95.h,
                          ),
                        ),

                        // 5. Content: Grouped sections vs Filtered vertical list
                        //    - "all" + no search → horizontal sections per category
                        //    - specific category or search → vertical card list
                        if (_selectedCategory.value == 'all' &&
                            _searchQuery.value.isEmpty) ...[
                          // ── Grouped Category Sections ──
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final category = QuestType.values[index];
                              final subtypes = _allSubtypes
                                  .where((s) => s.category == category)
                                  .toList();
                              if (subtypes.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return _buildCategorySection(
                                category,
                                subtypes,
                                user,
                                isDark,
                                contentColor,
                              );
                            }, childCount: QuestType.values.length),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 100.h),
                          ),
                        ] else ...[
                          // ── Filtered Vertical List ──
                          if (filteredList.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: _buildEmptyState(contentColor),
                            )
                          else
                            SliverPadding(
                              padding: EdgeInsets.fromLTRB(
                                24.w,
                                24.h,
                                24.w,
                                100.h,
                              ),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate((
                                  context,
                                  index,
                                ) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 20.h),
                                    child: _buildLibraryQuestCard(
                                      context,
                                      user,
                                      filteredList[index],
                                      isDark,
                                    ),
                                  );
                                }, childCount: filteredList.length),
                              ),
                            ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // 6. Floating Glass Island AppBar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: RepaintBoundary(
              child: _buildFloatingGlassAppBar(context, isDark, contentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingGlassAppBar(
    BuildContext context,
    bool isDark,
    Color contentColor,
  ) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 12.h,
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
              // Centered Title Pill
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        color: const Color(0xFF3B82F6),
                        size: 16.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          context.tr(
                            'quest_archive.title',
                            fallback: 'Quest Library',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                            color: contentColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Balanced spacer to match back button width
              SizedBox(width: 48.r),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryStatsDashboard(UserEntity user, bool isDark) {
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    // Calculate global stats across all active games (200 levels each)
    int clearedLevels = 0;
    for (final subtype in _allSubtypes) {
      final completed = user.completedLevels[subtype.name]?.length ?? 0;
      clearedLevels += completed.clamp(0, 200);
    }
    final totalLevels = _allSubtypes.length * 200;
    final progress = totalLevels > 0 ? (clearedLevels / totalLevels) : 0.0;

    return Semantics(
      label: context.tr(
        'quest_archive.mastery',
        fallback: 'Mastery',
        args: [
          (progress * 100).toStringAsFixed(
            progress < 0.01 && progress > 0 ? 2 : 1,
          ),
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
              color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
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
                          Text(
                            context.tr(
                              'quest_archive.global_progress',
                              fallback: 'Global Progress',
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF3B82F6),
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: AlignmentDirectional.centerStart,
                            child: Text(
                              context.tr(
                                'quest_archive.mastery',
                                fallback: 'Mastery',
                                args: [
                                  (progress * 100).toStringAsFixed(
                                    progress < 0.01 && progress > 0 ? 2 : 1,
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: contentColor,
                              ),
                              maxLines: 1,
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
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            context.tr(
                              'quest_archive.levels_cleared',
                              fallback: 'Levels Cleared',
                              args: [
                                clearedLevels.toString(),
                                totalLevels.toString(),
                              ],
                            ),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF3B82F6),
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                _buildProgressBar(
                  const Color(0xFF3B82F6),
                  clearedLevels + 1,
                  total: totalLevels,
                ),
                SizedBox(height: 20.h),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatMini(
                        Icons.check_circle_rounded,
                        context.tr(
                          'quest_archive.levels_cleared',
                          fallback: 'Levels Cleared',
                          args: [clearedLevels.toString(), totalLevels.toString()],
                        ),
                        '$clearedLevels',
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: _buildStatMini(
                          Icons.stars_rounded,
                          context.tr(
                            'quest_archive.status',
                            fallback: 'Status',
                          ),
                          _getGlobalStatus(context, progress),
                          const Color(0xFF3B82F6),
                          isDark,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _buildStatMini(
                          Icons.arrow_upward_rounded,
                          context.tr('quest_archive.next_rank', fallback: 'NEXT RANK'),
                          progress >= 0.99
                              ? '🏆'
                              : _getNextStatus(context, progress),
                          const Color(0xFF10B981),
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
    );
  }

  String _getGlobalStatus(BuildContext context, double progress) {
    if (progress <= 0.0) {
      return context.tr('quest_archive.status_initiate', fallback: 'Initiate');
    }
    if (progress < 0.15) {
      return context.tr('quest_archive.status_explorer', fallback: 'Explorer');
    }
    if (progress < 0.35) {
      return context.tr(
        'quest_archive.status_adventurer',
        fallback: 'Adventurer',
      );
    }
    if (progress < 0.55) {
      return context.tr('quest_archive.status_champion', fallback: 'Champion');
    }
    if (progress < 0.80) {
      return context.tr(
        'quest_archive.status_conqueror',
        fallback: 'Conqueror',
      );
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
            Flexible(
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

  Widget _buildSearchField(bool isDark, Color contentColor) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
        ),
        child: TextField(
          controller: _searchController,
          textInputAction: TextInputAction.search,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 18.sp,
            fontWeight: FontWeight.w500,
            color: contentColor,
          ),
          decoration: InputDecoration(
            hintText: context.tr(
              'quest_archive.search_hint',
              fallback: 'Search quests...',
            ),
            hintStyle: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: contentColor.withValues(alpha: 0.4),
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: const Color(0xFF3B82F6),
              size: 24.r,
            ),
            suffixIcon: ValueListenableBuilder<String>(
              valueListenable: _searchQuery,
              builder: (context, searchQuery, _) {
                return searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, size: 20.r),
                        color: contentColor.withValues(alpha: 0.6),
                        tooltip: context.tr('common.clear', fallback: 'Clear'),
                        onPressed: () => _searchController.clear(),
                      ).animate().scale(duration: 200.ms)
                    : const SizedBox.shrink();
              },
            ),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF1E293B) // slate-800
                : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.r),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: 20.h,
              horizontal: 20.w,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesTrack(bool isDark) {
    return SizedBox(
      height: 40.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory.value == cat;

          Color activeColor = _getCategoryChipColor(cat);
          final label = context
              .tr('categories.${cat.toLowerCase()}')
              .toUpperCase();

          return Padding(
            padding: EdgeInsetsDirectional.only(end: 12.w),
            child: Semantics(
              button: true,
              selected: isSelected,
              label: label,
              child: ScaleButton(
                onTap: () {
                  _selectedCategory.value = cat;
                },
                child: ExcludeSemantics(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    constraints: BoxConstraints(minHeight: 40.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.15)
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.02)),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.3)
                            : (isDark ? Colors.white : Colors.black).withValues(
                                alpha: 0.08,
                              ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? activeColor
                              : (isDark ? Colors.white60 : Colors.black54),
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUPED "ALL" VIEW — Category Section (Netflix pattern)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCategorySection(
    QuestType category,
    List<GameSubtype> subtypes,
    UserEntity user,
    bool isDark,
    Color contentColor,
  ) {
    final catColor = LevelThemeHelper.getCategoryBaseColor(
      category == QuestType.eliteMastery ? 'elitemastery' : category.name,
    );
    final displayCatColor = isDark
        ? catColor
        : HSLColor.fromColor(catColor).withLightness(0.4).toColor();
    final progress = _getCategoryProgress(user, category);
    final progressPercent = (progress * 100).toInt();
    final catLabel = context.tr(
      'categories.${category == QuestType.eliteMastery ? 'elite' : category.name}',
    );

    return Padding(
      padding: EdgeInsets.only(top: 28.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section Header ──
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              children: [
                Container(
                  width: 6.w,
                  height: 24.h,
                  decoration: BoxDecoration(
                    color: displayCatColor,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catLabel.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w900,
                          color: contentColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        context.tr(
                          'quest_archive.quests_progress',
                          fallback: '{} Quests · {}%',
                          args: [subtypes.length.toString(), progressPercent.toString()],
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: displayCatColor.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                ScaleButton(
                  onTap: () {
                    _selectedCategory.value =
                        category == QuestType.eliteMastery
                            ? 'elite'
                            : category.name;
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: displayCatColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: displayCatColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          context.tr('profile.view_all', fallback: 'VIEW ALL'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: displayCatColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 10.r,
                          color: displayCatColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // ── Horizontal Card Scroll ──
          SizedBox(
            height: 160.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              itemCount: subtypes.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: 14.w),
                  child: _buildCompactQuestCard(
                    subtypes[index],
                    user,
                    isDark,
                    displayCatColor,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactQuestCard(
    GameSubtype subtype,
    UserEntity user,
    bool isDark,
    Color catColor,
  ) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final currentLevel = (user.completedLevels[subtype.name]?.length ?? 0) + 1;
    final completedCount = (currentLevel - 1).clamp(0, 200);
    final isMastered = completedCount >= 200;
    final isNew =
        !user.categoryStats.containsKey(subtype.name) && currentLevel == 1;
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Semantics(
      button: true,
      label: '${theme.title}, Level $currentLevel',
      child: ScaleButton(
        onTap: () => context.push(
          '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(subtype.category.name)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
        ),
        child: ExcludeSemantics(
          child: Container(
            width: 148.w,
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isMastered
                    ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                    : catColor.withValues(alpha: isDark ? 0.15 : 0.1),
                width: isMastered ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon + Badge Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 42.r,
                      height: 42.r,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            catColor,
                            catColor.withValues(alpha: 0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                        boxShadow: [
                          BoxShadow(
                            color: catColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        GameHelper.getIconForSubtype(subtype),
                        color: Colors.white,
                        size: 22.r,
                      ),
                    ),
                    if (isNew)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: catColor,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          context.tr('quest_archive.new_badge', fallback: 'NEW').toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 7.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      )
                    else if (isMastered)
                      Icon(
                        Icons.verified_rounded,
                        color: const Color(0xFFFFD700),
                        size: 18.r,
                      )
                    else
                      Text(
                        context.tr('quest_archive.level', fallback: 'Lv.{}', args: [currentLevel.toString()]),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w900,
                          color: catColor.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                // Title
                Text(
                  theme.title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w900,
                    color: contentColor,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8.h),
                // Mini Progress Bar
                _buildProgressBar(catColor, currentLevel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildEmptyState(Color contentColor) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 48.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56.r,
              color: contentColor.withValues(alpha: 0.2),
            ),
            SizedBox(height: 16.h),
            Text(
              context.tr(
                'quest_archive.no_results',
                fallback: 'No matching quests found',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: contentColor.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              context.tr('quest_archive.no_results_sub', fallback: 'Try a different search or category'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: contentColor.withValues(alpha: 0.3),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILTERED VIEW — Expanded Quest Card
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLibraryQuestCard(
    BuildContext context,
    UserEntity user,
    GameSubtype subtype,
    bool isDark,
  ) {
    final theme = LevelThemeHelper.getTheme(subtype.name, isDark: isDark);
    final currentLevel = (user.completedLevels[subtype.name]?.length ?? 0) + 1;
    final completedCount = (currentLevel - 1).clamp(0, 200);
    final isNew =
        !user.categoryStats.containsKey(subtype.name) && currentLevel == 1;
    final isMastered = completedCount >= 200;
    final displayColor = isDark
        ? theme.primaryColor
        : HSLColor.fromColor(theme.primaryColor).withLightness(0.4).toColor();
    final contentColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final completedPercent = (completedCount / 200 * 100).toInt();

    return Semantics(
      button: true,
      label:
          '${theme.title}, ${context.tr('quest_archive.completed', fallback: 'Completed', args: [completedPercent.toString()])}',
      child: RepaintBoundary(
        child: ScaleButton(
          onTap: () => context.push(
            '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(subtype.category.name)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
          ),
          child: ExcludeSemantics(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isMastered
                      ? const Color(0xFFFFD700).withValues(alpha: 0.4)
                      : displayColor.withValues(alpha: isDark ? 0.12 : 0.08),
                  width: isMastered ? 1.5 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    // Left Color Stripe — instant category identification
                    Container(
                      width: 5.w,
                      decoration: BoxDecoration(
                        color: displayColor,
                        borderRadius: BorderRadiusDirectional.only(
                          topStart: Radius.circular(24.r),
                          bottomStart: Radius.circular(24.r),
                        ),
                      ),
                    ),
                    // Icon Column
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 20.h,
                      ),
                      child: Container(
                        width: 52.r,
                        height: 52.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              displayColor,
                              displayColor.withValues(alpha: 0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(18.r),
                          boxShadow: [
                            BoxShadow(
                              color: displayColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          GameHelper.getIconForSubtype(subtype),
                          color: Colors.white,
                          size: 26.r,
                        ),
                      ),
                    ),
                    // Content Column
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          top: 18.h,
                          bottom: 18.h,
                          right: 16.w,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: displayColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Text(
                                    context.tr(
                                      'categories.${subtype.category.name.toLowerCase()}',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color: displayColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                _buildBadge(
                                  displayColor,
                                  currentLevel,
                                  isNew,
                                  isMastered,
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              theme.title.toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w900,
                                color: contentColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            _buildProgressBar(displayColor, currentLevel),
                            SizedBox(height: 6.h),
                            Text(
                              context.tr(
                                'quest_archive.completed',
                                fallback: 'Completed',
                                args: [completedPercent.toString()],
                              ),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: FontWeight.w800,
                                color: displayColor.withValues(alpha: 0.6),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(Color color, int currentLevel, {int total = 200}) {
    final progress = ((currentLevel - 1).clamp(0, total)) / total.toDouble();
    return Container(
      height: 8.h,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: FractionallySizedBox(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: progress.clamp(0.05, 1.0),
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
        ),
      ),
    );
  }

  Widget _buildBadge(Color color, int currentLevel, bool isNew, [bool isMastered = false]) {
    if (isMastered) {
      return Icon(
        Icons.verified_rounded,
        color: const Color(0xFFFFD700),
        size: 20.r,
      );
    }

    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
          ],
        ),
        child: Text(
          context.tr('quest_archive.new_badge', fallback: 'New'),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ).animate().shimmer(duration: 1.seconds);
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        context.tr('quest_archive.level', fallback: 'Lv.{}', args: [currentLevel.toString()]),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _StickyFilterDelegate extends SliverPersistentHeaderDelegate {
  final bool isDark;
  final Color contentColor;
  final Widget searchField;
  final Widget categoriesTrack;
  final double topPadding;

  _StickyFilterDelegate({
    required this.isDark,
    required this.contentColor,
    required this.searchField,
    required this.categoriesTrack,
    required this.topPadding,
  });

  @override
  double get minExtent => 160.h; // increased to prevent RenderFlex overflow
  @override
  double get maxExtent => 160.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    // Determine how much glass effect to show based on scroll overlap
    final isPinned = overlapsContent || shrinkOffset > 0;

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: isPinned ? 8 : 0,
          sigmaY: isPinned ? 8 : 0,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: isPinned
                ? (isDark ? Colors.black : Colors.white).withValues(alpha: 0.8)
                : Colors.transparent,
            border: isPinned
                ? Border(
                    bottom: BorderSide(
                      color: (isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.05),
                    ),
                  )
                : null,
          ),
          padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              searchField,
              SizedBox(height: 12.h),
              categoriesTrack,
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StickyFilterDelegate oldDelegate) {
    return true; // Parent ListenableBuilder ensures we only rebuild on state change
  }
}
