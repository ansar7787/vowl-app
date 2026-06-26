import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

class StoryBuilderNarrativeTile extends StatelessWidget {
  final int index;
  final String sentence;
  final EliteMasteryQuest quest;
  final bool isHintVisible;
  final bool isDark;
  final ThemeResult theme;
  final bool isAnswered;
  final bool? isCorrect;

  const StoryBuilderNarrativeTile({
    super.key,
    required this.index,
    required this.sentence,
    required this.quest,
    required this.isHintVisible,
    required this.isDark,
    required this.theme,
    required this.isAnswered,
    this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final originalIndex = quest.sentences?.indexOf(sentence) ?? -1;
    final correctOrderIndex = quest.correctOrder?.indexOf(originalIndex) ?? -1;

    // Check if this specific tile is currently in its correct position
    bool isCorrectPosition = false;
    if (quest.correctOrder != null && quest.sentences != null) {
      final targetOriginalIndex = quest.correctOrder![index];
      if (originalIndex == targetOriginalIndex) {
        isCorrectPosition = true;
      }
    }

    Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.08);
    if (isCorrect == true) {
      borderColor = Colors.greenAccent;
    } else if (isCorrect == false) {
      borderColor = Colors.redAccent;
    } else if (isHintVisible && isCorrectPosition) {
      borderColor = theme.primaryColor;
    }

    return Semantics(
      // Additive label describing this tile's position and current
      // correctness — layered on top of (not replacing) the reorder
      // semantics ReorderableListView itself attaches around this whole
      // item, so screen-reader "move up"/"move down" actions keep working.
      label: _buildSemanticLabel(context, isCorrectPosition),
      child: GlassTile(
        borderRadius: BorderRadius.circular(22.r),
        padding: EdgeInsets.all(18.r),
        color: isDark ? Colors.black.withValues(alpha: 0.3) : null,
        border: Border.all(color: borderColor, width: 2),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor.withValues(alpha: 0.2),
                    theme.primaryColor.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: theme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? theme.primaryColor
                        : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                sentence,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (isHintVisible)
              Container(
                    margin: EdgeInsets.only(left: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB800), Color(0xFFFF9500)],
                      ),
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Text(
                      "#${correctOrderIndex + 1}",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  )
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut)
                  .shimmer(duration: 1500.ms, color: Colors.white54),
            SizedBox(width: 8.w),
            // FIX: paired with `buildDefaultDragHandles: false` on the
            // parent ReorderableListView. Without an explicit listener here,
            // disabling the default handle would leave nothing to grab;
            // wrapping just this icon keeps the same single, deliberate
            // drag affordance shown today instead of risking a second,
            // platform-added handle appearing next to it.
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_indicator_rounded,
                color: isDark ? Colors.white30 : Colors.black26,
                size: 26.r,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _buildSemanticLabel(BuildContext context, bool isCorrectPosition) {
    final position = context.tr(
      'games.semantic_story_tile_position',
      args: [(index + 1).toString()],
    );
    if (isCorrect == true) {
      return '$position $sentence. ${context.tr('games.semantic_correct_suffix')}';
    } else if (isCorrect == false) {
      return '$position $sentence. ${context.tr('games.semantic_incorrect_suffix')}';
    }
    return '$position $sentence';
  }
}
