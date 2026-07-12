import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordReorderCheckButton extends StatelessWidget {
  final bool hasWords;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onCheck;

  const WordReorderCheckButton({
    super.key,
    required this.hasWords,
    required this.isDark,
    required this.primaryColor,
    required this.onCheck,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ScaleButton(
        onTap: hasWords ? onCheck : null,
        child: Container(
          width: double.infinity,
          height: 58.h,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            gradient: LinearGradient(
              colors: hasWords
                  ? [primaryColor, primaryColor.withValues(alpha: 0.8)]
                  : [
                      Colors.grey.withValues(alpha: 0.3),
                      Colors.grey.withValues(alpha: 0.4),
                    ],
            ),
            boxShadow: hasWords
                ? [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              "CHECK SENTENCE",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: hasWords
                    ? Colors.white
                    : (isDark ? Colors.white30 : Colors.black26),
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
