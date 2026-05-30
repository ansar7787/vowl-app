import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/fog_painter.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class SituationSpeakingFogScrubberPanel extends StatelessWidget {
  final SpeakingQuest quest;
  final Color primaryColor;
  final bool isDark;
  final double scrubProgress;
  final double timeVal;
  final Function(double) onScrubUpdate;
  final VoidCallback onPlayTts;

  const SituationSpeakingFogScrubberPanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.scrubProgress,
    required this.timeVal,
    required this.onScrubUpdate,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 1.sw,
        height: 200.h,
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
            // Underlying Revealed Reality Scene Card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1B1B33), const Color(0xFF0F0F1D)]
                        : [Colors.cyan.shade50.withValues(alpha: 0.15), Colors.white],
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
                          "THE SOCIAL SCENE",
                          style: GoogleFonts.shareTechMono(
                            fontSize: 10.sp,
                            color: primaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        ScaleButton(
                          onTap: onPlayTts,
                          child: Icon(Icons.volume_up_rounded, color: primaryColor, size: 18.r),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      quest.situationText ?? "Situation description.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),

            // Tactile Condensing Fog Overlay
            if (scrubProgress < 0.98)
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) =>
                      onScrubUpdate(details.primaryDelta! / 260.w),
                  child: CustomPaint(
                    painter: FogPainter(
                      progress: scrubProgress,
                      time: timeVal,
                    ),
                  ),
                ),
              ),

            // Scrub Instructions Overlay
            if (scrubProgress == 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.swipe_rounded, color: Colors.cyanAccent, size: 30.r)
                              .animate(onPlay: (c) => c.repeat())
                              .shake(hz: 2, curve: Curves.easeInOut)
                              .then()
                              .fadeOut(),
                          SizedBox(height: 8.h),
                          Text(
                            "SWIPE TO WIPE CONDENSATION",
                            style: GoogleFonts.shareTechMono(
                              fontSize: 10.sp,
                              color: isDark ? Colors.black54 : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
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
