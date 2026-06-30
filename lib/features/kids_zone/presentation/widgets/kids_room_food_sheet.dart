import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class KidsRoomFoodSheet extends StatelessWidget {
  final UserEntity user;
  final Function(Map<String, dynamic> food) onFoodSelected;

  const KidsRoomFoodSheet({
    super.key,
    required this.user,
    required this.onFoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final food = [
      {'name': 'Apple', 'icon': '🍎', 'price': 0, 'happiness': 0.02},
      {'name': 'Cake', 'icon': '🍰', 'price': 50, 'happiness': 0.05},
      {'name': 'Golden Berry', 'icon': '🫐', 'price': 200, 'happiness': 0.10},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        border: Border.all(color: Colors.pink, width: 4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.pink.shade700,
            offset: Offset(0, -4.h),
          ),
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
                color: Colors.pink.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3.r),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              "YUMMY TREATS",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 22.sp,
                fontWeight: FontWeight.w900,
                color: Colors.pink.shade700,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 30.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: food.map((f) => _buildFoodItem(context, f)).toList(),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(BuildContext context, Map<String, dynamic> f) {
    return ScaleButton(
      onTap: () => onFoodSelected(f),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.pink.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.pink, width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withValues(alpha: 0.3),
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Text(
              f['icon'] as String,
              style: TextStyle(fontSize: 40.sp),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            (f['name'] as String).toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit', 
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
            ),
          ),
          if ((f['price'] as int) > 0) ...[
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${f['price']} ",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 13.sp, fontWeight: FontWeight.w900, color: Colors.pink.shade700),
                ),
                Icon(Icons.monetization_on_rounded, size: 13.sp, color: Colors.pink.shade700),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static void show(
    BuildContext context, {
    required UserEntity user,
    required Function(Map<String, dynamic> food) onFoodSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => KidsRoomFoodSheet(
        user: user,
        onFoodSelected: onFoodSelected,
      ),
    );
  }
}
