import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';

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
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/star_vault_bottom_sheet.dart';

import 'package:vowl/core/presentation/widgets/games/maps/modern_map_node.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/glass_map_header.dart';
import 'package:vowl/core/utils/locale_service.dart';


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

class _ModernCategoryMapState extends State<ModernCategoryMap>
    with TickerProviderStateMixin {
  String? _buddyMessage;
  Timer? _buddyMessageTimer;
  late ScrollController _scrollController;
  StoryBeat? _activeStoryBeat;
  int _totalLevels = 10;
  bool _isLoading = true;
  bool _isSequenceAnimating = false;
  int? _justUnlockedLevel;
  int? _celebratingLevel;
  late ConfettiController _confettiController;

  // ── Smooth Animation Controllers ──
  late AnimationController _entryController;
  late AnimationController _unlockPathController;
  late AnimationController _glowController;
  int? _previousActiveNode;

  late final ValueNotifier<int> _stateHash = ValueNotifier(0);

  void _updateState() {
    if (mounted) _stateHash.value++;
  }

  // PERF: Cache the static ambient background icons so they aren't recreated
  // on every build. The positions are deterministic (seeded Random), so the
  // list is stable for the widget's entire lifetime.
  List<Widget>? _cachedBackgroundIcons;
  GameCategory? _cachedBackgroundIconsCategory;
  bool? _cachedBackgroundIconsDark;

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
    
    // Calculate initial scroll position so the user instantly lands on their current level
    double initialOffset = 0.0;
    final authState = context.read<AuthBloc>().state;
    if (authState.user != null) {
      final completedLevels = authState.user!.completedLevels[widget.gameType] ?? [];
      final highestCompleted = completedLevels.isEmpty ? 0 : completedLevels.reduce(math.max);
      final targetLevel = math.min(200, highestCompleted + 1);
      
      // Obtain GameCategory using a dummy isDark value (doesn't affect category mapping)
      final theme = LevelThemeHelper.getCategoryTheme(
        widget.categoryId,
        isDark: false,
      );
      final double rowSpacing = _getVerticalSpacing(theme.category);
      final targetOffset = (targetLevel - 1) * rowSpacing;
      initialOffset = math.max(0.0, targetOffset - 300.h);
      _previousActiveNode = targetLevel;
    }

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // 1. Unified fade-in entry animation (path + nodes together)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 2. Path-draw animation when a level unlocks (Peaceful flowing water)
    _unlockPathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 3. Current-node subtle glow pulse (like Kids map)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Kick off smooth entry after initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryController.forward();
    });

    // Check Cache Synchronously for Instant Load
    final cachedLevels = CurriculumService.getCachedLevels(widget.gameType);
    if (cachedLevels != null) {
      _totalLevels = cachedLevels;
      _isLoading = false;
    }

    _loadCurriculum();
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
        _totalLevels = levels;
        _isLoading = false;
        _updateState();
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
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
        // PERF: reduced from 1600ms → 400ms. The previous 1600ms delay
        // stacked on top of the async curriculum load time, making the
        // story card feel sluggish (appearing 2-3s after the map was
        // already fully visible). We now wait for the exact frame the route
        // transition finishes cleanly, so the card entrance animation plays
        // on a mathematically settled frame.
        _executeWhenRouteSettled(() {
          if (mounted) {
            _activeStoryBeat = beat;
            _updateState();
          }
        });
      } else if (unlockedLevel == 1) {
        // PERF: reduced from 2000ms → 800ms for the same reason.
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted && _buddyMessage == null) {
            final mascotName = _formatMascotName(
              user.vowlMascot ?? 'vowl_prime',
            );
            _buddyMessage = context.tr(
                'category_map.first_level_greeting',
                args: [mascotName],
                fallback: "Hey! $mascotName here. Let's start Level 1! 🚀",
              );
            _updateState();
            _buddyMessageTimer = Timer(const Duration(seconds: 5), () {
              if (mounted) {
                _buddyMessage = null;
                _updateState();
              }
            });
          }
        });
      }
    }
  }

  void _scrollToCurrentLevel({bool animate = true}) {
    if (!_scrollController.hasClients) return;

    final authState = context.read<AuthBloc>().state;
    final List<int> completedLevels =
        authState.user?.completedLevels[widget.gameType] ?? [];
    final int highestCompleted =
        completedLevels.isEmpty ? 0 : completedLevels.reduce(math.max);

    // Always scroll to the node the user actually needs to interact with next
    final int targetLevel = math.min(200, highestCompleted + 1);

    final theme = LevelThemeHelper.getCategoryTheme(
      widget.categoryId,
      isDark: Theme.of(context).brightness == Brightness.dark,
    );
    final double rowSpacing = _getVerticalSpacing(theme.category);

    final double targetOffset = (targetLevel - 1) * rowSpacing;
    // Uses the exact math from the Kids Map: ignoring header heights pushes the
    // node perfectly into the comfortable lower-middle of the screen.
    final double targetY = math.max(0.0, targetOffset - 300.h);

    if (animate) {
      _scrollController.animateTo(
        targetY,
        duration: 800.milliseconds,
        curve: Curves.easeInOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetY);
    }
  }

  @override
  void dispose() {
    _buddyMessageTimer?.cancel();
    _scrollController.dispose();
    _entryController.dispose();
    _unlockPathController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _stateHash.dispose();
    super.dispose();
  }

  /// AAA Standard: Mathematically binds to the Flutter rendering pipeline.
  /// Ensures actions only execute once the navigation route animation is 100% complete,
  /// completely eliminating race conditions or timing bugs on slow devices.
  void _executeWhenRouteSettled(VoidCallback action) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null) {
      action();
      return;
    }
    
    // 1. Wait for overlaying screens (like the victory game screen) to finish popping
    if (route.secondaryAnimation != null && !route.secondaryAnimation!.isDismissed) {
      void listener(AnimationStatus status) {
        if (status == AnimationStatus.dismissed) {
          route.secondaryAnimation!.removeStatusListener(listener);
          if (mounted) action();
        }
      }
      route.secondaryAnimation!.addStatusListener(listener);
      return;
    }

    // 2. Otherwise, wait for THIS screen to finish pushing (if we just loaded the map)
    if (route.animation != null && !route.animation!.isCompleted) {
      void listener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          route.animation!.removeStatusListener(listener);
          if (mounted) action();
        }
      }
      route.animation!.addStatusListener(listener);
      return;
    }

    // 3. Screen is completely settled
    action();
  }

  /// True AAA Standard: A completely linear, async/await timeline orchestrated top-to-bottom.
  /// The path line draws with a slow, smooth "flowing water" feel and confetti
  /// locks the screen from scrolling until all particles have settled.
  Future<void> _playUnlockSequence(BuildContext context) async {
    _isSequenceAnimating = true;
    _updateState();

    // 1. Wait perfectly for the final settled frame to render (GPU Sync)
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 2. Trigger the smooth scroll to the new node and start drawing the path
    // AT THE EXACT SAME TIME. This completely eliminates the "starting delay".
    // As the screen scrolls, the path line will flow out of the old node
    // and chase the camera down to the new node.
    _scrollToCurrentLevel(animate: true);

    // 3. Play the organic water-flow path draw animation (2500ms)
    await _unlockPathController.forward();
    if (!mounted) return;

    // 5. Complete the node unlock pop
    _celebratingLevel = _justUnlockedLevel;
    _justUnlockedLevel = null;
    _updateState();

    // 6. Wait exactly one frame for Flutter to finish drawing the new bounce state, then fire confetti
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _confettiController.play();

    // 7. Wait for ALL confetti particles to fully fall and settle before
    //    re-enabling touch/scroll. The confetti controller runs for 2s,
    //    particles need ~1.5s more to physically fall off screen.
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      _celebratingLevel = null;
      _isSequenceAnimating = false;
      _updateState();
    }
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

    // Store initial active node for delta detection
    _previousActiveNode ??= math.min(200, completedLevels + 1);

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) {
        final prevUnlocked = prev.user?.unlockedLevels[widget.gameType] ?? 1;
        final currUnlocked = curr.user?.unlockedLevels[widget.gameType] ?? 1;
        final prevCompleted = prev.user?.completedLevels[widget.gameType]?.length ?? 0;
        final currCompleted = curr.user?.completedLevels[widget.gameType]?.length ?? 0;
        return prevUnlocked != currUnlocked || prevCompleted != currCompleted;
      },
      listener: (context, state) {
        // Trigger smooth unlock-path-draw animation
        final prevLevel = _previousActiveNode;
        final completed = state.user?.completedLevels[widget.gameType] ?? [];
        final highest = completed.isEmpty ? 0 : completed.reduce(math.max);
        final currLevel = math.min(200, highest + 1);
        _previousActiveNode = currLevel;

        if (prevLevel != null && currLevel > prevLevel) {
          // If multiple levels were unlocked at once (e.g., Tollgate Magic Lock),
          // skip the slow path-draw animation since the bottom sheet already celebrated it.
          if (currLevel - prevLevel > 1) {
            // FIX: Clear any residual single-unlock animation state so the map
            // doesn't render a stale justUnlockedLevel from a previous cycle.
            _justUnlockedLevel = null;
            _celebratingLevel = null;
            _unlockPathController.value = 1.0;
            _executeWhenRouteSettled(() {
              if (mounted) _scrollToCurrentLevel(animate: true);
            });
            return;
          }

          _justUnlockedLevel = currLevel;
          _updateState();
          _unlockPathController.reset();

          // Orchestrate the full unlock animation sequence via a pristine async state machine
          _executeWhenRouteSettled(() {
            if (mounted) _playUnlockSequence(context);
          });
        } else {
          // Wait a beat for the route transition to finish before scrolling
          _executeWhenRouteSettled(() {
            if (mounted) _scrollToCurrentLevel(animate: true);
          });
        }
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
        child: ValueListenableBuilder<int>(
          valueListenable: _stateHash,
          builder: (context, _, child) {
            return AbsorbPointer(
          absorbing: _isSequenceAnimating,
          child: Scaffold(
            backgroundColor: theme.backgroundColors[1],
            extendBody: true,
            body: Stack(
            children: [
              // 1. Clean Minimal Static Background
              _buildBackground(theme, isDark),

              // 2. Scrollable Map Core
              CustomScrollView(
                controller: _scrollController,
                physics: _isSequenceAnimating
                    ? const NeverScrollableScrollPhysics()
                    : const BouncingScrollPhysics(),
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

                  // Track View — Lazy SliverList with per-segment path painting & smooth entrance fade
                  if (_isLoading)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 40.r,
                              height: 40.r,
                              child: CircularProgressIndicator(
                                strokeWidth: 3.r,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.primaryColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              context.tr('games.loading_map', fallback: 'Loading map...'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : Colors.black26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                  SliverFadeTransition(
                    opacity: CurvedAnimation(
                      parent: _entryController,
                      curve: Curves.easeOut,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        // Last item: bottom spacer
                        if (index == _totalLevels) {
                          return SizedBox(height: 150.h);
                        }
                        final levelNumber = index + 1;
                        final point = points[index];
                        return ModernMapNode(
                          index: index,
                          levelNumber: levelNumber,
                          totalLevels: _totalLevels,
                          point: point,
                          points: points,
                          rowSpacing: rowSpacing,
                          unlockedLevels: unlockedLevels,
                          completedLevels: completedLevels,
                          isPremium: isPremium,
                          justUnlockedLevel: _justUnlockedLevel,
                          celebratingLevel: _celebratingLevel,
                          unlockPathController: _unlockPathController,
                          glowController: _glowController,
                          confettiController: _confettiController,
                          theme: theme,
                          isDark: isDark,
                          categoryId: widget.categoryId,
                          gameType: widget.gameType,
                        );
                      }, childCount: _totalLevels + 1),
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
                        _activeStoryBeat = null;
                        _updateState();
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
              ), // end of Positioned
            ],
          ),
        ),
        );
          },
        ),
      ),
    );
  }

  double _getVerticalSpacing(GameCategory category) {
    // 170.h is the true Diamond Standard. It keeps the map content-rich 
    // and perfectly dense without feeling squished.
    return 170.h;
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
    final screenWidth = ScreenUtil().screenWidth;
    final centerX = screenWidth / 2;
    final spacing = _getVerticalSpacing(category);
    // Max swing from center. 36% means it leaves a comfortable 14% margin on the edges.
    final maxOffset = screenWidth * 0.36;

    // ── Beautiful Premium S-Curve Path ──
    // 
    // We use a 7-node sine wave (freq = pi/3.5) combined with the perfectly 
    // smooth Catmull-Rom spline in the painter. This creates a massive, gorgeous,
    // organic river that flows naturally without any sharp Z-kinks or boring repetition!
    
    final rng = math.Random(category.index * 7919 + 31);
    const double freq = math.pi / 3.5; 
    
    for (int i = 0; i < _totalLevels; i++) {
      // Offset by category index to give each category a slightly different starting phase
      final double phase = (category.index * math.pi / 2);
      
      // Base pure sine wave that creates the sweeping S-shape
      final double baseSine = math.sin((i * freq) + phase);
      
      // ── STABILITY FIX ──
      // Previously, the amplitude could drop to 50% width, making certain sections 
      // (like the first 20 levels) look narrow, tight, or "straight". 
      // Now it varies smoothly between 85% and 100%, so the curves are ALWAYS 
      // wide, gorgeous, and sweeping everywhere.
      final double slowAmplitude = 0.925 + math.sin(i * 0.15 + category.index * 3) * 0.075;
      
      // Smoothly drift the entire S-curve slightly left or right across the screen
      final double slowDrift = math.sin(i * 0.08 + category.index * 7) * 0.12;
      
      // Add a slight per-node organic jitter (±3%) so it feels beautifully hand-placed
      final double jitter = (rng.nextDouble() - 0.5) * 0.06;
      
      // Force the first node (i=0) to be exactly in the center so the connection 
      // from the header is perfectly vertical. We gracefully fade the amplitude 
      // in over the first 1.5 nodes to smoothly start the sweeping S-curve.
      final double startFade = math.min(i / 1.5, 1.0);
      
      // Combine it all
      final double combined = ((baseSine * slowAmplitude + slowDrift + jitter) * startFade).clamp(-1.0, 1.0);

      final offsetX = centerX + (combined * maxOffset);
      final y = (i * spacing) + (spacing / 2);
      points.add(Offset(offsetX, y));
    }
    return points;
  }

  Widget _buildStarVaultButton(ThemeResult theme) {
    // PERF: BlocSelector to only rebuild when starRatings for this game change,
    // not on every AuthState emission (coins, XP, etc.).
    return BlocSelector<AuthBloc, AuthState, Map<String, dynamic>>(
      selector: (state) => state.user?.starRatings[widget.gameType] ?? {},
      builder: (context, categoryStars) {
        int gameplayStars = 0;
        final magicStars = (categoryStars['magic_stars'] as num?)?.toInt() ?? 0;
        categoryStars.forEach((key, value) {
          if (key != 'magic_stars' && key != 'claimed_chests') {
            gameplayStars += (value as num?)?.toInt() ?? 0;
          }
        });
        final totalStars = gameplayStars + magicStars;

        return Semantics(
          button: true,
          label: context.tr(
            'category_map.star_vault_label',
            args: [totalStars.toString()],
            fallback: 'Star Vault, $totalStars stars',
          ),
          child: ScaleButton(
          onTap: () => StarVaultBottomSheet.show(
            context,
            widget.gameType,
            theme.primaryColor,
          ),
          child: ExcludeSemantics(
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
          )),
        ));
      },
    );
  }

  Widget _buildGoldenKeysButton(ThemeResult theme) {
    // PERF: BlocSelector to only rebuild when key count changes.
    return BlocSelector<AuthBloc, AuthState, int>(
      selector: (state) => state.user?.keys ?? 0,
      builder: (context, keys) {
        return Semantics(
          button: true,
          label: context.tr(
            'category_map.golden_keys_label',
            args: [keys.toString()],
            fallback: 'Golden Keys, $keys keys',
          ),
          child: ScaleButton(
          onTap: () => KeyShopBottomSheet.show(
            context: context,
            isKidsMode: false,
            primaryColor: theme.primaryColor,
          ),
          child: ExcludeSemantics(
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
          )),
        ));
      },
    );
  }

  /// PERF: Cached builder for background icons. Only regenerates when
  /// category or dark mode actually changes.
  List<Widget> _buildBackgroundIconsCached(ThemeResult theme, bool isDark) {
    if (_cachedBackgroundIcons != null &&
        _cachedBackgroundIconsCategory == theme.category &&
        _cachedBackgroundIconsDark == isDark) {
      return _cachedBackgroundIcons!;
    }

    final icons = List<Widget>.generate(5, (index) {
      final random = math.Random(index + 700);
      IconData icon;
      switch (theme.category) {
        case GameCategory.reading:
          icon = [Icons.menu_book_rounded, Icons.auto_stories_rounded, Icons.chrome_reader_mode_rounded, Icons.library_books_rounded, Icons.book_rounded][index];
          break;
        case GameCategory.writing:
          icon = [Icons.edit_note_rounded, Icons.history_edu_rounded, Icons.draw_rounded, Icons.create_rounded, Icons.article_rounded][index];
          break;
        case GameCategory.speaking:
          icon = [Icons.mic_external_on_rounded, Icons.record_voice_over_rounded, Icons.mic_rounded, Icons.campaign_rounded, Icons.interpreter_mode_rounded][index];
          break;
        case GameCategory.listening:
          icon = [Icons.headset_rounded, Icons.graphic_eq_rounded, Icons.hearing_rounded, Icons.music_note_rounded, Icons.volume_up_rounded][index];
          break;
        case GameCategory.grammar:
          icon = [Icons.architecture_rounded, Icons.account_tree_rounded, Icons.hub_rounded, Icons.schema_rounded, Icons.lan_rounded][index];
          break;
        case GameCategory.vocabulary:
          icon = [Icons.bubble_chart_rounded, Icons.category_rounded, Icons.extension_rounded, Icons.widgets_rounded, Icons.apps_rounded][index];
          break;
        case GameCategory.eliteMastery:
          icon = [Icons.workspace_premium_rounded, Icons.military_tech_rounded, Icons.diamond_rounded, Icons.emoji_events_rounded, Icons.star_rounded][index];
          break;
        default:
          icon = Icons.star_rounded;
      }
      return Positioned(
        left: (0.1 + random.nextDouble() * 0.8) * 1.sw,
        top: (0.05 + index * 0.2) * 1.sh,
        child: Icon(
          icon,
          size: (14 + random.nextInt(12)).r,
          color: theme.primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
        ),
      );
    });

    _cachedBackgroundIcons = icons;
    _cachedBackgroundIconsCategory = theme.category;
    _cachedBackgroundIconsDark = isDark;
    return icons;
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

          // 2. Ambient Mesh Gradient
          const MeshGradientBackground(),

          // 3. Static ambient category icons — cached to avoid per-build allocation
          ..._buildBackgroundIconsCached(theme, isDark),
        ],
      ),
    );
  }
}




