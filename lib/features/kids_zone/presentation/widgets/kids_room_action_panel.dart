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
          Expanded(child: _buildModernActionButton(context, "Decor", "🎨", Colors.indigo, onDecor)),
          Expanded(child: _buildModernActionButton(context, "Feed", "🍎", Colors.green, onFeed)),
          Expanded(child: _buildModernActionButton(
            context,
            isSleeping ? "Wake" : "Sleep",
            isSleeping ? "☀️" : "🌙",
            Colors.deepPurple,
            onSleepToggle,
          )),
          Expanded(child: _buildModernActionButton(context, "Talk", "💬", Colors.lightBlue, onTalk)),
          Expanded(child: _buildModernActionButton(context, "Theme", "✨", Colors.teal, onThemeCycle)),
        ],
      ),
    );
  }

  Widget _buildModernActionButton(
    BuildContext context,
    String label,
    String emoji,
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
              border: Border.all(color: color, width: 3.w),
              boxShadow: [
                BoxShadow(
                  color: color,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
          ),
          SizedBox(height: 8.h),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'Outfit', 
              fontSize: 10.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
