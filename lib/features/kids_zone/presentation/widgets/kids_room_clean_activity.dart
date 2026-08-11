import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'dart:math';

class KidsRoomCleanActivity extends StatefulWidget {
  final VoidCallback onComplete;

  const KidsRoomCleanActivity({
    super.key,
    required this.onComplete,
  });

  @override
  State<KidsRoomCleanActivity> createState() => _KidsRoomCleanActivityState();
}

class _KidsRoomCleanActivityState extends State<KidsRoomCleanActivity> {
  final List<_Dust> _dustParticles = [];
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _spawnDust();
  }

  void _spawnDust() {
    for (int i = 0; i < 15; i++) {
      _dustParticles.add(_Dust(
        id: i.toString(),
        x: 0.1 + Random().nextDouble() * 0.8,
        y: 0.2 + Random().nextDouble() * 0.6,
        size: 30 + Random().nextDouble() * 30,
      ));
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_isFinished) return;
    
    final position = details.globalPosition;
    bool cleanedAny = false;

    setState(() {
      _dustParticles.removeWhere((dust) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        final dx = position.dx - (screenWidth * dust.x);
        final dy = position.dy - (screenHeight * dust.y);
        final distance = sqrt(dx * dx + dy * dy);
        
        if (distance < dust.size + 20) {
          cleanedAny = true;
          return true;
        }
        return false;
      });
    });

    if (cleanedAny) {
      // Play a soft swish sound or haptic here if available
    }

    if (_dustParticles.isEmpty && !_isFinished) {
      _finishCleaning();
    }
  }

  void _finishCleaning() {
    setState(() {
      _isFinished = true;
    });
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
        color: Colors.black.withValues(alpha: 0.5),
        child: Stack(
          children: [
            // Instructions
            if (!_isFinished)
              Positioned(
                top: 100.h,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(color: Colors.teal, width: 3.w),
                    ),
                    child: Text(
                      "Swipe to clean the dust! 🧹",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.teal,
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                    begin: const Offset(0.95, 0.95),
                    end: const Offset(1.05, 1.05),
                    duration: 1.seconds,
                  ),
                ),
              ),

            // Dust Particles
            ..._dustParticles.map((dust) {
              return Positioned(
                left: MediaQuery.of(context).size.width * dust.x - (dust.size / 2),
                top: MediaQuery.of(context).size.height * dust.y - (dust.size / 2),
                child: Text(
                  "💨",
                  style: TextStyle(
                    fontSize: dust.size.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              );
            }),

            // Finished overlay
            if (_isFinished)
              Center(
                child: Container(
                  padding: EdgeInsets.all(40.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40.r),
                    border: Border.all(color: Colors.teal, width: 4.w),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "SQUEAKY CLEAN!",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 32.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.teal.shade700,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        "Sparkling! ✨",
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
              ),
          ],
        ),
      ),
    );
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
