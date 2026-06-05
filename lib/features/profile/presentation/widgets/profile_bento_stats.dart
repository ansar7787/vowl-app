import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class ProfileBentoStats extends StatelessWidget {
  final UserEntity user;

  const ProfileBentoStats({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildAdventureLevelCard(context),

        SizedBox(height: 16.h),

        Row(
          children: [
            Expanded(
              child: _buildStatPod(
                context: context,
                title: 'Vowl Treasury',
                value: '${user.coins}',
                icon: Icons.paid_rounded,
                color: const Color(0xFF10B981),
                onTap: () => context.push(AppRouter.questCoinsRoute),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildStatPod(
                context: context,
                title: 'Daily Streak',
                value: '${user.currentStreak} Days',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEF4444),
                onTap: () => context.push(AppRouter.streakRoute),
              ),
            ),
          ],
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

        SizedBox(height: 16.h),

        _buildAdventureXPCard(context).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
      ],
    );
  }

  Widget _buildAdventureLevelCard(BuildContext context) {
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
                    'CURRENT LEVEL',
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8B5CF6),
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Level ${user.level}',
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Tap to view rank details',
                    style: TextStyle(fontFamily: 'Outfit', 
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white38
                          : Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white24
                  : Colors.black12,
              size: 28.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdventureXPCard(BuildContext context) {
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
                        'ADVENTURE XP',
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B82F6),
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        '${user.totalExp} Total Experience',
                        style: TextStyle(fontFamily: 'Outfit', 
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
                    Text(
                      'PROGRESS TO LEVEL ${user.level + 1}',
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white38
                            : Colors.black38,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      '${(xpProgress * 100).toInt()}%',
                      style: TextStyle(fontFamily: 'Outfit', 
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Stack(
                  children: [
                    Container(
                      height: 10.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    AnimatedContainer(
                      duration: 800.ms,
                      height: 10.h,
                      width:
                          (MediaQuery.of(context).size.width - 96.w) *
                          xpProgress,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatPod({
    required BuildContext context,
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleButton(
      onTap: () {
        di.sl<HapticService>().light();
        onTap();
      },
      child: GlassTile(
        borderRadius: BorderRadius.circular(28.r),
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
            Text(
              title,
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 11.sp,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white38
                    : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
