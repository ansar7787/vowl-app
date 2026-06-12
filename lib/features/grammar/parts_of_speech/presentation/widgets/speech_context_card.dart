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
          child: Text(
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
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
      ),
    );
  }
}
