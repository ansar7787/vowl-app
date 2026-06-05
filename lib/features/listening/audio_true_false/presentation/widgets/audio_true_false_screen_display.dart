import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
class AudioTrueFalseScreenDisplay extends StatelessWidget {
  final String statement;
  final Color color;
  final double tuningValue;

  const AudioTrueFalseScreenDisplay({
    super.key,
    required this.statement,
    required this.color,
    required this.tuningValue,
  });

  @override
  Widget build(BuildContext context) {
    double clarity = (1.0 - (tuningValue - 0.5).abs() * 2).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      height: 180.h,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Static
          if (clarity < 0.9)
            ...List.generate(
              15,
              (i) => Positioned(
                left: (i * 20).w,
                child: Container(
                  width: 2.w,
                  height: 180.h,
                  color: Colors.white10.withValues(alpha: 1.0 - clarity),
                ).animate(onPlay: (c) => c.repeat()).moveX(
                  begin: 0,
                  end: 10,
                  duration: 100.ms,
                ),
              ),
            ),
            
          // The Statement
          Opacity(
            opacity: clarity.clamp(0.1, 1.0),
            child: Padding(
              padding: EdgeInsets.all(24.r),
              child: Text(
                statement,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Color.lerp(Colors.white24, Colors.white, clarity),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
