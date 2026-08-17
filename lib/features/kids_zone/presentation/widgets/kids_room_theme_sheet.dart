import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class KidsRoomThemeSheet extends StatelessWidget {
  final UserEntity user;
  final String currentTheme;
  final Function(String theme) onThemeSelected;

  const KidsRoomThemeSheet({
    super.key,
    required this.user,
    required this.currentTheme,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      {'id': 'nature', 'name': 'Forest', 'icon': '🌲', 'color': Colors.teal},
      {'id': 'space', 'name': 'Space', 'icon': '🚀', 'color': Colors.indigo},
      {'id': 'ocean', 'name': 'Ocean', 'icon': '🌊', 'color': Colors.blue},
      {'id': 'sweet', 'name': 'Sweet', 'icon': '🍭', 'color': Colors.pink},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        border: Border.all(color: Colors.teal, width: 4.w),
        boxShadow: [
          BoxShadow(color: Colors.teal.shade700, offset: Offset(0, -4.h)),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: Colors.teal.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "MAGIC THEMES",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.teal.shade700,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: themes.map((t) => _buildThemeItem(context, t)).toList(),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeItem(BuildContext context, Map<String, dynamic> t) {
    final isSelected = t['id'] == currentTheme;
    final color = t['color'] as MaterialColor;

    return Expanded(
      child: ScaleButton(
        onTap: () => onThemeSelected(t['id'] as String),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : color.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isSelected ? 4.w : 2.w),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          offset: Offset(0, 4.h),
                        ),
                      ]
                    : [],
              ),
              child: Text(
                t['icon'] as String,
                style: TextStyle(fontSize: 35.sp),
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              (t['name'] as String).toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: Theme.of(context).brightness == Brightness.dark
                    ? (isSelected ? color.shade300 : Colors.white70)
                    : (isSelected ? color.shade700 : Colors.black87),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    required UserEntity user,
    required String currentTheme,
    required Function(String theme) onThemeSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => KidsRoomThemeSheet(
        user: user,
        currentTheme: currentTheme,
        onThemeSelected: onThemeSelected,
      ),
    );
  }
}
