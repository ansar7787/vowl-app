import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

/// Standalone animated indicator strip positioned above the hero card.
///
/// Features independent slide & fade transitions when the match discipline
/// or round advances, visually distinguishing match status from quiz content.
class ArenaDisciplineStrip extends StatelessWidget {
  final ArenaQuestion question;
  final int currentRound;
  final int totalRounds;
  final bool isDark;

  const ArenaDisciplineStrip({
    super.key,
    required this.question,
    required this.currentRound,
    required this.totalRounds,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final disc = question.discipline ?? 'word_clash';
    final lower = question.question.toLowerCase();

    final Color accentColor;
    final IconData icon;
    final String tagText;

    switch (disc) {
      case 'word_clash':
        final isAntonym =
            lower.contains('opposite') || lower.contains('antonym');
        accentColor = isAntonym ? AppColors.amber500 : AppColors.indigo500;
        icon = LucideIcons.zap;
        tagText = isAntonym ? 'WORD CLASH • ANTONYM' : 'WORD CLASH • SYNONYM';
        break;
      case 'phrase_duel':
        final isIdiom = lower.contains('idiom') || lower.contains('mean');
        final isPhrasal =
            lower.contains('phrasal') || lower.contains('particle');
        accentColor = isIdiom
            ? AppColors.teal500
            : (isPhrasal ? AppColors.violet500 : AppColors.emerald500);
        icon = LucideIcons.target;
        tagText = isIdiom
            ? 'PHRASE DUEL • IDIOM'
            : (isPhrasal
                  ? 'PHRASE DUEL • PHRASAL'
                  : 'PHRASE DUEL • COLLOCATION');
        break;
      case 'sentence_strike':
        accentColor = AppColors.rose500;
        icon = LucideIcons.flame;
        tagText = 'SENTENCE STRIKE • ACADEMIC';
        break;
      case 'context_blitz':
      default:
        accentColor = AppColors.blue500;
        icon = LucideIcons.brainCircuit;
        tagText = 'CONTEXT BLITZ • INFERENCE';
        break;
    }

    final textSecondary = isDark ? AppColors.slate400 : AppColors.slate500;

    return AnimatedSwitcher(
      duration: VowlMotion.fast,
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>('${question.discipline}_$currentRound'),
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.25),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12.sp, color: accentColor),
                SizedBox(width: 5.w),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    tagText,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'ROUND $currentRound OF $totalRounds',
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
