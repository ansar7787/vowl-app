import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_background_renderer.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_map_node.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/presentation/widgets/story_dialogue_box.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_star_vault_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';
import 'package:auto_size_text/auto_size_text.dart';

class KidsLevelMap extends StatefulWidget {
  final String gameType;
  final String title;
  final Color primaryColor;

  const KidsLevelMap({
    super.key,
    required this.gameType,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsLevelMap> createState() => _KidsLevelMapState();
}

class _KidsLevelMapState extends State<KidsLevelMap>
    with TickerProviderStateMixin {
  final ValueNotifier<StoryBeat?> _activeStoryBeat = ValueNotifier(null);
  late ScrollController _scrollController;

  // ── Smooth Animation Controllers ──
  late AnimationController _entryController;
  late AnimationController _unlockPathController;
  late AnimationController _glowController;
  int? _previousActiveNode;
  final ValueNotifier<bool> _isUnlockAnimating = ValueNotifier(false);
  final ValueNotifier<int?> _celebratingLevel = ValueNotifier(null);
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    // Calculate initial scroll position so the user instantly lands on their current level
    double initialOffset = 0.0;
    final authState = context.read<AuthBloc>().state;
    if (authState.user != null) {
      final completedLevels =
          authState.user!.completedLevels[widget.gameType] ?? [];
      final highestCompleted = completedLevels.isEmpty
          ? 0
          : completedLevels.reduce(math.max);
      final targetLevel = math.min(200, highestCompleted + 1);

      final targetOffset = (targetLevel - 1) * 200.h;
      initialOffset = math.max(0.0, targetOffset - 300.h);
      _previousActiveNode = targetLevel;
    }

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );

    // 1. Screen-entry animation (nodes fade and scale in instantly)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 2. Path-draw animation when a level unlocks (Peaceful flowing water)
    _unlockPathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    // 3. Current-node glow pulse (loops forever)
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Kick off smooth entry
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryController.forward();
    });

    _checkAndShowStoryBeat();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    _entryController.dispose();
    _unlockPathController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    _activeStoryBeat.dispose();
    _isUnlockAnimating.dispose();
    _celebratingLevel.dispose();
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
    if (route.secondaryAnimation != null &&
        !route.secondaryAnimation!.isDismissed) {
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
  Future<void> _playUnlockSequence(BuildContext context, int currLevel) async {
    _isUnlockAnimating.value = true;

    // 1. Wait perfectly for the final settled frame to render (GPU Sync)
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    // 2. Trigger the smooth scroll to the new node and start drawing the path
    // AT THE EXACT SAME TIME. This completely eliminates the "starting delay".
    // As the screen scrolls, the path line will flow out of the old node
    // and chase the camera down to the new node.
    _scrollToUnlockedLevel(delayMs: 0, animate: true);

    // 3. Play the organic water-flow path draw animation (2500ms)
    await _unlockPathController.forward();
    if (!mounted) return;

    // 5. Complete the node unlock pop
    _celebratingLevel.value = currLevel;

    // 6. Wait exactly one frame for Flutter to finish drawing the new bounce state, then fire confetti
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) _confettiController.play();

    // 7. Wait for ALL confetti particles to fully fall and settle before
    //    re-enabling touch/scroll. The confetti controller runs for 2s,
    //    particles need ~1.5s more to physically fall off screen.
    await Future.delayed(const Duration(milliseconds: 3500));
    if (mounted) {
      _celebratingLevel.value = null;
      _isUnlockAnimating.value = false;
    }
  }

  void _scrollToUnlockedLevel({int delayMs = 1500, bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Delay slightly to ensure page transition is finished and allow user to see their completion
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!mounted) return;

        final user = context.read<AuthBloc>().state.user;
        if (user != null) {
          final completedLevels = user.completedLevels[widget.gameType] ?? [];
          final highestCompleted = completedLevels.isEmpty
              ? 0
              : completedLevels.reduce(math.max);

          // Always scroll to the node the user actually needs to interact with next
          final targetLevel = math.min(200, highestCompleted + 1);

          // Store for unlock-animation delta detection
          _previousActiveNode ??= targetLevel;

          final double targetOffset = (targetLevel - 1) * 200.h;
          final double centeredOffset = math.max(0, targetOffset - 300.h);

          if (targetOffset > 100) {
            if (animate) {
              _scrollController.animateTo(
                centeredOffset,
                duration: 800.milliseconds,
                curve: Curves.easeInOutCubic,
              );
            } else {
              _scrollController.jumpTo(centeredOffset);
            }
          }
        }
      });
    });
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
        // Delay slightly for smooth entry
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _activeStoryBeat.value = beat;
          }
        });
      }
    }
  }

  double _getHorizontalOffset(int level, double screenWidth) {
    // 1. Maximize horizontal swing: push nodes closer to the edges to remove the "straight" feel.
    // Node width is ~100.r, so we leave a tiny 30.w safe padding on both left and right edges.
    final double availableWidth = screenWidth - 60.w - 100.r;
    final double center = 30.w + (availableWidth / 2);

    // 2. Increase frequency drastically (math.pi / 2.2).
    // The previous 0.6 frequency made the node travel straight down for 2-3 levels.
    // This higher frequency forces the path to aggressively wind left and right every 2 levels.
    final double baseWave = math.sin(level * (math.pi / 2.2));

    // 3. Keep amplitude consistently high so it aggressively uses all available horizontal space
    final double amplitude = 0.95 + (math.sin(level * 0.7) * 0.05);

    // 4. Jitter for a slightly hand-drawn board game look
    final random = math.Random(level * 123);
    final double jitter = (random.nextDouble() - 0.5) * 0.08;

    final double combined = (baseWave * amplitude + jitter).clamp(-1.0, 1.0);

    return center + (combined * (availableWidth / 2));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) {
        final prevUnlocked =
            previous.user?.unlockedLevels[widget.gameType] ?? 1;
        final currUnlocked = current.user?.unlockedLevels[widget.gameType] ?? 1;
        final prevCompleted =
            previous.user?.completedLevels[widget.gameType]?.length ?? 0;
        final currCompleted =
            current.user?.completedLevels[widget.gameType]?.length ?? 0;
        return prevUnlocked != currUnlocked || prevCompleted != currCompleted;
      },
      listener: (context, state) {
        // Trigger smooth unlock-path-draw animation
        final prevLevel = _previousActiveNode;
        final completedLevels =
            state.user?.completedLevels[widget.gameType] ?? [];
        final highestCompleted = completedLevels.isEmpty
            ? 0
            : completedLevels.reduce(math.max);
        final currLevel = math.min(200, highestCompleted + 1);
        _previousActiveNode = currLevel;

        if (prevLevel != null && currLevel > prevLevel) {
          // If multiple levels were skipped at once, skip the slow animation
          if (currLevel - prevLevel > 1) {
            // FIX: Clear any residual single-unlock animation state.
            _celebratingLevel.value = null;
            _unlockPathController.value = 1.0;
            _executeWhenRouteSettled(() {
              if (mounted) _scrollToUnlockedLevel(delayMs: 0, animate: true);
            });
            return;
          }

          _isUnlockAnimating.value = true;
          _unlockPathController.reset();

          // Orchestrate the full unlock animation sequence via a pristine async state machine
          _executeWhenRouteSettled(() {
            if (mounted) _playUnlockSequence(context, currLevel);
          });
        } else {
          // Wait a beat for the route transition to finish before scrolling
          _executeWhenRouteSettled(() {
            if (mounted) _scrollToUnlockedLevel(delayMs: 0, animate: true);
          });
        }
      },
      child: Builder(
        builder: (context) {
          // PERF: context.select instead of BlocBuilder — only rebuild when
          // the user entity reference itself changes, not on every AuthState.
          final user = context.select<AuthBloc, dynamic>(
            (bloc) => bloc.state.user,
          );
          final authStatus = context.select<AuthBloc, AuthStatus>(
            (bloc) => bloc.state.status,
          );
          int unlockedLevel = 1;
          List<int> completedLevels = [];
          bool isPremium = false;
          if (authStatus == AuthStatus.authenticated && user != null) {
            unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
            completedLevels = user.completedLevels[widget.gameType] ?? [];
            isPremium = user.isPremium;
          }

          // PERF: context.select instead of context.watch — only rebuild
          // when `isMidnight` actually changes, not on every ThemeCubit emission.
          final isMidnight = context.select<ThemeCubit, bool>(
            (cubit) => cubit.state.isMidnight,
          );
          final bgColor = isMidnight
              ? Colors.black
              : (isDark
                    ? Color.alphaBlend(
                        widget.primaryColor.withAlpha(100),
                        const Color(0xFF0F172A),
                      )
                    : Color.alphaBlend(
                        widget.primaryColor.withAlpha(60),
                        const Color(0xFFF8FAFC),
                      ));

          return ListenableBuilder(
            listenable: Listenable.merge([
              _isUnlockAnimating,
              _celebratingLevel,
              _activeStoryBeat,
            ]),
            builder: (context, _) {
              return AbsorbPointer(
                absorbing: _isUnlockAnimating.value,
                child: Scaffold(
                  backgroundColor: bgColor,
                  body: Stack(
                    children: [
                      _buildBackground(context),
                      CustomScrollView(
                        controller: _scrollController,
                        physics: _isUnlockAnimating.value
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(),
                        slivers: [
                          SliverAppBar(
                            pinned: false,
                            floating: false,
                            snap: false,
                            automaticallyImplyLeading: false,
                            backgroundColor: Colors.transparent,
                            surfaceTintColor: Colors.transparent,
                            elevation: 0,
                            toolbarHeight: 50.h,
                            title: Align(
                              alignment: Alignment.centerLeft,
                              child: ScaleButton(
                                onTap: () {
                                  if (context.canPop()) {
                                    context.pop();
                                  } else {
                                    context.go('/home');
                                  }
                                },
                                child: Container(
                                  width: 36.r,
                                  height: 36.r,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E293B)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.blue.shade700
                                          : Colors.blue.shade200,
                                      width: 3.w,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.blue.shade900
                                            : Colors.blue.shade100,
                                        offset: Offset(0, 4.h),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    color: const Color(0xFF0F172A),
                                    size: 16.r,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // 2. The World Portal Header (Part of the Map Journey)
                          SliverToBoxAdapter(
                            child: _buildChunkyMapHeader(user, isDark),
                          ),

                          // ── Map Segments ──
                          SliverPadding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final level = index + 1;
                                final highestCompleted = completedLevels.isEmpty
                                    ? 0
                                    : completedLevels.reduce(math.max);
                                final isCompleted = level <= highestCompleted;
                                final isPlayable =
                                    level == highestCompleted + 1 &&
                                    (level <= unlockedLevel || isPremium);
                                final isTollGate =
                                    level == highestCompleted + 1 &&
                                    level > unlockedLevel &&
                                    !isPremium;
                                final isHalfUnlocked =
                                    level > highestCompleted + 1 &&
                                    level <= unlockedLevel &&
                                    unlockedLevel > 10;
                                final isNextZone =
                                    level > unlockedLevel + 1 &&
                                    level <= unlockedLevel + 3 &&
                                    !isPremium &&
                                    highestCompleted >= unlockedLevel;
                                final isLocked =
                                    !isCompleted &&
                                    !isPlayable &&
                                    !isHalfUnlocked &&
                                    !isTollGate &&
                                    !isNextZone;
                                final isCurrent = isPlayable || isTollGate;
                                final isLast = index == 199;

                                // FIX: Check auth loading status from our selector
                                final isLoading =
                                    authStatus == AuthStatus.unknown;

                                final currentOffset = _getHorizontalOffset(
                                  level,
                                  screenWidth,
                                );
                                final nextOffset = isLast
                                    ? currentOffset
                                    : _getHorizontalOffset(
                                        level + 1,
                                        screenWidth,
                                      );
                                final prevOffset = level == 1
                                    ? currentOffset
                                    : _getHorizontalOffset(
                                        level - 1,
                                        screenWidth,
                                      );

                                return KidsMapNode(
                                  level: level,
                                  isLocked: isLocked,
                                  isCurrent: isCurrent,
                                  isLast: isLast,
                                  currentOffset: currentOffset,
                                  nextOffset: nextOffset,
                                  prevOffset: prevOffset,
                                  isLoading: isLoading,
                                  isTollGate: isTollGate,
                                  isCompleted: isCompleted,
                                  isPlayable: isPlayable,
                                  isNextZone: isNextZone,
                                  isPrevCompleted: level == 1
                                      ? true
                                      : (level - 1) <= highestCompleted,
                                  gameType: widget.gameType,
                                  primaryColor: widget.primaryColor,
                                  unlockPathController: _unlockPathController,
                                  entryController: _entryController,
                                  glowController: _glowController,
                                  confettiController: _confettiController,
                                  isUnlockAnimating: _isUnlockAnimating.value,
                                  celebratingLevel: _celebratingLevel.value,
                                );
                              }, childCount: 200),
                            ),
                          ),
                        ],
                      ),
                      if (_activeStoryBeat.value != null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black54,
                            child: StoryDialogueBox(
                              beat: _activeStoryBeat.value!,
                              isKidsMode: true,
                              onDismiss: () {
                                _activeStoryBeat.value = null;
                              },
                            ),
                          ).animate().fadeIn(),
                        ),
                      // Global Star Vault FAB
                      Positioned(
                        bottom: 32.h,
                        right: 24.w,
                        child: _buildStarVaultButton(),
                      ),

                      // Golden Keys FAB
                      Positioned(
                        bottom: 32.h,
                        left: 24.w,
                        child: _buildGoldenKeysButton(),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChunkyMapHeader(dynamic user, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(32.r),
          border: Border.all(color: widget.primaryColor, width: 3.w),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.6),
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: Row(
          children: [
            // Floating Sticker Icon
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  KidsAssets.stickerMap[widget.gameType]?[0] ?? '⭐',
                  style: TextStyle(fontSize: 32.sp),
                ),
              ),
            ).animate().scale(delay: 200.ms, curve: Curves.elasticOut),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('kids_zone.kids_quest', fallback: "KIDS QUEST"),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: widget.primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  AutoSizeText(
                    widget.title,
                    maxLines: 1,
                    minFontSize: 12,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Coins Mini-Pill
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on_rounded,
                          color: Colors.amber,
                          size: 14.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          context.tr(
                            'kids_zone.coins_label_caps',
                            args: ['${user?.kidsCoins ?? 0}'],
                            fallback: "${user?.kidsCoins ?? 0} COINS",
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Positioned.fill(
      child: KidsBackgroundRenderer(
        painterName: 'KidsWorldBackground',
        shaderName: '',
        primaryColor: widget.primaryColor,
        gameType: widget.gameType,
      ),
    );
  }

  Widget _buildStarVaultButton() {
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
          onTap: () => KidsStarVaultBottomSheet.show(
            context,
            widget.gameType,
            widget.primaryColor,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: widget.primaryColor,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.4),
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

  Widget _buildGoldenKeysButton() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final keys = state.user?.keys ?? 0;

        return ScaleButton(
          onTap: () => KeyShopBottomSheet.show(
            context: context,
            isKidsMode: true,
            primaryColor: widget.primaryColor,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.amber,
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: Colors.white, width: 2),
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
}
