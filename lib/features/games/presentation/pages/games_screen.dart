import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:haptic_feedback/haptic_feedback.dart';

import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/arena/presentation/pages/arena_duel_screen.dart';
import 'package:vowl/features/arena/presentation/pages/arena_lobby_waiting_screen.dart';
import 'package:vowl/features/arena/presentation/pages/arena_matchmaking_screen.dart';
import 'package:vowl/features/arena/presentation/utils/arena_network_helper.dart';
import 'package:vowl/features/arena/presentation/utils/arena_refuel_helper.dart';
import 'package:vowl/features/social_share/domain/entities/share_card_data.dart';
import 'package:vowl/features/social_share/presentation/widgets/share_card_preview_modal.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/vowl_micro_loader.dart';
import 'package:vowl/core/utils/game_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/data/constants/curriculum_manifest.dart';
import 'package:vowl/features/games/presentation/widgets/kids_category_shelf.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorffa000 = Color(0xFFFFA000);
  static const Color colorc0c0c0 = Color(0xFFC0C0C0);
  static const Color colorcd7f32 = Color(0xFFCD7F32);
}

// ---------------------------------------------------------------------------
// Main GamesScreen (Quest Hub & Arena)
// ---------------------------------------------------------------------------

/// 10/10 Games Hub screen featuring 1-tap quick resume, 1v1 PvP staking arena,
/// motivational curriculum mastery tiers, instant keyword search, and responsive 2-column quest cards.
class GamesScreen extends StatefulWidget {
  const GamesScreen({super.key});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  QuestType? _selectedCategory; // null = 'All'
  String _searchQuery = '';
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerHaptic() {
    try {
      Haptics.vibrate(HapticsType.light);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        (Theme.of(context).brightness == Brightness.dark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isMidnight
        ? Colors.black
        : (isDark ? AppColors.slate900 : Colors.white);

    return Scaffold(
      backgroundColor: bgColor,
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state.status == AuthStatus.authenticated
              ? state.user
              : null;

          if (user == null) return const _QuestHubShimmer();

          // Kids Mode isolation
          if (user.isKidsModeOnly) {
            return _buildKidsHub(context, user, isDark, isMidnight);
          }

          return Stack(
            children: [
              const MeshGradientBackground(showLetters: false),
              RefreshIndicator(
                onRefresh: () async {
                  context.read<AuthBloc>().add(const AuthRefreshUser());
                },
                color: AppColors.blue500,
                backgroundColor: isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? AppColors.midnightNavy : Colors.white),
                child: CustomScrollView(
                  controller: di.sl<ScrollController>(instanceName: 'games'),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    _GamesAppBar(isDark: isDark, user: user),
                    SliverPadding(
                      padding: EdgeInsets.only(
                        bottom: 120.h + MediaQuery.paddingOf(context).bottom,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          // 1. Quick Resume Hero Card (1-Tap Direct Play)
                          _QuickResumeHeroCard(user: user, isDark: isDark),

                          // 2. 1v1 PvP Staking Arena (Full-Width Flagship Card)
                          _PvPArenaCard(user: user, isDark: isDark),

                          // 3. Quick Speed Drills (Word Snap & Word Mixer)
                          _QuickDrillsRow(isDark: isDark),

                          // 4. Curriculum Mastery Tier Card (Replaces 0.1% bar)
                          _CurriculumMasteryCard(user: user, isDark: isDark),

                          // 6. Category Filter Dock & Search
                          _CategoryFilterDock(
                            selectedCategory: _selectedCategory,
                            searchController: _searchController,
                            searchQuery: _searchQuery,
                            isDark: isDark,
                            onCategorySelected: (cat) {
                              _triggerHaptic();
                              setState(() => _selectedCategory = cat);
                            },
                            onSearchChanged: (q) {
                              setState(
                                () => _searchQuery = q.trim().toLowerCase(),
                              );
                            },
                          ),

                          // 7. Responsive 2-Column Quest Cards Grid (With Smooth Category Transition)
                          AnimatedSwitcher(
                            duration: VowlMotion.shouldReduceMotion(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            layoutBuilder: (currentChild, previousChildren) =>
                                Stack(
                                  alignment: Alignment.topCenter,
                                  children: [
                                    ...previousChildren,
                                    ?currentChild,
                                  ],
                                ),
                            child: KeyedSubtree(
                              key: ValueKey<String>(
                                '${_selectedCategory?.name ?? "all"}_$_searchQuery',
                              ),
                              child: _QuestCardsGrid(
                                user: user,
                                isDark: isDark,
                                selectedCategory: _selectedCategory,
                                searchQuery: _searchQuery,
                              ),
                            ),
                          ),
                        ]),
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

  Widget _buildKidsHub(
    BuildContext context,
    UserEntity user,
    bool isDark,
    bool isMidnight,
  ) {
    return Stack(
      children: [
        const MeshGradientBackground(showLetters: false),
        CustomScrollView(
          controller: di.sl<ScrollController>(instanceName: 'games'),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _GamesAppBar(isDark: isDark, user: user, isKids: true),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.screen,
                16.h,
                AppSpacing.screen,
                120.h + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Text(
                    context.tr(
                      'games.kids_zone_title',
                      fallback: 'Kids Learning Zone',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.tr(
                      'games.kids_zone_subtitle',
                      fallback: 'Educational games for early learners',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: isDark ? Colors.white60 : AppColors.slate600,
                    ),
                  ),
                  SizedBox(height: 18.h),
                  KidsCategoryShelf(user: user),
                ]),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Sticky Glass App Bar with Live Coin & Streak Stats
// ---------------------------------------------------------------------------

class _GamesAppBar extends StatelessWidget {
  final bool isDark;
  final UserEntity user;
  final bool isKids;

  const _GamesAppBar({
    required this.isDark,
    required this.user,
    this.isKids = false,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final pillBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark
              ? AppColors.midnightNavy.withValues(alpha: 0.92)
              : Colors.white.withValues(alpha: 0.92));
    final pillBorder = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      pinned: true,
      centerTitle: true,
      expandedHeight: 110.h,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        centerTitle: true,
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title Pill
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 7.h,
                  ),
                  decoration: BoxDecoration(
                    color: pillBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: pillBorder, width: 1.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.3 : 0.06,
                        ),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(5.r),
                        decoration: BoxDecoration(
                          color: AppColors.blue500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isKids
                              ? Icons.child_care_rounded
                              : Icons.sports_esports_rounded,
                          color: AppColors.blue500,
                          size: 14.r,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        isKids
                            ? context.tr(
                                'games.tools_kids_zone',
                                fallback: 'Kids Zone',
                              )
                            : context.tr(
                                'games.quest_hub',
                                fallback: 'Quest Hub',
                              ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Live Coins Pill (Tap opens Treasury / Quest Coins screen)
                ScaleButton(
                  onTap: () {
                    try {
                      Haptics.vibrate(HapticsType.light);
                    } catch (_) {}
                    context.push(AppRouter.questCoinsRoute);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: pillBorder, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.coins,
                          color: AppColors.amber500,
                          size: 14.r,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          '${user.coins}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(width: 6.w),

                // Live Streak Pill (Tap opens Streak Calendar)
                ScaleButton(
                  onTap: () {
                    try {
                      Haptics.vibrate(HapticsType.light);
                    } catch (_) {}
                    context.push(AppRouter.streakRoute);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 7.h,
                    ),
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: pillBorder, width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.red500,
                          size: 15.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          '${user.currentStreak}',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : AppColors.slate900,
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
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Quick Resume Hero Card (Kills 5-Tap Friction with 1-Tap Play)
// ---------------------------------------------------------------------------

class _QuickResumeInfo {
  final GameSubtype subtype;
  final String category;
  final int activeLevel;
  final int maxLevels;
  final double progress;

  const _QuickResumeInfo({
    required this.subtype,
    required this.category,
    required this.activeLevel,
    required this.maxLevels,
    required this.progress,
  });

  static _QuickResumeInfo resolve(UserEntity user) {
    GameSubtype? bestSubtype;
    int highestCleared = -1;

    // Prioritize an in-progress game (started but not mastered)
    for (final type in QuestType.values) {
      for (final s in type.subtypes) {
        if (s.isLegacy) continue;
        final cleared = user.completedLevels[s.name]?.length ?? 0;
        final maxL = CurriculumManifest.getLevels(s.name);
        if (cleared > 0 && cleared < maxL && cleared > highestCleared) {
          highestCleared = cleared;
          bestSubtype = s;
        }
      }
    }

    // Fallback 1: Any started game
    if (bestSubtype == null) {
      for (final type in QuestType.values) {
        for (final s in type.subtypes) {
          if (s.isLegacy) continue;
          final cleared = user.completedLevels[s.name]?.length ?? 0;
          if (cleared > highestCleared) {
            highestCleared = cleared;
            bestSubtype = s;
          }
        }
      }
    }

    // Fallback 2: Default for brand new learners
    bestSubtype ??= GameSubtype.sentenceBuilder;

    final cleared = user.completedLevels[bestSubtype.name]?.length ?? 0;
    final maxL = CurriculumManifest.getLevels(bestSubtype.name);
    final activeLevel = (cleared >= maxL ? maxL : cleared + 1).clamp(
      1,
      maxL > 0 ? maxL : 20,
    );
    final progress = maxL > 0 ? (cleared / maxL).clamp(0.0, 1.0) : 0.0;
    final category = GameHelper.getCategoryForSubtype(bestSubtype);

    return _QuickResumeInfo(
      subtype: bestSubtype,
      category: category,
      activeLevel: activeLevel,
      maxLevels: maxL > 0 ? maxL : 20,
      progress: progress,
    );
  }
}

class _QuickResumeHeroCard extends StatelessWidget {
  final UserEntity user;
  final bool isDark;

  const _QuickResumeHeroCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final info = _QuickResumeInfo.resolve(user);
    final metadata = GameHelper.getGameMetadata(info.subtype, isDark: isDark);
    final color = metadata.color;

    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        8.h,
        AppSpacing.screen,
        8.h,
      ),
      child: ScaleButton(
        onTap: () {
          try {
            Haptics.vibrate(HapticsType.light);
          } catch (_) {}
          context.push(
            '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(info.category)}&gameType=${Uri.encodeQueryComponent(info.subtype.name)}',
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: borderColor, width: 1.0),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.15 : 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24.r),
            child: Stack(
              children: [
                // Subtle ambient glow behind the top-right circle
                Positioned(
                  right: -15.w,
                  top: -15.h,
                  child: Container(
                    width: 110.r,
                    height: 110.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: isDark ? 0.14 : 0.08),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(AppSpacing.cardSpacious),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Info on Left, Resumed Game Icon in Top-Right Circle
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // QUICK RESUME Tag
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 8.w,
                                    vertical: 3.5.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        LucideIcons.playCircle,
                                        size: 11.r,
                                        color: color,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        context.tr(
                                          'games.quick_resume',
                                          fallback: 'QUICK RESUME',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w900,
                                          color: color,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                // Game Title
                                Text(
                                  metadata.title,
                                  maxLines: 2,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 18.sp,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 2.h),
                                // Category Name
                                Text(
                                  metadata.categoryName,
                                  maxLines: 2,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          // Top-right circular design displaying the resumed game icon
                          Container(
                            width: 48.r,
                            height: 48.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(
                                alpha: isDark ? 0.22 : 0.12,
                              ),
                              border: Border.all(
                                color: color.withValues(
                                  alpha: isDark ? 0.40 : 0.25,
                                ),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(
                                    alpha: isDark ? 0.20 : 0.10,
                                  ),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                metadata.icon,
                                color: color,
                                size: 24.r,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16.h),

                      // Bottom Row: Level text on top, Progress bar underneath & 1-Tap Play CTA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Progress count placed on top of the progress bar
                                Text(
                                  '${context.tr('level_label_short', args: [info.activeLevel.toString()], fallback: 'Level ${info.activeLevel}')} / ${info.maxLevels}',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 11.sp,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? Colors.white60
                                        : AppColors.slate500,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                // Progress bar underneath the text
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: info.progress.clamp(0.04, 1.0),
                                    minHeight: 6.h,
                                    backgroundColor: color.withValues(
                                      alpha: 0.12,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // 1-Tap Play Button
                          ScaleButton(
                            onTap: () {
                              try {
                                Haptics.vibrate(HapticsType.medium);
                              } catch (_) {}
                              context.push(
                                '/game?category=${Uri.encodeQueryComponent(info.category)}&gameType=${Uri.encodeQueryComponent(info.subtype.name)}&level=${info.activeLevel}',
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 9.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    color,
                                    color.withValues(alpha: 0.85),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 16.r,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    context.tr(
                                      'game.continue_button',
                                      fallback: 'PLAY',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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

// ---------------------------------------------------------------------------
// 3. 1v1 PvP Staking Arena (Full-Width Flagship Card, Reduced Height)
// ---------------------------------------------------------------------------

class _PvPArenaCard extends StatefulWidget {
  final UserEntity user;
  final bool isDark;

  const _PvPArenaCard({required this.user, required this.isDark});

  @override
  State<_PvPArenaCard> createState() => _PvPArenaCardState();
}

class _PvPArenaCardState extends State<_PvPArenaCard> {
  bool _isLoading = false;

  void _showRefuelDialog() {
    final liveUser = context.read<AuthBloc>().state.user ?? widget.user;
    ArenaRefuelHelper.showRefuelDialog(context: context, user: liveUser);
  }

  DateTime? _lastMatchTapTime;

  Future<void> _startQuickMatch() async {
    final now = DateTime.now();
    if (_lastMatchTapTime != null &&
        now.difference(_lastMatchTapTime!) <
            const Duration(milliseconds: 750)) {
      return;
    }
    _lastMatchTapTime = now;

    if (_isLoading) return;

    if (!await ArenaNetworkHelper.ensureOnline(context)) return;
    if (!mounted) return;

    final liveUser = context.read<AuthBloc>().state.user ?? widget.user;
    if (liveUser.coins < 30) {
      _showRefuelDialog();
      return;
    }

    Navigator.of(
      context,
      rootNavigator: true,
    ).push(ArenaMatchmakingScreen.route(user: liveUser));
  }

  Future<void> _showJoinRoomDialog() async {
    if (!await ArenaNetworkHelper.ensureOnline(context)) return;
    if (!mounted) return;

    final liveUser = context.read<AuthBloc>().state.user ?? widget.user;
    if (liveUser.coins < 30) {
      _showRefuelDialog();
      return;
    }

    final controller = TextEditingController();
    bool isJoining = false;
    String? clipboardCandidate;

    // Check clipboard for potential duel code
    Clipboard.getData(Clipboard.kTextPlain)
        .then((clip) {
          final text = clip?.text?.trim().toUpperCase();
          if (text != null && text.isNotEmpty) {
            String extracted = text;
            if (extracted.contains('/DUEL/')) {
              extracted = extracted
                  .split('/DUEL/')
                  .last
                  .split('?')
                  .first
                  .trim();
            } else if (extracted.contains('CODE=')) {
              extracted = extracted.split('CODE=').last.split('&').first.trim();
            }
            if (extracted.length >= 4 &&
                extracted.length <= 16 &&
                !extracted.contains(' ')) {
              clipboardCandidate = extracted;
            }
          }
        })
        .catchError((_) {});

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          final isMidnight =
              isDark && Theme.of(ctx).scaffoldBackgroundColor == Colors.black;
          final cardBg = isMidnight
              ? AppColors.midnightSurface
              : (isDark ? const Color(0xFF131A29) : Colors.white);
          final textPrimary = isDark ? Colors.white : AppColors.slate900;
          final textSecondary = isDark
              ? AppColors.slate400
              : AppColors.slate600;
          final borderCol = isDark
              ? AppColors.indigo500.withValues(alpha: 0.22)
              : AppColors.indigo500.withValues(alpha: 0.16);

          return Dialog(
            backgroundColor: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
              side: BorderSide(color: borderCol, width: 1.0),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.cardSpacious),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Row: Swords icon + Title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          LucideIcons.swords,
                          color: AppColors.indigo500,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          'Join 1v1 Duel',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(
                          LucideIcons.x,
                          size: 18.sp,
                          color: textSecondary,
                        ),
                        onPressed: () => Navigator.of(dialogCtx).pop(),
                      ),
                    ],
                  ),

                  SizedBox(height: 12.h),

                  // Stake Badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.coins,
                          size: 13.r,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 5.w),
                        Text(
                          'Entry: 30🪙 • Winner Takes: 50🪙 + 5 XP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 14.h),

                  Text(
                    'Enter the room code shared by your challenger:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: textSecondary,
                    ),
                  ),

                  SizedBox(height: 10.h),

                  // Smart Clipboard Paste Chip (if detected)
                  if (clipboardCandidate != null &&
                      controller.text.isEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          controller.text = clipboardCandidate!;
                          setDialogState(() {});
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          margin: EdgeInsets.only(bottom: 8.h),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.clipboardPaste,
                                size: 12.r,
                                color: AppColors.indigo500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Paste "$clipboardCandidate"',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.indigo500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  // Input Box
                  TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: textPrimary,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'e.g. VOWL-DUEL-882',
                      hintStyle: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: textSecondary.withValues(alpha: 0.6),
                      ),
                      prefixIcon: Icon(
                        LucideIcons.keyRound,
                        size: 16.r,
                        color: isDark
                            ? AppColors.indigo400
                            : AppColors.indigo600,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 14.r,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                controller.clear();
                                setDialogState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF070A12)
                          : const Color(0xFFF1F5F9),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: borderCol),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(color: borderCol),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: const BorderSide(
                          color: AppColors.indigo500,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 18.h),

                  // Submit Button
                  ElevatedButton(
                    onPressed: isJoining
                        ? null
                        : () async {
                            String code = controller.text.trim().toUpperCase();
                            if (code.contains('/DUEL/')) {
                              code = code
                                  .split('/DUEL/')
                                  .last
                                  .split('?')
                                  .first
                                  .trim();
                            } else if (code.contains('CODE=')) {
                              code = code
                                  .split('CODE=')
                                  .last
                                  .split('&')
                                  .first
                                  .trim();
                            }
                            if (code.isEmpty) return;

                            if (!await ArenaNetworkHelper.ensureOnline(context)) {
                              setDialogState(() => isJoining = false);
                              return;
                            }
                            if (!mounted) return;

                            setDialogState(() => isJoining = true);
                            try {
                              final repo = di.sl<ArenaRepository>();
                              final session = await repo.joinRoom(
                                roomCode: code,
                                currentUser: widget.user,
                              );
                              if (dialogCtx.mounted) {
                                Navigator.of(dialogCtx).pop();
                              }
                              if (mounted) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).push(ArenaDuelScreen.route(session: session));
                              }
                            } catch (e) {
                              setDialogState(() => isJoining = false);
                              if (mounted) {
                                final errorMsg = e
                                    .toString()
                                    .replaceFirst('Exception: ', '')
                                    .trim();
                                CustomSnackBar.show(
                                  context: context,
                                  message: errorMsg.isNotEmpty
                                      ? errorMsg
                                      : 'Could not join duel room.',
                                  type: CustomSnackBarType.error,
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo500,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 44.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: isJoining
                        ? const VowlMicroLoader(color: Colors.white, size: 16)
                        : Text(
                            'Enter Duel (30🪙)',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),

                  SizedBox(height: 8.h),

                  TextButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) => controller.dispose());
  }

  Future<void> _createDuelInvite() async {
    if (_isLoading) return;

    if (!await ArenaNetworkHelper.ensureOnline(context)) return;
    if (!mounted) return;

    final liveUser = context.read<AuthBloc>().state.user ?? widget.user;
    if (liveUser.coins < 30) {
      _showRefuelDialog();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final repo = di.sl<ArenaRepository>();
      final session = await repo.createRoomCode(currentUser: liveUser);

      if (mounted) {
        // 1. Navigate to dedicated full-screen Waiting Lobby
        Navigator.of(
          context,
          rootNavigator: true,
        ).push(ArenaLobbyWaitingScreen.route(session: session));

        // 2. Open rich photo Share Card modal immediately
        ShareCardPreviewModal.show(
          context: context,
          data: ShareCardData.fromDuelInvite(
            userName: liveUser.safeDisplayName,
            userPhotoUrl: liveUser.photoUrl,
            roomCode: session.roomCode,
          ),
        );
      }
    } catch (e) {
      debugPrint('[_PvPArenaCard] Create duel invite error: $e');
      if (mounted) {
        CustomSnackBar.show(
          context: context,
          message: 'Could not create invite room. Please try again!',
          type: CustomSnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        widget.isDark &&
        Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (widget.isDark ? const Color(0xFF131A29) : Colors.white);
    final cardBorder = isMidnight
        ? AppColors.indigo500.withValues(alpha: 0.25)
        : (widget.isDark
              ? AppColors.indigo500.withValues(alpha: 0.20)
              : AppColors.indigo500.withValues(alpha: 0.16));
    final secondaryBg = widget.isDark
        ? AppColors.indigo950.withValues(alpha: 0.35)
        : AppColors.indigo50.withValues(alpha: 0.70);
    final secondaryBorder = widget.isDark
        ? AppColors.indigo400.withValues(alpha: 0.22)
        : AppColors.indigo500.withValues(alpha: 0.20);
    final secondaryTextColor = widget.isDark
        ? Colors.white
        : AppColors.indigo600;
    final secondaryIconColor = widget.isDark
        ? AppColors.indigo400
        : AppColors.indigo500;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        4.h,
        AppSpacing.screen,
        8.h,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: cardBorder, width: 1.0),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20.r),
          child: Stack(
            children: [
              Positioned(
                right: -10.w,
                top: -10.h,
                child: Container(
                  width: 80.r,
                  height: 80.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.indigo500.withValues(
                      alpha: widget.isDark ? 0.08 : 0.04,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(14.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: Swords Icon + Title & Badges + Subtitle
                    Row(
                      children: [
                        Container(
                          width: 44.r,
                          height: 44.r,
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.indigo500.withValues(
                                alpha: 0.25,
                              ),
                              width: 1.0,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.swords,
                              color: widget.isDark
                                  ? AppColors.indigo400
                                  : AppColors.indigo500,
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
                                  Expanded(
                                    child: Text(
                                      context.tr(
                                        'games.pvp_title',
                                        fallback: '1v1 Duel',
                                      ),
                                      maxLines: 2,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w900,
                                        color: widget.isDark
                                            ? Colors.white
                                            : AppColors.slate900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 7.w,
                                      vertical: 2.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber500.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(6.r),
                                      border: Border.all(
                                        color: AppColors.amber500.withValues(
                                          alpha: 0.30,
                                        ),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'WIN 50🪙',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 9.5.sp,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.amber500,
                                          ),
                                        ),
                                        Text(
                                          ' +5 XP',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 9.5.sp,
                                            fontWeight: FontWeight.w800,
                                            color: widget.isDark
                                                ? AppColors.indigo400
                                                : AppColors.indigo500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                context.tr(
                                  'games.pvp_subtitle',
                                  fallback:
                                      '30🪙 entry • 5-round live vocabulary duel',
                                ),
                                maxLines: 2,
                                softWrap: true,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.5.sp,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDark
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

                    // Bottom Row: 3 Action Buttons Placed Underneath
                    Row(
                      children: [
                        // 1. Primary Quick Match Battle CTA
                        Expanded(
                          flex: 5,
                          child: ScaleButton(
                            onTap: _isLoading ? null : _startQuickMatch,
                            child: Container(
                              height: 36.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    AppColors.indigo500,
                                    AppColors.indigo600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.indigo500.withValues(
                                      alpha: 0.35,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isLoading
                                  ? const VowlMicroLoader(
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 6.w,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              LucideIcons.swords,
                                              size: 14.r,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              'Battle (30🪙)',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 11.5.sp,
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // 2. Join Code Button
                        Expanded(
                          flex: 4,
                          child: ScaleButton(
                            onTap: _showJoinRoomDialog,
                            child: Container(
                              height: 36.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: secondaryBg,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: secondaryBorder),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        LucideIcons.keyRound,
                                        size: 13.r,
                                        color: secondaryIconColor,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Join Code',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // 3. Invite Friend Button
                        Expanded(
                          flex: 3,
                          child: ScaleButton(
                            onTap: _isLoading ? null : _createDuelInvite,
                            child: Container(
                              height: 36.h,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: secondaryBg,
                                borderRadius: BorderRadius.circular(10.r),
                                border: Border.all(color: secondaryBorder),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        LucideIcons.userPlus,
                                        size: 13.r,
                                        color: secondaryIconColor,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        'Invite',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 11.sp,
                                          fontWeight: FontWeight.w700,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
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
    );
  }
}

// ---------------------------------------------------------------------------
// 4. Quick Speed Drills: Word Snap & Word Mixer (Dual Card Row)
// ---------------------------------------------------------------------------

class _QuickDrillsRow extends StatelessWidget {
  final bool isDark;

  const _QuickDrillsRow({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? const Color(0xFF131A29) : Colors.white);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        0,
        AppSpacing.screen,
        8.h,
      ),
      child: Row(
        children: [
          // Left Card: Word Snap
          Expanded(
            child: ScaleButton(
              onTap: () {
                try {
                  Haptics.vibrate(HapticsType.light);
                } catch (_) {}
                context.push(AppRouter.wordSnapRoute);
              },
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.rose500.withValues(
                        alpha: isDark ? 0.08 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: AppColors.rose500.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.zap,
                            color: AppColors.rose500,
                            size: 14.r,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.rose500.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'WIN 10🪙 + 5 XP',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.rose500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Word Snap',
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '60s Daily Blitz',
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: isDark ? Colors.white60 : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(width: 10.w),

          // Right Card: Word Mixer
          Expanded(
            child: ScaleButton(
              onTap: () {
                try {
                  Haptics.vibrate(HapticsType.light);
                } catch (_) {}
                context.push(AppRouter.wordMixerRoute);
              },
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: AppColors.violet500.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet500.withValues(
                        alpha: isDark ? 0.08 : 0.04,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: AppColors.violet500.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.shuffle,
                            color: AppColors.violet500,
                            size: 14.r,
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 5.w,
                              vertical: 2.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.violet500.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'WIN 10🪙 + 5 XP',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.violet500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Word Mixer',
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Anagram Puzzle',
                      maxLines: 2,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        color: isDark ? Colors.white60 : AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Curriculum Mastery Card (Replaces the Demoralizing 0.1% Bar)
// ---------------------------------------------------------------------------

class _CurriculumMasteryCard extends StatelessWidget {
  final UserEntity user;
  final bool isDark;

  const _CurriculumMasteryCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    // Calculate total levels cleared across all non-legacy syllabus games
    int totalCleared = user.totalLevelsCompleted;
    if (totalCleared == 0) {
      for (final type in QuestType.values) {
        for (final s in type.subtypes) {
          if (s.isLegacy) continue;
          totalCleared += (user.completedLevels[s.name]?.length ?? 0);
        }
      }
    }

    // Determine current authentic Vowl mastery tier
    final String tierName;
    final String badgeEmoji;
    final Color tierColor;
    final int tierMin;
    final int tierMax;
    final String nextTierName;
    final String nextTierEmoji;

    if (totalCleared < 25) {
      tierName = context.tr('adventure.tier_beginner', fallback: 'Beginner');
      badgeEmoji = '🥉';
      tierColor = AppColors.amber500;
      tierMin = 0;
      tierMax = 25;
      nextTierName = context.tr('adventure.tier_novice', fallback: 'Novice');
      nextTierEmoji = '🥈';
    } else if (totalCleared < 75) {
      tierName = context.tr('adventure.tier_novice', fallback: 'Novice');
      badgeEmoji = '🥈';
      tierColor = _LocalPalette.colorc0c0c0;
      tierMin = 25;
      tierMax = 75;
      nextTierName = context.tr('adventure.tier_adept', fallback: 'Adept');
      nextTierEmoji = '🥇';
    } else if (totalCleared < 150) {
      tierName = context.tr('adventure.tier_adept', fallback: 'Adept');
      badgeEmoji = '🥇';
      tierColor = AppColors.gold;
      tierMin = 75;
      tierMax = 150;
      nextTierName = context.tr('adventure.tier_expert', fallback: 'Expert');
      nextTierEmoji = '💎';
    } else if (totalCleared < 300) {
      tierName = context.tr('adventure.tier_expert', fallback: 'Expert');
      badgeEmoji = '💎';
      tierColor = const Color(0xFF38BDF8);
      tierMin = 150;
      tierMax = 300;
      nextTierName = context.tr('adventure.tier_master', fallback: 'Master');
      nextTierEmoji = '👑';
    } else {
      tierName = context.tr('adventure.tier_master', fallback: 'Master');
      badgeEmoji = '👑';
      tierColor = const Color(0xFFA855F7);
      tierMin = 300;
      tierMax = 500;
      nextTierName = '';
      nextTierEmoji = '';
    }

    final levelsInTier = (totalCleared - tierMin).clamp(0, tierMax - tierMin);
    final tierSpan = tierMax - tierMin;
    final progress = tierSpan > 0
        ? (levelsInTier / tierSpan).clamp(0.04, 1.0)
        : 1.0;
    final toNext = tierMax - totalCleared;

    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.screen,
        4.h,
        AppSpacing.screen,
        8.h,
      ),
      child: ScaleButton(
        onTap: () {
          Haptics.vibrate(HapticsType.light);
          context.push(AppRouter.trophyRoomRoute);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: borderColor, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                width: 38.r,
                height: 38.r,
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                alignment: Alignment.center,
                child: Text(badgeEmoji, style: TextStyle(fontSize: 18.sp)),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '$tierName Tier',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.slate900,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                '($totalCleared lvls)',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white54
                                      : AppColors.slate500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    toNext > 0
                                        ? '$toNext to $nextTierName $nextTierEmoji'
                                        : 'Mastered! 👑',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      color: tierColor,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 2.w),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14.r,
                                color: tierColor,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3.r),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 5.h,
                        backgroundColor: tierColor.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                      ),
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
}

// ---------------------------------------------------------------------------
// 6. Category Filter Dock & Inline Search Bar
// ---------------------------------------------------------------------------

class _CategoryFilterDock extends StatelessWidget {
  final QuestType? selectedCategory;
  final TextEditingController searchController;
  final String searchQuery;
  final bool isDark;
  final ValueChanged<QuestType?> onCategorySelected;
  final ValueChanged<String> onSearchChanged;

  const _CategoryFilterDock({
    required this.selectedCategory,
    required this.searchController,
    required this.searchQuery,
    required this.isDark,
    required this.onCategorySelected,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final categories = QuestType.values;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    return Padding(
      padding: EdgeInsets.only(top: 8.h, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Search Field with optional Category Deep Dive
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    selectedCategory != null
                        ? context
                              .tr(
                                'games.${selectedCategory!.serializedName}.title',
                                fallback: selectedCategory!.name.toUpperCase(),
                              )
                              .toUpperCase()
                        : context.tr('games.title', fallback: 'QUEST ARCHIVE'),
                    maxLines: 2,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white70 : AppColors.slate700,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                if (selectedCategory != null)
                  ScaleButton(
                    onTap: () {
                      try {
                        Haptics.vibrate(HapticsType.light);
                      } catch (_) {}
                      context.push(
                        '${AppRouter.categoryGamesRoute}?category=${selectedCategory!.name}',
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: GameHelper.getCategoryColor(
                          selectedCategory!.name,
                        ).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: GameHelper.getCategoryColor(
                            selectedCategory!.name,
                          ).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('common.see_all', fallback: 'DEEP DIVE'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: GameHelper.getCategoryColor(
                                selectedCategory!.name,
                              ),
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 9.r,
                            color: GameHelper.getCategoryColor(
                              selectedCategory!.name,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  // 100+ Games Flagship Counter Badge (1-Tap Navigates to Quest Archive Screen)
                  ScaleButton(
                    onTap: () {
                      try {
                        Haptics.vibrate(HapticsType.light);
                      } catch (_) {}
                      context.push(AppRouter.libraryRoute);
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue500.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.blue500.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_esports_rounded,
                            size: 13.r,
                            color: AppColors.blue500,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            '100+ Games',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                              color: AppColors.blue500,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(width: 3.w),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 8.r,
                            color: AppColors.blue500,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          SizedBox(height: 10.h),

          // Quick Search Input - Clean, World-Class Standard Native Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isMidnight
                    ? AppColors.midnightSurface
                    : (isDark ? const Color(0xFF161F33) : Colors.white),
                hintText: context.tr(
                  'category_games.search_hint',
                  fallback: 'Search 100+ games, topics & skills...',
                ),
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white38 : AppColors.slate400,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18.r,
                  color: isDark ? Colors.white38 : AppColors.slate400,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 18.r,
                          color: isDark ? Colors.white60 : AppColors.slate600,
                        ),
                        splashRadius: 18.r,
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                      )
                    : null,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.h,
                  horizontal: 16.w,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: BorderSide(
                    color: isMidnight
                        ? Colors.white.withValues(alpha: 0.12)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : AppColors.slate200),
                    width: 1.0,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  borderSide: const BorderSide(
                    color: AppColors.blue500,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 8.h),

          // Horizontal Category Tab Pills - Full Bleed Edge-to-Edge Scroll
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
            child: Row(
              children: [
                // "All" Pill (100 games across all 9 categories)
                _FilterPill(
                  label: context.tr(
                    'categories.all',
                    fallback: 'All (${GameSubtype.values.length})',
                  ),
                  icon: Icons.auto_awesome_mosaic_rounded,
                  isSelected: selectedCategory == null,
                  color: AppColors.blue500,
                  isDark: isDark,
                  onTap: () => onCategorySelected(null),
                ),
                SizedBox(width: 8.w),
                // Category Pills
                ...categories.map((type) {
                  final isSelected = selectedCategory == type;
                  final color = GameHelper.getCategoryColor(type.name);
                  final icon = GameHelper.getIconForCategory(type);
                  final title = context.tr(
                    'games.${type.serializedName}.title',
                    fallback:
                        type.name[0].toUpperCase() + type.name.substring(1),
                  );

                  return Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: _FilterPill(
                      label: title,
                      icon: icon,
                      isSelected: isSelected,
                      color: color,
                      isDark: isDark,
                      onTap: () => onCategorySelected(type),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final pillBg = isSelected
        ? color
        : (isMidnight
              ? AppColors.midnightSurface
              : (isDark ? const Color(0xFF161F33) : Colors.white));
    final pillBorder = isSelected
        ? color
        : (isMidnight
              ? Colors.white.withValues(alpha: 0.12)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : AppColors.slate200));

    return Builder(
      builder: (pillCtx) {
        return ScaleButton(
          onTap: () {
            Scrollable.ensureVisible(
              pillCtx,
              alignment: 0.5,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            );
            onTap();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 12.w : 10.w,
              vertical: 7.h,
            ),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: pillBorder, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13.r,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : AppColors.slate700),
                ),
                SizedBox(width: 5.w),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : AppColors.slate800),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// 7. Responsive 2-Column Quest Cards Grid (With 1-Tap Play & Map Fallback)
// ---------------------------------------------------------------------------

class _QuestCardsGrid extends StatelessWidget {
  final UserEntity user;
  final bool isDark;
  final QuestType? selectedCategory;
  final String searchQuery;

  const _QuestCardsGrid({
    required this.user,
    required this.isDark,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    // Gather matching subtypes
    final List<GameSubtype> filtered = [];

    final categoriesToScan = selectedCategory != null
        ? [selectedCategory!]
        : QuestType.values;

    for (final type in categoriesToScan) {
      for (final s in type.subtypes) {
        if (s.isLegacy) continue;

        if (searchQuery.isNotEmpty) {
          final metadata = GameHelper.getGameMetadata(s, isDark: isDark);
          final matchesTitle = metadata.title.toLowerCase().contains(
            searchQuery,
          );
          final matchesCat = metadata.categoryName.toLowerCase().contains(
            searchQuery,
          );
          final matchesName = s.name.toLowerCase().contains(searchQuery);
          if (!matchesTitle && !matchesCat && !matchesName) continue;
        }

        filtered.add(s);
      }
    }

    if (filtered.isEmpty) {
      final categoryLabel = selectedCategory != null
          ? GameHelper.getCategoryForSubtype(
              selectedCategory!.subtypes.first,
            ).toUpperCase()
          : null;
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: 32.h,
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                LucideIcons.searchX,
                size: 36.r,
                color: isDark ? Colors.white30 : AppColors.slate300,
              ),
              SizedBox(height: 8.h),
              Text(
                categoryLabel != null
                    ? 'No quests found in $categoryLabel for "$searchQuery"'
                    : 'No quests found for "$searchQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : AppColors.slate500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screen),
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: GridView.builder(
          padding: EdgeInsets.only(top: 8.h, bottom: 16.h),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10.w,
            mainAxisSpacing: 10.h,
            childAspectRatio: 0.88,
          ),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final subtype = filtered[index];
            return _QuestGridCard(subtype: subtype, user: user, isDark: isDark);
          },
        ),
      ),
    );
  }
}

class _QuestGridCard extends StatelessWidget {
  final GameSubtype subtype;
  final UserEntity user;
  final bool isDark;

  const _QuestGridCard({
    required this.subtype,
    required this.user,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final metadata = GameHelper.getGameMetadata(subtype, isDark: isDark);
    final displayColor = metadata.color;
    final category = GameHelper.getCategoryForSubtype(subtype);

    final maxLevels = CurriculumManifest.getLevels(subtype.name);
    final levelsCleared = (user.completedLevels[subtype.name]?.length ?? 0)
        .clamp(0, maxLevels);
    final isMastered = levelsCleared >= maxLevels;
    final currentLevel = isMastered ? maxLevels : levelsCleared + 1;
    final isNew =
        levelsCleared == 0 && !user.categoryStats.containsKey(subtype.name);

    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return ScaleButton(
      // Tapping card body opens level roadmap
      onTap: () {
        context.push(
          '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(subtype.name)}',
        );
      },
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Icon + Level Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: displayColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(metadata.icon, color: displayColor, size: 18.r),
                ),
                _buildCardBadge(
                  context,
                  isNew,
                  isMastered,
                  currentLevel,
                  levelsCleared,
                  displayColor,
                ),
              ],
            ),

            // Middle: Title & Category
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metadata.title,
                  maxLines: 2,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.slate900,
                    height: 1.15,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  metadata.categoryName,
                  maxLines: 2,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 8.sp,
                    fontWeight: FontWeight.w800,
                    color: displayColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),

            // Bottom CTA: Direct Play Button (1-Tap Entry!)
            ScaleButton(
              onTap: () {
                try {
                  Haptics.vibrate(HapticsType.light);
                } catch (_) {}
                context.push(
                  '/game?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(subtype.name)}&level=$currentLevel',
                );
              },
              child: Container(
                width: double.infinity,
                height: 28.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: displayColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: displayColor.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: displayColor,
                      size: 14.r,
                    ),
                    SizedBox(width: 3.w),
                    Text(
                      'PLAY',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: displayColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardBadge(
    BuildContext context,
    bool isNew,
    bool isMastered,
    int currentLevel,
    int levelsCleared,
    Color color,
  ) {
    if (isNew) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          'NEW',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 8.sp,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      );
    }

    if (isMastered) {
      return Container(
        padding: EdgeInsets.all(3.r),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [IllustrationColors.premiumGold, _LocalPalette.colorffa000],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check_rounded, color: Colors.white, size: 12.r),
      );
    }

    // Tier color ring
    Color ringColor = color;
    if (levelsCleared >= 100) {
      ringColor = IllustrationColors.premiumGold;
    } else if (levelsCleared >= 50) {
      ringColor = _LocalPalette.colorc0c0c0;
    } else if (levelsCleared >= 25) {
      ringColor = _LocalPalette.colorcd7f32;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: ringColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: ringColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        'LVL $currentLevel',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 9.sp,
          fontWeight: FontWeight.w900,
          color: ringColor,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. Shimmer Loading Skeleton Matching the New 10/10 Layout
// ---------------------------------------------------------------------------

class _QuestHubShimmer extends StatelessWidget {
  const _QuestHubShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppColors.slate200);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screen,
            vertical: 20.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar Shimmer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoading.rounded(
                    width: 130.w,
                    height: 36.h,
                    borderRadius: 18,
                  ),
                  Row(
                    children: [
                      ShimmerLoading.rounded(
                        width: 60.w,
                        height: 36.h,
                        borderRadius: 18,
                      ),
                      SizedBox(width: 6.w),
                      ShimmerLoading.rounded(
                        width: 50.w,
                        height: 36.h,
                        borderRadius: 18,
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: 20.h),

              // Quick Resume Card Shimmer
              Container(
                width: double.infinity,
                height: 150.h,
                padding: EdgeInsets.all(18.r),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ShimmerLoading.rounded(width: 100.w, height: 16.h, borderRadius: 6),
                        ShimmerLoading.circular(width: 32.r, height: 32.r),
                      ],
                    ),
                    const Spacer(),
                    ShimmerLoading.rounded(width: 160.w, height: 22.h, borderRadius: 8),
                    SizedBox(height: 8.h),
                    ShimmerLoading.rounded(width: double.infinity, height: 8.h, borderRadius: 4),
                  ],
                ),
              ),

              SizedBox(height: 12.h),

              // Dual Action Row Shimmer
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 130.h,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading.circular(width: 36.r, height: 36.r),
                          const Spacer(),
                          ShimmerLoading.rounded(width: 70.w, height: 16.h, borderRadius: 6),
                          SizedBox(height: 6.h),
                          ShimmerLoading.rounded(width: 50.w, height: 10.h, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      height: 130.h,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading.circular(width: 36.r, height: 36.r),
                          const Spacer(),
                          ShimmerLoading.rounded(width: 70.w, height: 16.h, borderRadius: 6),
                          SizedBox(height: 6.h),
                          ShimmerLoading.rounded(width: 50.w, height: 10.h, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12.h),

              // Milestone Shimmer
              Container(
                height: 58.h,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(color: borderColor, width: 1.0),
                ),
                child: Row(
                  children: [
                    ShimmerLoading.circular(width: 28.r, height: 28.r),
                    SizedBox(width: 12.w),
                    ShimmerLoading.rounded(width: 120.w, height: 14.h, borderRadius: 6),
                    const Spacer(),
                    ShimmerLoading.rounded(width: 40.w, height: 18.h, borderRadius: 8),
                  ],
                ),
              ),

              SizedBox(height: 16.h),

              // Dock Pills Shimmer
              Row(
                children: [
                  ShimmerLoading.rounded(
                    width: 70.w,
                    height: 30.h,
                    borderRadius: 12,
                  ),
                  SizedBox(width: 6.w),
                  ShimmerLoading.rounded(
                    width: 90.w,
                    height: 30.h,
                    borderRadius: 12,
                  ),
                  SizedBox(width: 6.w),
                  ShimmerLoading.rounded(
                    width: 90.w,
                    height: 30.h,
                    borderRadius: 12,
                  ),
                ],
              ),

              SizedBox(height: 16.h),

              // 2-Column Grid Shimmer
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 160.h,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading.circular(width: 40.r, height: 40.r),
                          const Spacer(),
                          ShimmerLoading.rounded(width: 90.w, height: 16.h, borderRadius: 6),
                          SizedBox(height: 6.h),
                          ShimmerLoading.rounded(width: 60.w, height: 10.h, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      height: 160.h,
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: borderColor, width: 1.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShimmerLoading.circular(width: 40.r, height: 40.r),
                          const Spacer(),
                          ShimmerLoading.rounded(width: 90.w, height: 16.h, borderRadius: 6),
                          SizedBox(height: 6.h),
                          ShimmerLoading.rounded(width: 60.w, height: 10.h, borderRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
