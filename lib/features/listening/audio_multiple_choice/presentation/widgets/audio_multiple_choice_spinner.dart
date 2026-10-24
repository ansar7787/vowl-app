import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'audio_multiple_choice_satellite.dart';

/// Rotatable orbital spinner arranging satellite options around a central listen speaker hub.
class AudioMultipleChoiceSpinner extends StatelessWidget {
  /// List of option labels positioned along the orbital guide ring.
  final List<String> options;

  /// Index of the correct option.
  final int correct;

  /// Theme accent color.
  final Color color;

  /// Optional celebratory emoji shown upon correct answer.
  final String? emoji;

  /// Current rotational offset in radians.
  final double rotation;

  /// Currently selected option index, if any.
  final int? selectedIndex;

  /// Whether the question has been answered.
  final bool isAnswered;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Callback receiving delta panning updates to spin the orbit ring.
  final Function(double) onSpin;

  /// Callback receiving the selected satellite index.
  final Function(int) onSelectSatellite;

  /// Callback triggered when the central core audio replay button is tapped.
  final VoidCallback onTapCore;

  /// Creates an [AudioMultipleChoiceSpinner] widget.
  const AudioMultipleChoiceSpinner({
    super.key,
    required this.options,
    required this.correct,
    required this.color,
    this.emoji,
    required this.rotation,
    required this.selectedIndex,
    required this.isAnswered,
    required this.isCorrectState,
    required this.onSpin,
    required this.onSelectSatellite,
    required this.onTapCore,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return GestureDetector(
      onPanUpdate: (details) => onSpin(details.delta.dx),
      child: Container(
        key: const Key('audio_multiple_choice_spinner'),
        width: double.infinity,
        color: Colors.transparent, // Ensures the entire area is draggable
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbital Guide Ring
            Container(
              width: 230.r,
              height: 230.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
            ),

            // Satellite Options
            ...List.generate(options.length, (index) {
              final double angle =
                  (index * (2 * math.pi / options.length)) + rotation;
              final double radius = 115.r;
              return Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(
                    radius * math.cos(angle),
                    radius * math.sin(angle),
                  ),
                  child: AudioMultipleChoiceSatellite(
                    index: index,
                    text: options[index],
                    correct: correct,
                    color: color,
                    selectedIndex: selectedIndex,
                    isAnswered: isAnswered,
                    isCorrectState: isCorrectState,
                    onTap: () => onSelectSatellite(index),
                  ),
                ),
              );
            }),

            // Central Core (Listen Button)
            ScaleButton(
              key: const Key('satellite_core_btn'),
              onTap: onTapCore,
              child: Container(
                width: 78.r,
                height: 78.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrectState == true ? tokens.gameCorrect : color,
                  border: Border.all(
                    color: Colors.white,
                    width: 3.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isCorrectState == true
                              ? tokens.gameCorrect
                              : color)
                          .withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: isCorrectState == true && emoji != null
                    ? (reduceMotion
                        ? Center(
                            child:
                                Text(emoji!, style: TextStyle(fontSize: 34.r)),
                          )
                        : Center(
                            child:
                                Text(emoji!, style: TextStyle(fontSize: 34.r)),
                          ).animate().scale(
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          ))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 28.r,
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(
                                "Listen",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
