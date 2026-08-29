import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SynonymInstructionHeader extends StatelessWidget {
  final Color color;
  final String instruction;
  final bool isCompact;

  const SynonymInstructionHeader({
    super.key,
    required this.color,
    this.instruction = "WARP THE SYNONYM SHARD",
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            constraints: BoxConstraints(maxWidth: 340.w),
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16.w : 20.w,
              vertical: isCompact ? 8.h : 12.h,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? color.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 6.r : 8.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    Icons.radar_rounded,
                    size: isCompact ? 14.r : 16.r,
                    color: color,
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 1.seconds,
                    ),
                SizedBox(width: 12.w),
                Flexible(
                  child: Text(
                    instruction.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 10.sp : 12.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: 1.2,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOutQuad).slideY(
            begin: -0.2,
            end: 0,
            duration: 600.ms,
            curve: Curves.easeOutQuad,
          ),
    );
  }
}
