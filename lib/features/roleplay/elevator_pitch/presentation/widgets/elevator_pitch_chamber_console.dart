import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_soundwave_painter.dart';

class ElevatorPitchChamberConsole extends StatelessWidget {
  final Color color;
  final bool isDark;
  final double capsuleY;
  final double greenZoneY;
  final bool isListening;
  final String spokenText;
  final Animation<double> waveAnimation;
  final VoidCallback onFireBooster;

  const ElevatorPitchChamberConsole({
    super.key,
    required this.color,
    required this.isDark,
    required this.capsuleY,
    required this.greenZoneY,
    required this.isListening,
    required this.spokenText,
    required this.waveAnimation,
    required this.onFireBooster,
  });

  @override
  Widget build(BuildContext context) {
    final double totalShaftHeight = 240.h;
    final double zoneHeight = 72.h;

    // Normalize bounds logic
    final double greenTop = (totalShaftHeight - zoneHeight) * greenZoneY;
    final double capsuleTop = (totalShaftHeight - 32.h) * capsuleY;

    final bool isAligned = (capsuleY - greenZoneY).abs() < 0.14;

    return Container(
      width: 1.sw,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF07070F)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        children: [
          // 1. Elevator Vertical Physics Shaft
          GestureDetector(
            onTap: onFireBooster,
            child: Container(
              width: 64.w,
              height: totalShaftHeight,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0B0B14) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  width: 2,
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  // Drifting green harmonic target zone
                  Positioned(
                    top: greenTop,
                    child:
                        Container(
                              width: 58.w,
                              height: zoneHeight,
                              decoration: BoxDecoration(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: Colors.greenAccent.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.greenAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              color: Colors.greenAccent.withValues(alpha: 0.3),
                              duration: 1.5.seconds,
                            ),
                  ),

                  // Capsule Booster Rocket
                  Positioned(
                    top: capsuleTop,
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isAligned ? Colors.greenAccent : color,
                        boxShadow: [
                          BoxShadow(
                            color: (isAligned ? Colors.greenAccent : color)
                                .withValues(alpha: 0.45),
                            blurRadius: 12,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.rocket_launch_rounded,
                        color: Colors.white,
                        size: 16.r,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 20.w),

          // 2. Transcript and Soundwave Monitor Board
          Expanded(
            child: Container(
              height: totalShaftHeight,
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F0F1B) : Colors.white,
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(color: color.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "LIVE TELEMETRY SPECTRUM",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          color: color,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                            width: 10.r,
                            height: 10.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isListening
                                  ? Colors.redAccent
                                  : Colors.grey,
                            ),
                          )
                          .animate(target: isListening ? 1.0 : 0.0)
                          .scale(
                            begin: const Offset(1, 1),
                            end: const Offset(1.2, 1.2),
                          )
                          .fadeIn(),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Dynamic voice sinusoidal graphs
                  SizedBox(
                    height: 48.h,
                    child: AnimatedBuilder(
                      animation: waveAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: SoundwaveSpectrumPainter(
                            animationValue: waveAnimation.value,
                            isListening: isListening,
                            themeColor: color,
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 8.h),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        spokenText.isEmpty
                            ? "Tap the record lens and pitch your concept..."
                            : spokenText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontStyle: spokenText.isEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                          color: spokenText.isEmpty
                              ? (isDark ? Colors.white30 : Colors.black38)
                              : (isDark ? Colors.white70 : Colors.black87),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
