import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:auto_size_text/auto_size_text.dart';

class StreakHero extends StatelessWidget {
  final UserEntity user;

  const StreakHero({super.key, required this.user});

  static String _getTimeRemaining(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final difference = tomorrow.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    if (hours > 0) {
      return context.tr(
        'streak.time_remaining_hours',
        args: [hours.toString(), minutes.toString()],
        fallback: '${hours}h ${minutes}m left to keep your streak!',
      );
    }
    return context.tr(
      'streak.time_remaining_minutes',
      args: [minutes.toString()],
      fallback: '${minutes}m left to keep your streak!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = user.currentStreak;
    const color = Color(0xFFF97316);

    final now = DateTime.now();
    final hasPlayedToday =
        user.lastLoginDate != null &&
        user.lastLoginDate!.year == now.year &&
        user.lastLoginDate!.month == now.month &&
        user.lastLoginDate!.day == now.day;

    final String statusText;
    if (streak >= 30) {
      statusText = context.tr(
        'streak.status_legendary',
        fallback: 'LEGENDARY STREAK!',
      );
    } else if (streak >= 14) {
      statusText = context.tr(
        'streak.status_unstoppable',
        fallback: 'UNSTOPPABLE!',
      );
    } else if (streak > 7) {
      statusText = context.tr(
        'streak.status_on_fire',
        fallback: "YOU'RE ON FIRE!",
      );
    } else if (streak > 3) {
      statusText = context.tr(
        'streak.status_building_momentum',
        fallback: 'BUILDING MOMENTUM!',
      );
    } else if (streak > 0) {
      statusText = context.tr(
        'streak.status_keep_going',
        fallback: 'KEEP GOING!',
      );
    } else {
      statusText = context.tr(
        'streak.status_start',
        fallback: 'START YOUR STREAK!',
      );
    }

    return Semantics(
      label: context.tr(
        'streak.hero_summary_label',
        args: [streak.toString()],
        fallback: '$streak day streak. $statusText',
      ),
      child: GlassTile(
        padding: EdgeInsets.all(24.r),
        borderRadius: BorderRadius.circular(32.r),
        child: ExcludeSemantics(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                          width: 100.r,
                          height: 100.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 40,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .scale(
                          begin: const Offset(0.5, 0.5),
                          end: const Offset(1, 1),
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                        )
                        .fadeIn(duration: 800.ms),
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [color, Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.flame,
                        color: Colors.white,
                        size: 40.r,
                      ),
                    ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),
                  ],
                ),
                SizedBox(height: 24.h),
                Column(
                  children: [
                    Text(
                      '$streak',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 80.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ).animate().scale(
                      duration: 600.ms,
                      curve: Curves.easeOutBack,
                      delay: 200.ms,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      context.tr(
                        'streak.day_streak_label',
                        fallback: 'DAY STREAK',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: 4,
                      ),
                    ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                  ],
                ),
                SizedBox(height: 24.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.sparkles, color: color, size: 14.r),
                      SizedBox(width: 10.w),
                      Flexible(
                        child: AutoSizeText(
                          statusText,
                          maxLines: 1,
                          minFontSize: 8,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasPlayedToday && streak > 0) ...[
                  SizedBox(height: 8.h),
                  Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.alertTriangle,
                              color: Colors.amber,
                              size: 14.r,
                            ),
                            SizedBox(width: 10.w),
                            Flexible(
                              child: StreamBuilder(
                                stream: Stream.periodic(
                                  const Duration(minutes: 1),
                                ),
                                builder: (context, snapshot) {
                                  return AutoSizeText(
                                    _getTimeRemaining(context),
                                    maxLines: 1,
                                    minFontSize: 8,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.amber,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn()
                      .then()
                      .fade(begin: 1.0, end: 0.6, duration: 1500.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
