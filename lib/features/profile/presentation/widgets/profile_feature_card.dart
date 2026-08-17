import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileFeatureCard extends StatelessWidget {
  final Widget iconContent;
  final Color color;
  final Color shadowColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? bottomContent;

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
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
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
