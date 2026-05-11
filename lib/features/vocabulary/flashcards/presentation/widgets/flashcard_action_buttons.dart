import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FlashcardActionButtons extends StatelessWidget {
  final bool isFlipped;
  final bool isTransitioning;
  final ThemeResult theme;
  final bool isDark;
  final VoidCallback onAgain;
  final VoidCallback onGotIt;

  const FlashcardActionButtons({
    super.key,
    required this.isFlipped,
    required this.isTransitioning,
    required this.theme,
    required this.isDark,
    required this.onAgain,
    required this.onGotIt,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFlipped) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: Column(
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 32.r,
            ).animate(onPlay: (c) => c.repeat()).moveY(begin: 5, end: -5, duration: 1.seconds, curve: Curves.easeInOut),
            SizedBox(height: 10.h),
            Text(
              'TAP CARD TO REVEAL',
              style: GoogleFonts.outfit(
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 2,
                fontWeight: FontWeight.w900,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'AGAIN',
              icon: Icons.refresh_rounded,
              color: isDark ? Colors.red.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.1),
              textColor: isDark ? Colors.redAccent : Colors.red,
              onTap: isTransitioning ? null : onAgain,
            ),
          ),
          SizedBox(width: 15.w),
          Expanded(
            child: _buildActionButton(
              label: 'GOT IT',
              icon: Icons.check_circle_rounded,
              color: theme.primaryColor,
              textColor: Colors.white,
              onTap: isTransitioning ? null : onGotIt,
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: onTap == null ? color.withValues(alpha: 0.05) : color,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: onTap == null ? textColor.withValues(alpha: 0.1) : textColor.withValues(alpha: 0.3)),
        ),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1.0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 24.r),
              SizedBox(width: 8.w),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
