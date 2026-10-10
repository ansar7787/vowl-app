import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class DailyJournalScratchArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isAnswered;
  final int wordCount;
  final double journalProgress;
  final Color color;
  final bool isDark;

  const DailyJournalScratchArea({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isAnswered,
    required this.wordCount,
    required this.journalProgress,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : const Color(0xFFFDF8EE), // Warm paper tint
        borderRadius: BorderRadius.circular(16.r), // Slightly sharper corners like a book
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5D5C5), // Subtle paper border
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFFD3C5B5).withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: -2,
            offset: const Offset(0, 4), // Paper drop shadow
          ),
        ],
      ),
      child: Column(
        children: [
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
              fontFamily: 'Spectral',
              fontSize: 16.sp,
              color: Theme.of(context).colorScheme.onSurface,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: "Start writing here...",
              hintStyle: TextStyle(
                fontFamily: 'Spectral',
                color: isDark ? Colors.white30 : Colors.black38,
              ),
              border: InputBorder.none,
            ),
          ),
          SizedBox(height: 16.h),
          Semantics(
            label: "Word count: $wordCount words",
            container: true,
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Word count:",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "$wordCount words",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      color: wordCount >= 10
                          ? tokens.gameCorrect
                          : tokens.gameIncorrect,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Semantics(
            label: "Journal progress",
            value: "${(journalProgress * 100).round()} percent",
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 6.h,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: journalProgress,
                  child: AnimatedContainer(
                    duration: 300.milliseconds,
                    height: 6.h,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.5)],
                      ),
                      borderRadius: BorderRadius.circular(3.r),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
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
    );
  }
}
