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
  final String tts;
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
    required this.tts,
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
              width: 300.r,
              height: 300.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.1), width: 2),
              ),
            ),
            
            // Central Core
            ScaleButton(
              onTap: onTapCore,
              child: Container(
                width: 100.r,
                height: 100.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 20,
                    )
                  ],
                ),
                child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 50.r),
              ),
            ),
            
            // Satellite Options
            ...List.generate(options.length, (index) {
              double angle = (index * (2 * 3.14159 / options.length)) + rotation;
              double radius = 130.r;
              return Align(
                alignment: Alignment.center,
                child: Transform.translate(
                  offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
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
            
            // Target Zone
            Positioned(
              top: 40.h,
              child: Container(
                width: 40.w,
                height: 10.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 1.seconds),
            ),
          ],
        ),
      ),
    );
  }
}
