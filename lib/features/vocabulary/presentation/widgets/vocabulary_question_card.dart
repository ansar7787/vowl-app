import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/themes/vocab_level_theme.dart';
import 'package:auto_size_text/auto_size_text.dart';

class VocabularyQuestionCard extends StatelessWidget {
  final VocabularyQuest quest;
  final VocabLevelTheme? theme;
  final bool isDark;

  const VocabularyQuestionCard({
    super.key,
    required this.quest,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryColor =
        theme?.primaryColor ?? Theme.of(context).colorScheme.primary;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);

    // Cached once — avoids repeated null-coalescing and toUpperCase on rebuild.
    final String displayWord = quest.word ?? quest.prompt ?? 'Quest';
    final String instruction = quest.instruction.toUpperCase();

    final compositeLabel =
        '$instruction. $displayWord'
        '${quest.sentence != null ? ". ${quest.sentence}" : ""}';

    return Semantics(
      label: compositeLabel,
      // FIX: excludeSemantics: true prevents screen readers from announcing
      // both this composite label AND each individual child Text widget,
      // which would cause the content to be read twice.
      excludeSemantics: true,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AutoSizeText(
              instruction,
              textAlign: TextAlign.center,
              maxLines: 2,
              minFontSize: 8,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 12.h),
            // softWrap + maxLines guards against RenderFlex on long words.
            AutoSizeText(
              displayWord,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 3,
              minFontSize: 14,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            if (quest.sentence != null) ...[
              SizedBox(height: 12.h),
              AutoSizeText(
                quest.sentence!,
                textAlign: TextAlign.center,
                maxLines: 5,
                minFontSize: 10,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  color: textColor.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
