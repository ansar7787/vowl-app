import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/mesh_gradient_background.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class HomeSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color categoryColor;
  final VoidCallback? onSeeAll;
  final Widget? badge;

  final String? localizedTitleKey;
  final String? localizedSubtitleKey;

  const HomeSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.categoryColor,
    this.onSeeAll,
    this.badge,
    this.localizedTitleKey,
    this.localizedSubtitleKey,
  });

  @override
  Widget build(BuildContext context) {
    final contrastColor = MeshGradientBackground.getContrastColor(context);
    final secondaryColor = contrastColor.withValues(alpha: 0.6);
    final resolvedTitle = localizedTitleKey != null
        ? context.tr(localizedTitleKey!)
        : title;
    final resolvedSubtitle = localizedSubtitleKey != null
        ? context.tr(localizedSubtitleKey!)
        : subtitle;

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
                  Flexible(
                    child: Text(
                      resolvedTitle.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: contrastColor,
                        letterSpacing: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[SizedBox(width: 10.w), badge!],
                ],
              ),
              Text(
                resolvedSubtitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  color: secondaryColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (onSeeAll != null)
          Semantics(
            button: true,
            label:
                '${context.tr('common.see_all', fallback: 'See All')} $resolvedTitle',
            child: ScaleButton(
              onTap: onSeeAll,
              child: Container(
                // Outer box only ENLARGES the tappable area to the 48dp
                // accessibility minimum; it paints nothing itself, so the
                // visible pill below keeps its original compact size.
                constraints: BoxConstraints(minWidth: 48.r, minHeight: 48.r),
                alignment: Alignment.center,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: categoryColor.withValues(alpha: 0.2),
                    ),
                  ),
                  child: ExcludeSemantics(
                    child: Text(
                      context.tr('common.see_all', fallback: 'See All'),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w900,
                        color: categoryColor,
                        letterSpacing: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
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
