import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ReadAndAnswerBuoyOption extends StatelessWidget {
  final int index;
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final VoidCallback onTap;

  const ReadAndAnswerBuoyOption({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    bool isSelected = selectedIndex == index;
    bool isCorrect = isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    bool isWrong = isAnswered && isSelected && !isCorrect;

    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: ScaleButton(
        onTap: onTap,
        child: GlassTile(
          padding: EdgeInsets.all(24.r),
          borderRadius: BorderRadius.circular(20.r),
          color: isCorrect 
              ? Colors.greenAccent.withValues(alpha: isDark ? 0.3 : 0.2) 
              : (isWrong 
                  ? Colors.redAccent.withValues(alpha: isDark ? 0.3 : 0.2) 
                  : (isSelected 
                      ? color.withValues(alpha: 0.2) 
                      : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.03)))),
          border: Border.all(
            color: isCorrect 
                ? (isDark ? Colors.greenAccent : Colors.green) 
                : (isWrong 
                    ? (isDark ? Colors.redAccent : Colors.red) 
                    : (isSelected ? color : (isDark ? Colors.white24 : Colors.black12))),
            width: 2,
          ),
          child: Row(
            children: [
              Icon(
                isCorrect 
                    ? Icons.check_circle_outline_rounded 
                    : (isWrong ? Icons.cancel_outlined : Icons.radio_button_checked_rounded),
                color: isCorrect 
                    ? (isDark ? Colors.greenAccent : Colors.green) 
                    : (isWrong 
                        ? (isDark ? Colors.redAccent : Colors.red) 
                        : (isSelected ? color : (isDark ? Colors.white24 : Colors.black26))),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  text, 
                  style: GoogleFonts.outfit(
                    fontSize: 16.sp, 
                    fontWeight: FontWeight.w600, 
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
