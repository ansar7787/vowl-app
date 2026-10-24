import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Rich text widget displaying the evidence sentence with an inline target blank slot.
class ContextCluesEvidenceSentence extends StatelessWidget {
  /// The investigation sentence containing a `[TARGET]` placeholder tag.
  final String sentence;

  /// Theme accent color for slot borders and placeholder indicators.
  final Color color;

  /// Whether compact typography and padding should be applied.
  final bool isCompact;

  /// Whether the user has answered the question.
  final bool isAnswered;

  /// Whether the submitted response was correct, or `null` if pending.
  final bool? isCorrect;

  /// Currently selected vocabulary candidate word.
  final String? selectedOption;

  /// Creates a [ContextCluesEvidenceSentence] widget.
  const ContextCluesEvidenceSentence({
    super.key,
    required this.sentence,
    required this.color,
    required this.isCompact,
    required this.isAnswered,
    this.isCorrect,
    this.selectedOption,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = tokens?.textPrimary ?? (isDark ? Colors.white : AppColors.slate900);
    final parts = sentence.split("[TARGET]");

    final fontSize = isCompact ? 15.sp : 17.sp;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 28.w : 36.w,
        vertical: isCompact ? 12.h : 20.h,
      ),
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Text.rich(
            TextSpan(
              children: [
                _buildTextSpan(parts[0], textColor, fontSize),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: _buildTargetSlot(context, tokens, isDark, fontSize),
                ),
                if (parts.length > 1)
                  _buildTextSpan(parts[1], textColor, fontSize),
              ],
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ),
    );
  }

  TextSpan _buildTextSpan(String text, Color textColor, double fontSize) {
    return TextSpan(
      text: text,
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: fontSize,
        height: 1.6,
        color: textColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildTargetSlot(
    BuildContext context,
    AppColorTokens? tokens,
    bool isDark,
    double fontSize,
  ) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (isAnswered) {
      final successColor = tokens?.gameCorrect ?? Colors.green;
      final errorColor = tokens?.gameIncorrect ?? Colors.red;
      final slotColor = isCorrect == true ? successColor : errorColor;

      final answeredBlock = Container(
        margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
        decoration: BoxDecoration(
          color: slotColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: slotColor,
            width: 1.5,
          ),
        ),
        child: Text(
          selectedOption ?? "???",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: slotColor,
          ),
        ),
      );

      if (reduceMotion) return answeredBlock;
      return answeredBlock.animate().scale(
        duration: 350.ms,
        curve: Curves.easeOutBack,
      );
    }

    final slotPlaceholder = Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12.w : 18.w,
        vertical: 3.h,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Text(
        "______",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color.withValues(alpha: 0.6),
        ),
      ),
    );

    if (reduceMotion) return slotPlaceholder;

    return slotPlaceholder
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(
          duration: 2.seconds,
          color: color.withValues(alpha: 0.2),
        );
  }
}
