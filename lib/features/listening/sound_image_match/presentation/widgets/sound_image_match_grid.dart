import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

/// Two-by-two grid of illustrated image and word tiles for matching sounds.
class SoundImageMatchGrid extends StatelessWidget {
  /// Option word labels.
  final List<String> options;

  /// Option emoji graphics.
  final List<String> optionEmojis;

  /// Index of the correct option.
  final int correctAnswerIndex;

  /// Theme accent color.
  final Color color;

  /// Whether the answer has been locked in and evaluated.
  final bool isAnswered;

  /// Verification status (`true` if correct, `false` if wrong, `null` if pending).
  final bool? isCorrectState;

  /// Currently selected option index, if any.
  final int? selectedIndex;

  /// Callback when an image tile is tapped.
  final Function(int) onSelect;

  /// Creates a [SoundImageMatchGrid] options layout.
  const SoundImageMatchGrid({
    super.key,
    required this.options,
    required this.optionEmojis,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (options.isEmpty) return const SizedBox.shrink();

    if (options.length == 1) {
      return Center(
        child: SizedBox(
          width: 160.w,
          child: _buildOptionTile(context, 0, options[0], _getEmoji(0)),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildOptionTile(context, 0, options[0], _getEmoji(0)),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildOptionTile(context, 1, options[1], _getEmoji(1)),
                  ),
                ],
              ),
            ),
            if (options.length > 2) ...[
              SizedBox(height: 16.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildOptionTile(context, 2, options[2], _getEmoji(2)),
                    ),
                    SizedBox(width: 16.w),
                    if (options.length > 3)
                      Expanded(
                        child: _buildOptionTile(context, 3, options[3], _getEmoji(3)),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  String _getEmoji(int index) {
    if (index < optionEmojis.length) {
      return optionEmojis[index];
    }
    return '🖼️';
  }

  Widget _buildOptionTile(BuildContext context, int index, String text, String emoji) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final Color modernCorrect = tokens?.gameCorrect ?? AppColors.gameCorrect;
    final Color modernIncorrect = tokens?.gameIncorrect ?? AppColors.gameIncorrect;

    bool isSelected = selectedIndex == index;
    Color tileColor;
    Color borderColor;
    Color textColor;

    if (isAnswered && isSelected) {
      final isCorrect = isCorrectState == true;
      tileColor = (isCorrect ? modernCorrect : modernIncorrect).withValues(alpha: isDark ? 0.22 : 0.12);
      borderColor = isCorrect ? modernCorrect : modernIncorrect;
      textColor = isCorrect ? modernCorrect : modernIncorrect;
    } else if (isAnswered &&
        index == correctAnswerIndex &&
        isCorrectState == false) {
      tileColor = modernCorrect.withValues(alpha: isDark ? 0.22 : 0.12);
      borderColor = modernCorrect;
      textColor = modernCorrect;
    } else if (isSelected) {
      tileColor = color.withValues(alpha: isDark ? 0.25 : 0.15);
      borderColor = color;
      textColor = color;
    } else {
      tileColor = isDark
          ? color.withValues(alpha: 0.08)
          : Colors.white;
      borderColor = isDark
          ? color.withValues(alpha: 0.25)
          : color.withValues(alpha: 0.18);
      textColor = isDark
          ? Colors.white
          : const Color(0xFF1E293B);
    }

    return Semantics(
      label: text,
      button: true,
      excludeSemantics: true,
      child: ScaleButton(
        key: Key('sound_image_match_option_$index'),
        onTap: isAnswered ? null : () => onSelect(index),
        scaleDown: 0.95,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? borderColor : Colors.black)
                    .withValues(alpha: isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 112.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    key: Key('sound_image_match_emoji_$index'),
                    style: TextStyle(fontSize: 42.r),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    text.toUpperCase(),
                    key: Key('sound_image_match_text_$index'),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      height: 1.25,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
