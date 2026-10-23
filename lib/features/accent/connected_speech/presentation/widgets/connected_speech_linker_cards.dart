import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class ConnectedSpeechLinkerCards extends StatelessWidget {
  final List<String> options;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onSubmitChoice;
  final bool isCompact;

  const ConnectedSpeechLinkerCards({
    super.key,
    required this.options,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onSubmitChoice,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    final bool reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < options.length; i++) ...[
          if (i > 0) SizedBox(height: isCompact ? 8.h : 10.h),
          _buildLinkerCard(context, options[i], i, reduceMotion),
        ],
      ],
    );
  }

  Widget _buildLinkerCard(
    BuildContext context,
    String text,
    int index,
    bool reduceMotion,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool correct = index == correctIndex;
    final bool showResult = isAnswered && (isSelected || correct);

    Color cardColor = isDark
        ? AppColors.slate800.withValues(alpha: 0.6)
        : Colors.white.withValues(alpha: 0.85);
    Color borderColor = isDark
        ? AppColors.slate700.withValues(alpha: 0.8)
        : AppColors.slate200;
    Color textColor = isDark ? AppColors.slate100 : AppColors.slate900;

    if (showResult) {
      if (correct) {
        cardColor = AppColors.emerald500.withValues(alpha: 0.15);
        borderColor = AppColors.emerald500;
        textColor = AppColors.emerald500;
      } else {
        cardColor = AppColors.rose700.withValues(alpha: 0.15);
        borderColor = AppColors.rose700;
        textColor = AppColors.rose700;
      }
    } else if (isSelected) {
      cardColor = color.withValues(alpha: 0.15);
      borderColor = color;
      textColor = color;
    }

    Widget card = Semantics(
      button: true,
      label: 'Option ${String.fromCharCode(65 + index)}: $text',
      selected: isSelected,
      child: ScaleButton(
        key: ValueKey('linker_card_$index'),
        onTap: isAnswered ? null : () => onSubmitChoice(index, correctIndex),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: isCompact ? 52.h : 60.h,
            maxWidth: 420.w,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: isCompact ? 10.h : 12.h,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: borderColor,
              width: isSelected || (showResult && (isSelected || correct))
                  ? 2.0
                  : 1.2,
            ),
            boxShadow: [
              if (!isSelected && !showResult)
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.25)
                      : Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 3),
                  blurRadius: 6,
                ),
              if (showResult)
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: isCompact ? 28.r : 32.r,
                height: isCompact ? 28.r : 32.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected || (showResult && correct)
                      ? borderColor.withValues(alpha: 0.2)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.05)),
                  border: Border.all(
                    color: isSelected || (showResult && correct)
                        ? borderColor
                        : (isDark ? Colors.white24 : Colors.black12),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 12.sp : 13.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.left,
                  softWrap: true,
                  maxLines: null,
                  overflow: TextOverflow.clip,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 13.sp : 14.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: textColor,
                    height: 1.35,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Icon(
                showResult
                    ? (correct
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded)
                    : (isSelected
                          ? Icons.check_circle_outline_rounded
                          : Icons.radio_button_unchecked_rounded),
                color: showResult
                    ? borderColor
                    : (isSelected
                          ? color
                          : (isDark ? Colors.white24 : Colors.black26)),
                size: isCompact ? 18.r : 20.r,
              ),
            ],
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return card;
    }

    return card
        .animate()
        .fadeIn(delay: (80 * index).ms)
        .slideY(begin: 0.08, duration: 250.ms);
  }
}
