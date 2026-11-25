import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Shared CEFR + mechanic pill header for Practice drills.
class SynonymDrillBadge extends StatelessWidget {
  final String label;
  final String cefr;
  final Color primaryColor;
  final bool isDark;

  const SynonymDrillBadge({
    super.key,
    required this.label,
    required this.cefr,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.12),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        '$label • $cefr',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: isDark ? AppColors.slate50 : primaryColor,
        ),
      ),
    );
  }
}

/// Shared word bank pill used by Contrast Swap and Synonym Ladder drills.
class SynonymPracticeWordPill extends StatelessWidget {
  final String word;
  final bool isUsed;
  final Color primaryColor;
  final bool isDark;
  final double minWidth;
  final VoidCallback onTap;

  const SynonymPracticeWordPill({
    super.key,
    required this.word,
    required this.isUsed,
    required this.primaryColor,
    required this.isDark,
    this.minWidth = 88,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isUsed ? '$word, placed' : 'Place word $word',
      child: ScaleButton(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: 48, minWidth: minWidth),
          child: AnimatedContainer(
            duration: VowlMotion.shouldReduceMotion(context)
                ? Duration.zero
                : VowlMotion.fast,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: isUsed
                  ? (isDark ? AppColors.slate800 : AppColors.slate100)
                  : primaryColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: isUsed
                    ? (isDark ? AppColors.slate700 : AppColors.slate300)
                    : primaryColor,
                width: 1.5,
              ),
              boxShadow: isUsed
                  ? const []
                  : [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.28),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  word,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isUsed
                        ? (isDark ? AppColors.slate400 : AppColors.slate500)
                        : Colors.white,
                  ),
                ),
                if (isUsed) ...[
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.check_rounded,
                    size: 16.sp,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared coaching / hint / spoken feedback banner across Practice cards.
class SynonymPracticeBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color accent;
  final bool isDark;
  final String? ttsText;
  final Color? primaryColor;

  const SynonymPracticeBanner({
    super.key,
    required this.icon,
    required this.text,
    required this.accent,
    required this.isDark,
    this.ttsText,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.22 : 0.10),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.sp, color: isDark ? AppColors.slate50 : accent),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate50 : AppColors.slate800,
                height: 1.4,
              ),
            ),
          ),
          if (ttsText != null && primaryColor != null) ...[
            SizedBox(width: 8.w),
            TtsSpeakerButtonWidget(
              text: ttsText!,
              color: primaryColor!,
              size: 18,
            ),
          ],
        ],
      ),
    );
  }
}
