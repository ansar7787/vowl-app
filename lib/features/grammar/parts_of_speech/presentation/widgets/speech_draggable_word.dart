import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SpeechDraggableWord extends StatelessWidget {
  final String word;
  final Color primaryColor;
  final bool isDark;
  final bool isCompact;

  const SpeechDraggableWord({
    super.key,
    required this.word,
    required this.primaryColor,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: isCompact
          ? EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h)
          : EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
      borderRadius: BorderRadius.circular(isCompact ? 16.r : 24.r),
      child: Text(
        word, 
        textAlign: TextAlign.center, 
        style: TextStyle(
          fontFamily: 'Outfit', 
          fontSize: isCompact ? 20.sp : 28.sp, 
          color: isDark ? Colors.white : Colors.black87, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
