import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SentenceCorrectionDiagnosticWord extends StatelessWidget {
  final String text;
  final int index;
  final bool isSuspected;
  final bool isCorrectZap;
  final bool isWrongZap;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const SentenceCorrectionDiagnosticWord({
    super.key,
    required this.text,
    required this.index,
    required this.isSuspected,
    required this.isCorrectZap,
    required this.isWrongZap,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color itemColor = Colors.transparent;
    Color borderColor = primaryColor.withValues(alpha: 0.1);
    double borderWidth = 1;
    Color textColor = isDark ? Colors.white : Colors.black87;
    List<BoxShadow> shadows = [];
    TextDecoration? textDecoration;

    if (isCorrectZap) {
      itemColor = Colors.greenAccent.withValues(alpha: 0.15);
      borderColor = Colors.greenAccent;
      borderWidth = 2;
      textColor = Colors.greenAccent;
      shadows = [
        BoxShadow(
          color: Colors.greenAccent.withValues(alpha: 0.3),
          blurRadius: 15,
        ),
      ];
    } else if (isWrongZap) {
      itemColor = Colors.redAccent.withValues(alpha: 0.15);
      borderColor = Colors.redAccent;
      borderWidth = 2;
      textColor = Colors.redAccent;
      shadows = [
        BoxShadow(
          color: Colors.redAccent.withValues(alpha: 0.3),
          blurRadius: 15,
        ),
      ];
      textDecoration = TextDecoration.lineThrough;
    } else if (isSuspected) {
      itemColor = Colors.orangeAccent.withValues(alpha: 0.15);
      borderColor = Colors.orangeAccent;
      borderWidth = 2;
      textColor = Colors.orangeAccent;
      shadows = [
        BoxShadow(
          color: Colors.orangeAccent.withValues(alpha: 0.3),
          blurRadius: 10,
        ),
      ];
    }

    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: itemColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Text(
          text,
          style: GoogleFonts.fredoka(
            fontSize: 22.sp,
            fontWeight: isCorrectZap || isWrongZap || isSuspected
                ? FontWeight.bold
                : FontWeight.normal,
            color: textColor,
            decoration: textDecoration,
          ),
        ),
      ),
    )
    .animate(target: isSuspected ? 1 : 0)
    .shimmer(
      duration: 400.ms,
      color: isCorrectZap
          ? Colors.greenAccent
          : (isWrongZap ? Colors.redAccent : Colors.orangeAccent),
    )
    .shake(duration: 300.ms, hz: isWrongZap ? 10 : 0)
    .scale(
      begin: const Offset(1, 1),
      end: const Offset(1.05, 1.05),
      duration: 200.ms,
      curve: Curves.easeOutBack,
    );
  }
}
