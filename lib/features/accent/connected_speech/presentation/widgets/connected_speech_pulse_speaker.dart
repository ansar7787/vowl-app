import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class ConnectedSpeechPulseSpeaker extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;
  final bool isCompact;

  const ConnectedSpeechPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double buttonSize = isCompact ? 80.r : 110.r;
    final double iconSize = isCompact ? 28.r : 36.r;
    
    return ScaleButton(
      onTap: () => onPlayTts(text),
      child: Container(
        width: buttonSize,
        height: buttonSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: isCompact ? 2 : 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: isCompact ? 12 : 20),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded, color: color, size: iconSize)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2)),
              SizedBox(height: isCompact ? 2.h : 6.h),
              Text(
                "HEAR PHRASE",
                style: TextStyle(
                  fontFamily: 'RobotoMono', 
                  color: color,
                  fontSize: isCompact ? 7.sp : 8.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
