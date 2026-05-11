import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordLabHeader extends StatelessWidget {
  final bool isDark;
  final double progress;
  final ThemeResult theme;
  final int lives;
  final VoidCallback onExit;

  const WordLabHeader({
    super.key,
    required this.isDark,
    required this.progress,
    required this.theme,
    required this.lives,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 10.h),
      child: Row(
        children: [
          ScaleButton(
            onTap: onExit,
            child: Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close_rounded, size: 20.r, color: Colors.white),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Container(
              height: 8.h,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20.r),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          _buildHeartCount(),
        ],
      ),
    );
  }

  Widget _buildHeartCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.pink.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.pink.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 14.r),
          SizedBox(width: 6.w),
          Text(
            "$lives",
            style: GoogleFonts.shareTechMono(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.pinkAccent,
            ),
          ),
        ],
      ),
    );
  }
}
