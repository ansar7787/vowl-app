import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class TrueFalseReadingPassage extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;

  const TrueFalseReadingPassage({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(20.r),
      color: color.withValues(alpha: isDark ? 0.05 : 0.08),
      child: Text(
        passage, 
        style: TextStyle(fontFamily: 'Outfit', 
          fontSize: 16.sp, 
          height: 1.5, 
          color: isDark ? Colors.white70 : Colors.black87,
        ),
      ),
    );
  }
}
