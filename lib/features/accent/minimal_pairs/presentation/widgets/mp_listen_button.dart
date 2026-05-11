import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/widgets/accent/harmonic_waves.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  MpListenButton — Pulsing circular listen/play button
// ═══════════════════════════════════════════════════════════════════════════

class MpListenButton extends StatelessWidget {
  final bool isPlaying;
  final AnimationController pulseController;
  final VoidCallback onTap;

  const MpListenButton({
    super.key,
    required this.isPlaying,
    required this.pulseController,
    required this.onTap,
  });

  static const _blue = Color(0xFF3B82F6);

  static final _listenStyle = GoogleFonts.outfit(
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 2,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (_, child) {
        final s = 1.0 + (pulseController.value * 0.03);
        return Transform.scale(scale: isPlaying ? 1.0 : s, child: child);
      },
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                _blue.withValues(alpha: 0.9),
                _blue,
                const Color(0xFF2563EB),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _blue.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 4,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isPlaying)
                      SizedBox(
                        width: 40.w,
                        child: const HarmonicWaves(
                          color: Colors.white,
                          height: 28,
                        ),
                      ).animate().fadeIn()
                    else
                      Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 32.r,
                      ),
                    SizedBox(height: 4.h),
                    Text(
                      'LISTEN',
                      style: _listenStyle.copyWith(fontSize: 12.sp),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
