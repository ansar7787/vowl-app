import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class PitchModulationDialControl extends StatelessWidget {
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

  const PitchModulationDialControl({
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 1,
          child: _buildVerticalFader(correctIndex, color, isDark),
        ),
        SizedBox(width: 20.w),
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildOptionCard(options[1], 1, correctIndex, color, isDark),
              SizedBox(height: 32.h),
              _buildOptionCard(options[0], 0, correctIndex, color, isDark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalFader(int correct, Color color, bool isDark) {
    return GestureDetector(
      onPanUpdate: (details) => onDialRotate(details, correct),
      onPanEnd: (_) => onDialRelease(),
      child: Container(
        height: 180.h,
        width: 60.w,
        decoration: BoxDecoration(
          color: isDark ? Colors.black45 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center track line
            Container(
              width: 4.w,
              height: 150.h,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),

            // Fader thumb
            TweenAnimationBuilder<double>(
              duration: isDragging
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              // dialRotation: -1.0 is bottom (Option 0), +1.0 is top (Option 1).
              // Alignment.y goes from -1.0 (top) to +1.0 (bottom).
              // Therefore, we negate dialRotation for Alignment.y.
              tween: Tween<double>(begin: -dialRotation, end: -dialRotation),
              builder: (context, rotation, child) {
                return Align(
                  alignment: Alignment(0, rotation),
                  child: Container(
                    width: 48.r,
                    height: 48.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          isDark ? Colors.grey.shade700 : Colors.white,
                          isDark ? Colors.grey.shade900 : Colors.grey.shade300,
                        ],
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: color.withValues(alpha: isDragging ? 0.8 : 0.4),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: color,
                        size: 24.r,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;

    Color cardColor = color.withValues(alpha: 0.05);
    Color borderColor = color.withValues(alpha: 0.2);
    Color textColor = color;

    if (isAnswered && isSelected) {
      cardColor = correct
          ? Colors.greenAccent.withValues(alpha: 0.1)
          : Colors.redAccent.withValues(alpha: 0.1);
      borderColor = correct ? Colors.greenAccent : Colors.redAccent;
      textColor = correct ? Colors.greenAccent : Colors.redAccent;
    } else if (isSelected) {
      cardColor = color.withValues(alpha: 0.2);
      borderColor = color;
      textColor = isDark ? Colors.white : color;
    }

    String mainText = text;
    String subText = "";
    if (text.contains(" (") && text.endsWith(")")) {
      final parts = text.split(" (");
      mainText = parts[0];
      subText = parts[1].substring(0, parts[1].length - 1);
    }

    return ScaleButton(
      onTap: () => onSubmitChoice(index, correctIndex),
      child:
          AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected ? 3 : 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainText,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        letterSpacing: 1,
                      ),
                    ),
                    if (subText.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              )
              .animate(target: isSelected ? 1 : 0)
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.02, 1.02),
                duration: 150.ms,
              ),
    );
  }
}
