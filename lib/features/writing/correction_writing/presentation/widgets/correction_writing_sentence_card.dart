import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

class CorrectionWritingSentenceCard extends StatelessWidget {
  final String passage;
  final String? selectedCorrection;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;

  const CorrectionWritingSentenceCard({
    super.key,
    required this.passage,
    required this.selectedCorrection,
    required this.color,
    required this.isDark,
    this.isAnswered = false,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final startIdx = passage.indexOf('[');
    final endIdx = passage.indexOf(']');

    final cardDecoration = BoxDecoration(
      color: color.withValues(alpha: isDark ? 0.06 : 0.04),
      borderRadius: BorderRadius.circular(20.r),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.08),
        width: 1.2,
      ),
      boxShadow: [
        if (!isDark)
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
      ],
    );

    if (startIdx == -1 || endIdx == -1) {
      return Container(
        key: const Key('correction_writing_sentence_card'),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
        decoration: cardDecoration,
        child: Text(
          passage,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 17.sp,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            height: 1.6,
          ),
        ),
      );
    }

    final preText = passage.substring(0, startIdx);
    final errorText = passage.substring(startIdx + 1, endIdx);
    final postText = passage.substring(endIdx + 1);

    final bool hasSelection = selectedCorrection != null;

    final Color chipBgColor;
    final Color chipBorderColor;
    final Color chipTextColor;

    if (hasSelection) {
      if (isAnswered) {
        if (isCorrect == true) {
          chipBgColor = tokens.gameCorrect.withValues(alpha: 0.12);
          chipBorderColor = tokens.gameCorrect;
          chipTextColor = tokens.gameCorrect;
        } else {
          chipBgColor = tokens.gameIncorrect.withValues(alpha: 0.12);
          chipBorderColor = tokens.gameIncorrect;
          chipTextColor = tokens.gameIncorrect;
        }
      } else {
        chipBgColor = color.withValues(alpha: 0.12);
        chipBorderColor = color;
        chipTextColor = color;
      }
    } else {
      chipBgColor = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);
      chipBorderColor = isDark ? Colors.white24 : Colors.black26;
      chipTextColor = isDark
          ? Colors.white.withValues(alpha: 0.85)
          : Colors.black87;
    }

    return Container(
      key: const Key('correction_writing_sentence_card'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: cardDecoration,
      child: Center(
        child: Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.9)
                  : Colors.black87,
              height: 1.6,
            ),
            children: [
              TextSpan(text: preText),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: AnimatedContainer(
                  duration: 250.milliseconds,
                  margin: EdgeInsets.symmetric(horizontal: 6.w),
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: chipBgColor,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: chipBorderColor,
                      width: hasSelection ? 1.5 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        selectedCorrection ?? errorText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.5.sp,
                          color: chipTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isAnswered && hasSelection) ...[
                        SizedBox(width: 5.w),
                        Icon(
                          isCorrect == true
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 15.r,
                          color: isCorrect == true
                              ? tokens.gameCorrect
                              : tokens.gameIncorrect,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              TextSpan(text: postText),
            ],
          ),
          textAlign: TextAlign.center,
          softWrap: true,
        ),
      ),
    );
  }
}

