import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

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
                  LucideIcons.calendar,
                  size: 14.r,
                  color: isDark ? Colors.blueAccent : Colors.blue,
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  context.tr(
                    'streak.activity_heatmap',
                    fallback: 'ACTIVITY HEATMAP',
                  ),
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
                        Text(
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
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ).animate().shimmer(duration: 2000.ms, delay: 1000.ms),
                ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(
              'streak.heatmap_description',
              fallback:
                  'Complete a quest and earn XP to light your daily flame.',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 20.h),
          _buildModernCalendar(context),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildModernCalendar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = Localizations.localeOf(context).toString();
    final now = DateTime.now();
    final startOfHeatmap = now.subtract(const Duration(days: 6));
    final history = user.dailyXpHistory;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = startOfHeatmap.add(Duration(days: index));
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        final xp = history[dateKey] ?? 0;
        final isToday =
            day.day == now.day &&
            day.month == now.month &&
            day.year == now.year;

        final bool isSameLoginDay =
            user.lastLoginDate != null &&
            user.lastLoginDate!.day == now.day &&
            user.lastLoginDate!.month == now.month &&
            user.lastLoginDate!.year == now.year;

        final nowAtMidnight = DateTime(now.year, now.month, now.day);
        final dayAtMidnight = DateTime(day.year, day.month, day.day);
        final daysAgo = nowAtMidnight.difference(dayAtMidnight).inDays;

        bool isStreakDay = false;
        if (daysAgo >= 0) {
          if (isSameLoginDay) {
            // User played today, so streak counts from today (daysAgo = 0) backwards
            isStreakDay = daysAgo < user.currentStreak;
          } else {
            // User hasn't played today yet, so streak counts from yesterday (daysAgo = 1) backwards
            isStreakDay = daysAgo > 0 && daysAgo <= user.currentStreak;
          }
        }

        final bool isPlayed = xp > 0 || isStreakDay;
        final bool isFrozen = xp == 0 && isStreakDay && daysAgo > 0;
        final isFuture = day.isAfter(now);

        // BUG FIX: truncating the locale-formatted weekday name to its
        // first character only makes sense for Latin-script abbreviations
        // (M/T/W...). For CJK locales it produces a meaningless or
        // ambiguous fragment (e.g. Chinese abbreviates every weekday
        // starting with "周"), and combining surrogate-pair characters
        // could even be cut mid-codepoint. Showing the full short-form
        // weekday name (still compact: 2-3 chars in nearly every
        // supported language) inside a width-safe Flexible+FittedBox is
        // correct for every script.
        final dayName = DateFormat('E', locale).format(day);

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
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dayName,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        color: isToday
                            ? Colors.blueAccent
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.35)),
                        letterSpacing: 1,
                      ),
                      maxLines: 1,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildDayIndicator(
                    context,
                    isPlayed,
                    isToday,
                    isFuture,
                    xp,
                    isFrozen,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                      color: isToday ? Colors.blueAccent : null,
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDayIndicator(
    BuildContext context,
    bool isPlayed,
    bool isToday,
    bool isFuture,
    int xp,
    bool isFrozen,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine the gradient based on whether it's frozen or played
    Gradient? dayGradient;
    if (!isFuture && isPlayed) {
      if (isFrozen) {
        dayGradient = const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF3B82F6)],
        ); // Ice Blue
      } else {
        dayGradient = const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEF4444)],
        ); // Fire Orange
      }
    }

    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        gradient: dayGradient,
        color: isFuture
            ? (isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.05))
            : (!isPlayed
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05))
                  : null),
        shape: BoxShape.circle,
        border: (isToday && !isFuture)
            ? Border.all(color: Colors.blueAccent, width: 2)
            : (isFuture
                  ? Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
                    )
                  : (isPlayed
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
                          ))),
        boxShadow: (!isFuture && isPlayed)
            ? [
                BoxShadow(
                  color: isFrozen
                      ? const Color(0xFF38BDF8).withValues(alpha: 0.3)
                      : const Color(0xFFF97316).withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ]
            : (isToday && !isFuture
                  ? [
                      BoxShadow(
                        color: Colors.blueAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : null),
      ),
      child: Center(
        child: isFuture
            ? null
            : (isPlayed
                  ? Icon(
                      isFrozen ? LucideIcons.snowflake : LucideIcons.flame,
                      color: Colors.white,
                      size: isFrozen ? 16.r : 18.r,
                    )
                  : (isToday
                        ? Icon(
                                LucideIcons.circle,
                                color: Colors.blueAccent,
                                size: 8.r,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.2, 1.2),
                                duration: 1.seconds,
                              )
                        : null)),
      ),
    );
  }
}
