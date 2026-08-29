import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// A countdown timer bar for speed-challenge game modes.
///
/// Displays a thin animated gradient bar that depletes left-to-right.
/// Changes color green → yellow → red in the final 25%.
/// Pulses in the last 5 seconds. Awards bonus coins if user answers in time.
///
/// Usage:
/// ```dart
/// SpeedChallengeTimer(
///   durationSeconds: 30,
///   primaryColor: theme.primaryColor,
///   onTimeUp: () => _handleTimeExpired(),
///   onTick: (remaining) => setState(() => _remaining = remaining),
/// )
/// ```
class SpeedChallengeTimer extends StatefulWidget {
  /// Total countdown duration in seconds.
  final int durationSeconds;

  /// Theme accent colour.
  final Color primaryColor;

  /// Fires when the timer reaches zero.
  final VoidCallback onTimeUp;

  /// Optional callback on each second tick with remaining seconds.
  final ValueChanged<int>? onTick;

  /// Bonus coins label shown. Set to 0 to hide.
  final int bonusCoinsForSpeed;

  /// Whether to show the "+X Coins" bonus label.
  final bool showBonusLabel;

  /// Whether to auto-start the timer on mount. Default true.
  final bool autoStart;

  const SpeedChallengeTimer({
    super.key,
    this.durationSeconds = 30,
    required this.primaryColor,
    required this.onTimeUp,
    this.onTick,
    this.bonusCoinsForSpeed = 10,
    this.showBonusLabel = true,
    this.autoStart = true,
  });

  @override
  State<SpeedChallengeTimer> createState() => SpeedChallengeTimerState();
}

class SpeedChallengeTimerState extends State<SpeedChallengeTimer>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();

  late final AnimationController _controller;
  bool _isExpired = false;
  int _lastTickSecond = -1;

  late final ValueNotifier<int> _remainingSecondsNotifier;

  @override
  void initState() {
    super.initState();
    _remainingSecondsNotifier = ValueNotifier(widget.durationSeconds);
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.durationSeconds),
    );

    _controller.addListener(_onTick);
    _controller.addStatusListener(_onStatus);

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
    _remainingSecondsNotifier.dispose();
    super.dispose();
  }

  void _onTick() {
    final remaining = ((1.0 - _controller.value) * widget.durationSeconds).ceil();
    if (remaining != _lastTickSecond) {
      _lastTickSecond = remaining;
      _remainingSecondsNotifier.value = remaining;
      widget.onTick?.call(remaining);

      // Haptic pulse in last 5 seconds
      if (remaining <= 5 && remaining > 0) {
        _hapticService.selection();
      }
    }
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_isExpired) {
      _isExpired = true;
      _hapticService.error();
      widget.onTimeUp();
    }
  }

  /// Returns the remaining time in seconds.
  int get remainingSeconds =>
      ((1.0 - _controller.value) * widget.durationSeconds).ceil();

  /// Returns the fraction of time remaining (1.0 = full, 0.0 = expired).
  double get remainingFraction => 1.0 - _controller.value;

  /// Whether the user beat the timer (answered before expiry).
  bool get isTimerActive => _controller.isAnimating && !_isExpired;

  /// Pause the timer (e.g. when showing a dialog).
  void pause() => _controller.stop();

  /// Resume the timer.
  void resume() {
    if (!_isExpired) _controller.forward();
  }

  /// Start (or restart) the timer.
  void start() {
    _isExpired = false;
    _lastTickSecond = -1;
    _remainingSecondsNotifier.value = widget.durationSeconds;
    _controller.forward(from: 0.0);
  }

  /// Stop the timer and mark as completed (user answered in time).
  void stop() {
    _controller.stop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer bar (Rendered at 60fps for smooth width/color interpolation)
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final progress = _controller.value; // 0.0 → 1.0 (depleting)
            final remaining = 1.0 - progress;

            // Color transitions: green → yellow → red
            Color barColor;
            if (remaining > 0.5) {
              barColor = Color.lerp(
                const Color(0xFF22C55E), // green
                const Color(0xFFFBBF24), // yellow
                (1.0 - remaining) * 2.0, // 0→1 over top half
              )!;
            } else {
              barColor = Color.lerp(
                const Color(0xFFFBBF24), // yellow
                const Color(0xFFEF4444), // red
                (0.5 - remaining) * 2.0, // 0→1 over bottom half
              )!;
            }

            final isUrgent = remaining <= 0.166; // ~5 seconds on 30s timer

            return Container(
              height: 6.h,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(3.r),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: remaining.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        barColor,
                        barColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3.r),
                    boxShadow: [
                      BoxShadow(
                        color: barColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                ),
              ),
            ).animate(target: isUrgent ? 1 : 0).scale(
              begin: const Offset(1, 1),
              end: const Offset(1, 1.4),
              duration: 500.ms,
              curve: Curves.easeInOut,
            );
          },
        ),

        SizedBox(height: 6.h),

        // Time label + bonus indicator (Rendered at 1fps to save CPU overhead)
        ValueListenableBuilder<int>(
          valueListenable: _remainingSecondsNotifier,
          builder: (context, remainingSec, _) {
            final remainingFraction = remainingSec / widget.durationSeconds;
            
            Color barColor;
            if (remainingFraction > 0.5) {
              barColor = Color.lerp(
                const Color(0xFF22C55E),
                const Color(0xFFFBBF24),
                (1.0 - remainingFraction) * 2.0,
              )!;
            } else {
              barColor = Color.lerp(
                const Color(0xFFFBBF24),
                const Color(0xFFEF4444),
                (0.5 - remainingFraction) * 2.0,
              )!;
            }

            final isUrgent = remainingSec <= 5;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remaining time
                AutoSizeText(
                  '${remainingSec}s',
                  maxLines: 1,
                  minFontSize: 6,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: barColor,
                    letterSpacing: 1,
                  ),
                )
                .animate(target: isUrgent ? 1 : 0)
                .fade(begin: 1.0, end: 0.4, duration: 400.ms)
                .then()
                .fade(begin: 0.4, end: 1.0, duration: 400.ms),

                // Speed bonus indicator
                if (widget.showBonusLabel && widget.bonusCoinsForSpeed > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: AutoSizeText(
                      '⚡ +${widget.bonusCoinsForSpeed} Speed Bonus',
                      maxLines: 1,
                      minFontSize: 6,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            );
          }
        ),
      ],
    );
  }
}
