import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  final ValueChanged<double> onScratchUpdate;

  const DailyExpressionScratchPanel({
    super.key,
    required this.quest,
    required this.primaryColor,
    required this.isDark,
    required this.scratchProgress,
    required this.isListening,
    required this.timeVal,
    required this.onPlayTts,
    required this.onScratchUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28.r),
      child: Container(
        width: 1.sw,
        constraints: BoxConstraints(minHeight: 190.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131326) : Colors.white,
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white10),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15.r)],
        ),
        child: Stack(
          children: [
            // Underlying Revealed Golden Card (Sets the height of the stack)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E38), const Color(0xFF111124)]
                      : [primaryColor.withValues(alpha: 0.2), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: EdgeInsets.all(22.r),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "DAILY IDIOM",
                        style: TextStyle(
                          fontFamily: 'RobotoMono',
                          fontSize: 10.sp,
                          color: primaryColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                      ScaleButton(
                        onTap: onPlayTts,
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: primaryColor,
                          size: 18.r,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  if (scratchProgress == 1.0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      margin: EdgeInsets.only(bottom: 8.h),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                                Icons.mic_rounded,
                                size: 12.r,
                                color: primaryColor,
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.2, 1.2),
                              ),
                          SizedBox(width: 4.w),
                          Text(
                            "SPEAK THIS",
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.5),
                  Text(
                        quest.expression ?? "Bite the bullet",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w900,
                          color: primaryColor,
                          shadows: [
                            Shadow(
                              color: primaryColor.withValues(
                                alpha: isListening ? 0.8 : 0.3,
                              ),
                              blurRadius: isListening ? 20.r : 10.r,
                            ),
                          ],
                        ),
                      )
                      .animate(target: isListening ? 1 : 0)
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.05, 1.05),
                        duration: 200.ms,
                        curve: Curves.easeOutCubic,
                      ),
                  SizedBox(height: 10.h),
                  AnimatedOpacity(
                    opacity:
                        1.0, // Reverted dimming so educational context is always visible
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      (quest.meaning ?? "Meaning").toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                ],
              ),
            ),

            // Scratch Foil Overlay
            if (scratchProgress < 1.0)
              Positioned.fill(
                child: GestureDetector(
                  onPanUpdate: (details) {
                    final double dx = details.delta.dx;
                    final double dy = details.delta.dy;
                    final double dist =
                        (dx.abs() + dy.abs()) /
                        300.0; // scale distance to 0-1 range
                    onScratchUpdate(dist);
                  },
                  child: CustomPaint(
                    painter: ScratchPainter(
                      progress: scratchProgress,
                      isListening: isListening,
                      time: timeVal,
                      primaryColor: primaryColor,
                    ),
                  ),
                ),
              ),

            // Scratch Instructions Overlay
            if (scratchProgress == 0.0)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.1),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                                Icons.swipe_rounded,
                                color: Colors.white,
                                size: 30.r,
                              )
                              .animate(onPlay: (c) => c.repeat())
                              .shake(hz: 2, curve: Curves.easeInOut)
                              .then()
                              .fadeOut(),
                          SizedBox(height: 8.h),
                          Text(
                            "SWIPE TO REVEAL IDIOM",
                            style: TextStyle(
                              fontFamily: 'RobotoMono',
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
              ),
          ],
        ),
      ),
    );
  }
}
