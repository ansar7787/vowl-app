import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

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
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
            childAspectRatio: 1.0,
          ),
          itemCount: options.length,
          itemBuilder: (context, index) {
            String emoji = '🖼️';
            if (index < optionEmojis.length) {
              emoji = optionEmojis[index];
            }
            return _buildOptionTile(index, options[index], emoji);
          },
        );
      },
    );
  }

  Widget _buildOptionTile(int index, String text, String emoji) {
    bool isSelected = selectedIndex == index;
    Color tileColor;
    Color borderColor;

    if (isAnswered && isSelected) {
      tileColor = isCorrectState == true
          ? Colors.greenAccent.withValues(alpha: 0.2)
          : Colors.redAccent.withValues(alpha: 0.2);
      borderColor = isCorrectState == true
          ? Colors.greenAccent
          : Colors.redAccent;
    } else if (isAnswered &&
        index == correctAnswerIndex &&
        isCorrectState == false) {
      tileColor = Colors.greenAccent.withValues(alpha: 0.2);
      borderColor = Colors.greenAccent;
    } else if (isSelected) {
      tileColor = color.withValues(alpha: 0.3);
      borderColor = color;
    } else {
      tileColor = color.withValues(alpha: 0.05);
      borderColor = color.withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTap: () {
        if (!isAnswered) {
          onSelect(index);
        }
      },
      child: GlassTile(
        padding: EdgeInsets.all(12.r),
        borderRadius: BorderRadius.circular(20.r),
        color: tileColor,
        border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  emoji,
                  style: TextStyle(fontSize: 48.r),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 8.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isAnswered && index == correctAnswerIndex
                      ? Colors.green.shade700
                      : isAnswered && isSelected && isCorrectState == false
                      ? Colors.red.shade700
                      : color,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
