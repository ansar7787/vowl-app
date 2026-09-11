import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'audio_multiple_choice_satellite.dart';

class AudioMultipleChoiceSpinner extends StatelessWidget {
  final List<String> options;
  final int correct;
  final Color color;
  final String? emoji;
  final double rotation;
  final int? selectedIndex;
  final bool isAnswered;
  final bool? isCorrectState;
  final Function(double) onSpin;
  final Function(int) onSelectSatellite;
  final VoidCallback onTapCore;

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
    return GestureDetector(
      onPanUpdate: (details) => onSpin(details.delta.dx),
      child: Container(
        width: double.infinity,
        color: Colors.transparent, // Ensures the entire area is draggable
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Orbital Ring
            Container(
              width: 230.r,
              height: 230.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
            ),

            // Satellite Options
            ...List.generate(options.length, (index) {
              double angle =
                  (index * (2 * 3.14159 / options.length)) + rotation;
              double radius = 115.r;
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
              onTap: onTapCore,
              child: Container(
                width: 80.r,
                height: 80.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrectState == true ? Colors.greenAccent : color,
                  border: Border.all(
                    color: isCorrectState == true
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.5),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCorrectState == true
                          ? Colors.greenAccent.withValues(alpha: 0.6)
                          : color.withValues(alpha: 0.6),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: isCorrectState == true && emoji != null
                    ? Center(
                        child: Text(emoji!, style: TextStyle(fontSize: 36.r)),
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.graphic_eq_rounded,
                            color: isCorrectState == true
                                ? Colors.black87
                                : Colors.white,
                            size: 30.r,
                          ),
                          SizedBox(height: 2.h),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Text(
                                "LISTEN",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w900,
                                  color: isCorrectState == true
                                      ? Colors.black87
                                      : Colors.white,
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
