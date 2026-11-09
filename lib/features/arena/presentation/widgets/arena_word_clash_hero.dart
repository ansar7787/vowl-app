import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// 1. WORD CLASH ⚡: Instant Speed Target Card
class ArenaWordClashHero extends StatelessWidget {
  static final RegExp _quoteRegex = RegExp(r'"([^"]+)"');

  final ArenaQuestion q;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const ArenaWordClashHero({
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
    final lower = q.question.toLowerCase();
    final isAntonym = lower.contains('opposite') || lower.contains('antonym');
    final accentColor = isAntonym ? AppColors.amber500 : AppColors.indigo500;

    final quoteMatch = _quoteRegex.firstMatch(q.question);
    final targetWord = quoteMatch?.group(1);

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
        children: [
          if (targetWord != null) ...[
            Text(
              isAntonym
                  ? 'SELECT THE DIRECT OPPOSITE OF:'
                  : 'SELECT THE CLOSEST SYNONYM TO:',
              softWrap: true,
              style: TextStyle(
                fontSize: 11.sp,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w700,
                color: textSecondary,
              ),
            ),
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  targetWord.toUpperCase(),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ] else ...[
            Text(
              q.question,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
