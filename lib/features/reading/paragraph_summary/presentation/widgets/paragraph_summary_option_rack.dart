import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ParagraphSummaryOptionRack extends StatelessWidget {
  final List<String> options;
  final String correctAnswer;
  final Color color;
  final bool isDark;
  final String? selectedOption;
  final bool isAnswered;
  final Function(String) onTapOption;

  const ParagraphSummaryOptionRack({
    super.key,
    required this.options,
    required this.correctAnswer,
    required this.color,
    required this.isDark,
    required this.selectedOption,
    required this.isAnswered,
    required this.onTapOption,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    const optionLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(options.length, (index) {
        final opt = options[index];
        final isSelected = selectedOption == opt;
        final isCorrect = isAnswered &&
            opt.trim().toLowerCase() == correctAnswer.trim().toLowerCase();
        final isWrong = isAnswered && isSelected && !isCorrect;
        final label = index < optionLabels.length
            ? optionLabels[index]
            : '${index + 1}';

        return _SummaryOptionCard(
          key: ValueKey(opt),
          label: label,
          text: opt,
          isSelected: isSelected,
          isCorrect: isCorrect,
          isWrong: isWrong,
          isAnswered: isAnswered,
          themeColor: color,
          isDark: isDark,
          tokens: tokens,
          onTap: () => onTapOption(opt),
        );
      }),
    );
  }
}

class _SummaryOptionCard extends StatefulWidget {
  final String label;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool isAnswered;
  final Color themeColor;
  final bool isDark;
  final AppColorTokens tokens;
  final VoidCallback onTap;

  const _SummaryOptionCard({
    super.key,
    required this.label,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.isAnswered,
    required this.themeColor,
    required this.isDark,
    required this.tokens,
    required this.onTap,
  });

  @override
  State<_SummaryOptionCard> createState() => _SummaryOptionCardState();
}

class _SummaryOptionCardState extends State<_SummaryOptionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Color cardColor;
    Color borderColor;
    Color badgeBg;
    Color badgeTextColor;
    Widget? badgeIcon;

    if (widget.isCorrect) {
      cardColor = widget.tokens.gameCorrect
          .withValues(alpha: widget.isDark ? 0.15 : 0.1);
      borderColor = widget.tokens.gameCorrect;
      badgeBg = widget.tokens.gameCorrect;
      badgeTextColor = Colors.white;
      badgeIcon = Icon(Icons.check_rounded, color: Colors.white, size: 16.r);
    } else if (widget.isWrong) {
      cardColor = widget.tokens.gameIncorrect
          .withValues(alpha: widget.isDark ? 0.15 : 0.1);
      borderColor = widget.tokens.gameIncorrect;
      badgeBg = widget.tokens.gameIncorrect;
      badgeTextColor = Colors.white;
      badgeIcon = Icon(Icons.close_rounded, color: Colors.white, size: 16.r);
    } else if (widget.isSelected) {
      cardColor = widget.themeColor
          .withValues(alpha: widget.isDark ? 0.15 : 0.08);
      borderColor = widget.themeColor;
      badgeBg = widget.themeColor;
      badgeTextColor = Colors.white;
    } else {
      cardColor =
          widget.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
      borderColor = widget.isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08);
      badgeBg = widget.isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);
      badgeTextColor = widget.isDark ? Colors.white70 : Colors.black54;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) {
          if (!widget.isAnswered) setState(() => _isPressed = true);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.isAnswered ? null : widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOutQuad,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: borderColor,
                width: (widget.isSelected || widget.isCorrect || widget.isWrong)
                    ? 2.0
                    : 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (widget.isSelected || widget.isCorrect || widget.isWrong)
                          ? borderColor.withValues(alpha: 0.15)
                          : (widget.isDark
                              ? Colors.black.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.04)),
                  blurRadius:
                      (widget.isSelected || widget.isCorrect || widget.isWrong)
                          ? 10
                          : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28.r,
                  height: 28.r,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: badgeIcon ??
                        Text(
                          widget.label,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: badgeTextColor,
                          ),
                        ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: Text(
                      widget.text,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.45,
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.92)
                            : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
