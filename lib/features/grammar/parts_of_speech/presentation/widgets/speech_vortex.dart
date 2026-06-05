import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class SpeechVortex extends StatelessWidget {
  final int index;
  final String label;
  final Color color;
  final Alignment alignment;

  const SpeechVortex({
    super.key,
    required this.index,
    required this.label,
    required this.color,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 120.r, 
        height: 120.r,
        margin: EdgeInsets.all(10.r),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color.withValues(alpha: 0.6), 
                    color.withValues(alpha: 0.1), 
                    Colors.transparent,
                  ],
                ),
              ),
            ).animate(onPlay: (c) => c.repeat()).rotate(duration: 3.seconds),
            Text(
              label.toUpperCase(), 
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 10.sp, 
                fontWeight: FontWeight.w900, 
                color: color, 
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
