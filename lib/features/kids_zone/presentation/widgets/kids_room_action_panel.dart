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
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(30.r),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)],
        border: Border.all(color: Colors.white),
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
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
