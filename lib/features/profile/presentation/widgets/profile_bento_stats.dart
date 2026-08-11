import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileBentoStats extends StatelessWidget {
  final UserEntity user;

  const ProfileBentoStats({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final xpProgress = (user.totalExp % 100) / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        _BentoWideCard(
          title: context.tr('profile.current_level_label', fallback: 'Current Level'),
          value: context.tr('profile.level_value', fallback: 'Lvl {0}', args: ['${user.level}']),
          subtitle: context.tr('profile.tap_view_rank_details', fallback: 'Tap to view rank details'),
          icon: Icons.workspace_premium_rounded,
          color: const Color(0xFF8B5CF6),
          onTap: () {
            di.sl<HapticService>().selection();
            context.push(AppRouter.levelRoute);
          },
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _StatPod(
                title: context.tr('profile.vowl_treasury', fallback: 'Vowl Treasury'),
                value: '${user.coins}',
                icon: Icons.paid_rounded,
                color: const Color(0xFF10B981),
                onTap: () => context.push(AppRouter.questCoinsRoute),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _StatPod(
                title: context.tr('profile.daily_streak', fallback: 'Daily Streak'),
                value: context.tr('profile.streak_days', fallback: '{0} Days', args: ['${user.currentStreak}']),
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => context.push(AppRouter.streakRoute),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        SizedBox(height: 16.h),
        _BentoWideCard(
          title: context.tr('profile.adventure_xp_label', fallback: 'Adventure XP'),
          value: context.tr('profile.total_experience', fallback: 'Total Experience: {0}', args: ['${user.totalExp}']),
          icon: Icons.auto_awesome_rounded,
          color: const Color(0xFF3B82F6),
          onTap: () {
            di.sl<HapticService>().selection();
            context.push(AppRouter.adventureXPRoute);
          },
          bottomContent: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: AutoSizeText(
                      context.tr(
                        'profile.progress_to_level',
                        fallback: 'Progress to next level',
                        args: ['${user.level + 1}'],
                      ),
                      maxLines: 1,
                      minFontSize: 6,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white38 : Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Text(
                    '${(xpProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10.h),
              LayoutBuilder(
                builder: (context, trackConstraints) {
                  final trackWidth = trackConstraints.maxWidth;
                  return Stack(
                    children: [
                      Container(
                        height: 10.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      AnimatedContainer(
                        duration: 800.ms,
                        height: 10.h,
                        width: trackWidth * xpProgress.clamp(0.0, 1.0),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }
}

class _BentoWideCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final Widget? bottomContent;

  const _BentoWideCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28.r),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        title,
                        maxLines: 1,
                        minFontSize: 8,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        value,
                        maxLines: 1,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2.h),
                        AutoSizeText(
                          subtitle!,
                          maxLines: 1,
                          minFontSize: 8,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white24 : Colors.black12,
                  size: 28.r,
                ),
              ],
            ),
            if (bottomContent != null) ...[
              SizedBox(height: 20.h),
              bottomContent!,
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPod extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _StatPod({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().selection();
        onTap();
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(20.w),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24.r),
              ),
              SizedBox(height: 12.h),
              AutoSizeText(
                value,
                maxLines: 1,
                minFontSize: 14,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 4.h),
              AutoSizeText(
                title,
                maxLines: 1,
                minFontSize: 8,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
