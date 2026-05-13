import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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

    return Shimmer.fromColors(
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
    );
  }
}

class GameShimmerLoading extends StatelessWidget {
  final Color? primaryColor;
  const GameShimmerLoading({super.key, this.primaryColor});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200]!;
    final highlightColor = isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[50]!;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            SizedBox(height: 20.h),
            // Header Shimmer
            Row(
              children: [
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: 45.r, height: 45.r,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 12.h,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6.r)),
                    ),
                  ),
                ),
                SizedBox(width: 40.w),
                Shimmer.fromColors(
                  baseColor: baseColor,
                  highlightColor: highlightColor,
                  child: Container(
                    width: 80.w, height: 35.h,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                  ),
                ),
              ],
            ),
            SizedBox(height: 50.h),
            // Question Area Shimmer
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: 250.w, height: 25.h,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
            SizedBox(height: 16.h),
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: 180.w, height: 20.h,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
              ),
            ),
            SizedBox(height: 60.h),
            // Main Content Card Shimmer
            Shimmer.fromColors(
              baseColor: baseColor,
              highlightColor: highlightColor,
              child: Container(
                width: double.infinity, height: 320.h,
                decoration: BoxDecoration(
                  color: Colors.white, 
                  borderRadius: BorderRadius.circular(32.r),
                  border: Border.all(
                    color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey[200]!, 
                    width: 2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 50.h),
            // Footer Buttons Shimmer
            Row(
              children: [
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                Expanded(
                  child: Shimmer.fromColors(
                    baseColor: baseColor,
                    highlightColor: highlightColor,
                    child: Container(
                      height: 60.h,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20.r)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LeaderboardShimmerLoading extends StatelessWidget {
  const LeaderboardShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          SizedBox(height: 100.h),
          // Nexus Portal Shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _portalShimmer(context, 70, 80), // 2nd
                SizedBox(width: 12.w),
                _portalShimmer(context, 90, 100), // 1st
                SizedBox(width: 12.w),
                _portalShimmer(context, 70, 80), // 3rd
              ],
            ),
          ),
          SizedBox(height: 48.h),
          // Ranks List Shimmer
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: ShimmerLoading.rounded(height: 80, borderRadius: 24),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _portalShimmer(BuildContext context, double w, double h) {
    return Column(
      children: [
        ShimmerLoading.circular(width: 50.r, height: 50.r),
        SizedBox(height: 12.h),
        ShimmerLoading.rounded(width: w.r, height: h.r, borderRadius: 20),
      ],
    );
  }
}

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
              itemBuilder: (context, index) {
                return Container(
                  width: 300.w,
                  margin: EdgeInsets.only(right: 16.w),
                  child: ShimmerLoading.rounded(height: 180, borderRadius: 24),
                );
              },
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
            itemBuilder: (context, index) {
              return ShimmerLoading.rounded(height: 200, borderRadius: 24);
            },
          ),
        ],
      ),
    );
  }
}

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
                itemBuilder: (context, index) => Container(
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
