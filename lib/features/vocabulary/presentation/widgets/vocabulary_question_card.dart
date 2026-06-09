import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class VocabularyQuestionCard extends StatelessWidget {
  final VocabularyQuest quest;
  final dynamic theme;
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
        (theme?.primaryColor as Color?) ??
        Theme.of(context).colorScheme.primary;

    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.7);

    final String displayWord = quest.word ?? quest.prompt ?? 'Quest';

    return Semantics(
      label:
          '${quest.instruction}. $displayWord${quest.sentence != null ? ". ${quest.sentence}" : ""}',
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
            // No more redundant Row wrapper
            Text(
              quest.instruction.toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: 2,
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
            // softWrap + maxLines prevents RenderFlex on long words
            Text(
              displayWord,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 3,
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
              Text(
                quest.sentence!,
                textAlign: TextAlign.center,
                maxLines: 5,
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
