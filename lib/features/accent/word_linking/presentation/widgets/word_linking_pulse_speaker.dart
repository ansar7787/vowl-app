import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class WordLinkingPulseSpeaker extends StatelessWidget {
  final String text;
  final Color color;
  final Function(String) onPlayTts;

  const WordLinkingPulseSpeaker({
    super.key,
    required this.text,
    required this.color,
    required this.onPlayTts,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: () => onPlayTts(text),
      child: Container(
        width: 110.r,
        height: 110.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color, width: 3),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.graphic_eq_rounded, color: color, size: 36.r)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                  ),
              SizedBox(height: 6.h),
              Text(
                "HEAR LINKING",
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  color: color,
                  fontSize: 8.sp,
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
