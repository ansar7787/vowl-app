import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class KidsSmartMixWidget extends StatelessWidget {
  const KidsSmartMixWidget({super.key, required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    // Generate a daily seed based on the date
    final today = DateTime.now();
    final random = math.Random(today.year * 10000 + today.month * 100 + today.day);

    final allKidsCategories = [
      {'route': '/kids/map/handwriting', 'title': 'Write & Learn', 'color': const Color(0xFFF43F5E), 'icon': Icons.edit_rounded},
      {'route': '/kids/map/alphabet', 'title': 'ABC', 'color': const Color(0xFFF43F5E), 'icon': Icons.abc_rounded},
      {'route': '/kids/map/numbers', 'title': '123', 'color': const Color(0xFF0EA5E9), 'icon': Icons.pin_rounded},
      {'route': '/kids/map/colors', 'title': 'Colors', 'color': const Color(0xFFF59E0B), 'icon': Icons.palette_rounded},
      {'route': '/kids/map/shapes', 'title': 'Shapes', 'color': const Color(0xFF10B981), 'icon': Icons.category_rounded},
      {'route': '/kids/map/animals', 'title': 'Animals', 'color': const Color(0xFF8B5CF6), 'icon': Icons.pets_rounded},
      {'route': '/kids/map/fruits', 'title': 'Fruits', 'color': const Color(0xFFEC4899), 'icon': Icons.apple_rounded},
    ];

    allKidsCategories.shuffle(random);
    final dailyAdventures = allKidsCategories.take(3).toList();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(32.r),
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
          width: 3.w,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.2),
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
              Icon(Icons.auto_awesome, color: const Color(0xFFF59E0B), size: 28.sp),
              SizedBox(width: 12.w),
              Text(
                'DAILY ADVENTURE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
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
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          SizedBox(height: 20.h),
          ...dailyAdventures.asMap().entries.map((entry) {
            final cat = entry.value;
            final index = entry.key + 1;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
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
      onTap: () => context.push(
        route,
        extra: {'title': title, 'primaryColor': color},
      ),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2.w),
        ),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    offset: Offset(0, 4.h),
                  )
                ],
              ),
              child: Center(
                child: Text(
                  "$step",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
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
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
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
                  )
                ],
              ),
              child: Icon(icon, color: color, size: 24.sp),
            ),
          ],
        ),
      ),
    );
  }
}
