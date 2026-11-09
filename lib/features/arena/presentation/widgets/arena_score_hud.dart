import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ArenaScoreHud extends StatefulWidget {
  final String myName;
  final String? myPhotoUrl;
  final int myScore;
  final String rivalName;
  final String? rivalPhotoUrl;
  final int rivalScore;
  final int currentQuestionIndex;
  final int totalQuestions;
  final int timeRemaining;
  final bool isAnswered;
  final bool isDark;
  final bool isAiRival;
  final String? aiTierLabel;
  final bool animateTimer;
  final int comboStreak;

  const ArenaScoreHud({
    super.key,
    required this.myName,
    this.myPhotoUrl,
    required this.myScore,
    required this.rivalName,
    this.rivalPhotoUrl,
    required this.rivalScore,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.timeRemaining,
    this.isAnswered = false,
    required this.isDark,
    this.isAiRival = false,
    this.aiTierLabel,
    this.animateTimer = true,
    this.comboStreak = 0,
  });

  @override
  State<ArenaScoreHud> createState() => _ArenaScoreHudState();
}

class _ArenaScoreHudState extends State<ArenaScoreHud>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  int _lastHapticSecond = -1;
  double _comboScale = 1.0;
  Timer? _popTimer;

  @override
  void initState() {
    super.initState();
    if (widget.comboStreak >= 2) {
      _comboScale = 0.0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _comboScale = 1.0;
          });
        }
      });
    } else {
      _comboScale = 0.0;
    }

    if (widget.animateTimer) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15),
      );
      _controller!.addListener(_onTick);
      _controller!.addStatusListener(_onStatus);
      if (!widget.isAnswered) {
        _controller!.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant ArenaScoreHud oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.comboStreak != oldWidget.comboStreak) {
      _popTimer?.cancel();
      if (widget.comboStreak >= 2) {
        if (oldWidget.comboStreak < 2) {
          _comboScale = 0.0;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _comboScale = 1.0;
              });
            }
          });
        } else {
          setState(() {
            _comboScale = 1.25;
          });
          _popTimer = Timer(const Duration(milliseconds: 160), () {
            if (mounted) {
              setState(() {
                _comboScale = 1.0;
              });
            }
          });
        }
      } else {
        _comboScale = 0.0;
      }
    }

    if (!widget.animateTimer) return;

    if (_controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 15),
      );
      _controller!.addListener(_onTick);
      _controller!.addStatusListener(_onStatus);
    }

    if (oldWidget.currentQuestionIndex != widget.currentQuestionIndex) {
      _lastHapticSecond = -1;
      _controller!.duration = const Duration(seconds: 15);
      if (!widget.isAnswered) {
        _controller!.forward(from: 0.0);
      }
    } else if (widget.isAnswered && !oldWidget.isAnswered) {
      _controller!.stop();
    }
  }

  void _onTick() {
    if (_controller == null) return;
    final remainingFraction = 1.0 - _controller!.value;
    final remainingSec = (remainingFraction * 15).ceil().clamp(0, 15);

    if (remainingSec <= 5 &&
        remainingSec > 0 &&
        remainingSec != _lastHapticSecond) {
      _lastHapticSecond = remainingSec;
      if (di.sl.isRegistered<HapticService>()) {
        try {
          di.sl<HapticService>().selection();
        } catch (_) {}
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (di.sl.isRegistered<HapticService>()) {
        try {
          di.sl<HapticService>().error();
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _popTimer?.cancel();
    _controller?.removeListener(_onTick);
    _controller?.removeStatusListener(_onStatus);
    _controller?.dispose();
    super.dispose();
  }

  Color _getBarColor(double remainingFraction) {
    if (remainingFraction > 0.5) {
      return Color.lerp(
        AppColors.gameCorrect,
        AppColors.amber400,
        (1.0 - remainingFraction) * 2.0,
      )!;
    } else {
      return Color.lerp(
        AppColors.amber400,
        AppColors.red500,
        (0.5 - remainingFraction) * 2.0,
      )!;
    }
  }

  Widget _buildAnimatedTimerBadge(bool isDark) {
    return AnimatedBuilder(
      animation: _controller!,
      builder: (context, _) {
        final fraction = (1.0 - _controller!.value).clamp(0.0, 1.0);
        final secondsLeft = (fraction * 15).ceil().clamp(0, 15);
        final barColor = _getBarColor(fraction);
        final isUrgent = secondsLeft <= 5;

        return Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.ultraDeep : AppColors.slate100,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: barColor.withValues(alpha: isUrgent ? 0.6 : 0.3),
                  width: 1.w,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.clock, size: 11.5.sp, color: barColor),
                  SizedBox(width: 4.w),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${secondsLeft}s',
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w800,
                        color: barColor,
                      ),
                    ),
                  ),
                ],
              ),
            )
            .animate(target: isUrgent ? 1 : 0)
            .scale(
              begin: const Offset(1, 1),
              end: const Offset(1.08, 1.08),
              duration: 400.ms,
              curve: Curves.easeInOut,
            );
      },
    );
  }

  Widget _buildStaticTimerBadge(bool isDark) {
    final fraction = (widget.timeRemaining / 15.0).clamp(0.0, 1.0);
    final barColor = _getBarColor(fraction);
    final isUrgent = widget.timeRemaining <= 5;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.ultraDeep : AppColors.slate100,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: barColor.withValues(alpha: isUrgent ? 0.6 : 0.3),
          width: 1.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.clock, size: 11.5.sp, color: barColor),
          SizedBox(width: 4.w),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '${widget.timeRemaining}s',
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.5.sp,
                fontWeight: FontWeight.w800,
                color: barColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComboBadge(bool isDark) {
    return AnimatedScale(
      scale: _comboScale,
      duration: VowlMotion.fast,
      curve: Curves.easeOutBack,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.amber900.withValues(alpha: 0.4)
              : AppColors.amber100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: AppColors.amber500.withValues(alpha: 0.5),
            width: 1.w,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '🔥×${widget.comboStreak}',
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.amber400 : AppColors.amber600,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    // AI/Rival name and badge resolution
    final String displayRivalName;
    final String badgeLabel;

    if (widget.isAiRival) {
      displayRivalName = widget.rivalName.contains('(')
          ? widget.rivalName.split('(').first.trim()
          : widget.rivalName;
      if (widget.aiTierLabel != null && widget.aiTierLabel!.isNotEmpty) {
        final raw = widget.aiTierLabel!.toUpperCase();
        badgeLabel = raw == 'MEDIUM' ? 'MED' : raw;
      } else if (widget.rivalName.contains('(')) {
        final rawTier = widget.rivalName
            .split('(')
            .last
            .replaceAll(')', '')
            .trim()
            .toUpperCase();
        badgeLabel = rawTier == 'MEDIUM' ? 'MED' : rawTier;
      } else {
        badgeLabel = 'MED';
      }
    } else {
      displayRivalName = widget.rivalName;
      badgeLabel = 'LIVE';
    }

    return RepaintBoundary(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isDark ? AppColors.midnightSurface : AppColors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.slate800 : AppColors.slate200,
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: User - Timer/Combo - Rival
            Row(
              children: [
                // Current User Avatar
                UserAvatar(photoUrl: widget.myPhotoUrl, size: 40.r),
                SizedBox(width: 8.w),

                // Current User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.myName,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.white
                                : AppColors.slate900,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${widget.myScore} pts',
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 6.w),

                // Center Dynamic Timer Badge + Combo Streak
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_controller != null)
                      _buildAnimatedTimerBadge(isDark)
                    else
                      _buildStaticTimerBadge(isDark),
                    if (widget.comboStreak >= 2) ...[
                      SizedBox(width: 4.w),
                      _buildComboBadge(isDark),
                    ],
                  ],
                ),

                SizedBox(width: 6.w),

                // Rival Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          displayRivalName,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.white
                                : AppColors.slate900,
                          ),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 5.w,
                                vertical: 1.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isAiRival
                                    ? AppColors.cyan400.withValues(alpha: 0.15)
                                    : AppColors.emerald500.withValues(
                                        alpha: 0.15,
                                      ),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4.5.r,
                                    height: 4.5.r,
                                    decoration: BoxDecoration(
                                      color: widget.isAiRival
                                          ? AppColors.cyan400
                                          : AppColors.emerald500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    badgeLabel,
                                    softWrap: true,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: widget.isAiRival
                                          ? AppColors.cyan400
                                          : AppColors.emerald500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 5.w),
                            Text(
                              '${widget.rivalScore} pts',
                              softWrap: true,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.amber500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(width: 8.w),

                // Rival Avatar
                if (widget.isAiRival &&
                    (widget.rivalPhotoUrl == null ||
                        widget.rivalPhotoUrl!.isEmpty))
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.cyan400, AppColors.blue500],
                      ),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/vowly_head.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  UserAvatar(photoUrl: widget.rivalPhotoUrl, size: 40.r),
              ],
            ),

            SizedBox(height: 10.h),

            // Fluid 120fps countdown bar with single CustomPainter
            if (_controller != null)
              AnimatedBuilder(
                animation: _controller!,
                builder: (context, _) {
                  final progress = _controller!.value;
                  final remaining = (1.0 - progress).clamp(0.0, 1.0);
                  final barColor = _getBarColor(remaining);
                  final isUrgent = (remaining * 15.0) <= 5.0;

                  return SizedBox(
                        height: 5.h,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: _CountdownBarPainter(
                            progress: remaining,
                            barColor: barColor,
                            isDark: isDark,
                          ),
                        ),
                      )
                      .animate(target: isUrgent ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1, 1.35),
                        duration: 500.ms,
                        curve: Curves.easeInOut,
                      );
                },
              )
            else
              SizedBox(
                height: 5.h,
                width: double.infinity,
                child: CustomPaint(
                  painter: _CountdownBarPainter(
                    progress: (widget.timeRemaining / 15.0).clamp(0.0, 1.0),
                    barColor: _getBarColor(
                      (widget.timeRemaining / 15.0).clamp(0.0, 1.0),
                    ),
                    isDark: isDark,
                  ),
                ),
              ),

            SizedBox(height: 8.h),

            // Round progress dots
            _RoundProgressDots(
              currentQuestionIndex: widget.currentQuestionIndex,
              totalQuestions: widget.totalQuestions,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

/// High-performance 120fps painter for the countdown bar.
///
/// Draws rounded background track, subtle glow shadow, and rounded fill
/// in a single efficient paint call.
class _CountdownBarPainter extends CustomPainter {
  final double progress;
  final Color barColor;
  final bool isDark;

  const _CountdownBarPainter({
    required this.progress,
    required this.barColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final trackRadius = Radius.circular(size.height / 2);
    final trackRRect = RRect.fromRectAndRadius(Offset.zero & size, trackRadius);

    // 1. Rounded rect background track
    final trackPaint = Paint()
      ..color = isDark
          ? AppColors.white.withValues(alpha: 0.08)
          : AppColors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(trackRRect, trackPaint);

    final fillWidth = size.width * progress.clamp(0.0, 1.0);
    if (fillWidth <= 0) return;

    final fillRect = Rect.fromLTWH(0, 0, fillWidth, size.height);
    final fillRadius = Radius.circular(
      math.min(size.height / 2, fillWidth / 2),
    );
    final fillRRect = RRect.fromRectAndRadius(fillRect, fillRadius);

    // 2. Subtle glow shadow via Paint..maskFilter
    final glowPaint = Paint()
      ..color = barColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(fillRRect, glowPaint);

    // 3. Rounded rect fill on top
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [barColor, barColor.withValues(alpha: 0.85)],
      ).createShader(fillRect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(fillRRect, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _CountdownBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.barColor != barColor ||
        oldDelegate.isDark != isDark;
  }
}

enum _RoundDotState { completed, current, upcoming }

/// Indicator row showing progress through match rounds.
class _RoundProgressDots extends StatelessWidget {
  final int currentQuestionIndex;
  final int totalQuestions;
  final bool isDark;

  const _RoundProgressDots({
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final count = totalQuestions > 0 ? totalQuestions : 5;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final _RoundDotState dotState;
        if (index < currentQuestionIndex) {
          dotState = _RoundDotState.completed;
        } else if (index == currentQuestionIndex) {
          dotState = _RoundDotState.current;
        } else {
          dotState = _RoundDotState.upcoming;
        }

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 3.5.w),
          child: _RoundDot(state: dotState, isDark: isDark),
        );
      }),
    );
  }
}

class _RoundDot extends StatelessWidget {
  final _RoundDotState state;
  final bool isDark;

  const _RoundDot({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(7.r, 7.r),
      painter: _RoundDotPainter(state: state, isDark: isDark),
    );
  }
}

class _RoundDotPainter extends CustomPainter {
  final _RoundDotState state;
  final bool isDark;

  const _RoundDotPainter({required this.state, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeOffset = 0.5.w;
    final adjustedRadius = math.max(0.0, radius - strokeOffset);

    final activeColor = AppColors.indigo500;
    final inactiveBorderColor = isDark
        ? AppColors.slate700
        : AppColors.slate300;
    final inactiveFillColor = isDark ? AppColors.slate800 : AppColors.slate100;

    switch (state) {
      case _RoundDotState.completed:
        // Filled dot (●)
        final fillPaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, radius, fillPaint);
        break;

      case _RoundDotState.current:
        // Half dot (◐): Left half filled, right half empty/background with border
        final bgPaint = Paint()
          ..color = inactiveFillColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, adjustedRadius, bgPaint);

        final halfPaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.fill;
        final rect = Rect.fromCircle(center: center, radius: adjustedRadius);
        canvas.drawArc(rect, math.pi / 2, math.pi, true, halfPaint);

        final borderPaint = Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.w;
        canvas.drawCircle(center, adjustedRadius, borderPaint);
        break;

      case _RoundDotState.upcoming:
        // Empty dot (○)
        final bgPaint = Paint()
          ..color = inactiveFillColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(center, adjustedRadius, bgPaint);

        final borderPaint = Paint()
          ..color = inactiveBorderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.w;
        canvas.drawCircle(center, adjustedRadius, borderPaint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _RoundDotPainter oldDelegate) {
    return oldDelegate.state != state || oldDelegate.isDark != isDark;
  }
}
