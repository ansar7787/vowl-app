import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_colors.dart';

class GuessTitleLabelRack extends StatelessWidget {
  final List<String> labels;
  final String correct;
  final Color color;
  final bool isDark;
  final String? selectedTitle;
  final bool isAnswered;

  final ValueChanged<String>? onSelect;

  const GuessTitleLabelRack({
    super.key,
    required this.labels,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.selectedTitle,
    required this.isAnswered,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final correctColor = tokens?.gameCorrect ?? AppColors.gameCorrect;

    final screenWidth = MediaQuery.of(context).size.width;
    final totalPadding = 48.w;
    final spacing = 10.w;
    final availableWidth = screenWidth - totalPadding;
    // Standard uniform 2-column card width so every card is identical in size:
    final cardWidth = labels.length <= 1
        ? availableWidth
        : (availableWidth - spacing) / 2;

    return Wrap(
      spacing: spacing,
      runSpacing: 10.h,
      alignment: WrapAlignment.center,
      children: List.generate(labels.length, (index) {
        final label = labels[index];
        final isSelected = selectedTitle == label;
        final isCorrectOption =
            label.trim().toLowerCase() == correct.trim().toLowerCase();

        if (isAnswered) {
          if (isSelected) {
            return Visibility(
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              visible: false,
              child: SizedBox(
                width: cardWidth,
                child: _buildLabelCard(
                  label,
                  color,
                  isDark,
                  correctColor: correctColor,
                  enabled: false,
                ),
              ),
            );
          }
          if (!isCorrectOption) {
            return Opacity(
              opacity: 0.3,
              child: SizedBox(
                width: cardWidth,
                child: _buildLabelCard(
                  label,
                  color,
                  isDark,
                  correctColor: correctColor,
                  enabled: false,
                ),
              ),
            );
          }
        }

        return SizedBox(
          width: cardWidth,
          child: Draggable<String>(
            data: label,
            maxSimultaneousDrags: isAnswered ? 0 : 1,
            feedback: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: cardWidth,
                child: _buildLabelCard(
                  label,
                  color,
                  isDark,
                  correctColor: correctColor,
                  isFeedback: true,
                ),
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.35,
              child: _buildLabelCard(
                label,
                color,
                isDark,
                correctColor: correctColor,
              ),
            ),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isAnswered ? null : () => onSelect?.call(label),
              child: _buildLabelCard(
                label,
                color,
                isDark,
                correctColor: correctColor,
                isAnswered: isAnswered,
                isCorrectOption: isCorrectOption,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildLabelCard(
    String label,
    Color color,
    bool isDark, {
    required Color correctColor,
    bool isFeedback = false,
    bool enabled = true,
    bool isAnswered = false,
    bool isCorrectOption = false,
  }) {
    final showCorrect = isAnswered && isCorrectOption;

    Color bgColor;
    Color borderColor;

    if (showCorrect) {
      bgColor = correctColor.withValues(alpha: 0.12);
      borderColor = correctColor;
    } else if (isFeedback) {
      bgColor = isDark ? const Color(0xFF252A34) : Colors.white;
      borderColor = color;
    } else {
      bgColor = isDark ? const Color(0xFF1E222A) : Colors.white;
      borderColor = isDark
          ? Colors.white.withValues(alpha: 0.12)
          : Colors.black.withValues(alpha: 0.08);
    }

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 56.h),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: showCorrect
                ? correctColor.withValues(alpha: 0.2)
                : (isDark
                      ? Colors.black45
                      : Colors.black.withValues(alpha: 0.04)),
            blurRadius: isFeedback ? 16 : 6,
            offset: Offset(0, isFeedback ? 8 : 2),
          ),
        ],
        border: Border.all(
          color: borderColor,
          width: showCorrect || isFeedback ? 2 : 1.5,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: showCorrect
              ? correctColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF1E293B)),
        ),
      ),
    );
  }
}
