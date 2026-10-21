import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SocialSparkConnectionMonitor extends StatelessWidget {
  final String text;
  final String? socialContext;
  final String? instruction;
  final String? hint;
  final bool hintUsed;
  final String? explanation;
  final String? culturalNote;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;

  const SocialSparkConnectionMonitor({
    super.key,
    required this.text,
    this.socialContext,
    this.instruction,
    this.hint,
    this.hintUsed = false,
    this.explanation,
    this.culturalNote,
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
      key: const Key('social_spark_connection_monitor'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: outlineColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: outlineColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.forum_rounded, color: outlineColor, size: 20.r),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  isAnswered
                      ? ((isCorrect ?? false)
                            ? "PERFECT RESPONSE"
                            : "LET'S TRY AGAIN")
                      : "CONVERSATION BUILDER",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: outlineColor,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          if (instruction != null) ...[
            SizedBox(height: 12.h),
            Text(
              instruction!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey.shade200 : AppColors.slate800,
                height: 1.35,
              ),
            ),
          ],
          if (hintUsed && hint != null && hint!.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              key: const Key('social_spark_hint_banner'),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.amber,
                    size: 16.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      hint!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: isDark ? Colors.amber.shade300 : Colors.amber.shade800,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (socialContext != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: outlineColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(color: outlineColor.withValues(alpha: 0.25)),
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
                        fontWeight: FontWeight.w700,
                        color: outlineColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: outlineColor.withValues(alpha: text.isEmpty ? 0.1 : 0.3),
                  width: 1.0,
                ),
              ),
              child: Text(
                text.isEmpty ? "Tap words to build your response" : text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: text.isEmpty ? FontWeight.w400 : FontWeight.w600,
                  color: text.isEmpty
                      ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                      : (Theme.of(context).colorScheme.onSurface),
                  height: 1.35,
                ),
              ),
            ),
          ),
          if (isAnswered && (explanation != null || culturalNote != null)) ...[
            SizedBox(height: 14.h),
            Container(
              key: const Key('social_spark_explanation_card'),
              width: double.infinity,
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: outlineColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: outlineColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        (isCorrect ?? false)
                            ? Icons.verified_rounded
                            : Icons.lightbulb_outline_rounded,
                        color: outlineColor,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          (isCorrect ?? false)
                              ? "WHY THIS WORKS"
                              : "HELPFUL EXPLANATION",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: outlineColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (explanation != null) ...[
                    SizedBox(height: 8.h),
                    Text(
                      explanation!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? Colors.grey.shade200 : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (culturalNote != null) ...[
                    SizedBox(height: 6.h),
                    Text(
                      "Note: $culturalNote",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
