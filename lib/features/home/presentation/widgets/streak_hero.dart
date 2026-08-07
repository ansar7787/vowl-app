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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final streak = user.currentStreak;
    const color = Color(0xFFFF5F6D);

    final statusText = streak > 7
        ? context.tr('streak.status_on_fire', fallback: "YOU'RE ON FIRE!")
        : (streak > 0
              ? context.tr('streak.status_keep_going', fallback: 'KEEP GOING!')
              : context.tr(
                  'streak.status_start',
                  fallback: 'START YOUR STREAK!',
                ));

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
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 2.seconds,
                          curve: Curves.easeInOut,
                        )
                        .fadeIn(duration: 1.seconds),
                    Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [color, Color(0xFFFFC371)],
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
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          duration: 1200.ms,
                          curve: Curves.easeInOut,
                        ),
                  ],
                ),
                SizedBox(height: 20.h),
                Text(
                  "$streak",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 56.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    height: 1.0,
                  ),
                  maxLines: 1,
                ).animate().fadeIn().scale(duration: 600.ms),
                AutoSizeText(
                  context.tr('streak.day_streak_label', fallback: 'DAY STREAK'),
                  maxLines: 1,
                  minFontSize: 8,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: color,
                    letterSpacing: 4,
                  ),
                ),
                SizedBox(height: 16.h),
                Container(
                  constraints: BoxConstraints(maxWidth: double.infinity),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
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
                      SizedBox(width: 8.w),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
