import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color categoryColor;
  final VoidCallback? onSeeAll;
  final Widget? badge;

  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.categoryColor,
    this.onSeeAll,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final contrastColor = MeshGradientBackground.getContrastColor(context);
    final secondaryColor = contrastColor.withValues(alpha: 0.6);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Premium vertical indicator
        Container(
          width: 4.w,
          height: 32.h,
          decoration: BoxDecoration(
            color: categoryColor,
            borderRadius: BorderRadius.circular(2.r),
            boxShadow: [
              BoxShadow(
                color: categoryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      color: contrastColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (badge != null) ...[SizedBox(width: 10.w), badge!],
                ],
              ),
              Text(
                subtitle,
                style: GoogleFonts.outfit(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          ScaleButton(
            onTap: onSeeAll,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: categoryColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                'SEE ALL',
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: categoryColor,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class HomeSliverSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color categoryColor;
  final VoidCallback? onSeeAll;

  const HomeSliverSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.categoryColor,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      sliver: SliverToBoxAdapter(
        child: Column(
          children: [
            SizedBox(height: 32.h),
            HomeSectionHeader(
              title: title,
              subtitle: subtitle,
              categoryColor: categoryColor,
              onSeeAll: onSeeAll,
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
