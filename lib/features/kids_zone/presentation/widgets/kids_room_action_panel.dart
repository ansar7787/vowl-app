import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class KidsRoomActionPanel extends StatelessWidget {
  final bool isSleeping;
  final VoidCallback onDecor;
  final VoidCallback onFeed;
  final VoidCallback onSleepToggle;
  final VoidCallback onTalk;
  final VoidCallback onThemeCycle;

  const KidsRoomActionPanel({
    super.key,
    required this.isSleeping,
    required this.onDecor,
    required this.onFeed,
    required this.onSleepToggle,
    required this.onTalk,
    required this.onThemeCycle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(20.r),
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF1E293B) 
            : Colors.white,
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.grey.shade300, width: 4.w),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildModernActionButton(context, "Decor", Icons.palette_rounded, Colors.indigo, onDecor),
          _buildModernActionButton(context, "Feed", Icons.restaurant_rounded, Colors.pink, onFeed),
          _buildModernActionButton(
            context,
            isSleeping ? "Wake" : "Sleep",
            isSleeping ? Icons.wb_sunny_rounded : Icons.bedtime_rounded,
            Colors.amber,
            onSleepToggle,
          ),
          _buildModernActionButton(context, "Talk", Icons.chat_bubble_rounded, Colors.lightBlue, onTalk),
          _buildModernActionButton(context, "Theme", Icons.auto_awesome_rounded, Colors.teal, onThemeCycle),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ScaleButton(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 4.w),
              boxShadow: [
                BoxShadow(
                  color: color,
                  offset: Offset(0, 5.h),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit', 
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
