import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SsTopBar extends StatelessWidget {
  final double progress;
  final int livesRemaining;
  final Color primaryColor;
  final bool isMidnight;

  const SsTopBar({
    super.key,
    required this.progress,
    required this.livesRemaining,
    required this.primaryColor,
    this.isMidnight = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 10.h),
      child: Row(
        children: [
          ScaleButton(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black12,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 24.r,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14.h,
                backgroundColor: isDark ? Colors.white10 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          _buildHeartCount(livesRemaining),
        ],
      ),
    );
  }

  Widget _buildHeartCount(int lives) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: const Color(0xFFF43F5E).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite_rounded,
            size: 20.r,
            color: const Color(0xFFF43F5E),
          ),
          SizedBox(width: 6.w),
          Text(
            lives.toString(),
            style: GoogleFonts.outfit(
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFF43F5E),
            ),
          ),
        ],
      ),
    );
  }
}
