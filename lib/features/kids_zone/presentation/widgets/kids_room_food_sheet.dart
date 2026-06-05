import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
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

    return GlassTile(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "YUMMY TREATS",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: food.map((f) => _buildFoodItem(f)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(Map<String, dynamic> f) {
    return ScaleButton(
      onTap: () => onFoodSelected(f),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              f['icon'] as String,
              style: TextStyle(fontSize: 30.sp),
            ),
          ),
          Text(
            f['name'] as String,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if ((f['price'] as int) > 0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${f['price']} ",
                  style: TextStyle(fontFamily: 'Outfit', fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.black54),
                ),
                Icon(Icons.star_rounded, size: 9.sp, color: const Color(0xFFF59E0B)),
              ],
            ),
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
