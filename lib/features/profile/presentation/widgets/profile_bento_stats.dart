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

class ProfileBentoStats extends StatelessWidget {
  final UserEntity user;

  const ProfileBentoStats({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdventureLevelCard(user: user),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(
              child: _StatPod(
                title: context.tr(
                  'profile.vowl_treasury',
                  fallback: 'Vowl Treasury',
                ),
                value: '${user.coins}',
                icon: Icons.paid_rounded,
                color: const Color(0xFF10B981),
                onTap: () => context.push(AppRouter.questCoinsRoute),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _StatPod(
                title: context.tr(
                  'profile.daily_streak',
                  fallback: 'Daily Streak',
                ),
                value: context.tr(
                  'profile.streak_days',
                  fallback: 'Days',
                  args: ['${user.currentStreak}'],
                ),
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => context.push(AppRouter.streakRoute),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
        SizedBox(height: 16.h),
        _AdventureXPCard(
          user: user,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }
}

class _AdventureLevelCard extends StatelessWidget {
  final UserEntity user;

  const _AdventureLevelCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () => context.push(AppRouter.levelRoute),
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: const Color(0xFF8B5CF6),
                size: 32.r,
              ),
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr(
                      'profile.current_level_label',
                      fallback: 'Current Level',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    context.tr(
                      'profile.level_value',
                      fallback: 'Lvl',
                      args: ['${user.level}'],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    context.tr(
                      'profile.tap_view_rank_details',
                      fallback: 'Tap to view rank details',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
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
      ),
    );
  }
}

class _AdventureXPCard extends StatelessWidget {
  final UserEntity user;

  const _AdventureXPCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final xpProgress = (user.totalExp % 100) / 100;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ScaleButton(
      onTap: () => context.push(AppRouter.adventureXPRoute),
      child: GlassTile(
        borderRadius: BorderRadius.circular(32.r),
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: const Color(0xFF3B82F6),
                    size: 24.r,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(
                          'profile.adventure_xp_label',
                          fallback: 'Adventure XP',
                        ),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        context.tr(
                          'profile.total_experience',
                          fallback: 'Total Experience',
                          args: ['${user.totalExp}'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
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
            SizedBox(height: 20.h),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        context.tr(
                          'profile.progress_to_level',
                          fallback: 'Progress to next level',
                          args: ['${user.level + 1}'],
                        ),
                        maxLines: 1,
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
                // MAINTAINABILITY / CORRECTNESS FIX: the original computed
                // this bar's width as `(MediaQuery.of(context).size.width -
                // 96.w) * xpProgress`. The `96.w` magic number only "worked"
                // because it happened to match 2x the screen's outer
                // horizontal padding (in profile_screen.dart) plus 2x this
                // card's own padding - two values defined in two other
                // files. Any future change to either padding silently
                // breaks this bar's width with no compile error. It also
                // used the broad `MediaQuery.of(context).size`, which
                // rebuilds this whole widget on *any* MediaQuery change
                // (keyboard insets, orientation, text scale), not just
                // width changes.
                //
                // Fixed with `LayoutBuilder`, which reports the *actual*
                // width this widget was given by its real parent - no
                // magic numbers, no dependency on padding values defined
                // in other files, and no MediaQuery subscription at all.
                // The animation itself (duration/curve) is unchanged.
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
        di.sl<HapticService>().light();
        onTap();
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(28.r),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 20.r),
            ),
            SizedBox(height: 16.h),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                maxLines: 1,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
