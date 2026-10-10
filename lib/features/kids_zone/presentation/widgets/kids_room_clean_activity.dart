import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'dart:math';
import 'dart:ui';

class KidsRoomCleanActivity extends StatefulWidget {
  final VoidCallback onComplete;

  const KidsRoomCleanActivity({super.key, required this.onComplete});

  @override
  State<KidsRoomCleanActivity> createState() => _KidsRoomCleanActivityState();
}

class _KidsRoomCleanActivityState extends State<KidsRoomCleanActivity> {
  final ValueNotifier<List<_Dust>> _dustParticles = ValueNotifier([]);
  final ValueNotifier<bool> _isFinished = ValueNotifier(false);

  @override
  void dispose() {
    _dustParticles.dispose();
    _isFinished.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _spawnDust();
  }

  void _spawnDust() {
    final initialDust = <_Dust>[];
    for (int i = 0; i < 15; i++) {
      initialDust.add(
        _Dust(
          id: i.toString(),
          x: 0.1 + Random().nextDouble() * 0.8,
          y: 0.2 + Random().nextDouble() * 0.6,
          size: 30 + Random().nextDouble() * 30,
        ),
      );
    }
    _dustParticles.value = initialDust;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isFinished.value) return;

    final position = details.globalPosition;
    bool cleanedAny = false;

    final currentDust = List<_Dust>.from(_dustParticles.value);
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    currentDust.removeWhere((dust) {
      final dx = position.dx - (screenWidth * dust.x);
      final dy = position.dy - (screenHeight * dust.y);
      final distance = sqrt(dx * dx + dy * dy);

      if (distance < dust.size + 20) {
        cleanedAny = true;
        return true;
      }
      return false;
    });

    if (cleanedAny) {
      _dustParticles.value = currentDust;
    }

    if (_dustParticles.value.isEmpty && !_isFinished.value) {
      _finishCleaning();
    }
  }

  void _finishCleaning() {
    _isFinished.value = true;
    di.sl<SoundService>().playCorrect();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: _onPanUpdate,
      child: Material(
        type: MaterialType.transparency,
        child: ListenableBuilder(
          listenable: Listenable.merge([_dustParticles, _isFinished]),
          builder: (context, _) {
            return Stack(
              children: [
                // Background frosted glass effect for dirty/soapy room
                if (!_isFinished.value)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      color: Colors.lightBlueAccent.withValues(
                        alpha: 0.2,
                      ), // Soapy tint
                    ),
                  ),

                // Instructions
                if (!_isFinished.value)
                  Positioned(
                    top: 100.h,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Builder(
                        builder: (context) {
                          final reduceMotion = MediaQuery.disableAnimationsOf(
                            context,
                          );
                          Widget instructions = ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.w,
                                  vertical: 12.h,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(30.r),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.w,
                                  ),
                                ),
                                child: Text(
                                  "Swipe to wipe the bubbles! 🧽",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            ),
                          );
                          if (!reduceMotion) {
                            instructions = instructions
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.95, 0.95),
                                  end: const Offset(1.05, 1.05),
                                  duration: 1.seconds,
                                );
                          }
                          return instructions;
                        },
                      ),
                    ),
                  ),

                // Dirt/Bubbles Particles rendered in a single Canvas for performance
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _DustPainter(_dustParticles.value),
                    ),
                  ),
                ),

                // Finished overlay
                if (_isFinished.value)
                  Center(
                    child:
                        ClipRRect(
                          borderRadius: BorderRadius.circular(40.r),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 24.w),
                              padding: EdgeInsets.all(32.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(40.r),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4.w,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                  BoxShadow(
                                    color: Colors.tealAccent.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Builder(
                                    builder: (context) {
                                      final reduceMotion =
                                          MediaQuery.disableAnimationsOf(
                                            context,
                                          );
                                      Widget icon = Icon(
                                        Icons.auto_awesome_rounded,
                                        size: 56.sp,
                                        color: Colors.amber.shade400,
                                      );
                                      if (!reduceMotion) {
                                        icon = icon
                                            .animate(
                                              onPlay: (c) =>
                                                  c.repeat(reverse: true),
                                            )
                                            .scale(
                                              begin: const Offset(0.9, 0.9),
                                              end: const Offset(1.1, 1.1),
                                              duration: 1.seconds,
                                            );
                                      }
                                      return icon;
                                    },
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    "SQUEAKY\nCLEAN!",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 36.sp,
                                      height: 1.1,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.teal.shade800,
                                      shadows: [
                                        Shadow(
                                          color: Colors.white,
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16.h),
                                  Text(
                                    "Sparkling! ✨",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 22.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.teal.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DustPainter extends CustomPainter {
  final List<_Dust> particles;

  _DustPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    final paint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final dust in particles) {
      final rect = Rect.fromCenter(
        center: Offset(size.width * dust.x, size.height * dust.y),
        width: dust.size,
        height: dust.size,
      );

      // Draw shadow
      canvas.drawShadow(
        Path()..addOval(rect),
        Colors.blueAccent.withValues(alpha: 0.4),
        10,
        true,
      );

      // Draw bubble background
      paint.shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.7),
          Colors.lightBlueAccent.withValues(alpha: 0.5),
        ],
      ).createShader(rect);

      canvas.drawOval(rect, paint);

      // Draw border
      canvas.drawOval(rect, borderPaint);

      // We draw the emoji or a simple inner highlight
      // Using TextPainter is expensive if drawn per frame for many particles,
      // but 15 particles is acceptable. We can just draw a simple highlight.
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(
            size.width * dust.x - dust.size * 0.15,
            size.height * dust.y - dust.size * 0.15,
          ),
          width: dust.size * 0.3,
          height: dust.size * 0.3,
        ),
        highlightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) {
    return oldDelegate.particles != particles;
  }
}

class _Dust {
  final String id;
  final double x;
  final double y;
  final double size;

  _Dust({
    required this.id,
    required this.x,
    required this.y,
    required this.size,
  });
}
