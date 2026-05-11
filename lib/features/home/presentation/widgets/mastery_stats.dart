import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:go_router/go_router.dart';

class MasteryStats extends StatelessWidget {
  const MasteryStats({super.key, required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildInteractiveStatCard(
          context,
          'TOTAL EXPERIENCE',
          '${user.totalExp}',
          'VIEW XP HISTORY',
          Icons.auto_fix_high_rounded,
          const Color(0xFF2563EB),
          () => context.push(AppRouter.adventureXPRoute),
        ),
        SizedBox(height: 12.h),
        _buildInteractiveStatCard(
          context,
          'GLOBAL RANK',
          'Level ${user.level}',
          'VIEW LEADERBOARD',
          Icons.emoji_events_rounded,
          const Color(0xFFF59E0B),
          () => context.push(AppRouter.leaderboardRoute),
        ),
        SizedBox(height: 12.h),
        _buildInteractiveStatCard(
          context,
          'VOWL COINS',
          '${user.coins}',
          'VISIT COIN REWARDS',
          Icons.monetization_on_rounded,
          const Color(0xFF10B981),
          () => context.push(AppRouter.questCoinsRoute),
        ),
      ],
    );
  }

  Widget _buildInteractiveStatCard(
    BuildContext context,
    String label,
    String value,
    String subLabel,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        padding: EdgeInsets.all(20.r),
        borderRadius: BorderRadius.circular(28.r),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Icon(icon, color: color, size: 28.r),
            ),
            SizedBox(width: 18.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                        subLabel,
                        style: GoogleFonts.outfit(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white38 : Colors.black38,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10.r,
                        color: isDark ? Colors.white12 : Colors.black12,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
