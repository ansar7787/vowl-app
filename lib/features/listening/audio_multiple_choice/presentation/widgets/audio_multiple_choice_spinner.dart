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
              width: 220.r,
              height: 220.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.1),
                  width: 2,
                ),
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
                  color: isCorrectState == true
                      ? Colors.greenAccent
                      : (Theme.of(context).brightness == Brightness.dark
                            ? color.withValues(alpha: 0.2)
                            : Colors.white),
                  border: Border.all(
                    color: isCorrectState == true ? Colors.greenAccent : color,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isCorrectState == true
                          ? Colors.greenAccent.withValues(alpha: 0.4)
                          : color.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: isCorrectState == true && emoji != null
                    ? Center(
                        child: Text(emoji!, style: TextStyle(fontSize: 50.r)),
                      ).animate().scale(
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      )
                    : Icon(
                        Icons.graphic_eq_rounded,
                        color: isCorrectState == true ? Colors.black87 : color,
                        size: 50.r,
                      ),
              ),
            ),

            // Satellite Options
            ...List.generate(options.length, (index) {
              double angle =
                  (index * (2 * 3.14159 / options.length)) + rotation;
              double radius = 110.r;
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
          ],
        ),
      ),
    );
  }
}
