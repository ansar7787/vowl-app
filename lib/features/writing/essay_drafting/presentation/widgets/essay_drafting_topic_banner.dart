import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class EssayDraftingTopicBanner extends StatelessWidget {
  final String topic;
  final Color color;
  final bool isDark;

  const EssayDraftingTopicBanner({
    super.key,
    required this.topic,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.05 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 2),
      ),
      child: Stack(
        children: [
          const TechPatternOverlay(opacity: 0.05),
          Text(
            topic, 
            textAlign: TextAlign.center, 
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 15.sp, 
              fontWeight: FontWeight.w800, 
              color: isDark ? Colors.white : Colors.black87,
              height: 1.4
            )
          ),
        ],
      ),
    );
  }
}
