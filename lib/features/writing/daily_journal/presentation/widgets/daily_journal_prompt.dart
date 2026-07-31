import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class DailyJournalPrompt extends StatelessWidget {
  final String text;
  final Color primaryColor;
  final bool isDark;

  const DailyJournalPrompt({
    super.key,
    required this.text,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(24.r),
      color: primaryColor.withValues(alpha: isDark ? 0.05 : 0.08),
      child: Stack(
        children: [
          const Positioned.fill(
            child: TechPatternOverlay(opacity: 0.05),
          ),
          Row(
            children: [
              Icon(
                    Icons.nightlight_round,
                    color: Colors.amberAccent,
                    size: 24.r,
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .shimmer(duration: 3.seconds),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
