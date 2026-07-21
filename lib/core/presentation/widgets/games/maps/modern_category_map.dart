import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:vowl/core/utils/curriculum_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/presentation/widgets/story_dialogue_box.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/toll_gate_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/star_vault_bottom_sheet.dart';
import 'package:vowl/core/presentation/painters/category_path_painter.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/glass_map_header.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';

/// A premium, highly-performant quest category selection map.
///
/// Incorporates organic paths, mesh gradient backgrounds, interactive mascot triggers,
/// and automated local data preloading.
class ModernCategoryMap extends StatefulWidget {
  final String gameType;
  final String categoryId;

  const ModernCategoryMap({
    super.key,
    required this.gameType,
    required this.categoryId,
  });

  @override
  State<ModernCategoryMap> createState() => _ModernCategoryMapState();
}

class _ModernCategoryMapState extends State<ModernCategoryMap> {
  Color? _touchAuraColor;
  Timer? _auraTimer;
  String? _buddyMessage;
  Timer? _buddyMessageTimer;
  late ScrollController _scrollController;
  StoryBeat? _activeStoryBeat;
  int _totalLevels = 10;
  bool _isLoading = true;
  bool _showFullBackground = false;

  // PERF: point geometry only actually depends on `_totalLevels` and the
  // (constant for this widget's lifetime) category — not on every build
  // trigger. `context.watch<AuthBloc>()` used to force a full recompute of
  // up to 200 sine-wave points on *any* AuthState change, even ones with
  // nothing to do with this screen (coins, XP, etc. changing elsewhere).
  // Caching here means it's only recomputed when `_totalLevels` itself
  // changes (i.e. once, when curriculum data finishes loading).
  List<Offset>? _cachedPoints;
  int? _cachedPointsForLevelCount;
  // BUG FIX: the cache key previously tracked only `_totalLevels`, not
  // `category`. In the common case (this State's `widget.categoryId` never
  // changes post-construction) that's harmless. But Flutter can reuse this
  // exact State object across a `widget` update carrying a *different*
  // `categoryId` (same type, same tree position, no Key change - standard
  // element-reuse, with no `didUpdateWidget` override here to catch it) -
  // and if the new category happens to need the same `_totalLevels` value,
  // the cache would silently return points generated with the *previous*
  // category's vertical spacing, since `_generatePoints` depends on both
  // inputs, not just level count. Tracking both closes that gap outright.
  GameCategory? _cachedPointsForCategory;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();

    // 1. Check Cache Synchronously for Instant Load
    final cachedLevels = CurriculumService.getCachedLevels(widget.gameType);
    if (cachedLevels != null) {
      _totalLevels = cachedLevels;
      _isLoading = false;
    }

    _loadCurriculum();

    // 2. Delay background icons to ensure smooth page transition AND smooth initial scroll
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) {
        setState(() => _showFullBackground = true);
      }
    });
  }

  Future<void> _loadCurriculum() async {
    final levels = await CurriculumService.getTotalLevels(widget.gameType);
    if (!mounted) return;

    // Preload current quest batch
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
      di.sl<AssetQuestService>().preloadBatch(widget.gameType, unlockedLevel);
    }

    if (mounted) {
      if (_totalLevels != levels || _isLoading) {
        setState(() {
          _totalLevels = levels;
          _isLoading = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToCurrentLevel(animate: true);
          }
        });
        _checkAndShowStoryBeat();
      });
    }
  }

  /// Shared formatting for a snake_case mascot id ("vowl_prime") into a
  /// display name ("Vowl Prime"). Extracted — this exact logic used to be
  /// duplicated verbatim in both `_checkAndShowStoryBeat` and
  /// `_buildMascotMarker`.
  String _formatMascotName(String? mascotId) {
    if (mascotId == null || mascotId.isEmpty) {
      return context.tr(
        'category_map.default_companion_name',
        fallback: 'Companion',
      );
    }
    return mascotId
        .split('_')
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() + e.substring(1) : '')
        .join(' ');
  }

  void _checkAndShowStoryBeat() {
    final user = context.read<AuthBloc>().state.user;
    if (user != null) {
      final unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
      final beat = di.sl<StoryService>().getStoryBeat(
        context,
        widget.gameType,
        unlockedLevel,
      );
      if (beat != null) {
        Future.delayed(const Duration(milliseconds: 1600), () {
          if (mounted) {
            setState(() {
              _activeStoryBeat = beat;
            });
          }
        });
      } else if (unlockedLevel == 1) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _buddyMessage == null) {
            final mascotName = _formatMascotName(
              user.vowlMascot ?? 'vowl_prime',
            );
            setState(() {
              _buddyMessage = context.tr(
                'category_map.first_level_greeting',
                args: [mascotName],
                fallback: "Hey! $mascotName here. Let's start Level 1! 🚀",
              );
            });
            _buddyMessageTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) setState(() => _buddyMessage = null);
            });
          }
        });
      }
    }
  }

  void _scrollToCurrentLevel({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final authState = context.read<AuthBloc>().state;
    final int unlockedLevels =
        authState.user?.unlockedLevels[widget.gameType] ?? 1;

    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final double rowSpacing = _getVerticalSpacing(theme.category);

    final double targetY =
        64.h +
        150.h +
        ((unlockedLevels - 1) * rowSpacing) +
        (rowSpacing / 2) -
        (ScreenUtil().screenHeight / 2);

    final double maxScroll = _scrollController.position.maxScrollExtent;
    final double safeTargetY = targetY.clamp(0.0, maxScroll);

    if (animate) {
      _scrollController.animateTo(
        safeTargetY,
        duration: 1200.milliseconds,
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.jumpTo(safeTargetY);
    }
  }

  @override
  void dispose() {
    _auraTimer?.cancel();
    _buddyMessageTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: isDark,
    );
    // PERF: context.select instead of context.watch — this widget only
    // ever reads `state.user`, so only rebuild when that reference
    // actually changes, not on every AuthState emission.
    final user = context.select<AuthBloc, UserEntity?>(
      (bloc) => bloc.state.user,
    );
    int unlockedLevels = user?.unlockedLevels[widget.gameType] ?? 1;
    final completedLevelsList = user?.completedLevels[widget.gameType] ?? [];
    int completedLevels = completedLevelsList.isEmpty
        ? 0
        : completedLevelsList.reduce(math.max);
    if (completedLevels == 0 && unlockedLevels > 1) {
      completedLevels = unlockedLevels - 1;
    }

    final bool isPremium = user?.isPremium ?? false;

    // Auto-correct unlockedLevels for premium users who previously hit a free-tier toll gate
    // and then upgraded, so they don't have to replay the previous level to trigger the unlock.
    if (isPremium && unlockedLevels <= completedLevels) {
      unlockedLevels = completedLevels + 1;
    }

    final List<Offset> points = _generatePointsCached(theme.category);
    final double rowSpacing = _getVerticalSpacing(theme.category);
    final double totalContentHeight =
        40.h + (_totalLevels * rowSpacing) + 100.h;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.user?.unlockedLevels[widget.gameType] !=
          curr.user?.unlockedLevels[widget.gameType],
      listener: (context, state) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            _scrollToCurrentLevel(animate: true);
          }
        });
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
        child: Scaffold(
          backgroundColor: theme.backgroundColors[1],
          extendBody: true,
          body: Stack(
            children: [
              // 1. Clean Minimal Static Background
              _buildBackground(theme, isDark),

              // Touch Listener for Engagement
              GestureDetector(
                onTapDown: (details) {
                  _auraTimer?.cancel();
                  setState(() {
                    _touchAuraColor = theme.primaryColor;
                  });
                  _auraTimer = Timer(const Duration(milliseconds: 1500), () {
                    if (mounted) {
                      setState(() => _touchAuraColor = null);
                    }
                  });
                },
                child: Container(color: Colors.transparent),
              ),

              // 2. Scrollable Map Core
              CustomScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // SliverAppBar Back Pill
                  SliverAppBar(
                    pinned: false,
                    floating: false,
                    snap: false,
                    automaticallyImplyLeading: false,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    toolbarHeight: 50.h,
                    leadingWidth: 70.r,
                    leading: Padding(
                      padding: EdgeInsets.only(left: 16.r),
                      child: Semantics(
                        button: true,
                        label: context.tr('common.back', fallback: 'Back'),
                        child: ScaleButton(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                          child: Container(
                            width: 48.r,
                            height: 48.r,
                            alignment: Alignment.center,
                            child: ExcludeSemantics(
                              child: Builder(
                                builder: (context) {
                                  final isRtl =
                                      Directionality.of(context) ==
                                      TextDirection.rtl;
                                  return Container(
                                    width: 36.r,
                                    height: 36.r,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isRtl
                                          ? Icons.arrow_forward_ios_rounded
                                          : Icons.arrow_back_ios_new_rounded,
                                      color: const Color(0xFF0F172A),
                                      size: 16.r,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Header Panel Widget
                  SliverToBoxAdapter(
                    child: GlassMapHeader(
                      theme: theme,
                      user: user,
                      isDark: isDark,
                      gameType: widget.gameType,
                    ),
                  ),

                  // Track View
                  SliverToBoxAdapter(
                    child: _isLoading
                        ? SizedBox(height: ScreenUtil().screenHeight)
                        : Stack(
                            children: [
                              // Decoupled Path Line Graphics
                              CustomPaint(
                                size: Size(
                                  ScreenUtil().screenWidth,
                                  totalContentHeight,
                                ),
                                painter: CategoryPathPainter(
                                  points: points,
                                  color: theme.primaryColor,
                                  category: theme.category,
                                  isDark: isDark,
                                  unlockedLevels: unlockedLevels,
                                  completedLevels: completedLevels,
                                ),
                              ),

                              // Interactive Stage Nodes
                              //
                              // PERFORMANCE NOTE: every node here floats
                              // with a perpetual `.animate(...).moveY(...)`
                              // — not just the current level — and all
                              // `_totalLevels` (up to 200) nodes are built
                              // eagerly in this Column rather than lazily,
                              // for the same reason as ModernPathGameMap:
                              // the connecting CategoryPathPainter curve is
                              // computed from every point up front, which
                              // doesn't lend itself to simple sliver-based
                              // lazy loading without a deeper rendering
                              // rework. A true fix needs a custom
                              // RenderSliver that only paints visible path
                              // segments — too large a structural change to
                              // make blind without the ability to visually
                              // test it. RepaintBoundary per node is the
                              // safe, valuable mitigation that *is* applied
                              // here: each node's perpetual float animation
                              // no longer forces Flutter to walk/repaint
                              // every sibling node alongside it.
                                Column(
                                  children: [
                                    ...List.generate(_totalLevels, (index) {
                                      final levelNumber = index + 1;
                                      
                                      final point = points[index];

                                    return Container(
                                      height: rowSpacing,
                                      alignment: Alignment.center,
                                      child: Transform.translate(
                                        offset: Offset(
                                          point.dx -
                                              ScreenUtil().screenWidth / 2,
                                          0,
                                        ),
                                        child: _buildPathNode(
                                          context,
                                          levelNumber,
                                          unlockedLevels,
                                          completedLevels,
                                          isDark,
                                          theme,
                                          isPremium,
                                        ),
                                      ),
                                    );
                                  }),
                                  SizedBox(height: 150.h),
                                ],
                              ),
                            ],
                          ),
                  ),
                ],
              ),

              if (_activeStoryBeat != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black54,
                    child: StoryDialogueBox(
                      beat: _activeStoryBeat!,
                      onDismiss: () {
                        setState(() {
                          _activeStoryBeat = null;
                        });
                      },
                    ),
                  ).animate().fadeIn(),
                ),

              // Star Vault FAB
              Positioned(
                bottom: 32.h,
                right: 24.w,
                child: _buildStarVaultButton(theme),
              ),

              // Golden Keys FAB
              Positioned(
                bottom: 32.h,
                left: 24.w,
                child: _buildGoldenKeysButton(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getVerticalSpacing(GameCategory category) {
    switch (category) {
      case GameCategory.vocabulary:
        return 160.h;
      case GameCategory.grammar:
        return 180.h;
      case GameCategory.listening:
        return 150.h;
      case GameCategory.speaking:
        return 200.h;
      case GameCategory.reading:
        return 190.h;
      case GameCategory.writing:
        return 200.h;
      case GameCategory.accent:
        return 170.h;
      case GameCategory.roleplay:
        return 210.h;
      case GameCategory.eliteMastery:
        return 220.h;
    }
  }

  /// Cached wrapper around [_generatePoints]: recomputes only when
  /// `_totalLevels` or `category` actually change instead of on every
  /// rebuild.
  List<Offset> _generatePointsCached(GameCategory category) {
    if (_cachedPoints != null &&
        _cachedPointsForLevelCount == _totalLevels &&
        _cachedPointsForCategory == category) {
      return _cachedPoints!;
    }
    final points = _generatePoints(category);
    _cachedPoints = points;
    _cachedPointsForLevelCount = _totalLevels;
    _cachedPointsForCategory = category;
    return points;
  }

  List<Offset> _generatePoints(GameCategory category) {
    final List<Offset> points = [];
    final centerX = ScreenUtil().screenWidth / 2;
    final spacing = _getVerticalSpacing(category);
    final amplitude = 120.w;

    for (int i = 0; i < _totalLevels; i++) {
      final wave = math.sin(i * 0.5) * amplitude;
      final secondaryWave = math.cos(i * 0.3) * (amplitude * 0.3);
      final offsetX = centerX + wave + secondaryWave;
      final y = (i * spacing) + (spacing / 2);
      points.add(Offset(offsetX, y));
    }
    return points;
  }

  Widget _buildStarVaultButton(ThemeResult theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final categoryStars = state.user?.starRatings[widget.gameType] ?? {};
        int gameplayStars = 0;
        final magicStars = categoryStars['magic_stars'] ?? 0;
        categoryStars.forEach((key, value) {
          if (key != 'magic_stars' && key != 'claimed_chests') {
            gameplayStars += value;
          }
        });
        final totalStars = gameplayStars + magicStars;

        return ScaleButton(
          onTap: () => StarVaultBottomSheet.show(
            context,
            widget.gameType,
            theme.primaryColor,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  "$totalStars",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  Icons.star_rounded,
                  color: const Color(0xFFFFD700),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGoldenKeysButton(ThemeResult theme) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final keys = state.user?.keys ?? 0;

        return ScaleButton(
          onTap: () => KeyShopBottomSheet.show(
            context: context,
            isKidsMode: false,
            primaryColor: theme.primaryColor,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(30.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.key_rounded, color: Colors.white, size: 20.sp),
                SizedBox(width: 8.w),
                Text(
                  "$keys",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground(ThemeResult theme, bool isDark) {
    return RepaintBoundary(
      child: Stack(
        children: [
          // 1. Core Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.backgroundColors[0], theme.backgroundColors[1]],
              ),
            ),
          ),

          // 2. Interactive Mesh Alpha Gradient
          MeshGradientBackground(
            colors: [theme.primaryColor, theme.accentColor],
            auraColor: _touchAuraColor,
          ),

          if (_showFullBackground) ...[
            // 3. Floating Icons
            ...List.generate(15, (index) {
              final random = math.Random(index + 700);
              final duration = (40 + random.nextInt(30)).seconds;

              IconData icon;
              switch (theme.category) {
                case GameCategory.reading:
                  icon = random.nextBool()
                      ? Icons.menu_book_rounded
                      : Icons.auto_stories_rounded;
                  break;
                case GameCategory.writing:
                  icon = random.nextBool()
                      ? Icons.edit_note_rounded
                      : Icons.history_edu_rounded;
                  break;
                case GameCategory.speaking:
                  icon = random.nextBool()
                      ? Icons.mic_external_on_rounded
                      : Icons.record_voice_over_rounded;
                  break;
                case GameCategory.listening:
                  icon = random.nextBool()
                      ? Icons.headset_rounded
                      : Icons.graphic_eq_rounded;
                  break;
                case GameCategory.grammar:
                  icon = random.nextBool()
                      ? Icons.architecture_rounded
                      : Icons.account_tree_rounded;
                  break;
                case GameCategory.vocabulary:
                  icon = random.nextBool()
                      ? Icons.bubble_chart_rounded
                      : Icons.category_rounded;
                  break;
                case GameCategory.eliteMastery:
                  icon = random.nextBool()
                      ? Icons.workspace_premium_rounded
                      : Icons.military_tech_rounded;
                  break;
                default:
                  icon = Icons.star_rounded;
              }

              return Positioned(
                left: random.nextDouble() * 1.sw,
                top: random.nextDouble() * 2.sh,
                child:
                    Icon(
                          icon,
                          size: (12 + random.nextInt(18)).r,
                          color: theme.primaryColor.withValues(
                            alpha: isDark ? 0.20 : 0.12,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .moveY(
                          begin: 1.1.sh,
                          end: -100.h,
                          duration: duration,
                          curve: Curves.linear,
                        ),
              );
            }),

            // 4. Shimmering Particles
            ...List.generate(20, (index) {
              final random = math.Random(index + 800);
              return Positioned(
                left: random.nextDouble() * 1.sw,
                top: random.nextDouble() * 2.sh,
                child:
                    Container(
                          width: 3.r,
                          height: 3.r,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fadeOut(
                          duration: (1 + random.nextDouble() * 2).seconds,
                          curve: Curves.easeInOut,
                        ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPathNode(
    BuildContext context,
    int level,
    int unlockedLevels,
    int completedLevels,
    bool isDark,
    ThemeResult theme,
    bool isPremium,
  ) {
    final bool isCompleted = level <= completedLevels;
    final bool isPlayable =
        level == completedLevels + 1 && (level <= unlockedLevels || isPremium);
    // Hide Toll Gate until user actually reaches it
    final bool isTollGate =
        level == completedLevels + 1 && level > unlockedLevels && !isPremium;
    final bool isHalfUnlocked =
        level > completedLevels + 1 &&
        level <= unlockedLevels &&
        unlockedLevels > 10;
    // Hide Next Zone until Toll Gate is visible
    final bool isNextZone =
        level > unlockedLevels + 1 &&
        level <= unlockedLevels + 3 &&
        !isPremium &&
        completedLevels >= unlockedLevels;

    // They can only play if they actually reached it sequentially.
    final bool isUnlockedForClick = isCompleted || isPlayable;
    final bool isCurrent = isPlayable || isTollGate;
    Color tierColor = theme.primaryColor;
    if (isTollGate) {
      tierColor = Colors.amber;
    } else if (level >= 50 && level < 100) {
      tierColor = const Color(0xFFCD7F32);
    } else if (level >= 100 && level < 150) {
      tierColor = const Color(0xFFC0C0C0);
    } else if (level >= 150) {
      tierColor = const Color(0xFFFFD700);
    }

    final String statusLabel;
    if (isCompleted) {
      statusLabel = context.tr('games.level_completed', fallback: 'Completed');
    } else if (isPlayable) {
      statusLabel = context.tr(
        'games.level_current',
        fallback: 'Current level',
      );
    } else if (isTollGate) {
      statusLabel = context.tr(
        'games.level_locked_toll',
        fallback: 'Unlock required',
      );
    } else if (isHalfUnlocked) {
      statusLabel = context.tr(
        'games.level_locked_sequence',
        fallback: 'Complete previous to play',
      );
    } else {
      statusLabel = context.tr('games.level_locked', fallback: 'Locked');
    }

    return SizedBox(
      width: 160.r,
      height: 220.h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Semantics(
            button: true,
            label:
                '${context.tr('games.level_label_short', args: [level.toString()], fallback: 'Level $level')}, $statusLabel',
            child: ScaleButton(
              onTap: () {
                if (isTollGate) {
                  if (level > completedLevels + 1) {
                    _showLockedFeedback(context, Colors.amber);
                    return;
                  }
                  TollGateBottomSheet.show(
                    context: context,
                    level: level,
                    gameType: widget.gameType,
                  );
                  return;
                }

                if (!isUnlockedForClick) {
                  _showLockedFeedback(context, theme.primaryColor);
                  return;
                }

                context
                    .push(
                      // BUG FIX: was `theme.category.name`, which returns the
                      // raw camelCase GameCategory enum name (e.g.
                      // 'eliteMastery'). Every other category-key usage in
                      // this codebase (QuestRegistry's asset folder map,
                      // StoryService's legacyAdultScripts map) uses the
                      // lowercase form, and this screen's own sibling,
                      // ModernPathGameMap, builds this exact same route using
                      // its own `categoryId` field directly rather than
                      // re-deriving it from a theme enum. Using
                      // `widget.categoryId` here matches that established,
                      // correct pattern and avoids depending on whatever the
                      // `/game` route's query-param parsing happens to expect
                      // for case sensitivity.
                      '/game?category=${Uri.encodeQueryComponent(widget.categoryId)}&gameType=${Uri.encodeQueryComponent(widget.gameType)}&level=$level',
                    )
                    .then((_) {
                      if (mounted) {
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            _scrollToCurrentLevel(animate: true);
                          }
                        });
                      }
                    });
              },
              child: ExcludeSemantics(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildNodeCircle(
                      context,
                      level,
                      isCurrent,
                      isCompleted,
                      isPlayable,
                      isHalfUnlocked,
                      isTollGate,
                      isNextZone,
                      tierColor,
                      isDark,
                    ),

                    PositionedDirectional(
                      top: isCurrent ? 12.r : 10.r,
                      start: isCurrent ? 12.r : 10.r,
                      child: Container(
                        width: isCurrent ? 40.r : 35.r,
                        height: isCurrent ? 18.r : 15.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              Colors.white.withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (isCurrent)
            Positioned(
              top: 5.h,
              child: _buildMascotMarker(context)
                  .animate()
                  .fadeIn(duration: 600.milliseconds)
                  .scale(delay: 200.milliseconds, curve: Curves.elasticOut),
            ),
        ],
      ),
    );
  }

  void _showLockedFeedback(BuildContext context, Color color) {
    HapticFeedback.mediumImpact();
    CustomSnackBar.show(
      context: context,
      message: context.tr(
        'category_map.master_previous_levels',
        fallback: 'MASTER PREVIOUS LEVELS TO UNLOCK',
      ),
      type: CustomSnackBarType.info,
    );
  }

  Widget _buildMascotMarker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme(widget.gameType, isDark: isDark);

    final user = context.read<AuthBloc>().state.user;
    final unlockedLevels = user?.unlockedLevels[widget.gameType] ?? 1;
    final mascotId = user?.vowlMascot ?? 'vowl_prime';

    return Semantics(
      button: true,
      label: context.tr(
        'category_map.mascot_marker_action',
        fallback: 'Get a cheer from your mascot',
      ),
      child:
          GestureDetector(
                onTap: () {
                  _buddyMessageTimer?.cancel();
                  final mascotName = _formatMascotName(mascotId);

                  final messageKeys = [
                    'category_map.cheer_unstoppable',
                    'category_map.cheer_impressed',
                    'category_map.cheer_magic',
                    'category_map.cheer_genius',
                    'category_map.cheer_rock',
                    'category_map.cheer_winning',
                    'category_map.cheer_boom',
                    'category_map.cheer_smart',
                    'category_map.cheer_momentum',
                    'category_map.cheer_breathtaking',
                  ];
                  const fallbacks = [
                    "Level {0}! You're unstoppable, Superstar! ⭐",
                    "Level {0}! {1} is impressed! 🚀",
                    "Level {0}! Pure linguistic magic! ✨",
                    "Level {0}! Absolute genius energy! 🧠",
                    "Level {0}! You rock this stage! 🎸",
                    "Level {0}! We're winning big! 🏆",
                    "Level {0}! Boom! Perfect progress! 💥",
                    "Level {0}! {1} says: You're so smart! 🦉",
                    "Level {0}! Keep that momentum! 🏃‍♂️",
                    "Level {0}! Wow! Simply breathtaking! 🎈",
                  ];
                  final pick = math.Random().nextInt(messageKeys.length);
                  final message = context.tr(
                    messageKeys[pick],
                    args: [unlockedLevels.toString(), mascotName],
                    fallback: fallbacks[pick]
                        .replaceAll('{0}', unlockedLevels.toString())
                        .replaceAll('{1}', mascotName),
                  );

                  setState(() {
                    _buddyMessage = message;
                    _touchAuraColor = theme.primaryColor;
                  });

                  final cleanMessage = message
                      .replaceAll(
                        RegExp(
                          r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{1F600}-\u{1F64F}\u{1F680}-\u{1F6FF}\u{2B50}]',
                          unicode: true,
                        ),
                        '',
                      )
                      .trim();
                  di.sl<TtsService>().speak(cleanMessage);

                  HapticFeedback.lightImpact();
                  _buddyMessageTimer = Timer(const Duration(seconds: 4), () {
                    if (mounted) setState(() => _buddyMessage = null);
                  });
                },
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_buddyMessage != null)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child:
                              Container(
                                constraints: BoxConstraints(maxWidth: 220.w),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 14.w,
                                  vertical: 8.h,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(15.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10.r,
                                      offset: Offset(0, 5.h),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _buddyMessage!,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ).animate().scale(
                                curve: Curves.elasticOut,
                                duration: 500.ms,
                              ),
                        ),
                      VowlMascot(
                        size: 55.r,
                        useFloatingAnimation: true,
                        mascotId: mascotId,
                      ).animate().scale(
                        curve: Curves.elasticOut,
                        duration: 500.ms,
                      ),
                      CustomPaint(
                        size: Size(12.w, 8.h),
                        painter: TrianglePainter(color: theme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildNodeCircle(
    BuildContext context,
    int level,
    bool isCurrent,
    bool isCompleted,
    bool isPlayable,
    bool isHalfUnlocked,
    bool isTollGate,
    bool isNextZone,
    Color tierColor,
    bool isDark,
  ) {
    Widget circleWidget = Container(
      width: isCurrent ? 100.r : 85.r,
      height: isCurrent ? 100.r : 85.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: (isCompleted || isPlayable || isHalfUnlocked)
              ? [Colors.white, const Color(0xFFF1F5F9)]
              : isTollGate
              ? [Colors.amber.shade200, Colors.amber.shade400]
              : isNextZone
              ? [
                  Colors.amber.withValues(alpha: 0.1),
                  Colors.amber.withValues(alpha: 0.3),
                ]
              : [Colors.grey.shade400, Colors.grey.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color:
                ((isCompleted || isPlayable || isHalfUnlocked)
                        ? tierColor
                        : isTollGate
                        ? Colors.amber
                        : Colors.black)
                    .withValues(alpha: isDark ? 0.4 : 0.2),
            offset: Offset(0, 8.h),
            blurRadius: 15.r,
          ),
        ],
        border: Border.all(
          color: (isCompleted || isPlayable || isHalfUnlocked)
              ? tierColor
              : isTollGate
              ? Colors.amber.shade600
              : isNextZone
              ? Colors.amber.withValues(alpha: 0.4)
              : Colors.white24,
          width: isCurrent ? 4.r : 3.r,
        ),
      ),
      child: Container(
        margin: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.transparent,
              Colors.black.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Center(
          child: isTollGate
              ? Icon(
                  Icons.lock_rounded,
                  size: 36.r,
                  color: Colors.white,
                  shadows: const [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                )
              : (isCompleted || isPlayable || isHalfUnlocked)
              ? Padding(
                  padding: EdgeInsets.all(4.r),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.tr('home.level_label', fallback: 'Level'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w900,
                            color: tierColor,
                            letterSpacing: 2,
                          ),
                          maxLines: 1,
                        ),
                        Text(
                          "$level",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: (isPlayable || isCompleted ? 32 : 26).sp,
                            fontWeight: FontWeight.w900,
                            color: tierColor,
                            height: 0.9,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(0, 2.h),
                                blurRadius: 4.r,
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                        if (isCompleted) ...[
                          SizedBox(height: 2.h),
                          Builder(
                            builder: (context) {
                              final earnedStars =
                                  context
                                      .read<AuthBloc>()
                                      .state
                                      .user
                                      ?.starRatings[widget.gameType]?[level
                                      .toString()] ??
                                  0;
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(3, (index) {
                                  final isEarned = index < earnedStars;
                                  return Icon(
                                    Icons.star_rounded,
                                    size: index == 1 ? 14.r : 10.r,
                                    color: isEarned
                                        ? Colors.amber
                                        : Colors.black26,
                                  );
                                }),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : Icon(Icons.lock_rounded, size: 32.r, color: Colors.white54),
        ),
      ),
    );

    if (isCurrent) {
      return circleWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .moveY(
            begin: -6.r,
            end: 6.r,
            duration: 1.2.seconds,
            curve: Curves.easeInOut,
          );
    }

    return circleWidget;
  }
}
