import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordLinkingSentenceField extends StatelessWidget {
  final List<String> words;
  final String correctPair;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedNodeIndex;
  final Function(int, String, List<String>) onNodeTap;

  const WordLinkingSentenceField({
    super.key,
    required this.words,
    required this.correctPair,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedNodeIndex,
    required this.onNodeTap,
  });

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (int i = 0; i < words.length; i++) {
      children.add(_buildWordChip(words[i], color, isDark));

      if (i < words.length - 1) {
        children.add(_buildLinkNode(i, correctPair, words, color, isDark));
      }
    }

    return Container(
      width: 342.w,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Center(
        child: Wrap(
          spacing: 8.w,
          runSpacing: 12.h,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: children,
        ),
      ),
    );
  }

  Widget _buildWordChip(String word, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Text(
        word.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildLinkNode(
    int index,
    String correctPair,
    List<String> words,
    Color color,
    bool isDark,
  ) {
    final bool isSelected = selectedNodeIndex == index;

    // Check if this node represents the correct linking pair
    String selectedPair = "${words[index]} ${words[index + 1]}";
    final bool correct =
        selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

    Color nodeColor = color.withValues(alpha: 0.5);
    if (isAnswered) {
      if (correct) {
        nodeColor = Colors.greenAccent;
      } else if (isSelected) {
        nodeColor = Colors.redAccent;
      } else {
        nodeColor = color.withValues(alpha: 0.15); // dim unselected ones
      }
    } else if (isSelected) {
      nodeColor = color;
    }

    return ScaleButton(
      onTap: () => onNodeTap(index, correctPair, words),
      child:
          Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected || (isAnswered && correct)
                      ? nodeColor.withValues(alpha: 0.2)
                      : isDark
                          ? color.withValues(alpha: 0.15)
                          : color.withValues(alpha: 0.08),
                  border: Border.all(
                      color: isAnswered && !correct && !isSelected
                          ? Colors.transparent
                          : isSelected || isAnswered
                              ? nodeColor
                              : color.withValues(alpha: 0.4),
                      width: 2),
                  boxShadow: isSelected || (isAnswered && correct)
                      ? [
                          BoxShadow(
                            color: nodeColor.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Icon(
                      isSelected || isAnswered
                          ? Icons.link_rounded
                          : Icons.add_link_rounded,
                      size: 22.r,
                      color: nodeColor),
                ),
              )
              .animate(
                onPlay: (c) => c.repeat(reverse: true),
                target: isAnswered ? 0 : 1,
              )
              .shimmer(
                duration: 2.seconds,
                color: isDark ? Colors.white34 : color.withValues(alpha: 0.3),
              )
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 1.seconds,
                curve: Curves.easeInOut,
              ),
    );
  }
}
