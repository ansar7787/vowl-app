import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

class ReadingInferenceOption extends StatelessWidget {
  final int index;
  final String text;
  final String correct;
  final Color color;
  final bool isDark;
  final int? selectedIndex;
  final bool isAnswered;
  final double clarity;
  final VoidCallback onTap;

  const ReadingInferenceOption({
    super.key,
    required this.index,
    required this.text,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedIndex,
    required this.isAnswered,
    required this.clarity,
    required this.onTap,
  });

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  String get _letter =>
      index < _letters.length ? _letters[index] : '${index + 1}';

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bool isSelected = selectedIndex == index;
    final bool isCorrect =
        isAnswered && text.trim().toLowerCase() == correct.trim().toLowerCase();
    final bool isWrong = isAnswered && isSelected && !isCorrect;
    final bool isDisabled = clarity < 0.3 && !isAnswered;

    // Visual styles
    final Color bgColor;
    final Color borderColor;
    final Color badgeBg;
    final Color badgeTextColor;

    if (isCorrect) {
      bgColor = tokens.gameCorrect.withValues(alpha: 0.15);
      borderColor = tokens.gameCorrect.withValues(alpha: 0.6);
      badgeBg = tokens.gameCorrect;
      badgeTextColor = Colors.white;
    } else if (isWrong) {
      bgColor = tokens.gameIncorrect.withValues(alpha: 0.15);
      borderColor = tokens.gameIncorrect.withValues(alpha: 0.6);
      badgeBg = tokens.gameIncorrect;
      badgeTextColor = Colors.white;
    } else if (isSelected) {
      bgColor = color.withValues(alpha: 0.12);
      borderColor = color.withValues(alpha: 0.6);
      badgeBg = color;
      badgeTextColor = Colors.white;
    } else {
      bgColor = isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03);
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.black.withValues(alpha: 0.06);
      badgeBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : color.withValues(alpha: 0.08);
      badgeTextColor = isDark ? Colors.white70 : color;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Semantics(
        button: true,
        selected: isSelected,
        enabled: !isDisabled && !isAnswered,
        label: 'Option $_letter: $text',
        child: AbsorbPointer(
          absorbing: isDisabled,
          child: ScaleButton(
            onTap: onTap,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: isDisabled ? 0.4 : 1.0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || isCorrect || isWrong ? 2.w : 1.2.w,
                  ),
                  boxShadow: [
                    if (isCorrect || isWrong || isSelected)
                      BoxShadow(
                        color: borderColor.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    // Option letter or outcome icon badge
                    ExcludeSemantics(
                      child: Container(
                        width: 28.r,
                        height: 28.r,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: badgeBg,
                          shape: BoxShape.circle,
                        ),
                        child: isCorrect
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 16.r,
                              )
                            : isWrong
                            ? Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16.r,
                              )
                            : Text(
                                _letter,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                  color: badgeTextColor,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(width: 14.w),
                    // Option text
                    Expanded(
                      child: Text(
                        text,
                        softWrap: true,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.5.sp,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          height: 1.35,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
