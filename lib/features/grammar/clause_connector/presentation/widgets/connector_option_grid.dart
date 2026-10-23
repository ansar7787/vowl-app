import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// Grid of candidate connectors for selection in clause linking exercises.
class ConnectorOptionGrid extends StatelessWidget {
  /// Available connector option words.
  final List<String> options;

  /// Index of the selected option, or `null`.
  final int? selectedIndex;

  /// Index of the correct connector option, or `null`.
  final int? correctIndex;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether midnight contrast mode is enabled.
  final bool isMidnight;

  /// Theme accent color.
  final Color primaryColor;

  /// Callback executed when the learner selects an option.
  final Function(int) onSelected;

  /// Creates a [ConnectorOptionGrid] widget.
  const ConnectorOptionGrid({
    super.key,
    required this.options,
    this.selectedIndex,
    this.correctIndex,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14.w,
        mainAxisSpacing: 14.h,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (context, index) {
        final isSelected = selectedIndex == index;
        final isCorrect = correctIndex == index;
        final showResult = selectedIndex != null;

        Color? cardColor;
        if (showResult) {
          if (isCorrect) {
            cardColor = AppColors.emerald500;
          } else if (isSelected) {
            cardColor = AppColors.rose500;
          }
        }

        return ScaleButton(
          onTap: () => onSelected(index),
          child: GlassTile(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            borderRadius: BorderRadius.circular(18.r),
            color: cardColor?.withValues(alpha: 0.8),
            borderColor: isSelected && showResult
                ? Colors.white54
                : primaryColor.withValues(alpha: 0.15),
            child: Center(
              child: Text(
                options[index],
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: (isSelected || showResult)
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2);
      },
    );
  }
}
