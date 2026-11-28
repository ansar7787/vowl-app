import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';

/// Transition banner card briefly flashed between rounds (~1.2s)
/// to announce the upcoming round mechanic & instruction.
class ArenaRoundAnnounceCard extends StatelessWidget {
  final int roundNumber;
  final int totalRounds;
  final ArenaMechanicType mechanic;
  final bool isDark;
  final bool isMidnight;

  const ArenaRoundAnnounceCard({
    super.key,
    required this.roundNumber,
    required this.totalRounds,
    required this.mechanic,
    required this.isDark,
    required this.isMidnight,
  });

  Color _accentForMechanic(ArenaMechanicType type) {
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

  @override
  Widget build(BuildContext context) {
    final accent = _accentForMechanic(mechanic);
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.slate800 : Colors.white);

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: accent.withValues(alpha: 0.55),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.25 : 0.14),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                '${context.tr('arena.round_announce', args: ['$roundNumber', '$totalRounds'], fallback: 'ROUND $roundNumber OF $totalRounds')} • ${mechanic.timerSeconds}s',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: accent,
                ),
              ),
            ),
            SizedBox(height: 14.h),
            Text(
              mechanic.icon,
              style: TextStyle(fontSize: 34.sp),
            ),
            SizedBox(height: 10.h),
            Text(
              context.tr(
                'arena.mechanic_${mechanic.key}',
                fallback: mechanic.displayName,
              ).toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              context.tr(
                'arena.mechanic_${mechanic.key}_instr',
                fallback: mechanic.instruction,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
