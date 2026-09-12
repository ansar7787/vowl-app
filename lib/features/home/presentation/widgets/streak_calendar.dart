import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StreakCalendar extends StatelessWidget {
  final UserEntity user;

  const StreakCalendar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.blueAccent : Colors.blue).withValues(
                    alpha: 0.1,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.calendarDays,
                  size: 14.r,
                  color: isDark ? Colors.blueAccent : Colors.blue,
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: AutoSizeText(
                  context.tr('streak.this_week', fallback: 'THIS WEEK'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                  maxLines: 1,
                  minFontSize: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Spacer(),
              if (user.level >= 50)
                Tooltip(
                  message: context.tr(
                    'streak.protection_tooltip',
                    fallback:
                        'XP Level 50 Mastery: Permanent Streak Protection Active',
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.security_rounded,
                          color: const Color(0xFF10B981),
                          size: 12.r,
                        ),
                        SizedBox(width: 4.w),
                        AutoSizeText(
                          context.tr(
                            'streak.protected_badge',
                            fallback: 'PROTECTED',
                          ),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 9.sp,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF10B981),
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          minFontSize: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ).animate().shimmer(duration: 2000.ms, delay: 1000.ms),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              context.tr(
                'streak.heatmap_description',
                fallback: 'Earn XP to light your daily flame.',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          _buildModernCalendar(context),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  /// Determines whether [day] falls within the user's current streak window.
  static bool computeIsStreakDay({
    required DateTime day,
    required DateTime now,
    required DateTime? lastLoginDate,
    required int currentStreak,
  }) {
    final nowAtMidnight = DateTime(now.year, now.month, now.day);
    final dayAtMidnight = DateTime(day.year, day.month, day.day);
    final daysAgo = nowAtMidnight.difference(dayAtMidnight).inDays;
    if (daysAgo < 0) return false;

    final isSameLoginDay =
        lastLoginDate != null &&
        lastLoginDate.day == now.day &&
        lastLoginDate.month == now.month &&
        lastLoginDate.year == now.year;

    if (isSameLoginDay) {
      return daysAgo < currentStreak;
    } else {
      return daysAgo > 0 && daysAgo <= currentStreak;
    }
  }

  Widget _buildModernCalendar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final history = user.dailyXpHistory;

    // Calculate start: align to Monday of the current week
    final todayWeekday = now.weekday; // 1=Mon, 7=Sun
    final startDate = now.subtract(
      Duration(days: todayWeekday - 1),
    ); // This Monday

    // Day name headers
    final dayHeaders = List.generate(7, (i) {
      final d = startDate.add(Duration(days: i));
      return DateFormat('E', locale).format(d);
    });

    return Column(
      children: [
        // Day name headers
        Row(
          children: dayHeaders.map((name) {
            return Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.black.withValues(alpha: 0.4),
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 12.h),
        // 1 row of 7 days
        Row(
          children: List.generate(7, (dayOfWeek) {
            final day = startDate.add(Duration(days: dayOfWeek));
            final dateKey = DateFormat('yyyy-MM-dd').format(day);
            final xp = history[dateKey] ?? 0;
            final isToday =
                day.day == now.day &&
                day.month == now.month &&
                day.year == now.year;
            final isFuture = day.isAfter(now);

            final isStreakDay = computeIsStreakDay(
              day: day,
              now: now,
              lastLoginDate: user.lastLoginDate,
              currentStreak: user.currentStreak,
            );

            final bool isPlayed = xp > 0 || isStreakDay;
            final bool isFrozen = xp == 0 && isStreakDay && !isToday;

            final dayLabel = isFuture
                ? context.tr('streak.day_upcoming', fallback: 'Upcoming')
                : (isFrozen
                      ? context.tr(
                          'streak.day_frozen',
                          fallback: 'Streak freeze used',
                        )
                      : (isPlayed
                            ? context.tr(
                                'streak.day_completed',
                                fallback: 'Completed',
                              )
                            : (isToday
                                  ? context.tr(
                                      'streak.day_today_pending',
                                      fallback: "Today, not played yet",
                                    )
                                  : context.tr(
                                      'streak.day_missed',
                                      fallback: 'Missed',
                                    ))));

            return Expanded(
              child: Semantics(
                label:
                    '${DateFormat('EEEE, MMMM d', locale).format(day)}: $dayLabel',
                child: ExcludeSemantics(
                  child: _buildGridCell(
                    context,
                    isPlayed,
                    isToday,
                    isFuture,
                    xp,
                    isFrozen,
                    day.day,
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildGridCell(
    BuildContext context,
    bool isPlayed,
    bool isToday,
    bool isFuture,
    int xp,
    bool isFrozen,
    int dayNumber,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Gradient? dayGradient;
    if (!isFuture && isPlayed) {
      dayGradient = isFrozen
          ? const LinearGradient(colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)])
          : const LinearGradient(
              colors: [Color(0xFFF97316), Color(0xFFEF4444)],
            );
    }

    return Column(
      children: [
        Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            gradient: dayGradient,
            color: isFuture
                ? (isDark
                      ? Colors.white.withValues(alpha: 0.03)
                      : const Color(0xFFF1F5F9))
                : (!isPlayed
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFE2E8F0))
                      : null),
            shape: BoxShape.circle,
            border: (isToday && !isFuture)
                ? Border.all(color: Colors.blueAccent, width: 2)
                : null,
            boxShadow: (!isFuture && isPlayed)
                ? [
                    BoxShadow(
                      color: isFrozen
                          ? const Color(0xFF38BDF8).withValues(alpha: 0.25)
                          : const Color(0xFFF97316).withValues(alpha: 0.35),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isFuture
                ? null
                : (isPlayed
                      ? Icon(
                          isFrozen ? LucideIcons.snowflake : LucideIcons.flame,
                          color: Colors.white,
                          size: isFrozen ? 14.r : 16.r,
                        )
                      : (isToday
                            ? Icon(
                                LucideIcons.circle,
                                color: Colors.blueAccent,
                                size: 8.r,
                              ).animate().scale(
                                begin: const Offset(0.5, 0.5),
                                end: const Offset(1, 1),
                                duration: 800.ms,
                                curve: Curves.easeOutBack,
                              )
                            : null)),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '$dayNumber',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 9.sp,
            fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
            color: isToday
                ? Colors.blueAccent
                : (isFuture
                      ? (isDark
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.black.withValues(alpha: 0.2))
                      : null),
          ),
          maxLines: 1,
        ),
      ],
    );
  }
}
