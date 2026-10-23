import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

/// Column containing conclusion choice cards with evaluation feedback.
class ReadingConclusionOptions extends StatelessWidget {
  /// Candidate conclusion statements.
  final List<String> options;

  /// The authoritative correct conclusion.
  final String correct;

  /// Theme accent color applied to options.
  final Color primaryColor;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Index of the chosen conclusion card, or null if unselected.
  final int? selectedIndex;

  /// Whether the answer has been evaluated.
  final bool isAnswered;

  /// Callback invoked when a conclusion choice is tapped.
  final Function(int, String) onOptionTap;

  /// Creates a [ReadingConclusionOptions] widget.
  const ReadingConclusionOptions({
    super.key,
    required this.options,
    required this.correct,
    required this.primaryColor,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onOptionTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;

    return Column(
      children: List.generate(options.length, (index) {
        final optionText = options[index];
        final isSelected = selectedIndex == index;
        final isCorrect =
            isAnswered &&
            optionText.trim().toLowerCase() == correct.trim().toLowerCase();
        final isWrong = isAnswered && isSelected && !isCorrect;

        return _OptionCard(
          key: ValueKey(optionText),
          optionText: optionText,
          index: index,
          isSelected: isSelected,
          isCorrect: isCorrect,
          isWrong: isWrong,
          primaryColor: primaryColor,
          isDark: isDark,
          isAnswered: isAnswered,
          tokens: tokens,
          onTap: () {
            if (!isAnswered) {
              onOptionTap(index, optionText);
            }
          },
        );
      }),
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String optionText;
  final int index;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _OptionCard({
    super.key,
    required this.optionText,
    required this.index,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.tokens,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color borderColor;
    Color badgeBgColor;
    Color badgeTextColor;
    Color textColor;

    final optionLetter = String.fromCharCode(65 + widget.index);

    if (widget.isCorrect) {
      bgColor = widget.tokens.gameCorrect
          .withValues(alpha: widget.isDark ? 0.16 : 0.10);
      borderColor = widget.tokens.gameCorrect;
      badgeBgColor = widget.tokens.gameCorrect;
      badgeTextColor = Colors.white;
      textColor = widget.isDark ? Colors.white : const Color(0xFF1E293B);
    } else if (widget.isWrong) {
      bgColor = widget.tokens.gameIncorrect
          .withValues(alpha: widget.isDark ? 0.16 : 0.10);
      borderColor = widget.tokens.gameIncorrect;
      badgeBgColor = widget.tokens.gameIncorrect;
      badgeTextColor = Colors.white;
      textColor = widget.isDark ? Colors.white : const Color(0xFF1E293B);
    } else if (widget.isSelected) {
      bgColor = widget.primaryColor
          .withValues(alpha: widget.isDark ? 0.14 : 0.08);
      borderColor = widget.primaryColor;
      badgeBgColor = widget.primaryColor;
      badgeTextColor = Colors.white;
      textColor = widget.isDark ? Colors.white : const Color(0xFF1E293B);
    } else {
      bgColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.04)
          : Colors.white;
      borderColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.12)
          : const Color(0xFFE2E8F0);
      badgeBgColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFF1F5F9);
      badgeTextColor = widget.isDark
          ? Colors.white70
          : const Color(0xFF64748B);
      textColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.90)
          : const Color(0xFF1E293B);
    }

    final opacity = (widget.isAnswered && !widget.isCorrect && !widget.isWrong)
        ? 0.65
        : 1.0;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: opacity,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) {
            if (!widget.isAnswered) {
              setState(() => _isPressed = true);
            }
          },
          onTapUp: (_) {
            setState(() => _isPressed = false);
          },
          onTapCancel: () {
            setState(() => _isPressed = false);
          },
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.98 : 1.0,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutQuad,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isCorrect ||
                            widget.isWrong ||
                            widget.isSelected)
                        ? borderColor.withValues(alpha: 0.12)
                        : (widget.isDark
                            ? Colors.black.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.03)),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28.r,
                    height: 28.r,
                    margin: EdgeInsets.only(top: 1.h),
                    decoration: BoxDecoration(
                      color: badgeBgColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      optionLetter,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: badgeTextColor,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      widget.optionText,
                      textAlign: TextAlign.start,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.5.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.42,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (widget.isCorrect || widget.isWrong) ...[
                    SizedBox(width: 8.w),
                    Padding(
                      padding: EdgeInsets.only(top: 3.h),
                      child: Icon(
                        widget.isCorrect
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: widget.isCorrect
                            ? widget.tokens.gameCorrect
                            : widget.tokens.gameIncorrect,
                        size: 20.r,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
