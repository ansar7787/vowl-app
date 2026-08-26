import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Compact 4-item stats row that consolidates the old HomeQuickStats (3 items)
/// and CommandPod vaultOnly (3 items) into a single unified row.
///
/// Shows: 🔥 Streak | 💰 Coins | 🏆 Badges | ⭐ Level
/// Each tile is tappable to navigate to its detail screen.
class UnifiedStatsRow extends StatelessWidget {
  final UserEntity user;
  final int? globalRank;

  const UnifiedStatsRow({super.key, required this.user, this.globalRank});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.streak', fallback: 'Streak'),
            value: '${user.currentStreak}',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFF97316),
            route: AppRouter.streakRoute,
            delay: 0,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.coins', fallback: 'Coins'),
            value: _formatNumber(user.coins),
            icon: Icons.paid_rounded,
            color: const Color(0xFF10B981),
            route: AppRouter.questCoinsRoute,
            delay: 80,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.badges', fallback: 'Badges'),
            value: '${user.badges.length}',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFF59E0B),
            route: AppRouter.trophyRoomRoute,
            delay: 160,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.level_label', fallback: 'Level'),
            value: '${user.level}',
            icon: Icons.star_rounded,
            color: const Color(0xFF6366F1),
            route: AppRouter.levelRoute,
            delay: 240,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String route,
    required int delay,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: '$label: $value',
      child: ScaleButton(
        onTap: () => context.push(route),
        child: GlassTile(
          borderRadius: BorderRadius.circular(20.r),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
          child: ExcludeSemantics(
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(7.r),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 16.r),
                  ),
                  SizedBox(height: 6.h),
                  AutoSizeText(
                    value,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    minFontSize: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2.h),
                  AutoSizeText(
                    label,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 8.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white38 : Colors.black45,
                      letterSpacing: 0.8,
                    ),
                    maxLines: 1,
                    minFontSize: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.12, end: 0);
  }
}
