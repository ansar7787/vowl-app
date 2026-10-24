import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/scratch_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
  static const Color color1e1e38 = Color(0xFF1E1E38);
  static const Color color111124 = Color(0xFF111124);
}

/// Interactive scratch-card panel concealing an idiom until revealed by gesture or tap.
class DailyExpressionScratchPanel extends StatelessWidget {
  /// Active speaking quest entity containing expression and meaning.
  final SpeakingQuest quest;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Notifier tracking scratch reveal completion fraction (0.0 to 1.0).
  final ValueNotifier<double> scratchProgressNotifier;

  /// Shimmer animation timeline notifier.
  final ValueNotifier<double> timeValNotifier;

  /// Whether complex gesture animations are disabled for accessibility.
  final bool reduceComplexGestures;

  /// Callback executed to play pronunciation TTS audio.
  final VoidCallback onPlayTts;

  /// Callback invoked when scratch reveal fraction updates.
  final ValueChanged<double> onScratchUpdate;

  /// Creates a [DailyExpressionScratchPanel].
  const DailyExpressionScratchPanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.scratchProgressNotifier,
    required this.timeValNotifier,
    this.reduceComplexGestures = false,
    required this.onPlayTts,
    required this.onScratchUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    return Semantics(
      label: scratchProgressNotifier.value >= 1.0
          ? 'Daily expression: ${quest.expression ?? "Bite the bullet"}. Meaning: ${quest.meaning ?? ""}'
          : 'Hidden daily idiom. Swipe or tap to reveal idiom.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28.r),
        child: Container(
          key: const Key('daily_expression_scratch_panel'),
          width: 1.sw,
          constraints: BoxConstraints(minHeight: 190.h),
          decoration: BoxDecoration(
            color: isDark ? _LocalPalette.color131326 : Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black38
                    : Colors.black.withValues(alpha: 0.06),
                blurRadius: 16.r,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ValueListenableBuilder<double>(
            valueListenable: scratchProgressNotifier,
            builder: (context, scratchProgress, child) {
              return Stack(
                children: [
                  // Underlying Revealed Golden Card (Sets the height of the stack)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                _LocalPalette.color1e1e38,
                                _LocalPalette.color111124,
                              ]
                            : [primaryColor.withValues(alpha: 0.2), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Daily Idiom",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Semantics(
                              label: 'Listen to expression pronunciation',
                              button: true,
                              child: ScaleButton(
                                key: const Key('daily_expression_tts_button'),
                                onTap: onPlayTts,
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  color: primaryColor,
                                  size: 20.r,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        if (scratchProgress == 1.0)
                          () {
                            final speakBadge = Container(
                              key: const Key('daily_expression_speak_badge'),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 5.h,
                              ),
                              margin: EdgeInsets.only(bottom: 8.h),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  reduceMotion
                                      ? Icon(
                                          Icons.mic_rounded,
                                          size: 14.r,
                                          color: primaryColor,
                                        )
                                      : Icon(
                                          Icons.mic_rounded,
                                          size: 14.r,
                                          color: primaryColor,
                                        )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .scale(
                                            begin: const Offset(1, 1),
                                            end: const Offset(1.15, 1.15),
                                          ),
                                  SizedBox(width: 6.w),
                                  Text(
                                    "Speak this",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            );
                            return reduceMotion
                                ? speakBadge
                                : speakBadge
                                    .animate()
                                    .fadeIn()
                                    .slideY(begin: 0.5);
                          }(),
                        Text(
                          quest.expression ?? "Bite the bullet",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                            height: 1.25,
                            shadows: [
                              Shadow(
                                color: primaryColor.withValues(alpha: 0.25),
                                blurRadius: 8.r,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),
                        AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            quest.meaning ?? "Meaning",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                      ],
                    ),
                  ),

                  // Scratch Foil Overlay
                  if (scratchProgress < 1.0)
                    Positioned.fill(
                      child: GestureDetector(
                        key: const Key('daily_expression_scratch_foil'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onScratchUpdate(1.0),
                        onPanUpdate: reduceComplexGestures
                            ? null
                            : (details) {
                                final double dx = details.delta.dx;
                                final double dy = details.delta.dy;
                                final double dist =
                                    (dx.abs() + dy.abs()) / 300.0;
                                onScratchUpdate(dist);
                              },
                        child: ValueListenableBuilder<double>(
                          valueListenable: timeValNotifier,
                          builder: (context, timeVal, _) {
                            return CustomPaint(
                              painter: ScratchPainter(
                                progress: scratchProgress,
                                time: timeVal,
                                primaryColor: primaryColor,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Scratch Instructions Overlay
                  if (scratchProgress == 0.0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          key: const Key('daily_expression_scratch_hint'),
                          color: Colors.black.withValues(alpha: 0.1),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                reduceMotion
                                    ? Icon(
                                        reduceComplexGestures
                                            ? Icons.touch_app_rounded
                                            : Icons.swipe_rounded,
                                        color: Colors.white,
                                        size: 30.r,
                                      )
                                    : Icon(
                                        reduceComplexGestures
                                            ? Icons.touch_app_rounded
                                            : Icons.swipe_rounded,
                                        color: Colors.white,
                                        size: 30.r,
                                      )
                                        .animate(onPlay: (c) => c.repeat())
                                        .shake(
                                          hz: 2,
                                          curve: Curves.easeInOut,
                                        )
                                        .then()
                                        .fadeOut(),
                                SizedBox(height: 8.h),
                                Text(
                                  reduceComplexGestures
                                      ? "Tap to reveal idiom"
                                      : "Swipe to reveal idiom",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
