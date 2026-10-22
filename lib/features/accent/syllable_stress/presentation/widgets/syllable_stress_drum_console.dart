import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class SyllableStressDrumConsole extends StatelessWidget {
  final List<String> syllables;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final Function(int, int) onPadTap;

  const SyllableStressDrumConsole({
    super.key,
    required this.syllables,
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onPadTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      key: const ValueKey('syllable_stress_drum_console'),
      spacing: 12.w,
      runSpacing: 12.h,
      alignment: WrapAlignment.center,
      children: List.generate(
        syllables.length,
        (i) => _buildDrumPad(
          context,
          i,
          syllables[i],
          correctIndex,
          color,
          isDark,
        ),
      ),
    );
  }

  Widget _buildDrumPad(
    BuildContext context,
    int index,
    String text,
    int correct,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedIndex == index;
    final bool isCorrect = isAnswered && index == correct;
    final bool isWrong = isAnswered && isSelected && index != correct;
    final bool reduceMotion = VowlMotion.shouldReduceMotion(context);

    Color padColor = isCorrect
        ? AppColors.gameCorrect
        : (isWrong ? AppColors.gameIncorrect : color);
    Color contentColor = isSelected ? padColor : color;
    if (isAnswered && index == correct) {
      padColor = AppColors.gameCorrect;
      contentColor = AppColors.gameCorrect;
    }

    final boltIcon = Icon(
      Icons.bolt_rounded,
      color: AppColors.gameCorrect,
      size: 16.r,
    );

    return Semantics(
      button: true,
      label: text,
      child: ScaleButton(
        key: ValueKey('syllable_pad_$index'),
        onTap: isAnswered ? () {} : () => onPadTap(index, correct),
        child: AnimatedContainer(
          duration: 150.milliseconds,
          width: 82.r,
          height: 82.r,
          decoration: BoxDecoration(
            color: isSelected
                ? padColor.withValues(alpha: 0.18)
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isSelected || (isAnswered && index == correct)
                  ? padColor
                  : color.withValues(alpha: 0.28),
              width: 2.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: padColor.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isSelected || (isAnswered && index == correct)
                            ? contentColor
                            : (Theme.of(context).colorScheme.onSurface),
                      ),
                    ),
                  ),
                ),
                if (index == correct && isAnswered) ...[
                  SizedBox(height: 3.h),
                  reduceMotion ? boltIcon : boltIcon.animate().scale(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
