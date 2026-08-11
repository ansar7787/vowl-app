import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:auto_size_text/auto_size_text.dart';

class KidsProfileCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color shadowColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? bottomContent;

  const KidsProfileCard({
    super.key,
    required this.icon,
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
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: shadowColor, width: 2.w),
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        offset: Offset(0, 4.h),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24.r,
                  ),
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
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark ? Colors.white24 : Colors.black12,
                  size: 16.r,
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
