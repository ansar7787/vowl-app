import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ConsonantClarityTactileGrid extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onSubmitChoice;

  const ConsonantClarityTactileGrid({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onSubmitChoice,
  });

  @override
  Widget build(BuildContext context) {
    // If only 2 options, we can put them in a row. If more, wrap them.
    final bool useRow = options.length <= 2;

    return Center(
      child: useRow
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKeycap(options[0], 0),
                SizedBox(width: 40.w),
                _buildKeycap(options[1], 1),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 24.w,
              runSpacing: 24.h,
              children: List.generate(
                  options.length, (index) => _buildKeycap(options[index], index)),
            ),
    );
  }

  Widget _buildKeycap(String text, int index) {
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    // Default neutral styling for glassmorphic keycap
    Color capColor = isDark
        ? const Color(0xFF1E293B).withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.9);
    Color borderColor = color.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white70 : Colors.black87;


    // Styling when selected / locked in
    if (showResult) {
      capColor = isCorrect
          ? const Color(0xFF10B981).withValues(alpha: 0.2)
          : const Color(0xFFE11D48).withValues(alpha: 0.2);
      borderColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFE11D48);
      textColor = isCorrect ? const Color(0xFF10B981) : const Color(0xFFE11D48);
    } else if (isSelected) {
      capColor = color.withValues(alpha: 0.2);
      borderColor = color;
      textColor = color;
    }

    return ScaleButton(
      onTap: () {
        if (!isAnswered) onSubmitChoice(index, correctIndex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: 100.r,
        height: 100.r,
        margin: EdgeInsets.only(top: isSelected ? 6.r : 0.r), // Physical push down effect
        decoration: BoxDecoration(
          color: capColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: borderColor, width: isSelected ? 3.0 : 1.5),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black12,
                offset: const Offset(0, 8),
                blurRadius: 10,
              ),
            if (showResult)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              )
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 32.sp,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideY(begin: 0.2);
  }
}
