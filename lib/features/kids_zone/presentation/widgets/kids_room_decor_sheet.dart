import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
        border: Border.all(color: Colors.amber, width: 4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.shade700,
            offset: Offset(0, -4.h),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60.w,
                height: 6.h,
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                "DECORATE ROOM",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.amber.shade700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 10.h),
              TabBar(
                tabs: const [Tab(text: "BEDS"), Tab(text: "WINDOWS")],
                labelColor: Colors.amber.shade700,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.amber.shade700,
                indicatorWeight: 4,
                labelStyle: TextStyle(fontFamily: 'Outfit', fontSize: 14.sp, fontWeight: FontWeight.w900),
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
              color: isEquipped 
                  ? Colors.amber.withValues(alpha: 0.1) 
                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isEquipped ? Colors.amber : Colors.grey.shade300, 
                width: isEquipped ? 4.w : 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isEquipped ? Colors.amber.withValues(alpha: 0.5) : Colors.grey.shade300,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item['icon'] as String, style: TextStyle(fontSize: 32.sp)),
                SizedBox(height: 6.h),
                Text(
                  item['name'] as String, 
                  style: TextStyle(
                    fontFamily: 'Outfit', 
                    fontSize: 13.sp, 
                    fontWeight: FontWeight.w900, 
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87
                  ),
                ),
                if (!isOwned) ...[
                  SizedBox(height: 4.h),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${item['price']} ",
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 12.sp, fontWeight: FontWeight.w900, color: Colors.amber.shade700),
                      ),
                      Icon(Icons.monetization_on_rounded, size: 14.sp, color: Colors.amber.shade700),
                    ],
                  ),
                ],
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
