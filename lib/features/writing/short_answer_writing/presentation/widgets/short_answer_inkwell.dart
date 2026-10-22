import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';

class ShortAnswerInkwell extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAnswered;
  final int wordCount;
  final double inkLevel;
  final Color color;
  final bool isDark;

  const ShortAnswerInkwell({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAnswered,
    required this.wordCount,
    required this.inkLevel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final successColor = isDark ? tokens.gameCorrect : KidsColors.safeGreen;

    return GestureDetector(
      onTap: isAnswered ? null : () => focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(18.r),
        decoration: BoxDecoration(
          color: isDark ? AppColors.slate800 : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isAnswered
                ? color.withValues(alpha: 0.35)
                : (isDark ? AppColors.slate700 : AppColors.slate200),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 20.r, color: color),
                    SizedBox(width: 8.w),
                    Text(
                      "YOUR RESPONSE",
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color: color,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Semantics(
                  label: "Word count: $wordCount out of 4 minimum",
                  container: true,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 5.h,
                      ),
                      decoration: BoxDecoration(
                        color: wordCount >= 4
                            ? successColor.withValues(alpha: 0.15)
                            : (isDark
                                ? AppColors.slate700.withValues(alpha: 0.6)
                                : AppColors.slate100),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: wordCount >= 4
                              ? successColor.withValues(alpha: 0.3)
                              : (isDark
                                  ? AppColors.slate600
                                  : AppColors.slate300),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        "$wordCount / 4 WORDS MIN",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.5.sp,
                          color: wordCount >= 4
                              ? successColor
                              : (isDark
                                  ? AppColors.slate300
                                  : AppColors.slate600),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              key: const Key('short_answer_text_field'),
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
              minLines: 3,
              enabled: !isAnswered,
              onTapOutside: (PointerDownEvent event) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              onTap: () {
                if (focusNode.hasFocus) {
                  SystemChannels.textInput.invokeMethod('TextInput.show');
                }
              },
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                color: isDark ? AppColors.white : AppColors.slate900,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
              decoration: InputDecoration(
                hintText: "Type your sentence here...",
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  color: isDark ? AppColors.slate500 : AppColors.slate400,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8.h),
              ),
            ),
            SizedBox(height: 12.h),
            Semantics(
              label: "Answer progress",
              value: "${(inkLevel * 100).round()} percent",
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate700 : AppColors.slate200,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: inkLevel,
                    child: AnimatedContainer(
                      duration: 250.milliseconds,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: wordCount >= 4 ? successColor : color,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
