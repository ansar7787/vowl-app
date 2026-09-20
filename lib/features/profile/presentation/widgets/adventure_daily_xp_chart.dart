import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color818cf8 = Color(0xFF818CF8);
}

class AdventureDailyXpChart extends StatelessWidget {
  final Map<String, int> history;

  const AdventureDailyXpChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    int maxXP = 100;
    final last7DaysXP = List.generate(7, (index) {
      final date = startOfWeek.add(Duration(days: index));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final xp = history[dateKey] ?? 0;
      if (xp > maxXP) maxXP = xp;
      return xp;
    });

    final weeklyTotal = last7DaysXP.fold(0, (total, xp) => total + xp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with weekly total ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.r),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr(
                  'adventure.daily_xp_history',
                  fallback: 'DAILY XP HISTORY',
                ),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white38 : AppColors.slate500,
                  letterSpacing: 1.5,
                ),
              ),
              if (weeklyTotal > 0)
                Text(
                  '${NumberFormat('#,###').format(weeklyTotal)} XP',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.indigo500,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 16.r),

        // ── Chart or empty state ──
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.r),
          child: GlassTile(
            padding: EdgeInsets.all(20.r),
            borderRadius: BorderRadius.circular(32.r),
            child: weeklyTotal == 0
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.r),
                      child: Text(
                        context.tr(
                          'adventure.chart_empty',
                          fallback: 'Complete a quest to start tracking!',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final xp = last7DaysXP[index];
                      final heightFactor = (xp / maxXP).clamp(0.05, 1.0);
                      final barDate = startOfWeek.add(Duration(days: index));
                      final isToday =
                          barDate.year == now.year &&
                          barDate.month == now.month &&
                          barDate.day == now.day;
                      final dayLabel = DateFormat.E(
                        Localizations.localeOf(context).toString(),
                      ).format(barDate);

                      return Semantics(
                        label:
                            '$dayLabel: $xp XP${isToday ? ', ${context.tr('adventure.today', fallback: 'today')}' : ''}',
                        child: Column(
                          children: [
                            // ── XP value label ──
                            SizedBox(
                              height: 16.r,
                              child: xp > 0
                                  ? FittedBox(
                                      child: Text(
                                        '$xp',
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 9.sp,
                                          fontWeight: FontWeight.w800,
                                          color: isToday
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : (isDark
                                                    ? Colors.white54
                                                    : Colors.black45),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                            SizedBox(height: 2.r),
                            // ── Bar ──
                            Container(
                              height: 80.r,
                              width: 36.r,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              alignment: Alignment.bottomCenter,
                              child: FractionallySizedBox(
                                heightFactor: heightFactor,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: xp > 0
                                          ? isToday
                                                ? [
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    _LocalPalette.color818cf8,
                                                  ]
                                                : [
                                                    Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withValues(alpha: 0.6),
                                                  ]
                                          : [
                                              Colors.grey.withValues(
                                                alpha: 0.1,
                                              ),
                                              Colors.grey.withValues(
                                                alpha: 0.2,
                                              ),
                                            ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    boxShadow: xp > 0
                                        ? [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(
                                                    alpha: isToday ? 0.5 : 0.3,
                                                  ),
                                              blurRadius: isToday ? 12 : 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.r),
                            // ── Day label ──
                            Text(
                              dayLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: isToday
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                                color: isToday
                                    ? AppColors.indigo500
                                    : (isDark
                                          ? Colors.white38
                                          : AppColors.slate500),
                              ),
                            ),
                            // ── Today dot ──
                            if (isToday)
                              Container(
                                margin: EdgeInsets.only(top: 4.r),
                                width: 4.r,
                                height: 4.r,
                                decoration: const BoxDecoration(
                                  color: AppColors.indigo500,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
        ),
      ],
    );
  }
}
