import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Tactile keycap grid for selecting among candidate consonant phonemes.
class ConsonantClarityTactileGrid extends StatelessWidget {
  /// Available consonant phoneme or word options.
  final List<String> options;

  /// Index of the correct option.
  final int correctIndex;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Currently selected option index, or `null`.
  final int? selectedIndex;

  /// Callback executed when the learner selects a keycap.
  final Function(int, int) onSubmitChoice;

  /// Creates a [ConsonantClarityTactileGrid] widget.
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
    // If 2 or fewer options, arrange in a balanced row; otherwise wrap
    final bool useRow = options.length <= 2;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Center(
      child: useRow
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildKeycap(options[0], 0, reduceMotion),
                SizedBox(width: 24.w),
                _buildKeycap(options[1], 1, reduceMotion),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.center,
              spacing: 20.w,
              runSpacing: 20.h,
              children: List.generate(
                options.length,
                (index) => _buildKeycap(options[index], index, reduceMotion),
              ),
            ),
    );
  }

  Widget _buildKeycap(String text, int index, bool reduceMotion) {
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = index == correctIndex;
    final bool showResult = isAnswered && isSelected;

    // Default neutral styling for glassmorphic keycap
    Color capColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.85)
        : Colors.white.withValues(alpha: 0.95);
    Color borderColor = color.withValues(alpha: 0.25);
    Color textColor = isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.slate900;

    // Styling when selected / locked in
    if (showResult) {
      capColor = isCorrect
          ? AppColors.emerald500.withValues(alpha: 0.2)
          : AppColors.rose700.withValues(alpha: 0.2);
      borderColor = isCorrect ? AppColors.emerald500 : AppColors.rose700;
      textColor = isCorrect ? AppColors.emerald500 : AppColors.rose700;
    } else if (isSelected) {
      capColor = color.withValues(alpha: 0.18);
      borderColor = color;
      textColor = color;
    }

    Widget keycap = ScaleButton(
      key: ValueKey('tactile_keycap_$index'),
      onTap: () {
        if (!isAnswered) onSubmitChoice(index, correctIndex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        width: 92.r,
        height: 92.r,
        margin: EdgeInsets.only(
          top: isSelected ? 4.r : 0.r,
        ), // Tactile press displacement
        decoration: BoxDecoration(
          color: capColor,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: isDark ? Colors.black45 : Colors.black12,
                offset: const Offset(0, 6),
                blurRadius: 8,
              ),
            if (showResult)
              BoxShadow(
                color: borderColor.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!reduceMotion) {
      keycap = keycap
          .animate()
          .fadeIn(delay: (50 * index).ms)
          .slideY(begin: 0.2);
    }

    return keycap;
  }
}
