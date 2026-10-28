import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
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
import 'package:vowl/core/theme/app_colors.dart';

/// Compact 4-item stats row that consolidates the old HomeQuickStats (3 items)
/// and CommandPod vaultOnly (3 items) into a single unified row.
///
/// Shows: 🔥 Streak | 💰 Coins | 🏆 Badges | ⭐ Level / Rank
/// Each tile is tappable to navigate to its detail screen. Supports shimmer
/// placeholders for initial feed loading and background rank resolution.
class UnifiedStatsRow extends StatelessWidget {
  /// Current authenticated [user] entity. May be null in shimmer mode.
  final UserEntity? user;

  /// Current global leaderboard rank position, or `null`.
  final int? globalRank;

  /// Whether the entire 4-card stats row is in a loading/shimmer state.
  final bool isLoading;

  /// Whether leaderboard rank calculation is currently in flight.
  final bool isRankLoading;

  /// Creates a [UnifiedStatsRow] for [user] with optional [globalRank].
  const UnifiedStatsRow({
    super.key,
    required UserEntity this.user,
    this.globalRank,
    this.isLoading = false,
    this.isRankLoading = false,
  });

  /// Shimmer placeholder constructor for pre-load and skeleton states.
  const UnifiedStatsRow.shimmer({
    super.key,
  })  : user = null,
        globalRank = null,
        isLoading = true,
        isRankLoading = true;

  @override
  Widget build(BuildContext context) {
    if (isLoading || user == null) {
      return Row(
        children: [
          Expanded(
            child: _buildShimmerTile(
              context,
              color: IllustrationColors.warmOrange,
              labelWidth: 36.w,
              valueWidth: 26.w,
              delay: 0,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildShimmerTile(
              context,
              color: AppColors.emerald500,
              labelWidth: 32.w,
              valueWidth: 34.w,
              delay: 80,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildShimmerTile(
              context,
              color: AppColors.amber500,
              labelWidth: 38.w,
              valueWidth: 22.w,
              delay: 160,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _buildShimmerTile(
              context,
              color: AppColors.indigo500,
              labelWidth: 28.w,
              valueWidth: 28.w,
              delay: 240,
            ),
          ),
        ],
      );
    }

    final currentUser = user!;

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.streak', fallback: 'STREAK'),
            value: '${currentUser.currentStreak}',
            icon: Icons.local_fire_department_rounded,
            color: IllustrationColors.warmOrange,
            route: AppRouter.streakRoute,
            delay: 0,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.coins', fallback: 'COINS'),
            value: _formatNumber(currentUser.coins),
            icon: Icons.paid_rounded,
            color: AppColors.emerald500,
            route: AppRouter.questCoinsRoute,
            delay: 80,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.badges', fallback: 'BADGES'),
            value: '${currentUser.badges.length}',
            icon: Icons.emoji_events_rounded,
            color: AppColors.amber500,
            route: AppRouter.trophyRoomRoute,
            delay: 160,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: _buildStatTile(
            context,
            label: context.tr('home.rank_label', fallback: 'Rank'),
            value: globalRank != null ? '#$globalRank' : '—',
            icon: Icons.public_rounded,
            color: AppColors.indigo500,
            route: AppRouter.leaderboardRoute,
            delay: 240,
            isLoadingValue: isRankLoading,
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

  Widget _buildShimmerTile(
    BuildContext context, {
    required Color color,
    required double labelWidth,
    required double valueWidth,
    required int delay,
  }) {
    return GlassTile(
      borderRadius: BorderRadius.circular(20.r),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
      blur: 0,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ShimmerLoading.circular(width: 28.r, height: 28.r),
            SizedBox(height: 6.h),
            ShimmerLoading.rounded(
              width: valueWidth,
              height: 14.h,
              borderRadius: 4.r,
            ),
            SizedBox(height: 5.h),
            ShimmerLoading.rounded(
              width: labelWidth,
              height: 8.h,
              borderRadius: 3.r,
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: delay.ms, duration: 400.ms)
        .slideY(begin: 0.12, end: 0);
  }

  Widget _buildStatTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String route,
    required int delay,
    bool isLoadingValue = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final valueWidget = isLoadingValue
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            child: ShimmerLoading.rounded(
              width: 30.w,
              height: 14.h,
              borderRadius: 4.r,
            ),
          )
        : AutoSizeText(
            value,
            key: ValueKey(value),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.slate900,
              height: 1.1,
            ),
            maxLines: 1,
            minFontSize: 10,
            overflow: TextOverflow.ellipsis,
          );

    return Semantics(
          button: true,
          label: '$label: $value',
          child: ScaleButton(
            onTap: () => context.push(route),
            child: GlassTile(
              borderRadius: BorderRadius.circular(20.r),
              padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 4.w),
              blur: 0,
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: valueWidget,
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
