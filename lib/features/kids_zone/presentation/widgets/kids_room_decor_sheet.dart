import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class KidsRoomDecorSheet extends StatelessWidget {
  final UserEntity user;
  final Map<String, List<Map<String, dynamic>>> furnitureStore;
  final Function(String category, Map<String, dynamic> item) onItemTap;

  const KidsRoomDecorSheet({
    super.key,
    required this.user,
    required this.furnitureStore,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "DECORATE ROOM",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const TabBar(
                tabs: [Tab(text: "BEDS"), Tab(text: "WINDOWS")],
                labelColor: Colors.black87,
                indicatorColor: Colors.black87,
              ),
              SizedBox(
                height: 250.h,
                child: TabBarView(
                  children: [
                    _buildStoreGrid(context, 'bed'),
                    _buildStoreGrid(context, 'window'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreGrid(BuildContext context, String category) {
    final items = furnitureStore[category]!;
    return GridView.builder(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isOwned = user.kidsOwnedFurniture.contains(item['id']);
        final isEquipped = user.kidsEquippedFurniture[category] == item['id'];
        return ScaleButton(
          onTap: () => onItemTap(category, item),
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped ? Colors.black.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(15.r),
              border: Border.all(color: isEquipped ? Colors.black26 : Colors.transparent),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['icon'] as String, style: TextStyle(fontSize: 24.sp)),
                Text(item['name'] as String, style: TextStyle(fontFamily: 'Outfit', fontSize: 11.sp, fontWeight: FontWeight.bold)),
                if (!isOwned)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${item['price']} ",
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 9.sp, fontWeight: FontWeight.w900, color: Colors.black54),
                      ),
                      Icon(Icons.star_rounded, size: 9.sp, color: const Color(0xFFF59E0B)),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void show(
    BuildContext context, {
    required UserEntity user,
    required Map<String, List<Map<String, dynamic>>> furnitureStore,
    required Function(String category, Map<String, dynamic> item) onItemTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => KidsRoomDecorSheet(
        user: user,
        furnitureStore: furnitureStore,
        onItemTap: onItemTap,
      ),
    );
  }
}
