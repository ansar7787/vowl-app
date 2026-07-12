import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class IdiomsSystemMessage extends StatelessWidget {
  final String text;
  final Color color;

  const IdiomsSystemMessage({
    super.key,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 9.sp,
            color: color,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }
}

class IdiomsStrangerMessage extends StatelessWidget {
  final String emojis;
  final Color color;
  final bool isDark;

  const IdiomsStrangerMessage({
    super.key,
    required this.emojis,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
              bottomRight: Radius.circular(24.r),
            ),
            border: Border.all(
              color: isDark
                  ? color.withValues(alpha: 0.3)
                  : color.withValues(alpha: 0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Text(emojis, style: TextStyle(fontSize: 48.sp)),
        )
        .animate()
        .slideX(begin: -0.1, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn();
  }
}

class IdiomsUserMessage extends StatelessWidget {
  final String text;
  final Color color;
  final bool? isCorrect;
  final bool isDark;

  const IdiomsUserMessage({
    super.key,
    required this.text,
    required this.color,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isCorrect == true
        ? Colors.green
        : (isCorrect == false ? Colors.red : color);
    return Container(
          constraints: BoxConstraints(maxWidth: 0.75.sw),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isDark
                ? bgColor.withValues(alpha: 0.15)
                : bgColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24.r),
              topRight: Radius.circular(24.r),
              bottomLeft: Radius.circular(24.r),
            ),
            border: Border.all(
              color: bgColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: bgColor.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  text.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              if (isCorrect != null) ...[
                SizedBox(width: 10.w),
                Icon(
                  isCorrect! ? Icons.verified_rounded : Icons.gpp_bad_rounded,
                  color: isCorrect! ? Colors.greenAccent : Colors.redAccent,
                  size: 18.r,
                ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
              ],
            ],
          ),
        )
        .animate()
        .slideX(begin: 0.1, duration: 500.ms, curve: Curves.easeOutCubic)
        .fadeIn();
  }
}
