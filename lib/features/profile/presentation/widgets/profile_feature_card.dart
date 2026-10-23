import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:auto_size_text/auto_size_text.dart';

/// Stylized card component highlighting profile actions and auxiliary modules.
class ProfileFeatureCard extends StatelessWidget {
  /// Icon or decorative widget rendered inside the leading badge.
  final Widget iconContent;

  /// Primary theme color for background accents.
  final Color color;

  /// Shadow color providing depth under the card.
  final Color shadowColor;

  /// Primary header label.
  final String title;

  /// Secondary description or category label.
  final String subtitle;

  /// Callback executed when the card is pressed.
  final VoidCallback onTap;

  /// Optional widget displayed beneath the main content.
  final Widget? bottomContent;

  /// Creates a [ProfileFeatureCard].
  const ProfileFeatureCard({
    super.key,
    required this.iconContent,
    required this.color,
    required this.shadowColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.bottomContent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ScaleButton(
      onTap: onTap,
      child: GlassTile(
        borderRadius: BorderRadius.circular(24.r),
        padding: EdgeInsets.all(20.w),
        blur: 0,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(14.r),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, shadowColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor.withValues(alpha: 0.4),
                        blurRadius: 12.r,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: iconContent,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        title,
                        maxLines: 1,
                        minFontSize: 12,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      AutoSizeText(
                        subtitle,
                        maxLines: 2,
                        minFontSize: 8,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                          height: 1.3,
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
            if (bottomContent != null) ...[
              SizedBox(height: 20.h),
              bottomContent!,
            ],
          ],
        ),
      ),
    );
  }
}
