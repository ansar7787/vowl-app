import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class SpeechDraggableWord extends StatelessWidget {
  final String word;
  final Color primaryColor;
  final bool isDark;

  const SpeechDraggableWord({
    super.key,
    required this.word,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 20.h),
      borderRadius: BorderRadius.circular(24.r),
      child: Text(
        word, 
        textAlign: TextAlign.center, 
        style: GoogleFonts.fredoka(
          fontSize: 28.sp, 
          color: isDark ? Colors.white : Colors.black87, 
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
