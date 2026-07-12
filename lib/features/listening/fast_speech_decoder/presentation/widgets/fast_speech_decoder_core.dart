import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class FastSpeechDecoderCore extends StatelessWidget {
  final String textToSpeak;
  final double speed;
  final Color color;
  final double rotation;
  final Function(double) onRotate;
  final VoidCallback onTapTts;

  const FastSpeechDecoderCore({
    super.key,
    required this.textToSpeak,
    required this.speed,
    required this.color,
    required this.rotation,
    required this.onRotate,
    required this.onTapTts,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onRotate(details.delta.dx + details.delta.dy),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Outer Gear Background
          Transform.rotate(
            angle: rotation * 4,
            child: Icon(
              Icons.settings_suggest_rounded,
              size: 180.r,
              color: color.withValues(alpha: 0.05),
            ),
          ),

          // Outer Ring Indicator
          Container(
            width: 150.r,
            height: 150.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.1),
                width: 6.r,
              ),
            ),
          ),

          // Playable Dial
          ScaleButton(
            onTap: onTapTts,
            child: Container(
              width: 110.r,
              height: 110.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.9),
                  ],
                  stops: const [0.2, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 25,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 60.r,
                  ),
                  Positioned(
                    bottom: 20.r,
                    child: Text(
                      "LISTEN",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 7.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tactical Needle
          Transform.rotate(
            angle: (rotation - 0.5) * 3.5,
            child: Container(
              height: 170.h,
              width: 4.w,
              alignment: Alignment.topCenter,
              child: Container(
                width: 4.w,
                height: 20.h,
                decoration: BoxDecoration(
                  color: Colors.orangeAccent,
                  borderRadius: BorderRadius.circular(2.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orangeAccent.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
