import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

/// A premium-feeling chip that displays a Smart Reply AI suggestion.
///
/// Has a subtle gradient, an AI sparkle icon, and supports an on-tap action
/// that will integrate with the monetization gate.
class SmartReplyChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isPremium;

  const SmartReplyChip({
    super.key,
    required this.text,
    required this.onTap,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 12.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark 
              ? [const Color(0xFF6366F1).withValues(alpha: 0.15), const Color(0xFF8B5CF6).withValues(alpha: 0.15)]
              : [const Color(0xFF6366F1).withValues(alpha: 0.08), const Color(0xFF8B5CF6).withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: const Color(0xFF8B5CF6),
              size: 16.r,
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds)
             .tint(color: Colors.white, duration: 1.seconds),
            SizedBox(width: 8.w),
            Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (!isPremium) ...[
              SizedBox(width: 8.w),
              Icon(
                Icons.play_circle_outline_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 14.r,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
