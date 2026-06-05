import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FlashcardSwipeFront extends StatelessWidget {
  final dynamic quest;
  final Color color;
  final bool isDark;
  final double width;
  final double height;

  const FlashcardSwipeFront({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? Colors.white10 : color.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              quest.topicEmoji ?? "🏷️",
              style: TextStyle(fontSize: 56.sp),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          SizedBox(height: 32.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              quest.word?.toUpperCase() ?? "",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87,
                letterSpacing: 4,
              ),
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 14.r,
                color: color.withValues(alpha: 0.5),
              ),
              SizedBox(width: 8.w),
              Text(
                "TAP TO FLIP",
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 10.sp,
                  color: color.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
