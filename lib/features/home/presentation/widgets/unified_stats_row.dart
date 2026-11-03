import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Compact 4-item telemetry shelf on the home screen (The Apex Telemetry Shelf).
///
/// Consolidates high-frequency player metrics into a unified, high-status
/// cockpit cluster with accessible typography (>= 10.5sp):
/// - 🔥 Streak: Current consecutive days of practice. Routes to [AppRouter.streakRoute].
/// - 💰 Coins: Current wallet economy balance. Routes to [AppRouter.questCoinsRoute].
/// - 🏆 Badges: Total unlocked achievements count. Routes to [AppRouter.trophyRoomRoute].
/// - 🌐 Rank: Global leaderboard standing position. Routes to [AppRouter.leaderboardRoute].
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
      return _buildShimmerShelf(context);
    }

    final currentUser = user!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final shelfWidget = RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131A29) : Colors.white,
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF131A29), Color(0xFF0F1522)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(22.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTelemetryTile(
                context,
                label: context.tr('home.streak', fallback: 'STREAK'),
                value: '${currentUser.currentStreak}',
                icon: Icons.local_fire_department_rounded,
                color: IllustrationColors.warmOrange,
                route: AppRouter.streakRoute,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildTelemetryTile(
                context,
                label: context.tr('home.coins', fallback: 'COINS'),
                value: _formatNumber(currentUser.coins),
                icon: Icons.paid_rounded,
                color: AppColors.emerald500,
                route: AppRouter.questCoinsRoute,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildTelemetryTile(
                context,
                label: context.tr('home.badges', fallback: 'BADGES'),
                value: '${currentUser.badges.length}',
                icon: Icons.emoji_events_rounded,
                color: AppColors.amber500,
                route: AppRouter.trophyRoomRoute,
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: _buildTelemetryTile(
                context,
                label: context.tr('home.rank_label', fallback: 'Rank'),
                value: globalRank != null ? '#$globalRank' : '—',
                icon: Icons.public_rounded,
                color: AppColors.indigo500,
                route: AppRouter.leaderboardRoute,
                isLoadingValue: isRankLoading,
              ),
            ),
          ],
        ),
      ),
    );

    if (VowlMotion.shouldReduceMotion(context)) return shelfWidget;

    return shelfWidget
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  String _formatNumber(int n) {
    if (n >= 10000) return '${(n / 1000).toStringAsFixed(0)}k';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildTelemetryTile(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required String route,
    bool isLoadingValue = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final valueWidget = isLoadingValue
        ? Padding(
            padding: EdgeInsets.symmetric(vertical: 2.h),
            child: ShimmerLoading.rounded(
              width: 28.w,
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
              letterSpacing: -0.3,
              height: 1.1,
            ),
            maxLines: 1,
            minFontSize: 11,
            overflow: TextOverflow.ellipsis,
          );

    return Semantics(
      button: true,
      label: '$label: $value',
      child: ScaleButton(
        onTap: () {
          try {
            di.sl<HapticService>().selection();
          } catch (_) {}
          context.push(route);
        },
        child: ExcludeSemantics(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : AppColors.slate50,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Inset circular halo with solid authentic brand tint
                Container(
                  width: 30.r,
                  height: 30.r,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.14 : 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 15.r),
                  ),
                ),
                SizedBox(height: 6.h),

                // Metric numeric value
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: valueWidget,
                ),
                SizedBox(height: 2.h),

                // Metric uppercase label (strictly >= 10.5sp, minFontSize: 9)
                AutoSizeText(
                  label,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.5.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.slate400 : AppColors.slate500,
                    letterSpacing: 0.6,
                  ),
                  maxLines: 1,
                  minFontSize: 9,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerShelf(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131A29) : Colors.white,
        borderRadius: BorderRadius.circular(22.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _buildShimmerTile(context, labelWidth: 34.w, valueWidth: 24.w)),
          SizedBox(width: 4.w),
          Expanded(child: _buildShimmerTile(context, labelWidth: 30.w, valueWidth: 32.w)),
          SizedBox(width: 4.w),
          Expanded(child: _buildShimmerTile(context, labelWidth: 36.w, valueWidth: 20.w)),
          SizedBox(width: 4.w),
          Expanded(child: _buildShimmerTile(context, labelWidth: 28.w, valueWidth: 26.w)),
        ],
      ),
    );
  }

  Widget _buildShimmerTile(
    BuildContext context, {
    required double labelWidth,
    required double valueWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.02)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ShimmerLoading.circular(width: 28.r, height: 28.r),
          SizedBox(height: 7.h),
          ShimmerLoading.rounded(
            width: valueWidth,
            height: 14.h,
            borderRadius: 4.r,
          ),
          SizedBox(height: 5.h),
          ShimmerLoading.rounded(
            width: labelWidth,
            height: 9.h,
            borderRadius: 3.r,
          ),
        ],
      ),
    );
  }
}
