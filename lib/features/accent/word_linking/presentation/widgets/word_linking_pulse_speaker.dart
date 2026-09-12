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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.1),
              border: Border.all(color: color, width: 3),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 20),
              ],
            ),
            child: Center(
              child: Icon(Icons.graphic_eq_rounded, color: color, size: 32.r)
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.2, 1.2),
                  ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            "HEAR LINKING",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              color: color,
              fontSize: 11.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
