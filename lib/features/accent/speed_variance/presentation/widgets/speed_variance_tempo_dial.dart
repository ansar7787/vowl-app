import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

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
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildChromeDial(correctIndex, color, isDark),
        SizedBox(height: 18.h),
        Text(
          isDragging ? "Release to select" : "Turn dial or tap your answer",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.85),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 16.h),
        _buildOptionCard(
          context,
          options.isNotEmpty ? options[0] : '',
          0,
          correctIndex,
          color,
          isDark,
        ),
        SizedBox(height: 12.h),
        _buildOptionCard(
          context,
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
        key: const ValueKey('speed_variance_chrome_dial'),
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDialRotate(details, correct),
        onPanEnd: (_) => onDialRelease(),
        child: Transform.rotate(
          angle: dialRotation,
          child: Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  isDark ? Colors.black : Colors.grey.shade400,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 2.5,
              ),
            ),
            child: Center(
              child: Container(
                width: 8.r,
                height: 42.r,
                margin: EdgeInsets.only(bottom: 42.r),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4.r),
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

  Widget _buildOptionCard(
    BuildContext context,
    String text,
    int index,
    int correctIndex,
    Color color,
    bool isDark,
  ) {
    if (text.isEmpty) return const SizedBox();

    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;

    Color cardBg = color.withValues(alpha: isDark ? 0.06 : 0.08);
    Color textColor = color;
    Color descColor = isDark ? Colors.white70 : Colors.black87;
    Color borderColor = color.withValues(
      alpha: isSelected ? 1.0 : (isDark ? 0.2 : 0.25),
    );

    if (isAnswered && isSelected) {
      cardBg = correct
          ? AppColors.gameCorrect.withValues(alpha: 0.16)
          : AppColors.gameIncorrect.withValues(alpha: 0.16);
      textColor = correct ? AppColors.gameCorrect : AppColors.gameIncorrect;
      borderColor = textColor;
      descColor = textColor.withValues(alpha: 0.9);
    } else if (isSelected) {
      cardBg = color;
      textColor = Colors.white;
      descColor = Colors.white.withValues(alpha: 0.9);
      borderColor = color;
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

    final shouldReduce = VowlMotion.shouldReduceMotion(context);
    Widget cardContent = Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: borderColor, width: isSelected ? 2.0 : 1.5),
        boxShadow: [
          if (isSelected)
            BoxShadow(
              color: correct
                  ? AppColors.gameCorrect.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.12),
            ),
            child: Icon(
              index == 0
                  ? Icons.rotate_left_rounded
                  : Icons.rotate_right_rounded,
              color: textColor,
              size: 22.r,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  softWrap: true,
                  maxLines: null,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    letterSpacing: 0.2,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    softWrap: true,
                    maxLines: null,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w400,
                      color: descColor,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (!shouldReduce) {
      cardContent = cardContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.015, 1.015),
            duration: (2 + index).seconds,
          );
    }

    return ScaleButton(
      key: ValueKey('speed_variance_option_$index'),
      onTap: () => onSubmitChoice(index, correctIndex),
      child: cardContent,
    );
  }
}
