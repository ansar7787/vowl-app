import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class ReadingSpeedPulseZone extends StatelessWidget {
  final String passage;
  final Color color;
  final bool isDark;
  final double clarityRadius;
  final double pulseScale;
  final int timerValue;
  final VoidCallback onTapPulse;

  const ReadingSpeedPulseZone({
    super.key,
    required this.passage,
    required this.color,
    required this.isDark,
    required this.clarityRadius,
    required this.pulseScale,
    required this.timerValue,
    required this.onTapPulse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // The Passage (Hidden unless pulsed)
            AnimatedOpacity(
              duration: 400.milliseconds,
              opacity: clarityRadius,
              child: GlassTile(
                padding: EdgeInsets.all(28.r),
                borderRadius: BorderRadius.circular(24.r),
                color: color.withValues(alpha: isDark ? 0.05 : 0.08),
                child: Text(
                  passage, 
                  textAlign: TextAlign.center, 
                  style: TextStyle(fontFamily: 'Outfit', 
                    fontSize: 16.sp, 
                    height: 1.4,
                    color: isDark ? Colors.white : Colors.black87, 
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // The Core Button
            if (clarityRadius < 0.5)
              GestureDetector(
                onTap: onTapPulse,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.0, end: pulseScale),
                  duration: 100.milliseconds,
                  builder: (context, double scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 130.r,
                        height: 130.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: isDark ? 0.15 : 0.08),
                          border: Border.all(color: color, width: 4),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            "${timerValue}S", 
                            style: TextStyle(fontFamily: 'RobotoMono', 
                              color: isDark ? Colors.white : color, 
                              fontSize: 26.sp, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds, color: Colors.white24),
              ),
          ],
        ),
        SizedBox(height: 24.h),
        Text(
          "STABILIZE THE RHYTHM TO SPEED READ", 
          style: TextStyle(fontFamily: 'Outfit', 
            fontSize: 12.sp, 
            color: color.withValues(alpha: 0.6), 
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
