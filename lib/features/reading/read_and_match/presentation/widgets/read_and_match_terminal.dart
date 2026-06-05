import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadAndMatchTerminal extends StatelessWidget {
  final String text;
  final bool isSource;
  final Color color;
  final bool isDark;
  final bool isMatched;
  final bool isActive;
  final VoidCallback onTap;

  const ReadAndMatchTerminal({
    super.key,
    required this.text,
    required this.isSource,
    required this.color,
    required this.isDark,
    required this.isMatched,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.milliseconds,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isMatched 
              ? color.withValues(alpha: isDark ? 0.15 : 0.08) 
              : (isActive ? color.withValues(alpha: isDark ? 0.3 : 0.15) : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04))),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isMatched || isActive ? color : (isDark ? Colors.white10 : Colors.black12), 
            width: 2,
          ),
          boxShadow: [
            if (isMatched || isActive) 
              BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          text.contains("]") ? text.split("]").last.trim() : text, 
          textAlign: TextAlign.center, 
          style: TextStyle(fontFamily: 'RobotoMono', 
            fontSize: 13.sp, 
            color: isMatched || isActive 
                ? (isDark ? Colors.white : color) 
                : (isDark ? Colors.white70 : Colors.black87), 
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
