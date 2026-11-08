import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/user_avatar.dart';
import 'package:vowl/core/theme/app_colors.dart';
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
  });

  @override
  State<ArenaScoreHud> createState() => _ArenaScoreHudState();
}

class _ArenaScoreHudState extends State<ArenaScoreHud>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  int _lastHapticSecond = -1;

  static const Color _greenColor = Color(0xFF22C55E);

  @override
  void initState() {
    super.initState();
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

    if (remainingSec <= 5 && remainingSec > 0 && remainingSec != _lastHapticSecond) {
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
    _controller?.removeListener(_onTick);
    _controller?.removeStatusListener(_onStatus);
    _controller?.dispose();
    super.dispose();
  }

  Color _getBarColor(double remainingFraction) {
    if (remainingFraction > 0.5) {
      return Color.lerp(
        _greenColor,
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
          color: isDark ? AppColors.midnightSurface : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
            width: 1.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Row: User - Timer - Rival
            Row(
              children: [
                // Current User Avatar
                UserAvatar(photoUrl: widget.myPhotoUrl, size: 36.r),
                SizedBox(width: 8.w),

                // Current User Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.myName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '${widget.myScore} pts',
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

                // Center Dynamic Timer Badge (Animated via controller or fallback to timeRemaining)
                if (_controller != null)
                  AnimatedBuilder(
                    animation: _controller!,
                    builder: (context, _) {
                      final fraction = (1.0 - _controller!.value).clamp(0.0, 1.0);
                      final secondsLeft = (fraction * 15).ceil().clamp(0, 15);
                      final barColor = _getBarColor(fraction);
                      final isUrgent = secondsLeft <= 5;

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: barColor.withValues(alpha: isUrgent ? 0.6 : 0.3),
                            width: 1.w,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.clock,
                              size: 11.5.sp,
                              color: barColor,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '${secondsLeft}s',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w800,
                                color: barColor,
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
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF070A12) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(LucideIcons.clock, size: 11.5.sp, color: AppColors.indigo500),
                        SizedBox(width: 4.w),
                        Text(
                          '${widget.timeRemaining}s',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                          ),
                        ),
                      ],
                    ),
                  ),

                SizedBox(width: 6.w),

                // Rival Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        displayRivalName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.5.h),
                              decoration: BoxDecoration(
                                color: widget.isAiRival
                                    ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                                    : AppColors.emerald500.withValues(alpha: 0.15),
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
                                          ? const Color(0xFF06B6D4)
                                          : AppColors.emerald500,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    badgeLabel,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 8.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: widget.isAiRival
                                          ? const Color(0xFF06B6D4)
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
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFF59E0B),
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
                if (widget.isAiRival && (widget.rivalPhotoUrl == null || widget.rivalPhotoUrl!.isEmpty))
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                      ),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/vowly_head.webp',
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  UserAvatar(photoUrl: widget.rivalPhotoUrl, size: 36.r),
              ],
            ),

            SizedBox(height: 10.h),

            // Fluid 60fps countdown bar with SpeedChallengeTimer mechanics
            if (_controller != null)
              AnimatedBuilder(
                animation: _controller!,
                builder: (context, _) {
                  final progress = _controller!.value;
                  final remaining = (1.0 - progress).clamp(0.0, 1.0);
                  final barColor = _getBarColor(remaining);
                  final isUrgent = (remaining * 15.0) <= 5.0;

                  return Container(
                    height: 5.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(3.r),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: remaining,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [barColor, barColor.withValues(alpha: 0.75)],
                          ),
                          borderRadius: BorderRadius.circular(3.r),
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.45),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(3.r),
                child: LinearProgressIndicator(
                  value: (widget.timeRemaining / 15.0).clamp(0.0, 1.0),
                  minHeight: 5.h,
                  backgroundColor: isDark ? AppColors.slate800 : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.timeRemaining <= 4
                        ? AppColors.rose500
                        : (widget.timeRemaining <= 7 ? const Color(0xFFF59E0B) : AppColors.indigo500),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

