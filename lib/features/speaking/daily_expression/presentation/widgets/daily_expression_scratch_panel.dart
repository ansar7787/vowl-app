import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/scratch_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class DailyExpressionScratchPanel extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final double scratchProgress;
  final bool isListening;
  final double timeVal;
  final VoidCallback onPlayTts;

  const DailyExpressionScratchPanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.scratchProgress,
    required this.isListening,
    required this.timeVal,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 1.sw,
        height: 190.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131326) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15.r,
            )
          ],
        ),
        child: Stack(
          children: [
            // Underlying Revealed Golden Card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E1E38), const Color(0xFF111124)]
                        : [Colors.amber.shade50.withValues(alpha: 0.2), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: EdgeInsets.all(22.r),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "DAILY IDIOM",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10.sp,
                            color: Colors.amberAccent,
                            letterSpacing: 1.5,
                          ),
                        ),
                        ScaleButton(
                          onTap: onPlayTts,
                          child: Icon(Icons.volume_up_rounded, color: Colors.amberAccent, size: 18.r),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      quest.expression ?? "Bite the bullet",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.amberAccent,
                        shadows: [
                          Shadow(
                            color: Colors.amberAccent.withValues(alpha: 0.3),
                            blurRadius: 10.r,
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      (quest.meaning ?? "Meaning").toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // Scratch Foil Overlay
            Positioned.fill(
              child: CustomPaint(
                painter: ScratchPainter(
                  progress: scratchProgress,
                  isListening: isListening,
                  time: timeVal,
                ),
              ),
            ),

            // Scratch Instructions Overlay
            if (scratchProgress == 0.0)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.1),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swipe_rounded, color: Colors.white, size: 30.r)
                            .animate(onPlay: (c) => c.repeat())
                            .shake(hz: 2, curve: Curves.easeInOut)
                            .then()
                            .fadeOut(),
                        SizedBox(height: 8.h),
                        Text(
                          "SPOKEN FREQUENCY DISSOLVES FOIL",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
