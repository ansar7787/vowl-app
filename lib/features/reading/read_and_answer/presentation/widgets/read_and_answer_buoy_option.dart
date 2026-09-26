import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color064e3b = Color(0xFF064E3B);
  static const Color colord1fae5 = Color(0xFFD1FAE5);
  static const Color color34d399 = Color(0xFF34D399);
  static const Color color059669 = Color(0xFF059669);
  static const Color color7f1d1d = Color(0xFF7F1D1D);
  static const Color colorfee2e2 = Color(0xFFFEE2E2);
  static const Color colorf87171 = Color(0xFFF87171);
  static const Color colordc2626 = Color(0xFFDC2626);
}

class ReadAndAnswerBuoyOption extends StatelessWidget {
  final int index;
  final String text;
  final bool isCorrectOption;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedIndex;
  final VoidCallback onTap;

  const ReadAndAnswerBuoyOption({
    super.key,
    required this.index,
    required this.text,
    required this.isCorrectOption,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedIndex,
    required this.onTap,
  });

  // Alphabet labels for options — covers up to 8 options gracefully.
  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];

  String get _letter =>
      index < _letters.length ? _letters[index] : '${index + 1}';

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    final bool isSelected = selectedIndex == index;

    // Computed ONCE and shared between visual state logic and semantic label.
    final bool showAsCorrect = isAnswered && isCorrectOption;
    final bool showAsWrong = isAnswered && isSelected && !isCorrectOption;

    // ---------------------------------------------------------------------------
    // Visual tokens
    // ---------------------------------------------------------------------------
    final Color cardBg;
    final Color borderCol;
    final Color iconCol;
    final IconData iconData;

    if (showAsCorrect) {
      cardBg = isDark ? _LocalPalette.color064e3b : _LocalPalette.colord1fae5;
      borderCol = AppColors.emerald500;
      iconCol = isDark ? _LocalPalette.color34d399 : _LocalPalette.color059669;
      iconData = Icons.check_circle_rounded;
    } else if (showAsWrong) {
      cardBg = isDark ? _LocalPalette.color7f1d1d : _LocalPalette.colorfee2e2;
      borderCol = AppColors.red500;
      iconCol = isDark ? _LocalPalette.colorf87171 : _LocalPalette.colordc2626;
      iconData = Icons.cancel_rounded;
    } else if (isSelected) {
      cardBg = isDark
          ? color.withValues(alpha: 0.15)
          : color.withValues(alpha: 0.08);
      borderCol = color;
      iconCol = color;
      iconData = Icons.radio_button_checked_rounded;
    } else {
      cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;
      borderCol = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05);
      iconCol = isDark ? Colors.white30 : Colors.black26;
      iconData = Icons.radio_button_off_rounded;
    }

    // ---------------------------------------------------------------------------
    // Semantic label — screen readers hear full context without looking at UI.
    // ---------------------------------------------------------------------------
    final String semanticLabel;
    if (showAsCorrect) {
      semanticLabel = 'Option $_letter: $text. Correct answer.';
    } else if (showAsWrong) {
      semanticLabel = 'Option $_letter: $text. Incorrect.';
    } else if (isSelected) {
      semanticLabel = 'Option $_letter: $text. Selected.';
    } else {
      semanticLabel = 'Option $_letter: $text.';
    }

    final animDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: Semantics(
        label: semanticLabel,
        button: !isAnswered, // Not interactive once answered
        selected: isSelected,
        enabled: !isAnswered,
        // excludeSemantics prevents the child Row/Icon/Text from producing
        // duplicate announcements — the wrapper label covers everything.
        excludeSemantics: true,
        child: ScaleButton(
          onTap: onTap,
          child: AnimatedContainer(
            duration: animDuration,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: borderCol, width: 2),
              boxShadow: isSelected && !isAnswered
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.02),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: animDuration,
                  // ExcludeSemantics: icon is decorative; label above covers state.
                  child: ExcludeSemantics(
                    child: Icon(
                      iconData,
                      color: iconCol,
                      size: 22.r,
                      key: ValueKey<IconData>(iconData),
                    ),
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.slate800,
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
