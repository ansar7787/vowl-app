import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color121212 = Color(0xFF121212);
}

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
    return GestureDetector(
      onTap: isAnswered ? null : () => focusNode.requestFocus(),
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: isDark ? _LocalPalette.color121212 : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isAnswered
                ? color.withValues(alpha: 0.5)
                : (isDark ? Colors.white12 : Colors.black12),
            width: 2,
          ),
          boxShadow: isAnswered
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: -5,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 18.r, color: color),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "YOUR RESPONSE",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            color: color,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Semantics(
                  label: "Word count: $wordCount out of 4 minimum",
                  container: true,
                  child: ExcludeSemantics(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: wordCount >= 4
                            ? (isDark
                                  ? tokens.gameCorrect.withValues(alpha: 0.1)
                                  : KidsColors.safeGreen.withValues(alpha: 0.1))
                            : (isDark ? Colors.white10 : Colors.black12),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        "$wordCount / 4 WORDS MIN",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 9.sp,
                          color: wordCount >= 4
                              ? (isDark ? tokens.gameCorrect : KidsColors.safeGreen)
                              : (isDark ? Colors.white54 : Colors.black54),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              focusNode: focusNode,
              maxLines: 5,
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
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Type your sentence here...",
                hintStyle: TextStyle(
                  fontFamily: 'Outfit',
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
              ),
            ),
            SizedBox(height: 12.h),
            Semantics(
              label: "Ink level progress",
              value: "${(inkLevel * 100).round()} percent",
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white10 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: inkLevel,
                    child: AnimatedContainer(
                      duration: 300.milliseconds,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2.r),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ],
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
