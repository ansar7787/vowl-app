import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_painters.dart';

class AntonymNebulaCore extends StatelessWidget {
  final String word;
  final Color color;
  final bool isDark;
  final bool targetIsPositive;

  const AntonymNebulaCore({
    super.key,
    required this.word,
    required this.color,
    required this.isDark,
    required this.targetIsPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "DRAG TO OPPOSITE",
          style: GoogleFonts.shareTechMono(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 1,
          ),
        ).animate().fadeIn(),
        SizedBox(height: 15.h),
        Container(
          width: 140.r,
          height: 140.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark ? Colors.black : Colors.white,
            border: Border.all(
              color: color.withValues(alpha: 0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(painter: CorePainter(color)),
              )
              .animate(onPlay: (c) => c.repeat())
              .rotate(duration: 12.seconds),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    targetIsPositive ? "[+]" : "[-]",
                    style: GoogleFonts.shareTechMono(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: FittedBox(
                      child: Text(
                        word.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.04, 1.04),
          duration: 2.seconds,
        ),
      ],
    );
  }
}
