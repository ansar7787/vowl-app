import 'package:vowl/core/theme/illustration_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color c_0EA5E9 = Color(0xFF0EA5E9);
}

class KidsSmartMixWidget extends StatelessWidget {
  const KidsSmartMixWidget({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Generate a daily seed based on the date
    final today = DateTime.now();
    final random = math.Random(
      today.year * 10000 + today.month * 100 + today.day,
    );

    final allKidsCategories = [
      {
        'route': '/kids/map/handwriting',
        'title': 'Write & Learn',
        'color': AppColors.rose500,
        'icon': Icons.edit_rounded,
      },
      {
        'route': '/kids/map/alphabet',
        'title': 'ABC',
        'color': AppColors.rose500,
        'icon': Icons.abc_rounded,
      },
      {
        'route': '/kids/map/numbers',
        'title': '123',
        'color': _LocalPalette.c_0EA5E9,
        'icon': Icons.pin_rounded,
      },
      {
        'route': '/kids/map/colors',
        'title': 'Colors',
        'color': AppColors.amber500,
        'icon': Icons.palette_rounded,
      },
      {
        'route': '/kids/map/shapes',
        'title': 'Shapes',
        'color': AppColors.emerald500,
        'icon': Icons.category_rounded,
      },
      {
        'route': '/kids/map/animals',
        'title': 'Animals',
        'color': AppColors.violet500,
        'icon': Icons.pets_rounded,
      },
      {
        'route': '/kids/map/fruits',
        'title': 'Fruits',
        'color': IllustrationColors.vibrantPink,
        'icon': Icons.apple_rounded,
      },
    ];

    allKidsCategories.shuffle(random);
    final dailyAdventures = allKidsCategories.take(3).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.3),
          width: 3.w,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.2),
            offset: Offset(0, 8.h),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.amber500, size: 20.sp),
              SizedBox(width: 8.w),
              Text(
                'DAILY ADVENTURE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate800,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Play these 3 games to earn a special badge!',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 12.h),
          ...dailyAdventures.asMap().entries.map((entry) {
            final cat = entry.value;
            final index = entry.key + 1;
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: _buildAdventureCard(
                context,
                index,
                cat['title'] as String,
                cat['route'] as String,
                cat['color'] as Color,
                cat['icon'] as IconData,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAdventureCard(
    BuildContext context,
    int step,
    String title,
    String route,
    Color color,
    IconData icon,
  ) {
    return ScaleButton(
      onTap: () =>
          context.push(route, extra: {'title': title, 'primaryColor': color}),
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2.w),
        ),
        child: Row(
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  "$step",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : AppColors.slate800,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    offset: Offset(0, 2.h),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
          ],
        ),
      ),
    );
  }
}
