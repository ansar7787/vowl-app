import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GuessTitleCargoCrate extends StatelessWidget {
  final String passage;
  final String correct;
  final Color color;
  final bool isDark;
  final String? selectedTitle;
  final bool isAnswered;
  final bool? isCorrect;
  final Function(String) onAccept;

  const GuessTitleCargoCrate({
    super.key,
    required this.passage,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedTitle,
    required this.isAnswered,
    required this.isCorrect,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.22 : 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black38
                : color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtle reading passage section indicator
          Row(
            children: [
              Icon(
                Icons.menu_book_rounded,
                size: 14.r,
                color: color,
              ),
              SizedBox(width: 6.w),
              Text(
                'PASSAGE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          // Passage body text
          Text(
            passage,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w400,
              height: 1.6,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : const Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 20.h),
          // Title drop slot
          DragTarget<String>(
            onWillAcceptWithDetails: (details) => !isAnswered,
            onAcceptWithDetails: (details) {
              onAccept(details.data);
            },
            builder: (context, candidateData, rejectedData) {
              final isHovered = candidateData.isNotEmpty;
              final Color borderClr = isAnswered
                  ? (isCorrect == true
                        ? tokens.gameCorrect
                        : tokens.gameIncorrect)
                  : (isHovered ? color : color.withValues(alpha: 0.35));

              final Color bgClr = isAnswered
                  ? (isCorrect == true
                        ? tokens.gameCorrect.withValues(alpha: 0.12)
                        : tokens.gameIncorrect.withValues(alpha: 0.12))
                  : (isHovered
                        ? color.withValues(alpha: 0.12)
                        : color.withValues(alpha: isDark ? 0.05 : 0.03));

              return Container(
                constraints: BoxConstraints(minHeight: 62.h),
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: bgClr,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: borderClr,
                    width: 1.8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.r),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Subtle watermark quote icon
                      Positioned(
                        right: 4.w,
                        bottom: -6.h,
                        child: Icon(
                          Icons.format_quote_rounded,
                          size: 48.r,
                          color: borderClr.withValues(alpha: 0.08),
                        ),
                      ),
                      // Text content
                      Center(
                        child: AnimatedSwitcher(
                          duration: 250.milliseconds,
                          child: selectedTitle != null
                              ? Text(
                                  selectedTitle!,
                                  key: ValueKey(selectedTitle),
                                  textAlign: TextAlign.center,
                                  softWrap: true,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    height: 1.35,
                                    color: isCorrect == true
                                        ? tokens.gameCorrect
                                        : (isCorrect == false
                                              ? tokens.gameIncorrect
                                              : (isDark
                                                    ? Colors.white
                                                    : const Color(0xFF1E293B))),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.touch_app_outlined,
                                      size: 16.r,
                                      color: color.withValues(
                                        alpha: isHovered ? 0.85 : 0.5,
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Flexible(
                                      child: Text(
                                        "DRAG & DROP TITLE HERE",
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          color: color.withValues(
                                            alpha: isHovered ? 0.85 : 0.5,
                                          ),
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
