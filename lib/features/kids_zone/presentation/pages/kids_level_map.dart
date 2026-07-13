import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:shimmer/shimmer.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/core/presentation/widgets/story_dialogue_box.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_star_vault_bottom_sheet.dart';
import 'package:vowl/core/presentation/widgets/key_shop_bottom_sheet.dart';

import 'package:vowl/features/kids_zone/presentation/widgets/kids_toll_gate_bottom_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/painters/kids_segment_path_painter.dart';

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

class _KidsLevelMapState extends State<KidsLevelMap> {
  StoryBeat? _activeStoryBeat;
  late ScrollController _scrollController;
  String? _buddyMessage;
  Timer? _buddyMessageTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _checkAndShowStoryBeat();
    _scrollToUnlockedLevel();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _buddyMessageTimer?.cancel();
    super.dispose();
  }

  void _scrollToUnlockedLevel() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Delay slightly to ensure page transition is finished and allow user to see their completion
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;

        final user = context.read<AuthBloc>().state.user;
        if (user != null) {
          final unlockedLevel = user.unlockedLevels[widget.gameType] ?? 1;
          final double targetOffset = (unlockedLevel - 1) * 200.h;
          final double centeredOffset = max(0, targetOffset - 300.h);

          if (targetOffset > 100) {
            _scrollController.animateTo(
              centeredOffset,
              duration: 800.milliseconds,
              curve: Curves.easeInOutQuart,
            );
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

  VowlMascotState _buddyState = VowlMascotState.neutral;

  void _handleBuddyTap() {
    final authState = context.read<AuthBloc>().state;
    final level = authState.user?.unlockedLevels[widget.gameType] ?? 1;

    final messages = [
      "Level $level! Superstar! ⭐",
      "Level $level! To the moon! 🚀",
      "Level $level! Magic touch! ✨",
      "Level $level! Hi-Five! 🖐️",
      "Level $level! Genius! 🧠",
      "Level $level! You rock! 🎸",
      "Level $level! Winner! 🏆",
      "Level $level! Boom! 💥",
      "Level $level! So smart! 🦉",
      "Level $level! Go go go! 🏃‍♂️",
      "Level $level! Wow! 🎈",
      "Level $level! Amazing! 🌈",
    ];

    final message = messages[Random().nextInt(messages.length)];

    _buddyMessageTimer?.cancel();
    setState(() {
      _buddyMessage = message;
      _buddyState = VowlMascotState.happy;
    });

    // Speak the message
    final cleanMessage = message.replaceAll(
      RegExp(
        r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
        unicode: true,
      ),
      '',
    );

    debugPrint("KIDS_MAP: Buddy speaking: $cleanMessage");
    di.sl<SoundService>().playMascotInteraction();
    di.sl<TtsService>().speak(cleanMessage);

    // Hide message after 3 seconds
    _buddyMessageTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _buddyMessage = null;
          _buddyState = VowlMascotState.neutral;
        });
      }
    });
  }

  double _getHorizontalOffset(int level, double screenWidth) {
    // Seeded random to keep map consistent across rebuilds
    final random = Random(level * 123);
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
        return prevUnlocked != currUnlocked;
      },
      listener: (context, state) {
        _scrollToUnlockedLevel();
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

                          return _buildMapSegment(
                            context,
                            level,
                            isLocked,
                            isCurrent,
                            isLast,
                            currentOffset,
                            nextOffset,
                            state.status == AuthStatus.unknown,
                            isTollGate,
                            isCompleted,
                            isPlayable,
                            isNextZone,
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

  Widget _buildBuddy(BuildContext context, {required bool isNearRightEdge}) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        return GestureDetector(
          onTap: _handleBuddyTap,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // SPEECH BUBBLE
              if (_buddyMessage != null)
                Positioned(
                  bottom: 75.h,
                  left: isNearRightEdge ? null : -40.w,
                  right: isNearRightEdge ? -40.w : null,
                  child: _buildBuddySpeechBubble(_buddyMessage!),
                ),

              VowlMascot(
                    size: 55.r,
                    state: _buddyState,
                    useFloatingAnimation: true,
                    isKidsMode: true,
                  )
                  .animate(target: _buddyMessage != null ? 1 : 0)
                  .shake(hz: 10, curve: Curves.easeInOut)
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                    duration: 200.ms,
                    curve: Curves.easeOutBack,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.2, 1.2),
                    end: const Offset(1, 1),
                    duration: 200.ms,
                  ),
            ],
          ),
        ).animate().scale(curve: Curves.easeOutBack).fadeIn();
      },
    );
  }

  Widget _buildBuddySpeechBubble(String text) {
    return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              constraints: BoxConstraints(maxWidth: 160.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // Bubble Tail
            Padding(
              padding: EdgeInsets.only(right: 15.w),
              child: CustomPaint(
                size: Size(15.w, 10.h),
                painter: _BubbleTailPainter(Colors.white),
              ),
            ),
          ],
        )
        .animate()
        .fadeIn()
        .moveY(begin: 10, end: 0)
        .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
  }

  Widget _buildMapSegment(
    BuildContext context,
    int level,
    bool isLocked,
    bool isCurrent,
    bool isLast,
    double currentOffset,
    double nextOffset,
    bool isLoading,
    bool isTollGate,
    bool isCompleted,
    bool isPlayable,
    bool isNextZone,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isLoading) {
      return _buildShimmerSegment(context, currentOffset, nextOffset, isLast);
    }

    return CustomPaint(
      painter: SegmentPathPainter(
        color: isCompleted
            ? widget.primaryColor
            : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05)),
        currentOffset: currentOffset,
        nextOffset: nextOffset,
        isLast: isLast,
        level: level,
      ),
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: currentOffset,
              top: 50.h, // Vertically center the node in the 200.h segment
              child:
                  _buildLevelNode(
                        context,
                        level,
                        isLocked,
                        isCurrent,
                        isTollGate,
                        isCompleted,
                        isPlayable,
                        isNextZone,
                      )
                      .animate()
                      .fadeIn(duration: 800.ms, delay: (level % 5 * 100).ms)
                      .scale(
                        begin: const Offset(0.7, 0.7),
                        curve: Curves.easeOutBack,
                      )
                      .moveY(begin: 40, end: 0, curve: Curves.easeOutQuad),
            ),
            if (isCurrent)
              Positioned(
                left: currentOffset > 0.5.sw
                    ? currentOffset - 35.r
                    : currentOffset + 45.r,
                top: 25.h, // Moved closer to the node center
                child: _buildBuddy(
                  context,
                  isNearRightEdge: currentOffset > 0.5.sw,
                ),
              ),
            if (level == 10 || level == 50 || level == 100 || level == 200)
              _buildStickerGoal(level, isLocked),
          ],
        ),
      ),
    );
  }

  Widget _buildStickerGoal(int level, bool isLocked) {
    final stickerId = level == 10
        ? "sticker_${widget.gameType}"
        : "${widget.gameType}_sticker_$level";
    final stickerEmoji = KidsAssets.getStickerEmoji(stickerId);

    // Tiered Borders based on user request
    Color borderColor;
    String tierName;
    if (level == 10) {
      borderColor = const Color(0xFF10B981); // Emerald Green
      tierName = "GREEN TIER";
    } else if (level == 50) {
      borderColor = const Color(0xFFB45309); // Bronze/Amber
      tierName = "BRONZE TIER";
    } else if (level == 100) {
      borderColor = const Color(0xFF94A3B8); // Silver/Slate
      tierName = "SILVER TIER";
    } else {
      borderColor = const Color(0xFFF59E0B); // Gold
      tierName = "GOLD TIER";
    }

    return Positioned(
      top: -85.h,
      left: 0,
      right: 0,
      child:
          Column(
                children: [
                  Container(
                    width: 75.r,
                    height: 75.r,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isLocked ? Colors.white24 : borderColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isLocked ? Colors.black : borderColor)
                              .withValues(alpha: 0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(40.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: isLocked ? 10 : 0,
                          sigmaY: isLocked ? 10 : 0,
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedKidsAsset(
                                emoji: stickerEmoji,
                                size: 50.r,
                                animation: isLocked
                                    ? KidsAssetAnimation.none
                                    : KidsAssetAnimation.pulse,
                                color: isLocked
                                    ? Colors.grey[400]?.withValues(alpha: 0.3)
                                    : null,
                              ),
                              if (isLocked)
                                Container(
                                  padding: EdgeInsets.all(6.r),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '🔒',
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: isLocked
                          ? Colors.black.withValues(alpha: 0.3)
                          : Colors.amber,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      isLocked ? "LVL $level $tierName" : "STICKER WON! ✨",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -5,
                end: 5,
                duration: 2.seconds,
                curve: Curves.easeInOutSine,
              ),
    );
  }

  Widget _buildShimmerSegment(
    BuildContext context,
    double currentOffset,
    double nextOffset,
    bool isLast,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.white24 : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomPaint(
        painter: SegmentPathPainter(
          color: Colors.white,
          currentOffset: currentOffset,
          nextOffset: nextOffset,
          isLast: isLast,
          level: 0, // Shimmer level
        ),
        child: Container(
          height: 200.h,
          padding: EdgeInsets.only(left: currentOffset),
          alignment: Alignment.centerLeft,
          child: Container(
            width: 100.r,
            height: 100.r,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
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
                    "KIDS QUEST",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: widget.primaryColor,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    widget.title,
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
                          "${user?.kidsCoins ?? 0} COINS",
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        MeshGradientBackground(
          colors: isDark
              ? [
                  widget.primaryColor.withAlpha(100),
                  const Color(0xFF0F172A),
                  widget.primaryColor.withAlpha(80),
                ]
              : [
                  widget.primaryColor.withAlpha(60),
                  const Color(0xFFF8FAFC),
                  widget.primaryColor.withAlpha(40),
                ],
        ).animate().fadeIn(duration: 400.ms),
        // Decorative clouds
        Positioned(top: 100.h, left: -100.w, child: _buildCloud(context, 180.w))
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveX(
              begin: 0,
              end: 200,
              duration: 10.seconds,
              curve: Curves.easeInOutSine,
            ),

        Positioned(
              bottom: 250.h,
              right: -100.w,
              child: _buildCloud(context, 160.w),
            )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveX(
              begin: 0,
              end: -250,
              duration: 14.seconds,
              curve: Curves.easeInOutSine,
            ),
      ],
    );
  }

  Widget _buildCloud(BuildContext context, double width) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Icon(
      Icons.cloud_rounded,
      color: (isDark ? Colors.white.withAlpha(15) : Colors.white).withAlpha(
        180,
      ),
      size: width,
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

  Widget _buildLevelNode(
    BuildContext context,
    int level,
    bool isLocked,
    bool isCurrent,
    bool isTollGate,
    bool isCompleted,
    bool isPlayable,
    bool isNextZone,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () {
        if (isTollGate) {
          final completedLevels =
              context
                  .read<AuthBloc>()
                  .state
                  .user
                  ?.completedLevels[widget.gameType] ??
              [];
          final highestCompleted = completedLevels.isEmpty
              ? 0
              : completedLevels.reduce(math.max);

          if (level > highestCompleted + 1) {
            CustomSnackBar.show(
              context: context,
              message: context.tr(
                'games.kids_level_locked_sequence',
                fallback: 'Complete previous levels first!',
              ),
              type: CustomSnackBarType.info,
            );
            return;
          }
          KidsTollGateBottomSheet.show(
            context: context,
            level: level,
            gameType: widget.gameType,
            primaryColor: widget.primaryColor,
          );
        } else if (isPlayable || isCompleted) {
          _navigateToGame(context, level);
        } else if (!isLocked && !isPlayable && !isCompleted) {
          CustomSnackBar.show(
            context: context,
            message: context.tr(
              'games.kids_level_locked_sequence',
              fallback: 'Complete previous levels first!',
            ),
            type: CustomSnackBarType.info,
          );
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Clean Drop Shadow
          Container(
            width: isCurrent ? 100.r : 85.r,
            height: isCurrent ? 100.r : 85.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (isTollGate
                              ? Colors.amber
                              : isLocked
                              ? Colors.black
                              : widget.primaryColor)
                          .withValues(alpha: 0.15),
                  blurRadius: 20.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
          ),

          // 2. Main Disk Body
          Container(
                width: isCurrent ? 100.r : 85.r,
                height: isCurrent ? 100.r : 85.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTollGate
                      ? Colors.amber.shade400
                      : isNextZone
                      ? Colors.amber.shade100.withValues(alpha: 0.5)
                      : isLocked
                      ? (isDark ? Colors.grey[800] : Colors.grey[200])
                      : widget.primaryColor,
                  border: Border.all(
                    color: isTollGate
                        ? Colors.amber.shade700
                        : isNextZone
                        ? Colors.amber.shade300.withValues(alpha: 0.5)
                        : (isLocked ? Colors.transparent : Colors.white),
                    width: isCurrent ? 5.r : 3.r,
                  ),
                ),
                child: Center(
                  child: isTollGate
                      ? Icon(
                          Icons.key_rounded,
                          color: Colors.white,
                          size: 40.r,
                          shadows: const [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ],
                        )
                      : isLocked
                      ? Icon(
                          Icons.lock_rounded,
                          color: isDark ? Colors.white24 : Colors.black12,
                          size: 24.r,
                        )
                      : Padding(
                          padding: EdgeInsets.all(8.r),
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "$level",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: (isCurrent ? 32 : 26).sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                if (isCompleted || isPlayable) ...[
                                  SizedBox(height: 2.h),
                                  Builder(
                                    builder: (context) {
                                      final earnedStars =
                                          context
                                              .read<AuthBloc>()
                                              .state
                                              .user
                                              ?.starRatings[widget
                                              .gameType]?[level.toString()] ??
                                          0;
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(3, (index) {
                                          final isEarned = index < earnedStars;
                                          return Icon(
                                            Icons.star_rounded,
                                            size: index == 1 ? 14.r : 10.r,
                                            color: isEarned
                                                ? Colors.amber
                                                : Colors.white38,
                                          );
                                        }),
                                      );
                                    },
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -5.r,
                end: 5.r,
                duration: 2.seconds,
                curve: Curves.easeInOutSine,
              ),

          // 3. Current Level Indicator
          if (isCurrent)
            Container(
                  width: 120.r,
                  height: 120.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      width: 2.r,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.2, 1.2),
                  duration: 1.5.seconds,
                )
                .fadeOut(),
        ],
      ),
    );
  }

  void _navigateToGame(BuildContext context, int level) {
    final routeMap = {
      'alphabet': AppRouter.kidsAlphabetRoute,
      'numbers': AppRouter.kidsNumbersRoute,
      'colors': AppRouter.kidsColorsRoute,
      'shapes': AppRouter.kidsShapesRoute,
      'animals': AppRouter.kidsAnimalsRoute,
      'fruits': AppRouter.kidsFruitsRoute,
      'family': AppRouter.kidsFamilyRoute,
      'school': AppRouter.kidsSchoolRoute,
      'verbs': AppRouter.kidsVerbsRoute,
      'routine': AppRouter.kidsRoutineRoute,
      'emotions': AppRouter.kidsEmotionsRoute,
      'prepositions': AppRouter.kidsPrepositionsRoute,
      'phonics': AppRouter.kidsPhonicsRoute,
      'time': AppRouter.kidsTimeRoute,
      'opposites': AppRouter.kidsOppositesRoute,
      'day_night': AppRouter.kidsDayNightRoute,
      'nature': AppRouter.kidsNatureRoute,
      'home': AppRouter.kidsHomeRoute,
      'food': AppRouter.kidsFoodRoute,
      'transport': AppRouter.kidsTransportRoute,
      'body_parts': AppRouter.kidsBodyPartsRoute,
      'clothing': AppRouter.kidsClothingRoute,
    };

    final route = routeMap[widget.gameType];
    debugPrint(
      "KIDS_MAP: Navigating to ${widget.gameType} level $level. Route: $route",
    );

    if (route != null) {
      context.push(route, extra: level);
    } else {
      debugPrint(
        "KIDS_MAP_ERROR: Route for gameType '${widget.gameType}' not found!",
      );
      CustomSnackBar.show(
        context: context,
        message: context.tr('games.kids_under_construction', fallback: 'Under Construction', fallback: 'Under Construction'),
        type: CustomSnackBarType.warning,
      );
    }
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  _BubbleTailPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, 0);
    path.lineTo(size.width / 2, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
