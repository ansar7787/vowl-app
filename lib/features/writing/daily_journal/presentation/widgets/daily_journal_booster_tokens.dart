import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Interactive chips displaying required target words that dynamically highlight upon usage in the entry.
class DailyJournalBoosterTokens extends StatelessWidget {
  /// The list of target vocabulary words the user is encouraged to incorporate.
  final List<String> keywords;

  /// The current input text typed by the user, evaluated for keyword presence.
  final String text;

  /// The theme accent color applied to chips and indicators.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Creates a [DailyJournalBoosterTokens] widget.
  const DailyJournalBoosterTokens({
    super.key,
    required this.keywords,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Target words (use at least 2)",
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            color: isDark ? Colors.white70 : Colors.black87,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          alignment: WrapAlignment.center,
          children: keywords.map((k) {
            final bool isUsed = RegExp(
              r'\b' + RegExp.escape(k.toLowerCase()),
            ).hasMatch(text.toLowerCase());
            final displayColor = isUsed
                ? tokens.gameCorrect
                : (isDark ? Colors.white24 : Colors.black26);

            return GestureDetector(
              key: Key('daily_journal_token_$k'),
              onTap: () {
                // Speak the token loudly so they learn pronunciation!
                di.sl<TtsService>().speak(k);

                if (!isUsed) {
                  CustomSnackBar.show(
                    context: context,
                    message:
                        "Type '$k' in your journal entry to include this word.",
                    type: CustomSnackBarType.info,
                  );
                } else {
                  CustomSnackBar.show(
                    context: context,
                    message: "'$k' is already included! Great job.",
                    type: CustomSnackBarType.success,
                  );
                }
              },
              child: AnimatedContainer(
                duration: 300.milliseconds,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: isUsed
                      ? tokens.gameCorrect.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: displayColor, width: 1.5),
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
                          ? tokens.gameCorrect
                          : (isDark ? Colors.white38 : Colors.black38),
                    ),
                    SizedBox(width: 8.w),
                    Flexible(
                      child: Text(
                        k,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          color: isUsed
                              ? tokens.gameCorrect
                              : (isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black87),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
