import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';

class VictoryFlightOverlay extends StatelessWidget {
  final VoidCallback onFinished;
  final int level;
  final String? accessoryId;

  const VictoryFlightOverlay({
    super.key,
    required this.onFinished,
    this.level = 1,
    this.accessoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: Stack(
          children: [
            // Kinetic Speed Lines
            for (int i = 0; i < 8; i++)
              Positioned(
                left: -100,
                top: (100 + i * 80).h,
                child: Container(
                  width: 200.w,
                  height: 2.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withValues(alpha: 0), Colors.white.withValues(alpha: 0.3)],
                    ),
                  ),
                )
                .animate()
                .moveX(begin: 0, end: 1.5.sw, duration: 800.ms, delay: (i * 100).ms)
                .fadeOut(),
              ),

            // Owly flying with cinematic arc
            Positioned(
              left: -200,
              top: 300.h,
              child: VowlMascot(
                state: VowlMascotState.happy,
                size: 120.r,
                useFloatingAnimation: false,
                level: level,
                accessoryId: accessoryId,
              )
              .animate(onComplete: (_) => onFinished())
              // Horizontal Flight
              .moveX(
                begin: 0,
                end: 1.2.sw + 200,
                duration: 1200.ms,
                curve: Curves.easeInCubic,
              )
              // Vertical Arc
              .moveY(
                begin: 0,
                end: -150.h,
                duration: 600.ms,
                curve: Curves.easeOutQuad,
              )
              .then()
              .moveY(
                begin: 0,
                end: 200.h,
                duration: 600.ms,
                curve: Curves.easeInQuad,
              )
              // Dynamic Rotation (Leaning into flight)
              .rotate(
                begin: 0.1,
                end: 0.4,
                duration: 1200.ms,
                curve: Curves.easeInOut,
              )
              // Zoom Effect (Coming closer to camera)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              )
              .then()
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(0.4, 0.4),
                duration: 600.ms,
                curve: Curves.easeInBack,
              ),
            ),
            
            // Magical Sparkle Trail
            for (int i = 0; i < 12; i++)
              _buildSparkle(i),
          ],
        ),
      ),
    );
  }

  Widget _buildSparkle(int index) {
    final random = Random();
    final delay = (index * 100).ms;
    final duration = 1000.ms;

    return Positioned(
      left: -50,
      top: (250 + random.nextInt(200)).h,
      child: Text(
        index % 2 == 0 ? '✨' : '⭐',
        style: TextStyle(fontSize: (10 + random.nextInt(15)).sp),
      )
      .animate()
      .moveX(
        begin: 0,
        end: 1.2.sw + 50,
        duration: duration,
        curve: Curves.easeInOutBack,
        delay: delay,
      )
      .scale(begin: const Offset(0, 0), end: const Offset(1.2, 1.2), duration: 200.ms, delay: delay)
      .then()
      .scale(begin: const Offset(1, 1), end: const Offset(0, 0), duration: 400.ms, delay: 500.ms)
      .fadeOut(delay: 750.ms),
    );
  }
}
