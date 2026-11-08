import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/presentation/bloc/arena_duel_state.dart';

/// 2. PHRASE DUEL 🎯: Collocation & Idiom Puzzle
class ArenaPhraseDuelHero extends StatelessWidget {
  final ArenaQuestion q;
  final ArenaDuelState state;
  final bool isDark;
  final bool isMidnight;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  const ArenaPhraseDuelHero({
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
    final isIdiom = lower.contains('idiom') || lower.contains('mean');
    final isPhrasal = lower.contains('phrasal') || lower.contains('particle');
    final accentColor = isIdiom
        ? AppColors
              .teal500 // Cyan/Teal
        : (isPhrasal
              ? AppColors.violet500
              : AppColors.emerald500); // Purple or Emerald

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
          Text(
            isIdiom
                ? 'DECIPHER THE FIGURATIVE EXPRESSION:'
                : 'FIT THE NATURAL COLLOCATING PHRASE:',
            softWrap: true,
            style: TextStyle(
              fontSize: 10.5.sp,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
              color: textSecondary,
            ),
          ),
          SizedBox(height: 8.h),

          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: accentColor.withValues(alpha: 0.2)),
            ),
            child: Text(
              q.question,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                height: 1.4,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
