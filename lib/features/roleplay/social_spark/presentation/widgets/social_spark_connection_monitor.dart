import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SocialSparkConnectionMonitor extends StatelessWidget {
  final String text;
  final String? socialContext;
  final String? instruction;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;

  const SocialSparkConnectionMonitor({
    super.key,
    required this.text,
    this.socialContext,
    this.instruction,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    Color outlineColor = color;
    if (isAnswered) {
      outlineColor = (isCorrect ?? false)
          ? tokens.gameCorrect
          : tokens.gameIncorrect;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: outlineColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: outlineColor.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hub_rounded, color: outlineColor, size: 20.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  isAnswered
                      ? ((isCorrect ?? false)
                            ? "ALIGNMENT STABLE"
                            : "SIGNAL COLLAPSED")
                      : "CONSTELLATION HARMONICS",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: outlineColor,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          if (instruction != null) ...[
            SizedBox(height: 14.h),
            Text(
              instruction!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
              ),
            ),
          ],
          if (socialContext != null) ...[
            SizedBox(height: 14.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: outlineColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: outlineColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: outlineColor,
                    size: 14.r,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      "SCENE: ${socialContext!.toUpperCase()}",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: outlineColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 20.h),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Text(
                text.isEmpty ? "Tap words to build your response" : text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: text.isEmpty ? 16.sp : 18.sp,
                  fontWeight: FontWeight.w500,
                  color: text.isEmpty
                      ? Colors.grey.shade600
                      : (Theme.of(context).colorScheme.onSurface),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}
