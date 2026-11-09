import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// 4. CONTEXT BLITZ 🧠: Deductive Reasoning Dossier
class ArenaContextBlitzHero extends StatelessWidget {
  final ArenaQuestion q;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const ArenaContextBlitzHero({
    super.key,
    required this.q,
    required this.state,
    required this.isDark,
    required this.isMidnight,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    const accentColor = AppColors.blue500; // Sky Blue
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return Container(
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.search, size: 12.sp, color: accentColor),
              SizedBox(width: 6.w),
              Expanded(
                child: Text(
                  'ANALYZE CONTEXT CLUES & INFER THE MISSING MEANING:',
                  softWrap: true,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    letterSpacing: 0.9,
                    fontWeight: FontWeight.w700,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: _buildRichClueText(q.question, textPrimary, accentColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRichClueText(String text, Color textPrimary, Color accentColor) {
    final regex = RegExp(r'("[^"]+"|\*{2}[^*]+\*{2}|_{3,})');
    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return Text(
        text,
        textAlign: TextAlign.left,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 14.5.sp,
          fontWeight: FontWeight.w600,
          height: 1.45,
          color: textPrimary,
        ),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w600,
              height: 1.45,
              color: textPrimary,
            ),
          ),
        );
      }
      final matchedText = match.group(0)!;
      final cleanText = matchedText.replaceAll('**', '');
      spans.add(
        TextSpan(
          text: cleanText,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w900,
            height: 1.45,
            color: accentColor,
          ),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: textPrimary,
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.left,
      softWrap: true,
    );
  }
}
