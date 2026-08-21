import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';

/// Displays the sentence or question context for the current quest.
///
/// The entrance animation is keyed on [quest] so it re-triggers whenever
/// the quest changes — without a key the animation only plays once on first
/// build and is skipped for subsequent quests.
class SpeechContextCard extends StatelessWidget {
  final GrammarQuest quest;
  final Color primaryColor;
  final bool isDark;
  final bool isCompact;

  const SpeechContextCard({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = quest.sentence ?? quest.question ?? 'Identify the function';
    final fontSize = quest.sentence != null
        ? (isCompact ? 15.sp : 20.sp)
        : (isCompact ? 13.sp : 16.sp);
    final fontWeight = quest.sentence != null
        ? FontWeight.w500
        : FontWeight.w600;

    return Semantics(
      label: content,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Container(
          key: ValueKey(quest.hashCode), // Re-animate when quest changes.
          padding: EdgeInsets.all(isCompact ? 14.r : 22.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  content,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: fontSize,
                    color: isDark ? Colors.white : Colors.black87,
                    height: 1.5,
                    fontWeight: fontWeight,
                  ),
                ),
                if (quest.transformations != null && quest.transformations!.isNotEmpty) ...[
                  SizedBox(height: 16.h),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: quest.transformations!.map((word) => Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
        ),
      );
  }
}
