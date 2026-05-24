import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  quest.instruction.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: theme.primaryColor,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            quest.word ?? quest.prompt ?? "Quest",
            textAlign: TextAlign.center,
            style: GoogleFonts.fredoka(
              fontSize: 28.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          if (quest.sentence != null) ...[
            SizedBox(height: 12.h),
            Text(
              quest.sentence!,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15.sp,
                color: (isDark ? Colors.white : Colors.black87).withValues(
                  alpha: 0.7,
                ),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
