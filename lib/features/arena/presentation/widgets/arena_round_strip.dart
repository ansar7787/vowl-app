import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';

/// Animated round indicator strip positioned above each mechanic widget,
/// displaying the active round mechanic icon, name, and round progress.
class ArenaRoundStrip extends StatelessWidget {
  final ArenaChallenge challenge;
  final int currentRound;
  final int totalRounds;
  final bool isDark;

  const ArenaRoundStrip({
    super.key,
    required this.challenge,
    required this.currentRound,
    required this.totalRounds,
    required this.isDark,
  });

  Color _accentColor(ArenaMechanicType type) {
    switch (type) {
      case ArenaMechanicType.wordSnap:
        return AppColors.indigo500;
      case ArenaMechanicType.typeDuel:
        return AppColors.emerald500;
      case ArenaMechanicType.rapidJudge:
        return AppColors.blue500;
      case ArenaMechanicType.sentenceBuild:
        return AppColors.violet500;
      case ArenaMechanicType.spotError:
        return AppColors.rose500;
      case ArenaMechanicType.mcq:
        return AppColors.teal500;
      case ArenaMechanicType.speedSpell:
      case ArenaMechanicType.voiceDuel:
        return AppColors.amber500;
    }
  }

  IconData _iconData(ArenaMechanicType type) {
    switch (type) {
      case ArenaMechanicType.wordSnap:
        return LucideIcons.zap;
      case ArenaMechanicType.typeDuel:
        return LucideIcons.keyboard;
      case ArenaMechanicType.rapidJudge:
        return LucideIcons.checkSquare;
      case ArenaMechanicType.sentenceBuild:
        return LucideIcons.puzzle;
      case ArenaMechanicType.spotError:
        return LucideIcons.target;
      case ArenaMechanicType.mcq:
        return LucideIcons.helpCircle;
      case ArenaMechanicType.speedSpell:
        return LucideIcons.trophy;
      case ArenaMechanicType.voiceDuel:
        return LucideIcons.mic;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mechanic = challenge.mechanic;
    final accentColor = _accentColor(mechanic);
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
        key: ValueKey<String>('${mechanic.key}_$currentRound'),
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
                Icon(_iconData(mechanic), size: 12.sp, color: accentColor),
                SizedBox(width: 5.w),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${mechanic.icon} ${context.tr('arena.mechanic_${mechanic.key}', fallback: mechanic.displayName).toUpperCase()}',
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
                context.tr(
                  'arena.round_announce',
                  args: ['$currentRound', '$totalRounds'],
                  fallback: 'ROUND $currentRound OF $totalRounds',
                ),
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
