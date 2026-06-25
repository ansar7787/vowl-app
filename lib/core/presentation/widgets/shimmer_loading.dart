import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ---------------------------------------------------------------------------
// Core shimmer block
// ---------------------------------------------------------------------------

/// Theme-adaptive rectangular, circular, or rounded placeholder shimmer that
/// isolates its high-frequency slide paints inside a [RepaintBoundary].
class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shapeBorder;

  const ShimmerLoading.rectangular({
    super.key,
    this.width,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerLoading.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  ShimmerLoading.rounded({
    super.key,
    this.width,
    required this.height,
    double borderRadius = 12,
  }) : shapeBorder = RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(borderRadius.r),
       );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey[300]!,
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.grey[100]!,
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          decoration: ShapeDecoration(color: Colors.grey, shape: shapeBorder),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private shared shimmer-box widget
// Replaces the per-build local function in GameShimmerLoading to avoid
// closure re-allocation on every build() call.
// ---------------------------------------------------------------------------

class _ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  final BoxShape shape;
  final Color? accent;

  const _ShimmerBox({
    this.width,
    required this.height,
    this.radius = 12,
    this.shape = BoxShape.rectangle,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = accent ?? Colors.grey;
    final baseColor = isDark
        ? color.withValues(alpha: 0.08)
        : color.withValues(alpha: 0.06);
    final highlightColor = isDark
        ? color.withValues(alpha: 0.18)
        : color.withValues(alpha: 0.12);

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        period: const Duration(milliseconds: 1800),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.grey[200],
            borderRadius: shape == BoxShape.circle
                ? null
                : BorderRadius.circular(radius.r),
            shape: shape,
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
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Header
            Row(
              children: [
                _ShimmerBox(
                  width: 45.r,
                  height: 45.r,
                  shape: BoxShape.circle,
                  accent: accent,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _ShimmerBox(height: 12.h, radius: 6, accent: accent),
                ),
                SizedBox(width: 40.w),
                _ShimmerBox(
                  width: 80.w,
                  height: 35.h,
                  radius: 20,
                  accent: accent,
                ),
              ],
            ),
            SizedBox(height: 50.h),
            // Question area
            _ShimmerBox(width: 250.w, height: 25.h, radius: 12, accent: accent),
            SizedBox(height: 16.h),
            _ShimmerBox(width: 180.w, height: 20.h, radius: 10, accent: accent),
            SizedBox(height: 60.h),
            // Main content card
            Container(
              width: double.infinity,
              height: 320.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: (accent ?? Colors.grey).withValues(
                    alpha: Theme.of(context).brightness == Brightness.dark
                        ? 0.15
                        : 0.08,
                  ),
                  width: 2,
                ),
              ),
              child: _ShimmerBox(height: 320.h, radius: 32, accent: accent),
            ),
            SizedBox(height: 50.h),
            // Footer buttons
            Row(
              children: [
                Expanded(
                  child: _ShimmerBox(height: 60.h, radius: 20, accent: accent),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: _ShimmerBox(height: 60.h, radius: 20, accent: accent),
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
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 100.h),
          // Portal podium
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
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
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: ShimmerLoading.rounded(height: 80, borderRadius: 24),
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

/// Home dashboard skeleton loader.
class HomeShimmerLoading extends StatelessWidget {
  const HomeShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(24.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ShimmerLoading.rounded(height: 12, width: 100),
                    SizedBox(height: 8.h),
                    ShimmerLoading.rounded(height: 24, width: 180),
                  ],
                ),
                const ShimmerLoading.circular(width: 45, height: 45),
              ],
            ),
          ),
          SizedBox(
            height: 180.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              padding: EdgeInsets.only(left: 24.w),
              itemBuilder: (context, index) => Container(
                width: 300.w,
                margin: EdgeInsets.only(right: 16.w),
                child: ShimmerLoading.rounded(height: 180, borderRadius: 24),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(24.r),
            child: ShimmerLoading.rounded(height: 20, width: 150),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16.h,
              crossAxisSpacing: 16.w,
              childAspectRatio: 0.85,
            ),
            itemCount: 4,
            itemBuilder: (context, index) =>
                ShimmerLoading.rounded(height: 200, borderRadius: 24),
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
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          children: [
            SizedBox(height: 60.h),
            const ShimmerLoading.circular(width: 120, height: 120),
            SizedBox(height: 24.h),
            ShimmerLoading.rounded(height: 32, width: 200),
            SizedBox(height: 8.h),
            ShimmerLoading.rounded(height: 16, width: 150),
            SizedBox(height: 40.h),
            ShimmerLoading.rounded(height: 100, borderRadius: 24),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: ShimmerLoading.rounded(height: 80, borderRadius: 20),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: ShimmerLoading.rounded(height: 80, borderRadius: 20),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            ShimmerLoading.rounded(height: 100, borderRadius: 24),
            SizedBox(height: 40.h),
            ShimmerLoading.rounded(height: 24, width: 150),
            SizedBox(height: 16.h),
            SizedBox(
              height: 100.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                itemBuilder: (context, i) => Container(
                  width: 100.w,
                  margin: EdgeInsets.only(right: 16.w),
                  child: ShimmerLoading.rounded(height: 100, borderRadius: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
