import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'package:confetti/confetti.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/animated_kids_asset.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_toll_gate_bottom_sheet.dart';
import 'package:vowl/features/kids_zone/presentation/painters/kids_segment_path_painter.dart';
import 'package:vowl/core/utils/locale_service.dart';

class KidsMapNode extends StatefulWidget {
  final int level;
  final bool isLocked;
  final bool isCurrent;
  final bool isLast;
  final double currentOffset;
  final double nextOffset;
  final double prevOffset;
  final bool isLoading;
  final bool isTollGate;
  final bool isCompleted;
  final bool isPlayable;
  final bool isNextZone;
  final bool isPrevCompleted;
  
  final String gameType;
  final Color primaryColor;

  final AnimationController unlockPathController;
  final AnimationController entryController;
  final AnimationController glowController;
  final ConfettiController confettiController;
  
  final bool isUnlockAnimating;
  final int? celebratingLevel;

  const KidsMapNode({
    super.key,
    required this.level,
    required this.isLocked,
    required this.isCurrent,
    required this.isLast,
    required this.currentOffset,
    required this.nextOffset,
    required this.prevOffset,
    required this.isLoading,
    required this.isTollGate,
    required this.isCompleted,
    required this.isPlayable,
    required this.isNextZone,
    required this.isPrevCompleted,
    required this.gameType,
    required this.primaryColor,
    required this.unlockPathController,
    required this.entryController,
    required this.glowController,
    required this.confettiController,
    required this.isUnlockAnimating,
    required this.celebratingLevel,
  });

  @override
  State<KidsMapNode> createState() => _KidsMapNodeState();
}

class _KidsMapNodeState extends State<KidsMapNode> {
  String? _buddyMessage;
  Timer? _buddyMessageTimer;
  VowlMascotState _buddyState = VowlMascotState.neutral;

  @override
  void dispose() {
    _buddyMessageTimer?.cancel();
    super.dispose();
  }

  void _handleBuddyTap() {
    _buddyMessageTimer?.cancel();

    // Trigger state change animation
    setState(() {
      _buddyState = VowlMascotState.happy;
    });

    final messages = [
      'kids_zone.cheer_great',
      'kids_zone.cheer_star',
      'kids_zone.cheer_smart',
      'kids_zone.cheer_wow',
    ];
    final fallbacks = [
      "You're doing great! 🌟",
      "You're a super star! ⭐",
      "So smart! 🧠",
      "Wow! Keep going! 🚀",
    ];
    
    final index = math.Random().nextInt(messages.length);
    final msg = context.tr(messages[index], fallback: fallbacks[index]);

    setState(() {
      _buddyMessage = msg;
    });

    di.sl<TtsService>().speak(msg.replaceAll(RegExp(r'[^\w\s\!]'), ''));

    _buddyMessageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _buddyMessage = null;
          _buddyState = VowlMascotState.neutral;
        });
      }
    });
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
              // 10/10 Bouncy Comic Cloud Bubble
              if (_buddyMessage != null)
                Positioned(
                  top: -30.h,
                  right: isNearRightEdge ? 45.r : null,
                  left: !isNearRightEdge ? 45.r : null,
                  child: _buildBuddySpeechBubble(_buddyMessage!, isNearRightEdge),
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

  Widget _buildBuddySpeechBubble(String text, bool isNearRightEdge) {
    return Container(
      constraints: BoxConstraints(maxWidth: 180.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          topRight: Radius.circular(28.r),
          bottomLeft: isNearRightEdge ? Radius.circular(28.r) : Radius.circular(2.r),
          bottomRight: isNearRightEdge ? Radius.circular(2.r) : Radius.circular(28.r),
        ),
        border: Border.all(
          color: widget.primaryColor,
          width: 4.r,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.3),
            blurRadius: 15.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: AutoSizeText(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.sp,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF1E293B),
        ),
        textAlign: TextAlign.center,
        minFontSize: 10,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
    )
    .animate()
    .scale(
      alignment: isNearRightEdge ? Alignment.bottomRight : Alignment.bottomLeft,
      curve: Curves.elasticOut,
      duration: 700.ms,
    )
    .then()
    .animate(onPlay: (c) => c.repeat(reverse: true))
    .scale(
      begin: const Offset(1.0, 1.0),
      end: const Offset(1.05, 1.05),
      duration: 1.5.seconds,
      curve: Curves.easeInOutSine,
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
      tierName = context.tr('kids_zone.tier_green', fallback: "GREEN TIER");
    } else if (level == 50) {
      borderColor = const Color(0xFFB45309); // Bronze/Amber
      tierName = context.tr('kids_zone.tier_bronze', fallback: "BRONZE TIER");
    } else if (level == 100) {
      borderColor = const Color(0xFFA0B2C6); // Premium Ice-Silver
      tierName = context.tr('kids_zone.tier_silver', fallback: "SILVER TIER");
    } else if (level == 200) {
      borderColor = const Color(0xFF00F0FF); // Cyan/Diamond (Legendary)
      tierName = context.tr('kids_zone.tier_legendary', fallback: "LEGENDARY TIER");
    } else {
      borderColor = const Color(0xFFF59E0B); // Gold
      tierName = context.tr('kids_zone.tier_gold', fallback: "GOLD TIER");
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
                      isLocked ? context.tr('kids_zone.lvl_tier', args: ['$level', tierName], fallback: "LVL $level $tierName") : context.tr('kids_zone.sticker_won', fallback: "STICKER WON! ✨"),
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

  Widget _buildShimmerSegment(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.white24 : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: CustomPaint(
        painter: SegmentPathPainter(
          incomingColor: Colors.white,
          outgoingColor: Colors.white,
          currentOffset: widget.currentOffset,
          nextOffset: widget.nextOffset,
          prevOffset: widget.currentOffset, // Shimmer doesn't need perfect continuity
          isLast: widget.isLast,
          level: 0, // Shimmer level
        ),
        child: Container(
          height: 200.h,
          padding: EdgeInsets.only(left: widget.currentOffset),
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

  Widget _buildLevelNode(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () {
        if (widget.isTollGate) {
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

          if (widget.level > highestCompleted + 1) {
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
            level: widget.level,
            gameType: widget.gameType,
            primaryColor: widget.primaryColor,
          );
        } else if (widget.isPlayable || widget.isCompleted) {
          _navigateToGame(context, widget.level);
        } else if (!widget.isLocked && !widget.isPlayable && !widget.isCompleted) {
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
          if (widget.isCurrent || widget.celebratingLevel == widget.level)
            Builder(
              builder: (context) {
                final isMilestone = widget.level == 10 || widget.level == 50 || widget.level == 100 || widget.level == 200;
                return ConfettiWidget(
                  confettiController: widget.confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  emissionFrequency: isMilestone ? 0.05 : 0.1,
                  numberOfParticles: isMilestone ? 80 : 20,
                  gravity: isMilestone ? 0.1 : 0.2,
                  colors: const [
                    Colors.green,
                    Colors.blue,
                    Colors.pink,
                    Colors.orange,
                    Colors.purple,
                    Colors.amber,
                  ],
                );
              },
            ),
          // 1. Clean Drop Shadow
          Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      (widget.isTollGate
                              ? Colors.amber
                              : widget.isLocked
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
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isTollGate
                      ? Colors.amber.shade400
                      : widget.isNextZone
                      ? Colors.amber.shade100.withValues(alpha: 0.5)
                      : widget.isLocked
                      ? (isDark 
                          ? Color.lerp(const Color(0xFF0F172A), widget.primaryColor, 0.2)! 
                          : Color.lerp(const Color(0xFFF8FAFC), widget.primaryColor, 0.15)!)
                      : widget.primaryColor,
                  border: Border.all(
                    color: widget.isTollGate
                        ? Colors.amber.shade700
                        : widget.isNextZone
                        ? Colors.amber.shade300.withValues(alpha: 0.5)
                        : (widget.isLocked ? Colors.transparent : Colors.white),
                    width: widget.isCurrent ? 5.r : 3.r,
                  ),
                ),
                child: Center(
                  child: widget.isTollGate
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
                      : widget.isLocked
                      ? Icon(
                          Icons.lock_rounded,
                          color: isDark 
                              ? widget.primaryColor.withValues(alpha: 0.4) 
                              : widget.primaryColor.withValues(alpha: 0.3),
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
                                  "${widget.level}",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: (widget.isCurrent ? 32 : 26).sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                if (widget.isCompleted || widget.isPlayable) ...[
                                  SizedBox(height: 2.h),
                                  Builder(
                                    builder: (context) {
                                      final earnedStars =
                                          context
                                              .read<AuthBloc>()
                                              .state
                                              .user
                                              ?.starRatings[widget
                                              .gameType]?[widget.level.toString()] ??
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

          // 3. Current Level – Double-Ring Glow Beacon
          if (widget.isCurrent) ...[
            // Inner soft glow ring
            Container(
                  width: 115.r,
                  height: 115.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.4),
                      width: 3.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 20.r,
                        spreadRadius: 4.r,
                      ),
                    ],
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(0.92, 0.92),
                  end: const Offset(1.05, 1.05),
                  duration: 1.8.seconds,
                  curve: Curves.easeInOutSine,
                )
                .fadeIn(begin: 0.5),
            // Outer expanding pulse ring
            Container(
                  width: 130.r,
                  height: 130.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.2),
                      width: 2.r,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat())
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1.3, 1.3),
                  duration: 2.seconds,
                  curve: Curves.easeOut,
                )
                .fadeOut(duration: 2.seconds),
          ],
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
      'handwriting': AppRouter.kidsHandwritingRoute,
      'weather': AppRouter.kidsWeatherRoute,
      'professions': AppRouter.kidsProfessionsRoute,
    };

    final route = routeMap[widget.gameType];

    if (route != null) {
      context.push(route, extra: level);
    } else {
      CustomSnackBar.show(
        context: context,
        message: context.tr(
          'games.kids_under_construction',
          fallback: 'Under Construction',
        ),
        type: CustomSnackBarType.warning,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.isLoading) {
      return _buildShimmerSegment(context);
    }

    return AnimatedBuilder(
      animation: Listenable.merge([
        widget.unlockPathController,
        widget.entryController,
      ]),
      builder: (context, child) {
        // Immediate entry for all visible nodes (removes the empty-screen delay)
        final entryT = Curves.easeOutCubic.transform(widget.entryController.value);

        // Path-draw progress for the segment right before the current node
        double incomingProgress = 1.0;
        double outgoingProgress = 1.0;
        
        if (widget.isUnlockAnimating) {
          final user = context.read<AuthBloc>().state.user;
          final completed = user?.completedLevels[widget.gameType] ?? [];
          final highest = completed.isEmpty ? 0 : completed.reduce(math.max);
          final currActive = math.min(200, highest + 1);
          
          // easeOutSine starts instantly (no starting delay) and flows smoothly, slowing down gracefully at the end
          final double rawValue = Curves.easeOutSine.transform(widget.unlockPathController.value);
          
          if (widget.level == currActive) {
            // Draws the second half of the path (from the midpoint to the new node)
            incomingProgress = ((rawValue - 0.5) * 2).clamp(0.0, 1.0);
          } else if (widget.level == currActive - 1) {
            // Draws the first half of the path (from the previous node to the midpoint)
            outgoingProgress = (rawValue * 2).clamp(0.0, 1.0);
          }
        }

        return Opacity(
          opacity: entryT,
          child: Transform.scale(
            scale: 0.85 + 0.15 * entryT,
            child: CustomPaint(
              painter: SegmentPathPainter(
                incomingColor: widget.isPrevCompleted
                    ? widget.primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05)),
                outgoingColor: widget.isCompleted
                    ? widget.primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05)),
                currentOffset: widget.currentOffset,
                nextOffset: widget.nextOffset,
                prevOffset: widget.prevOffset,
                isLast: widget.isLast,
                level: widget.level,
                incomingPathProgress: incomingProgress,
                outgoingPathProgress: outgoingProgress,
                isCurrent: widget.isCurrent,
                glowAnimation: widget.isCurrent ? widget.glowController : null,
              ),
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        height: 200.h,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: widget.currentOffset,
              top: 50.h, // Vertically center the node in the 200.h segment
                child: Builder(
                  builder: (context) {
                    Widget node = _buildLevelNode(context);
                    
                    if (widget.isUnlockAnimating) {
                      final user = context.read<AuthBloc>().state.user;
                      final completed = user?.completedLevels[widget.gameType] ?? [];
                      final highest = completed.isEmpty ? 0 : completed.reduce(math.max);
                      final currActive = math.min(200, highest + 1);
                      if (widget.level == currActive) {
                        final double rawValue = Curves.easeOutSine.transform(widget.unlockPathController.value);
                        // The path mathematically touches the node's edge at rawValue = 0.74
                        final double popProgress = ((rawValue - 0.74) * (1.0 / 0.26)).clamp(0.0, 1.0);
                        final double pulseScale = math.sin(popProgress * math.pi); // 0.0 -> 1.0 -> 0.0
                        
                        return Transform.scale(
                          scale: 1.0 + 0.3 * pulseScale, // Node stays 100%, swells to 130%, and settles back to 100%
                          child: node,
                        );
                      }
                    }
                    return node;
                  },
                ),
            ),
            if (widget.isCurrent)
              Positioned(
                left: widget.currentOffset > 0.5.sw
                    ? widget.currentOffset - 50.r // Buddy sits neatly to the left of the node
                    : widget.currentOffset + 90.r, // Buddy sits neatly to the right of the node
                top: 25.h,
                child: _buildBuddy(
                  context,
                  isNearRightEdge: widget.currentOffset > 0.5.sw,
                ),
              ),
            if (widget.level == 10 || widget.level == 50 || widget.level == 100 || widget.level == 150 || widget.level == 200)
              _buildStickerGoal(widget.level, widget.isLocked),
          ],
        ),
      ),
    );
  }
}

