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
  StoryBeat? _activeStoryBeat;
  late ScrollController _scrollController;


  // ── Smooth Animation Controllers ──
  late AnimationController _entryController;
  late AnimationController _unlockPathController;
  late AnimationController _glowController;
  int? _previousActiveNode;
  bool _isUnlockAnimating = false;
  int? _celebratingLevel;
  late ConfettiController _confettiController;

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
      
      final targetOffset = (targetLevel - 1) * 200.h;
      initialOffset = math.max(0.0, targetOffset - 300.h);
      _previousActiveNode = targetLevel;
    }

    _scrollController = ScrollController(initialScrollOffset: initialOffset);
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));

    // 1. Screen-entry animation (nodes fade and scale in instantly)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // 2. Path-draw animation when a level unlocks (Smooth and organic)
    _unlockPathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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
    super.dispose();
  }

  /// True AAA Standard: A completely linear, async/await timeline orchestrated top-to-bottom.
  Future<void> _playUnlockSequence(BuildContext context, int currLevel) async {
    // 1. Wait until the user has fully returned to the map screen
    while (mounted && context.mounted && ModalRoute.of(context)?.isCurrent != true) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) return;

    // 2. Wait a tiny beat for the screen pop route transition to finish completely
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;

    // 3. Trigger the smooth scroll to the new node
    _scrollToUnlockedLevel(delayMs: 0, animate: true);

    // 4. Wait a tiny fraction of a second for the scroll to gain momentum
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;

    // 5. Play the smooth, fast organic path draw animation
    await _unlockPathController.forward();
    if (!mounted) return;

    // 6. Complete the node unlock pop
    setState(() {
      _celebratingLevel = currLevel;
      _isUnlockAnimating = false;
    });

    // 7. Wait exactly one frame for Flutter to finish drawing the new bounce state, then fire confetti
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _confettiController.play();
    });

    // 8. Wait 3 seconds, then cleanup celebration memory
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      setState(() {
        _celebratingLevel = null;
      });
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
          final highestCompleted = completedLevels.isEmpty ? 0 : completedLevels.reduce(math.max);
          
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
            setState(() {
              _activeStoryBeat = beat;
            });
          }
        });
      }
    }
  }



  double _getHorizontalOffset(int level, double screenWidth) {
    // Seeded random to keep map consistent across rebuilds
    final random = math.Random(level * 123);
    // Map width minus node size (90.r) and safe edge padding (50.w * 2)
    final double availableWidth = screenWidth - 190.r;
    return 50.w + random.nextDouble() * availableWidth;
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
        final prevCompleted = previous.user?.completedLevels[widget.gameType]?.length ?? 0;
        final currCompleted = current.user?.completedLevels[widget.gameType]?.length ?? 0;
        return prevUnlocked != currUnlocked || prevCompleted != currCompleted;
      },
      listener: (context, state) {
        // Trigger smooth unlock-path-draw animation
        final prevLevel = _previousActiveNode;
        final completedLevels = state.user?.completedLevels[widget.gameType] ?? [];
        final highestCompleted = completedLevels.isEmpty ? 0 : completedLevels.reduce(math.max);
        final currLevel = math.min(200, highestCompleted + 1);
        _previousActiveNode = currLevel;

        if (prevLevel != null && currLevel > prevLevel) {
          // If multiple levels were skipped at once, skip the slow animation
          if (currLevel - prevLevel > 1) {
            _unlockPathController.value = 1.0;
            _scrollToUnlockedLevel(delayMs: 400, animate: true);
            return;
          }

          setState(() {
            _isUnlockAnimating = true;
          });
          _unlockPathController.reset();

          // Orchestrate the full unlock animation sequence via a pristine async state machine
          _playUnlockSequence(context, currLevel);
        } else {
          // Wait until the user returns to the map before scrolling so they can watch it happen
          Timer.periodic(const Duration(milliseconds: 200), (timer) {
            if (!mounted) {
              timer.cancel();
              return;
            }
            if (ModalRoute.of(context)?.isCurrent == true) {
              timer.cancel();
              Future.delayed(const Duration(milliseconds: 600), () {
                if (mounted) _scrollToUnlockedLevel(delayMs: 0, animate: true);
              });
            }
          });
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          int unlockedLevel = 1;
          List<int> completedLevels = [];
          bool isPremium = false;
          if (state.status == AuthStatus.authenticated && state.user != null) {
            unlockedLevel = state.user!.unlockedLevels[widget.gameType] ?? 1;
            completedLevels =
                state.user!.completedLevels[widget.gameType] ?? [];
            isPremium = state.user!.isPremium;
          }

          final isMidnight = context.watch<ThemeCubit>().state.isMidnight;
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

          return Scaffold(
            backgroundColor: bgColor,
            body: Stack(
              children: [
                _buildBackground(context),
                CustomScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
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
                          onTap: () => context.pop(),
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
                      child: _buildChunkyMapHeader(state.user, isDark),
                    ),

                    // ── Map Segments ──
                    SliverPadding(
                      padding: EdgeInsets.symmetric(vertical: 20.h),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
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

                          final currentOffset = _getHorizontalOffset(
                            level,
                            screenWidth,
                          );
                          final nextOffset = isLast
                              ? currentOffset
                              : _getHorizontalOffset(level + 1, screenWidth);
                          final prevOffset = level == 1 
                              ? currentOffset 
                              : _getHorizontalOffset(level - 1, screenWidth);
                              
                          return KidsMapNode(
                            level: level,
                            isLocked: isLocked,
                            isCurrent: isCurrent,
                            isLast: isLast,
                            currentOffset: currentOffset,
                            nextOffset: nextOffset,
                            prevOffset: prevOffset,
                            isLoading: state.status == AuthStatus.unknown,
                            isTollGate: isTollGate,
                            isCompleted: isCompleted,
                            isPlayable: isPlayable,
                            isNextZone: isNextZone,
                            isPrevCompleted: level == 1 ? true : (level - 1) <= highestCompleted,
                            gameType: widget.gameType,
                            primaryColor: widget.primaryColor,
                            unlockPathController: _unlockPathController,
                            entryController: _entryController,
                            glowController: _glowController,
                            confettiController: _confettiController,
                            isUnlockAnimating: _isUnlockAnimating,
                            celebratingLevel: _celebratingLevel,
                          );
                        }, childCount: 200),
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
                        isKidsMode: true,
                        onDismiss: () {
                          setState(() {
                            _activeStoryBeat = null;
                          });
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
                          context.tr('kids_zone.coins_label_caps', args: ['${user?.kidsCoins ?? 0}'], fallback: "${user?.kidsCoins ?? 0} COINS"),
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
