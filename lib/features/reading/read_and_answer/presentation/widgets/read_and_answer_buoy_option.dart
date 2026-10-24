import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color064e3b = Color(0xFF064E3B);
  static const Color colord1fae5 = Color(0xFFD1FAE5);
  static const Color color059669 = Color(0xFF059669);
  static const Color color7f1d1d = Color(0xFF7F1D1D);
  static const Color colorfee2e2 = Color(0xFFFEE2E2);
  static const Color colordc2626 = Color(0xFFDC2626);
}

/// Interactive buoy card widget displaying a candidate answer option.
class ReadAndAnswerBuoyOption extends StatelessWidget {
  /// Zero-based option index determining option letter.
  final int index;

  /// The candidate answer text.
  final String text;

  /// Whether this option represents the correct answer.
  final bool isCorrectOption;

  /// Theme accent color applied to cards.
  final Color color;

  /// Whether the active theme is in dark mode.
  final bool isDark;

  /// Whether the quest has been evaluated.
  final bool isAnswered;

  /// The currently chosen option index, or null if unselected.
  final int? selectedIndex;

  /// Callback invoked when this buoy option is tapped.
  final VoidCallback onTap;

  /// Creates a [ReadAndAnswerBuoyOption] widget.
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
    final Color badgeBg;
    final Color badgeTextColor;

    if (showAsCorrect) {
      cardBg = isDark ? _LocalPalette.color064e3b : _LocalPalette.colord1fae5;
      borderCol = AppColors.emerald500;
      badgeBg = isDark ? _LocalPalette.color059669 : AppColors.emerald500;
      badgeTextColor = Colors.white;
    } else if (showAsWrong) {
      cardBg = isDark ? _LocalPalette.color7f1d1d : _LocalPalette.colorfee2e2;
      borderCol = AppColors.red500;
      badgeBg = isDark ? _LocalPalette.colordc2626 : AppColors.red500;
      badgeTextColor = Colors.white;
    } else if (isSelected) {
      cardBg = isDark
          ? color.withValues(alpha: 0.15)
          : color.withValues(alpha: 0.08);
      borderCol = color;
      badgeBg = color;
      badgeTextColor = Colors.white;
    } else {
      cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
      borderCol = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.06);
      badgeBg = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : color.withValues(alpha: 0.08);
      badgeTextColor = isDark ? Colors.white70 : color;
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

    Widget buildCard({bool isDraggingFeedback = false}) {
      return AnimatedContainer(
        duration: animDuration,
        padding: EdgeInsets.symmetric(
          horizontal: isDraggingFeedback ? 16.w : 16.w,
          vertical: isDraggingFeedback ? 12.h : 14.h,
        ),
        decoration: BoxDecoration(
          color: isDraggingFeedback
              ? (isDark ? const Color(0xFF1E293B) : Colors.white)
              : cardBg,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDraggingFeedback ? color : borderCol,
            width: (isSelected || isDraggingFeedback) ? 2.0 : 1.5,
          ),
          boxShadow: (isSelected && !isAnswered) || isDraggingFeedback
              ? [
                  BoxShadow(
                    color: color.withValues(
                      alpha: isDraggingFeedback ? 0.35 : 0.15,
                    ),
                    blurRadius: isDraggingFeedback ? 16 : 8,
                    offset: Offset(0, isDraggingFeedback ? 4 : 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize:
              isDraggingFeedback ? MainAxisSize.min : MainAxisSize.max,
          children: [
            // Letter badge or status icon
            ExcludeSemantics(
              child: AnimatedContainer(
                duration: animDuration,
                width: 28.r,
                height: 28.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                child: showAsCorrect
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 16.r,
                      )
                    : showAsWrong
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
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.slate800,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Semantics(
        label: semanticLabel,
        button: !isAnswered, // Not interactive once answered
        selected: isSelected,
        enabled: !isAnswered,
        excludeSemantics: true,
        child: Draggable<int>(
          key: ValueKey('read_and_answer_option_$index'),
          data: index,
          maxSimultaneousDrags: isAnswered ? 0 : 1,
          feedback: Material(
            color: Colors.transparent,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: buildCard(isDraggingFeedback: true),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.25,
            child: buildCard(),
          ),
          child: ScaleButton(
            key: ValueKey('read_and_answer_option_tap_$index'),
            onTap: isAnswered ? () {} : onTap,
            child: buildCard(),
          ),
        ),
      ),
    );
  }
}
