import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Interactive card presenting the passage sentence with a pneumatic slot target for missing words.
class ClozeTestPneumaticPort extends StatelessWidget {
  /// The sentence text containing the '____' blank placeholder.
  final String text;

  /// The authoritative correct word string.
  final String correct;

  /// Theme accent color applied to ports and highlights.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// The word option currently placed into the blank, or null if unoccupied.
  final String? dockedOption;

  /// Optional part-of-speech or grammatical category of the target word.
  final String? wordCategory;

  /// Whether the answer has been evaluated.
  final bool isAnswered;

  /// Callback invoked when a word option is dropped or selected into the port.
  final Function(String) onDock;

  /// Creates a [ClozeTestPneumaticPort] widget.
  const ClozeTestPneumaticPort({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.dockedOption,
    this.wordCategory,
    required this.isAnswered,
    required this.onDock,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final parts = text.split('____');

    final bool correctDocked =
        isAnswered &&
        dockedOption?.trim().toLowerCase() == correct.trim().toLowerCase();
    final bool wrongDocked = isAnswered && !correctDocked;

    final cardBg = isDark
        ? const Color(0xFF161922)
        : Colors.white;
    final cardBorder = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : color.withValues(alpha: 0.18);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 22.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : color).withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17.sp,
                color: isDark ? Colors.white.withValues(alpha: 0.92) : const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
                height: 1.6,
                letterSpacing: 0.2,
              ),
              children: [
                TextSpan(text: parts[0]),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: DragTarget<String>(
                    onAcceptWithDetails: (details) => onDock(details.data),
                    builder: (context, candidateData, rejectedData) {
                      final isFilled = dockedOption != null;
                      final slotBg = correctDocked
                          ? tokens.gameCorrect.withValues(alpha: 0.18)
                          : (wrongDocked
                              ? tokens.gameIncorrect.withValues(alpha: 0.18)
                              : (isFilled
                                  ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : color.withValues(alpha: 0.06))));

                      final slotBorderColor = correctDocked
                          ? tokens.gameCorrect
                          : (wrongDocked
                              ? tokens.gameIncorrect
                              : (isFilled
                                  ? color
                                  : (isDark
                                      ? Colors.white24
                                      : color.withValues(alpha: 0.35))));

                      final slotTextColor = correctDocked
                          ? tokens.gameCorrect
                          : (wrongDocked
                              ? tokens.gameIncorrect
                              : (isFilled
                                  ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                  : color.withValues(alpha: isDark ? 0.75 : 0.65)));

                      return Container(
                        margin: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 6.h,
                        ),
                        constraints: BoxConstraints(
                          minWidth: 84.w,
                          maxWidth: 190.w,
                        ),
                        decoration: BoxDecoration(
                          color: slotBg,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: slotBorderColor,
                            width: 1.5,
                          ),
                          boxShadow: [
                            if (isFilled)
                              BoxShadow(
                                color: (correctDocked
                                        ? tokens.gameCorrect
                                        : (wrongDocked ? tokens.gameIncorrect : color))
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            dockedOption?.toUpperCase() ?? "DRAG HERE",
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: isFilled ? 15.sp : 12.sp,
                              color: slotTextColor,
                              fontWeight: isFilled ? FontWeight.w700 : FontWeight.w600,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      )
                          .animate(target: isFilled ? 1 : 0)
                          .shimmer(duration: 800.ms);
                    },
                  ),
                ),
                if (parts.length > 1)
                  TextSpan(text: parts.sublist(1).join('____')),
              ],
            ),
          ),
          if (wordCategory != null && wordCategory!.trim().isNotEmpty) ...[
            SizedBox(height: 16.h),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: isDark ? 0.12 : 0.07),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.help_outline_rounded,
                      size: 13.r,
                      color: color.withValues(alpha: 0.8),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Hint: ',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    Text(
                      '(${wordCategory!.trim().toLowerCase()})',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: color.withValues(alpha: isDark ? 0.9 : 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
