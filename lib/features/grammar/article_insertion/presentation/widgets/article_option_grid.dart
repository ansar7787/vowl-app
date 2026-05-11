import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

class ArticleOptionGrid extends StatefulWidget {
  final GameQuest quest;
  final int? selectedOptionIndex;
  final bool isDark;
  final bool isMidnight;
  final ThemeResult theme;
  final Function(int) onOptionSelected;

  const ArticleOptionGrid({
    super.key,
    required this.quest,
    this.selectedOptionIndex,
    required this.isDark,
    this.isMidnight = false,
    required this.theme,
    required this.onOptionSelected,
  });

  @override
  State<ArticleOptionGrid> createState() => _ArticleOptionGridState();
}

class _ArticleOptionGridState extends State<ArticleOptionGrid> {
  late List<int> _shuffledIndices;
  late String _questId;

  @override
  void initState() {
    super.initState();
    _questId = widget.quest.id;
    _generateIndices();
  }

  @override
  void didUpdateWidget(covariant ArticleOptionGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quest.id != _questId) {
      _questId = widget.quest.id;
      _generateIndices();
    }
  }

  void _generateIndices() {
    final count = widget.quest.options?.length ?? 0;
    _shuffledIndices = List.generate(count, (index) => index);
    _shuffledIndices.shuffle();
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.w,
        mainAxisSpacing: 16.h,
        childAspectRatio: 2.5,
      ),
      itemCount: widget.quest.options?.length ?? 0,
      itemBuilder: (context, index) {
        final originalIndex = _shuffledIndices[index];
        final isSelected = widget.selectedOptionIndex == originalIndex;
        final isCorrect = originalIndex == widget.quest.correctAnswerIndex;
        final showResult = widget.selectedOptionIndex != null;

        Color? cardColor;
        if (showResult) {
          if (isCorrect) {
            cardColor = const Color(0xFF10B981);
          } else if (isSelected) {
            cardColor = const Color(0xFFF43F5E);
          }
        }

        return ScaleButton(
              onTap: () => widget.onOptionSelected(originalIndex),
              child: GlassTile(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                borderRadius: BorderRadius.circular(20.r),
                color: cardColor?.withValues(alpha: 0.8),
                borderColor: isSelected && showResult
                    ? Colors.white54
                    : widget.theme.primaryColor.withValues(alpha: 0.1),
                child: Center(
                  child: Text(
                    widget.quest.options![originalIndex],
                    style: GoogleFonts.outfit(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: (isSelected || showResult)
                          ? (isCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF43F5E))
                          : (widget.isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ),
            )
            .animate()
            .fadeIn(delay: (index * 80).ms)
            .slideY(begin: 0.2, curve: Curves.easeOutBack);
      },
    );
  }
}
