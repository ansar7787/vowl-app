import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ReadingInferenceOption extends StatelessWidget {
  final int index;
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final double clarity;
  final VoidCallback onTap;

  const ReadingInferenceOption({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.clarity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedIndex == index;
    bool isCorrect =
        isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    bool isWrong = isAnswered && isSelected && !isCorrect;
    bool isDisabled = clarity < 0.3 && !isAnswered;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: ScaleButton(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isDisabled ? 0.35 : 1.0,
          child: GlassTile(
            padding: EdgeInsets.all(20.r),
            borderRadius: BorderRadius.circular(20.r),
            color: isCorrect
                ? Colors.greenAccent.withValues(alpha: 0.25)
                : (isWrong
                      ? Colors.redAccent.withValues(alpha: 0.25)
                      : (isSelected
                            ? color.withValues(alpha: 0.15)
                            : (isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04)))),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
