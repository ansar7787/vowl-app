import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/app_spacing.dart';

// ---------------------------------------------------------------------------
// Core shimmer block
// ---------------------------------------------------------------------------

/// Theme-adaptive rectangular, circular, or rounded placeholder shimmer that
/// isolates its high-frequency slide paints inside a [RepaintBoundary].
class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shapeBorder;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading.rectangular({
    super.key,
    this.width,
    required this.height,
    this.baseColor,
    this.highlightColor,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.baseColor,
    this.highlightColor,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerLoading.rounded({
    super.key,
    this.width,
    required this.height,
    double borderRadius = 12,
    this.baseColor,
    this.highlightColor,
  }) : shapeBorder = RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(borderRadius.r),
       );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;

    final defaultBaseColor = isMidnight
        ? const Color(0xFF141A26)
        : (isDark ? AppColors.slate800 : AppColors.slate200);

    final defaultHighlightColor = isMidnight
        ? const Color(0xFF242E42)
        : (isDark ? AppColors.slate700 : const Color(0xFFF8FAFC));

    final effectiveBaseColor = baseColor ?? defaultBaseColor;

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: effectiveBaseColor,
        highlightColor: highlightColor ?? defaultHighlightColor,
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          decoration: ShapeDecoration(
            color: effectiveBaseColor,
            shape: shapeBorder,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game category shimmer screen
// ---------------------------------------------------------------------------

/// Full-screen shimmer skeleton for game category loading states.
class GameShimmerLoading extends StatelessWidget {
  final Color? primaryColor;
  const GameShimmerLoading({super.key, this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final accent = primaryColor;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.screen,
          vertical: 24.h,
        ),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Header
            Row(
              children: [
                ShimmerLoading.circular(width: 45.r, height: 45.r),
                SizedBox(width: 16.w),
                Expanded(
                  child: ShimmerLoading.rounded(height: 12.h, borderRadius: 6),
                ),
                SizedBox(width: 40.w),
                ShimmerLoading.rounded(
                  width: 80.w,
                  height: 35.h,
                  borderRadius: 20,
                ),
              ],
            ),
            SizedBox(height: 50.h),
            // Question area
            ShimmerLoading.rounded(
              width: 250.w,
              height: 25.h,
              borderRadius: 12,
            ),
            SizedBox(height: 16.h),
            ShimmerLoading.rounded(
              width: 180.w,
              height: 20.h,
              borderRadius: 10,
            ),
            SizedBox(height: 60.h),
            // Main content card
            Container(
              width: double.infinity,
              height: 320.h,
              decoration: BoxDecoration(
                color: (Theme.of(context).brightness == Brightness.dark &&
                        Theme.of(context).scaffoldBackgroundColor == Colors.black)
                    ? AppColors.midnightSurface
                    : (Theme.of(context).brightness == Brightness.dark
                          ? AppColors.midnightNavy
                          : Colors.white),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: (Theme.of(context).brightness == Brightness.dark &&
                          Theme.of(context).scaffoldBackgroundColor == Colors.black)
                      ? Colors.white.withValues(alpha: 0.12)
                      : (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.08)
                            : AppTheme.borderLight),
                  width: 1.0,
                ),
              ),
              child: ShimmerLoading.rounded(height: 320.h, borderRadius: 24),
            ),
            SizedBox(height: 50.h),
            // Footer buttons
            Row(
              children: [
                Expanded(
                  child: ShimmerLoading.rounded(height: 60.h, borderRadius: 20),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: ShimmerLoading.rounded(height: 60.h, borderRadius: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Leaderboard shimmer
// ---------------------------------------------------------------------------

/// Nexus Hub leaderboard rankings shimmer loader.
class LeaderboardShimmerLoading extends StatelessWidget {
  const LeaderboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 160.h),
          // Portal podium
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _portalShimmer(70, 80), // 2nd
                SizedBox(width: 12.w),
                _portalShimmer(90, 100), // 1st
                SizedBox(width: 12.w),
                _portalShimmer(70, 80), // 3rd
              ],
            ),
          ),
          SizedBox(height: 48.h),
          // Rankings list
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Container(
                  height: 74.h,
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      ShimmerLoading.rounded(width: 24.w, height: 16.h, borderRadius: 6),
                      SizedBox(width: 14.w),
                      ShimmerLoading.circular(width: 44.r, height: 44.r),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShimmerLoading.rounded(width: 110.w, height: 14.h, borderRadius: 6),
                            SizedBox(height: 6.h),
                            ShimmerLoading.rounded(width: 70.w, height: 10.h, borderRadius: 4),
                          ],
                        ),
                      ),
                      ShimmerLoading.rounded(width: 50.w, height: 20.h, borderRadius: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _portalShimmer(double w, double h) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerLoading.circular(width: 50.r, height: 50.r),
        SizedBox(height: 12.h),
        ShimmerLoading.rounded(width: w.r, height: h.r, borderRadius: 20),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Home Dashboard shimmer
// ---------------------------------------------------------------------------

/// Home dashboard skeleton loader matching the true home screen hierarchy.
class HomeShimmerLoading extends StatelessWidget {
  const HomeShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 16.h),

            // 1. Hero Header (CommandPod) Shimmer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerLoading.rounded(
                      height: 12.h,
                      width: 110.w,
                      borderRadius: 6,
                    ),
                    SizedBox(height: 8.h),
                    ShimmerLoading.rounded(
                      height: 24.h,
                      width: 170.w,
                      borderRadius: 8,
                    ),
                  ],
                ),
                ShimmerLoading.circular(width: 48.r, height: 48.r),
              ],
            ),
            SizedBox(height: 24.h),

            // 2. Continue Learning Card Shimmer
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(22.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : AppColors.indigo500.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ShimmerLoading.circular(width: 40.r, height: 40.r),
                      ShimmerLoading.rounded(
                        width: 90.w,
                        height: 24.h,
                        borderRadius: 12.r,
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  ShimmerLoading.rounded(
                    width: 175.w,
                    height: 24.h,
                    borderRadius: 8.r,
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ShimmerLoading.rounded(
                              width: 110.w,
                              height: 12.h,
                              borderRadius: 4.r,
                            ),
                            SizedBox(height: 10.h),
                            ShimmerLoading.rounded(
                              width: double.infinity,
                              height: 8.h,
                              borderRadius: 4.r,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16.w),
                      ShimmerLoading.circular(width: 44.r, height: 44.r),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 3. 4-Card Unified Stats Row Shimmer (Streak | Coins | Badges | Rank)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatTileSkeleton(
                      valueWidth: 26.w,
                      labelWidth: 36.w,
                      isDark: isDark,
                      isMidnight: isMidnight,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildStatTileSkeleton(
                      valueWidth: 34.w,
                      labelWidth: 30.w,
                      isDark: isDark,
                      isMidnight: isMidnight,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildStatTileSkeleton(
                      valueWidth: 22.w,
                      labelWidth: 38.w,
                      isDark: isDark,
                      isMidnight: isMidnight,
                    ),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: _buildStatTileSkeleton(
                      valueWidth: 28.w,
                      labelWidth: 26.w,
                      isDark: isDark,
                      isMidnight: isMidnight,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 28.h),

            // 4. Quest Arena Header & Bento Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShimmerLoading.rounded(
                  height: 18.h,
                  width: 130.w,
                  borderRadius: 6,
                ),
                ShimmerLoading.rounded(
                  height: 14.h,
                  width: 56.w,
                  borderRadius: 6,
                ),
              ],
            ),
            SizedBox(height: 14.h),
            ShimmerLoading.rounded(height: 130.h, borderRadius: 24),
            SizedBox(height: 24.h),

            // 5. Global Progress Card Shimmer
            ShimmerLoading.rounded(height: 90.h, borderRadius: 20),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  static Widget _buildStatTileSkeleton({
    required double valueWidth,
    required double labelWidth,
    required bool isDark,
    bool isMidnight = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 2.w),
      decoration: BoxDecoration(
        color: isMidnight
            ? Colors.white.withValues(alpha: 0.04)
            : (isDark
                  ? Colors.white.withValues(alpha: 0.03)
                  : AppColors.slate100),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isMidnight
              ? Colors.white.withValues(alpha: 0.08)
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : AppTheme.borderLight),
          width: 1.0,
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

// ---------------------------------------------------------------------------
// Profile shimmer
// ---------------------------------------------------------------------------

/// Profile screen skeleton loader.
class ProfileShimmerLoading extends StatelessWidget {
  const ProfileShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMidnight =
        isDark && Theme.of(context).scaffoldBackgroundColor == Colors.black;
    final cardBg = isMidnight
        ? AppColors.midnightSurface
        : (isDark ? AppColors.midnightNavy : Colors.white);
    final borderColor = isMidnight
        ? Colors.white.withValues(alpha: 0.12)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : AppTheme.borderLight);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          children: [
            SizedBox(height: 30.h),
            // Header card
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Column(
                children: [
                  const ShimmerLoading.circular(width: 80, height: 80),
                  SizedBox(height: 14.h),
                  ShimmerLoading.rounded(height: 20.h, width: 150.w, borderRadius: 8),
                  SizedBox(height: 8.h),
                  ShimmerLoading.rounded(height: 12.h, width: 100.w, borderRadius: 6),
                  SizedBox(height: 18.h),
                  ShimmerLoading.rounded(height: 8.h, width: double.infinity, borderRadius: 4),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            // 4 Bento Stats Row
            Row(
              children: List.generate(
                4,
                (i) => Expanded(
                  child: Container(
                    height: 72.h,
                    margin: EdgeInsets.only(right: i < 3 ? 8.w : 0),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(18.r),
                      border: Border.all(color: borderColor, width: 1.0),
                    ),
                    child: Center(
                      child: ShimmerLoading.circular(width: 28.r, height: 28.r),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Arena card
            Container(
              width: double.infinity,
              height: 120.h,
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(color: borderColor, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerLoading.rounded(height: 16.h, width: 140.w, borderRadius: 6),
                  const Spacer(),
                  ShimmerLoading.rounded(height: 40.h, width: double.infinity, borderRadius: 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
