import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SpeedVarianceTempoDial extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool isDragging;
  final double dialRotation;
  final int? selectedIndex;
  final Function(DragUpdateDetails, int) onDialRotate;
  final VoidCallback onDialRelease;
  final Function(int, int) onSubmitChoice;

  const SpeedVarianceTempoDial({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isDragging,
    required this.dialRotation,
    required this.selectedIndex,
    required this.onDialRotate,
    required this.onDialRelease,
    required this.onSubmitChoice,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildChromeDial(correctIndex, color, isDark),
        SizedBox(height: 24.h),
        Text(
          isDragging ? "MAINTAINING SPEED..." : "ROTATE DIAL OR TAP PREFERENCE",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.bold,
            color: color.withValues(alpha: 0.8),
            letterSpacing: 1,
          ),
        ),
        SizedBox(height: 24.h),
        _buildConnectedSpeechOrb(options[0], 0, correctIndex, color, isDark),
        SizedBox(height: 12.h),
        _buildConnectedSpeechOrb(
          options.length > 1 ? options[1] : '',
          1,
          correctIndex,
          color,
          isDark,
        ),
      ],
    );
  }

  Widget _buildChromeDial(int correct, Color color, bool isDark) {
    return Center(
      child: GestureDetector(
        onPanUpdate: (details) => onDialRotate(details, correct),
        onPanEnd: (_) => onDialRelease(),
        child: Transform.rotate(
          angle: dialRotation,
          child: Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  isDark ? Colors.black : Colors.grey.shade400,
                ],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(3, 3),
                ),
              ],
              border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
            ),
            child: Center(
              child: Container(
                width: 10.r,
                height: 45.r,
                margin: EdgeInsets.only(bottom: 45.r),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5.r),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 5,
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

  Widget _buildConnectedSpeechOrb(
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    if (text.isEmpty) return const SizedBox();

    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;

    Color orbColor = color.withValues(alpha: 0.1);
    Color textColor = color;
    Color descColor = isDark ? Colors.white70 : Colors.black87;

    if (isAnswered && isSelected) {
      orbColor = correct
          ? Colors.greenAccent.withValues(alpha: 0.2)
          : Colors.redAccent.withValues(alpha: 0.2);
      textColor = correct ? Colors.greenAccent : Colors.redAccent;
      descColor = textColor.withValues(alpha: 0.9);
    } else if (isSelected) {
      orbColor = color;
      textColor = Colors.white;
      descColor = Colors.white.withValues(alpha: 0.9);
    }

    String title = text;
    String description = '';
    final int parenIndex = text.indexOf(' (');
    if (parenIndex != -1) {
      title = text.substring(0, parenIndex);
      description = text.substring(
        parenIndex + 2,
        text.length - (text.endsWith(')') ? 1 : 0),
      );
    }

    return ScaleButton(
      onTap: () => onSubmitChoice(index, correctIndex),
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                alignment: Alignment.center,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: orbColor,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isAnswered && isSelected
                        ? textColor
                        : color.withValues(alpha: isSelected ? 1.0 : 0.3),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? (correct
                                ? Colors.greenAccent.withValues(alpha: 0.3)
                                : color.withValues(alpha: 0.3))
                          : Colors.transparent,
                      blurRadius: 15,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    if (index == 0) ...[
                      Icon(Icons.rotate_left, color: textColor, size: 28.r),
                      SizedBox(width: 16.w),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: index == 0
                            ? CrossAxisAlignment.start
                            : CrossAxisAlignment.end,
                        children: [
                          Text(
                            title,
                            textAlign: index == 0
                                ? TextAlign.left
                                : TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            SizedBox(height: 6.h),
                            Text(
                              description,
                              textAlign: index == 0
                                  ? TextAlign.left
                                  : TextAlign.right,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: descColor,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (index == 1) ...[
                      SizedBox(width: 16.w),
                      Icon(Icons.rotate_right, color: textColor, size: 28.r),
                    ],
                  ],
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: (2 + index).seconds,
              ),
    );
  }
}
