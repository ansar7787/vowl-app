import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

class SoundImageMatchGrid extends StatelessWidget {
  final List<String> options;
  final List<String> optionEmojis;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final Function(int) onSelect;

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
    bool isSelected = selectedIndex == index;
    Color tileColor;
    Color borderColor;

    final tokens = Theme.of(context).extension<AppColorTokens>();
    final Color modernCorrect = tokens?.gameCorrect ?? AppColors.gameCorrect;
    final Color modernIncorrect = tokens?.gameIncorrect ?? AppColors.gameIncorrect;

    if (isAnswered && isSelected) {
      tileColor = isCorrectState == true
          ? modernCorrect.withValues(alpha: 0.15)
          : modernIncorrect.withValues(alpha: 0.15);
      borderColor = isCorrectState == true ? modernCorrect : modernIncorrect;
    } else if (isAnswered &&
        index == correctAnswerIndex &&
        isCorrectState == false) {
      tileColor = modernCorrect.withValues(alpha: 0.15);
      borderColor = modernCorrect;
    } else if (isSelected) {
      tileColor = color.withValues(alpha: 0.25);
      borderColor = color;
    } else {
      tileColor = color.withValues(alpha: 0.08);
      borderColor = Colors.white.withValues(alpha: 0.5);
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
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: tileColor,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: borderColor.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 110.h),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    emoji,
                    key: Key('sound_image_match_emoji_$index'),
                    style: TextStyle(fontSize: 48.r),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    text.toUpperCase(),
                    key: Key('sound_image_match_text_$index'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w800,
                      color: isAnswered && index == correctAnswerIndex
                          ? modernCorrect
                          : isAnswered && isSelected && isCorrectState == false
                          ? modernIncorrect
                          : color,
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
