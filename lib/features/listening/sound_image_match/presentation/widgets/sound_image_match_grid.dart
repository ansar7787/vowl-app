import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/presentation/widgets/scale_button.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _buildOptionTile(0, options[0], _getEmoji(0)),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _buildOptionTile(1, options[1], _getEmoji(1)),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            if (options.length > 2)
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildOptionTile(2, options[2], _getEmoji(2)),
                    ),
                    SizedBox(width: 16.w),
                    if (options.length > 3)
                      Expanded(
                        child: _buildOptionTile(3, options[3], _getEmoji(3)),
                      )
                    else
                      const Spacer(),
                  ],
                ),
              ),
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

  Widget _buildOptionTile(int index, String text, String emoji) {
    bool isSelected = selectedIndex == index;
    Color tileColor;
    Color borderColor;

    final Color modernCorrect = const Color(0xFF00C896);
    final Color modernIncorrect = const Color(0xFFFF5E5E);

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

    return ScaleButton(
      onTap: isAnswered ? null : () => onSelect(index),
      scaleDown: 0.95,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: borderColor, width: isSelected ? 2.5 : 1.5),
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
                  style: TextStyle(fontSize: 48.r),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                Text(
                  text.toUpperCase(),
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
    );
  }
}
