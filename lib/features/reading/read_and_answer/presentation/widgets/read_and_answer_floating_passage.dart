import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ReadAndAnswerFloatingPassage extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const ReadAndAnswerFloatingPassage({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(32.r),
      borderRadius: BorderRadius.circular(30.r),
      color: color.withValues(alpha: isDark ? 0.05 : 0.08),
      child: Text(
        text, 
        style: GoogleFonts.fredoka(
          fontSize: 20.sp, 
          height: 1.8, 
          color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87, 
          fontWeight: FontWeight.w500,
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
      color: isDark ? Colors.white10 : Colors.black12, 
      duration: 3.seconds,
    );
  }
}
