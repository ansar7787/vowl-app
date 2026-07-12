import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class FindWordMeaningQuestionHeader extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const FindWordMeaningQuestionHeader({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(20.r),
      color: color.withValues(alpha: isDark ? 0.1 : 0.08),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: color, size: 24.r),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              "LOCATE THE WORD MEANING: $text",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? color : color.withValues(alpha: 0.9),
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
