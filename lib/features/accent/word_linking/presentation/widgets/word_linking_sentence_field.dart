import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class WordLinkingSentenceField extends StatefulWidget {
  final List<String> words;
  final String correctPair;
  final String? linkingType;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final int? selectedNodeIndex;
  final Function(int, String, List<String>) onNodeTap;

  const WordLinkingSentenceField({
    super.key,
    required this.words,
    required this.correctPair,
    this.linkingType,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.selectedNodeIndex,
    required this.onNodeTap,
  });

  @override
  State<WordLinkingSentenceField> createState() =>
      _WordLinkingSentenceFieldState();
}

class _WordLinkingSentenceFieldState extends State<WordLinkingSentenceField> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];

    for (int i = 0; i < widget.words.length; i++) {
      children.add(
        _buildWordChip(widget.words[i], widget.color, widget.isDark),
      );

      if (i < widget.words.length - 1) {
        children.add(SizedBox(width: 8.w));
        children.add(
          _buildLinkNode(
            i,
            widget.correctPair,
            widget.words,
            widget.color,
            widget.isDark,
          ),
        );
        children.add(SizedBox(width: 8.w));
      }
    }

    return Container(
      key: const ValueKey('word_linking_sentence_field'),
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 500.w),
      decoration: BoxDecoration(
        color: widget.isDark
            ? AppColors.slate800.withValues(alpha: 0.5)
            : AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.isDark
              ? AppColors.slate700.withValues(alpha: 0.8)
              : AppColors.slate200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.isDark
                ? Colors.black.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: RawScrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          thumbColor: widget.color.withValues(alpha: 0.35),
          radius: Radius.circular(8.r),
          thickness: 3.h,
          child: Center(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordChip(String word, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : AppColors.slate200,
          width: 1.5,
        ),
      ),
      child: Text(
        word.toUpperCase(),
        softWrap: false,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: Theme.of(context).colorScheme.onSurface,
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
    final bool isSelected = widget.selectedNodeIndex == index;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    String selectedPair = "${words[index]} ${words[index + 1]}";
    final bool correct =
        selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

    Color nodeColor = color.withValues(alpha: 0.5);
    if (widget.isAnswered) {
      if (correct) {
        nodeColor = AppColors.gameCorrect;
      } else if (isSelected) {
        nodeColor = AppColors.gameIncorrect;
      } else {
        nodeColor = color.withValues(alpha: 0.15);
      }
    } else if (isSelected) {
      nodeColor = color;
    }

    Widget nodeContent = Container(
      width: 44.r,
      height: 44.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected || (widget.isAnswered && correct)
            ? nodeColor.withValues(alpha: 0.2)
            : isDark
            ? color.withValues(alpha: 0.15)
            : color.withValues(alpha: 0.08),
        border: Border.all(
          color: widget.isAnswered && !correct && !isSelected
              ? Colors.transparent
              : isSelected || widget.isAnswered
              ? nodeColor
              : color.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: isSelected || (widget.isAnswered && correct)
            ? [
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.4),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Center(
        child: widget.isAnswered && correct
            ? Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 24.r,
                    color: nodeColor,
                  ),
                  if (widget.linkingType != null)
                    Positioned(
                      top: -24.h,
                      child: Builder(
                        builder: (context) {
                          final badge = Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: nodeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6.r),
                              border: Border.all(
                                color: nodeColor.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Text(
                              _formatLinkingType(widget.linkingType!),
                              softWrap: false,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: nodeColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          );
                          if (reduceMotion) return badge;
                          return badge.animate().scale(
                            delay: 300.ms,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                          );
                        },
                      ),
                    ),
                ],
              )
            : Icon(
                isSelected || widget.isAnswered
                    ? Icons.link_rounded
                    : Icons.add_link_rounded,
                size: 22.r,
                color: nodeColor,
              ),
      ),
    );

    if (!reduceMotion && !widget.isAnswered) {
      nodeContent = nodeContent
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            duration: 2.seconds,
            color: isDark ? Colors.white38 : color.withValues(alpha: 0.3),
          )
          .scale(
            begin: const Offset(1, 1),
            end: const Offset(1.08, 1.08),
            duration: 1.seconds,
            curve: Curves.easeInOut,
          );
    }

    return ScaleButton(
      key: ValueKey('word_link_node_$index'),
      onTap: widget.isAnswered
          ? null
          : () => widget.onNodeTap(index, correctPair, words),
      child: nodeContent,
    );
  }

  String _formatLinkingType(String type) {
    switch (type) {
      case 'consonant_to_vowel':
        return 'C → V';
      case 'vowel_to_vowel':
        return 'V → V';
      case 'consonant_to_consonant':
        return 'C → C';
      default:
        return 'Link';
    }
  }
}
