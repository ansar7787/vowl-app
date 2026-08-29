import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/presentation/painters/modern_segment_path_painter.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/presentation/widgets/games/maps/components/toll_gate_bottom_sheet.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ModernMapNode extends StatefulWidget {
  final int index;
  final int levelNumber;
  final int totalLevels;
  final Offset point;
  final List<Offset> points;
  final double rowSpacing;

  final int unlockedLevels;
  final int completedLevels;
  final bool isPremium;

  final int? justUnlockedLevel;
  final int? celebratingLevel;

  final AnimationController unlockPathController;
  final AnimationController glowController;
  final ConfettiController confettiController;

  final ThemeResult theme;
  final bool isDark;
  

  final String categoryId;
  final String gameType;

  const ModernMapNode({
    super.key,
    required this.index,
    required this.levelNumber,
    required this.totalLevels,
    required this.point,
    required this.points,
    required this.rowSpacing,
    required this.unlockedLevels,
    required this.completedLevels,
    required this.isPremium,
    required this.justUnlockedLevel,
    required this.celebratingLevel,
    required this.unlockPathController,
    required this.glowController,
    required this.confettiController,
    required this.theme,
    required this.isDark,

    required this.categoryId,
    required this.gameType,
  });

  @override
  State<ModernMapNode> createState() => _ModernMapNodeState();
}

class _ModernMapNodeState extends State<ModernMapNode> {
  String? _buddyMessage;
  Timer? _buddyMessageTimer;

  @override
  void dispose() {
    _buddyMessageTimer?.cancel();
    super.dispose();
  }

  Color _getTierColor(int level, bool isTollGate, Color baseColor) {
    if (isTollGate) {
      return Colors.amber;
    } else if (level >= 50 && level < 100) {
      return const Color(0xFFCD7F32); // Bronze
    } else if (level >= 100 && level < 150) {
      return const Color(0xFFC0C0C0); // Silver
    } else if (level >= 150) {
      return const Color(0xFFFFD700); // Gold
    }
    return baseColor;
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

  String _formatMascotName(String id) {
    final Map<String, String> nameMap = {
      'vowl_prime': 'Vowl',
      'vowl_ninja': 'Sensei Vowl',
      'vowl_pirate': 'Captain Vowl',
      'vowl_astronaut': 'Astro Vowl',
      'vowl_wizard': 'Merlin Vowl',
      'vowl_king': 'King Vowl',
    };
    return nameMap[id] ?? 'Vowl';
  }

  Widget _buildModernSpeechBubble(Color primaryColor, bool isLeft) {
    return CustomPaint(
      painter: _PremiumBubblePainter(
        baseColor: primaryColor,
        isDark: widget.isDark,
        isLeft: isLeft,
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 190.w),
        padding: EdgeInsets.only(
          top: 14.h,
          bottom: 14.h,
          left: isLeft ? 28.w : 16.w,
          right: !isLeft ? 28.w : 16.w,
        ),
        child: AutoSizeText(
          _buddyMessage!,
          style: TextStyle(
            fontFamily: 'Outfit',
            color: Colors.white,
            fontSize: 12.sp,
            fontWeight: FontWeight.w700,
            shadows: const [
              Shadow(
                color: Colors.black45,
                offset: Offset(0, 1),
                blurRadius: 2,
              ),
            ],
          ),
          maxLines: 4,
          minFontSize: 9,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(
      alignment: isLeft ? Alignment.bottomLeft : Alignment.bottomRight,
      curve: Curves.easeOutBack,
    );
  }

  Widget _buildMascotMarker(BuildContext context) {
    final theme = LevelThemeHelper.getTheme(widget.gameType, isDark: widget.isDark);
    final user = context.read<AuthBloc>().state.user;
    final mascotId = user?.vowlMascot ?? 'vowl_prime';

    // 10/10 Smart Alignment: Flips the bubble to face the empty center of the screen
    // This absolutely guarantees it will never clip off the sides, and since it expands sideways,
    // it will never clip off the top edge of the screen either.
    final bool isLeftHalf = widget.point.dx <= ScreenUtil().screenWidth / 2;

    return Semantics(
      button: true,
      label: context.tr(
        'category_map.mascot_marker_action',
        fallback: 'Get a cheer from your mascot',
      ),
      child: GestureDetector(
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
            args: [widget.unlockedLevels.toString(), mascotName],
            fallback: fallbacks[pick]
                .replaceAll('{0}', widget.unlockedLevels.toString())
                .replaceAll('{1}', mascotName),
          );

          setState(() {
            _buddyMessage = message;
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
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Mascot
              VowlMascot(
                size: 55.r,
                useFloatingAnimation: true,
                mascotId: mascotId,
              ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),

              // 10/10 Glassmorphism Speech Bubble
              if (_buddyMessage != null)
                Positioned(
                  top: -30.h,
                  left: isLeftHalf ? 45.r : null,
                  right: !isLeftHalf ? 45.r : null,
                  child: _buildModernSpeechBubble(theme.primaryColor, isLeftHalf),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNodeCircle(
    BuildContext context,
    bool isCurrent,
    bool isCompleted,
    bool isPlayable,
    bool isHalfUnlocked,
    bool isTollGate,
    bool isNextZone,
    Color tierColor,
  ) {
    Widget circleWidget = Container(
      width: isCurrent ? 96.r : 88.r,
      height: isCurrent ? 96.r : 88.r,
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
                    .withValues(alpha: widget.isDark ? 0.4 : 0.2),
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
          width: 3.r,
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
                          "${widget.levelNumber}",
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
                                      ?.starRatings[widget.gameType]?[widget.levelNumber
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
      return AnimatedBuilder(
        animation: widget.glowController,
        builder: (context, child) {
          final glowValue = Curves.easeInOutSine.transform(
            widget.glowController.value,
          );
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: (102 + 16 * glowValue).r,
                height: (102 + 16 * glowValue).r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: tierColor.withValues(
                    alpha: 0.12 * (1.0 - glowValue * 0.5),
                  ),
                  border: Border.all(
                    color: tierColor.withValues(alpha: 0.25 + 0.25 * glowValue),
                    width: 2.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tierColor.withValues(
                        alpha: 0.15 + 0.15 * glowValue,
                      ),
                      blurRadius: 18.r + 10.r * glowValue,
                      spreadRadius: 2.r + 3.r * glowValue,
                    ),
                  ],
                ),
              ),
              Transform.translate(
                offset: Offset(0, -6.h * glowValue),
                child: Transform.scale(
                  scale: 1.0 + 0.08 * glowValue,
                  child: child!,
                ),
              ),
            ],
          );
        },
        child: circleWidget,
      );
    }

    return circleWidget;
  }

  @override
  Widget build(BuildContext context) {
    final bool isNodeCompleted = widget.levelNumber <= widget.completedLevels;
    final bool isPrevNodeCompleted = widget.index == 0
        ? true
        : (widget.index <= widget.completedLevels);
    final bool isPlayable =
        widget.levelNumber == widget.completedLevels + 1 &&
        (widget.levelNumber <= widget.unlockedLevels || widget.isPremium);
    final bool isTollGateSegment =
        widget.levelNumber == widget.completedLevels + 1 &&
        widget.levelNumber > widget.unlockedLevels &&
        !widget.isPremium;
    final bool isCurrent = isPlayable || isTollGateSegment;
    final bool isJustUnlocked = widget.levelNumber == widget.justUnlockedLevel;
    final bool isPrevToJustUnlocked = widget.justUnlockedLevel != null && widget.levelNumber == widget.justUnlockedLevel! - 1;
    final bool isHalfUnlocked =
        widget.levelNumber > widget.completedLevels + 1 &&
        widget.levelNumber <= widget.unlockedLevels &&
        widget.unlockedLevels > 10;
    final bool isNextZone =
        widget.levelNumber > widget.unlockedLevels + 1 &&
        widget.levelNumber <= widget.unlockedLevels + 3 &&
        !widget.isPremium &&
        widget.completedLevels >= widget.unlockedLevels;
    final bool isUnlockedForClick = isNodeCompleted || isPlayable;
    final Color tierColor = _getTierColor(widget.levelNumber, isTollGateSegment, widget.theme.primaryColor);

    final Animation<double> nodeAnimation;
    if (isCurrent) {
      nodeAnimation = widget.glowController;
    } else {
      nodeAnimation = const AlwaysStoppedAnimation(0);
    }

    double incomingProgress = 1.0;
    double outgoingProgress = 1.0;
    
    if (widget.justUnlockedLevel != null) {
      final double rawValue = Curves.easeOutSine.transform(widget.unlockPathController.value);
      if (isJustUnlocked) {
        incomingProgress = ((rawValue - 0.5) * 2).clamp(0.0, 1.0);
      } else if (isPrevToJustUnlocked) {
        outgoingProgress = (rawValue * 2).clamp(0.0, 1.0);
      }
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([nodeAnimation, widget.unlockPathController]),
        builder: (context, child) {
          Widget nodeWidget = child!;
          
          if (isJustUnlocked) {
            final double rawValue = Curves.easeOutSine.transform(widget.unlockPathController.value);
            final double popProgress = ((rawValue - 0.74) * (1.0 / 0.26)).clamp(0.0, 1.0);
            final double pulseScale = math.sin(popProgress * math.pi);
            
            nodeWidget = Transform.scale(
              scale: 1.0 + 0.3 * pulseScale,
              child: nodeWidget,
            );
          }

          return CustomPaint(
            painter: ModernSegmentPathPainter(
              currentPoint: Offset(widget.point.dx, widget.rowSpacing / 2),
              prevPoint: widget.index > 0
                  ? Offset(widget.points[widget.index - 1].dx, 0)
                  : null,
              nextPoint: widget.index < widget.totalLevels - 1
                  ? Offset(widget.points[widget.index + 1].dx, widget.rowSpacing)
                  : null,
              prevPrevX: widget.index > 1
                  ? widget.points[widget.index - 2].dx
                  : null,
              nextNextX: widget.index < widget.totalLevels - 2
                  ? widget.points[widget.index + 2].dx
                  : null,
              activeColor: tierColor,
              isCompleted: isNodeCompleted,
              isPrevCompleted: isPrevNodeCompleted,
              isFirst: widget.index == 0,
              isLast: widget.index == widget.totalLevels - 1,
              isDark: widget.isDark,
              isTollGate: isTollGateSegment,
              incomingPathProgress: incomingProgress,
              outgoingPathProgress: outgoingProgress,
              glowAnimation: isCurrent ? widget.glowController : null,
            ),
            child: nodeWidget,
          );
        },
        child: SizedBox(
          height: widget.rowSpacing,
          child: Align(
            alignment: Alignment.center,
            child: Transform.translate(
              offset: Offset(
                widget.point.dx - ScreenUtil().screenWidth / 2,
                0,
              ),
              child: SizedBox(
                width: 160.r,
                height: 220.h,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Semantics(
                      button: true,
                      label: context.tr('games.level_label_short', args: [widget.levelNumber.toString()], fallback: 'Level ${widget.levelNumber}'),
                      child: ScaleButton(
                        onTap: () {
                          if (isTollGateSegment) {
                            if (widget.levelNumber > widget.completedLevels + 1) {
                              _showLockedFeedback(context, Colors.amber);
                              return;
                            }
                            TollGateBottomSheet.show(
                              context: context,
                              level: widget.levelNumber,
                              gameType: widget.gameType,
                            );
                            return;
                          }

                          if (!isUnlockedForClick) {
                            _showLockedFeedback(context, widget.theme.primaryColor);
                            return;
                          }

                          context.push(
                            '/game?category=${Uri.encodeQueryComponent(widget.categoryId)}&gameType=${Uri.encodeQueryComponent(widget.gameType)}&level=${widget.levelNumber}',
                          );
                        },
                        child: ExcludeSemantics(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              if (isCurrent || widget.celebratingLevel == widget.levelNumber)
                                Builder(
                                  builder: (context) {
                                    final isMilestone = widget.levelNumber == 10 || widget.levelNumber == 50 || widget.levelNumber == 100 || widget.levelNumber == 200;
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
                              _buildNodeCircle(
                                context,
                                isCurrent,
                                isNodeCompleted,
                                isPlayable,
                                isHalfUnlocked,
                                isTollGateSegment,
                                isNextZone,
                                tierColor,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpeechBubbleClipper extends CustomClipper<Path> {
  final bool isLeft;
  _SpeechBubbleClipper({required this.isLeft});

  @override
  Path getClip(Size size) {
    final double r = 16.r;
    final double tailW = 14.w;
    
    final path = Path();
    if (isLeft) {
      // Box
      path.moveTo(tailW + r, 0);
      path.lineTo(size.width - r, 0);
      path.arcToPoint(Offset(size.width, r), radius: Radius.circular(r));
      path.lineTo(size.width, size.height - r);
      path.arcToPoint(Offset(size.width - r, size.height), radius: Radius.circular(r));
      path.lineTo(tailW + r, size.height);
      path.arcToPoint(Offset(tailW, size.height - r), radius: Radius.circular(r));
      
      // Tail on left side, pointing bottom-left
      path.lineTo(tailW, size.height - r - 10.h);
      path.lineTo(0, size.height - r - 2.h); // tail tip
      path.lineTo(tailW, size.height - r - 26.h);
      
      path.lineTo(tailW, r);
      path.arcToPoint(Offset(tailW + r, 0), radius: Radius.circular(r));
    } else {
      // Box
      path.moveTo(r, 0);
      path.lineTo(size.width - tailW - r, 0);
      path.arcToPoint(Offset(size.width - tailW, r), radius: Radius.circular(r));
      
      // Tail on right side, pointing bottom-right
      path.lineTo(size.width - tailW, size.height - r - 26.h);
      path.lineTo(size.width, size.height - r - 2.h); // tail tip
      path.lineTo(size.width - tailW, size.height - r - 10.h);
      
      path.lineTo(size.width - tailW, size.height - r);
      path.arcToPoint(Offset(size.width - tailW - r, size.height), radius: Radius.circular(r));
      path.lineTo(r, size.height);
      path.arcToPoint(Offset(0, size.height - r), radius: Radius.circular(r));
      path.lineTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _SpeechBubbleClipper oldClipper) => oldClipper.isLeft != isLeft;
}

class _PremiumBubblePainter extends CustomPainter {
  final Color baseColor;
  final bool isDark;
  final bool isLeft;

  _PremiumBubblePainter({
    required this.baseColor,
    required this.isDark,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final clipper = _SpeechBubbleClipper(isLeft: isLeft);
    final path = clipper.getClip(size);

    // High-performance translucent gradient instead of expensive blur
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor.withValues(alpha: isDark ? 0.85 : 0.95),
        baseColor.withValues(alpha: isDark ? 0.45 : 0.75),
      ],
    );

    final paint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
      
    canvas.drawPath(path, paint);
    
    // Crisp solid inner highlight border (cheap to render, sells the 3D look)
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDark ? 0.2 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5.r;
    
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _PremiumBubblePainter oldDelegate) =>
      oldDelegate.baseColor != baseColor ||
      oldDelegate.isDark != isDark ||
      oldDelegate.isLeft != isLeft;
}
