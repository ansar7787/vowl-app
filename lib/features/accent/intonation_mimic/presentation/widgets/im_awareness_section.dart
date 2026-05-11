import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class ImAwarenessSection extends StatelessWidget {
  final String prompt;
  final ThemeResult theme;

  const ImAwarenessSection({
    super.key,
    required this.prompt,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 18.h),
      borderRadius: BorderRadius.circular(24.r),
      borderColor: Colors.amber.withValues(alpha: 0.3),
      color: Colors.amber.withValues(alpha: isDark ? 0.05 : 0.08),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.self_improvement_rounded,
              color: Colors.amber,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              prompt,
              style: GoogleFonts.outfit(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.amber.shade200 : Colors.amber.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }
}
