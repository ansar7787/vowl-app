import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class StreakCalendar extends StatelessWidget {
  final UserEntity user;

  const StreakCalendar({
    super.key,
    required this.user,
  });

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
                  color: (isDark ? Colors.blueAccent : Colors.blue).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.calendar,
                  size: 14.r,
                  color: isDark ? Colors.blueAccent : Colors.blue,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'ACTIVITY HEATMAP',
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black.withValues(alpha: 0.6),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          _buildModernCalendar(context),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.05);
  }

  Widget _buildModernCalendar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final startOfHeatmap = now.subtract(const Duration(days: 6));
    final history = user.dailyXpHistory;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final day = startOfHeatmap.add(Duration(days: index));
        final dateKey = DateFormat('yyyy-MM-dd').format(day);
        final xp = history[dateKey] ?? 0;
        final isToday = day.day == now.day && day.month == now.month && day.year == now.year;

        final bool isSameLoginDay = user.lastLoginDate != null &&
            user.lastLoginDate!.day == now.day &&
            user.lastLoginDate!.month == now.month &&
            user.lastLoginDate!.year == now.year;

        final bool isPlayed = xp > 0 || (isToday && isSameLoginDay && user.currentStreak > 0);
        final isFuture = day.isAfter(now);

        final dayName = DateFormat('E').format(day);
        final firstLetter = dayName.isNotEmpty ? dayName[0] : '';

        return Expanded(
          child: Column(
            children: [
              Text(
                firstLetter,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  color: isToday
                      ? Colors.blueAccent
                      : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.35)),
                  letterSpacing: 1,
                ),
              ),
              SizedBox(height: 10.h),
              _buildDayIndicator(context, isPlayed, isToday, isFuture, xp),
              SizedBox(height: 10.h),
              Text(
                '${day.day}',
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                  color: isToday ? Colors.blueAccent : null,
                ),
              ),
            ],
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
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 36.r,
      height: 36.r,
      decoration: BoxDecoration(
        gradient: (!isFuture && isPlayed)
            ? const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEF4444)])
            : null,
        color: isFuture
            ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05))
            : (!isPlayed
                ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                : null),
        shape: BoxShape.circle,
        border: (isToday && !isFuture)
            ? Border.all(color: Colors.blueAccent, width: 2)
            : (isFuture
                ? Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05))
                : (isPlayed
                    ? null
                    : Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05)))),
        boxShadow: (!isFuture && isPlayed)
            ? [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.3),
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
                ? Icon(LucideIcons.flame, color: Colors.white, size: 18.r)
                : (isToday
                    ? Icon(LucideIcons.circle, color: Colors.blueAccent, size: 8.r)
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 1.seconds)
                    : null)),
      ),
    );
  }
}
