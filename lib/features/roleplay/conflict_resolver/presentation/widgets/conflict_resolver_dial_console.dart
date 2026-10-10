import 'package:vowl/core/theme/app_color_tokens.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_equalizer_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
  static const Color color2a2a3e = Color(0xFF2A2A3E);
  static const Color color131326 = Color(0xFF131326);
}

class ConflictResolverDialConsole extends StatelessWidget {
  final Color color;
  final bool isDark;
  final double rotation;
  final Animation<double> waveAnimation;
  final Function(DragUpdateDetails, Offset) onDialDragged;
  final VoidCallback? onStepLeft;
  final VoidCallback? onStepRight;
  final String? focusedText;
  final bool isAnswered;
  final bool? isCorrect;
  final bool isFirstStagePassed;

  const ConflictResolverDialConsole({
    super.key,
    required this.color,
    required this.isDark,
    required this.rotation,
    required this.waveAnimation,
    required this.onDialDragged,
    this.onStepLeft,
    this.onStepRight,
    this.focusedText,
    this.isAnswered = false,
    this.isCorrect,
    this.isFirstStagePassed = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final double dialDiameter = 180.r;
    final Offset dialCenter = Offset(dialDiameter / 2, dialDiameter / 2);

    // Only show correct/incorrect colors AFTER submission
    // If they passed phase 1, their dial selection was correct, so color it green regardless of phase 2.
    final bool showCorrect =
        (isAnswered && isCorrect == true) || isFirstStagePassed;
    final bool showIncorrect =
        isAnswered && isCorrect == false && !isFirstStagePassed;

    Color currentColor = color;
    if (showCorrect) currentColor = tokens.gameCorrect;
    if (showIncorrect) currentColor = tokens.gameIncorrect;

    final bool isSignalTuned = focusedText != null;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: isDark
            ? _LocalPalette.color07070f
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        children: [
          // Holographic Dial Board
          GestureDetector(
            onPanUpdate: (details) => onDialDragged(details, dialCenter),
            child: Container(
              width: dialDiameter,
              height: dialDiameter,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Spinning audio spectrum equalizer lines
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: EqualizerArcPainter(
                            rotationValue: rotation,
                            timeAnimation: waveAnimation.value,
                            themeColor: currentColor,
                          ),
                        );
                      },
                    ),
                  ),

                  // Metallic rotatable core knob
                  Transform.rotate(
                    angle: rotation * 2 * math.pi,
                    child: Container(
                      width: 110.r,
                      height: 110.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isDark
                              ? [
                                  _LocalPalette.color2a2a3e,
                                  _LocalPalette.color131326,
                                ]
                              : [Colors.white, Colors.grey.shade300],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(3, 3),
                          ),
                        ],
                        border: Border.all(
                          color: isSignalTuned
                              ? currentColor
                              : currentColor.withValues(alpha: 0.3),
                          width: isSignalTuned ? 3 : 1.5,
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotary position notch marker
                          Positioned(
                            top: 8.r,
                            child: Container(
                              width: 6.r,
                              height: 16.r,
                              decoration: BoxDecoration(
                                color: isSignalTuned
                                    ? currentColor
                                    : currentColor.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(3.r),
                              ),
                            ),
                          ),
                          Icon(
                            showCorrect
                                ? Icons.check_rounded
                                : (showIncorrect
                                      ? Icons.close_rounded
                                      : Icons.sensors_rounded),
                            color: isSignalTuned
                                ? currentColor
                                : currentColor.withValues(alpha: 0.5),
                            size: 28.r,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // D-Pad Controls for Accessibility
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: onStepLeft,
                icon: Icon(
                  Icons.arrow_left_rounded,
                  size: 36.r,
                  color: currentColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: currentColor.withValues(alpha: 0.1),
                  padding: EdgeInsets.all(4.r),
                ),
              ),
              SizedBox(width: 32.w),
              IconButton(
                onPressed: onStepRight,
                icon: Icon(
                  Icons.arrow_right_rounded,
                  size: 36.r,
                  color: currentColor,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: currentColor.withValues(alpha: 0.1),
                  padding: EdgeInsets.all(4.r),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Calibration level metrics / Text Options
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: focusedText == null
                ? Container(
                    key: const ValueKey("static"),
                    constraints: BoxConstraints(minHeight: 80.h),
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.blur_on_rounded,
                          color: Colors.grey.withValues(alpha: 0.5),
                          size: 24.r,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          "TUNING... STATIC NOISE",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: Colors.grey,
                            letterSpacing: 2.0,
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    key: ValueKey(focusedText),
                    constraints: BoxConstraints(minHeight: 80.h),
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: currentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: currentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "PROPOSED RESPONSE:",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            color: currentColor,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          focusedText!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            height: 1.3,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
