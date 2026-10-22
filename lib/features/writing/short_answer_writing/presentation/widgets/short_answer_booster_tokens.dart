import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';

class ShortAnswerBoosterTokens extends StatelessWidget {
  final List<String> keywords;
  final String text;
  final Color color;
  final bool isDark;

  const ShortAnswerBoosterTokens({
    super.key,
    required this.keywords,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final successColor = isDark ? tokens.gameCorrect : KidsColors.safeGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              size: 16.r,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
            ),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                "REQUIRED KEYWORDS (USE ALL)",
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 8.h,
          alignment: WrapAlignment.start,
          children: keywords.map((k) {
            final kwLower = k.toLowerCase();
            final bool isUsed = RegExp(
              r'\b' + RegExp.escape(kwLower) + r'\b',
              caseSensitive: false,
            ).hasMatch(text);

            return AnimatedContainer(
              key: Key('short_answer_booster_token_$k'),
              duration: 250.milliseconds,
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isUsed
                    ? successColor.withValues(alpha: isDark ? 0.18 : 0.1)
                    : (isDark ? AppColors.slate800 : Colors.white),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isUsed
                      ? successColor
                      : (isDark ? AppColors.slate700 : AppColors.slate300),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUsed
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 16.r,
                    color: isUsed
                        ? successColor
                        : (isDark ? AppColors.slate500 : AppColors.slate400),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    k.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      color: isUsed
                          ? successColor
                          : (isDark ? AppColors.slate300 : AppColors.slate700),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
