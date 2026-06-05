import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class FindWordMeaningMagnifierField extends StatelessWidget {
  final String passage;
  final String correct;
  final Color color;
  final bool isDark;
  final Offset lensPos;
  final bool isAnswered;
  final Function(Offset) onLensMove;
  final Function(String) onWordTap;

  const FindWordMeaningMagnifierField({
    super.key,
    required this.passage,
    required this.correct,
    required this.color,
    required this.isDark,
    required this.lensPos,
    required this.isAnswered,
    required this.onLensMove,
    required this.onWordTap,
  });

  @override
  Widget build(BuildContext context) {
    final words = passage.split(' ');
    return SizedBox(
      height: 420.h,
      width: double.infinity,
      child: Stack(
        children: [
          // The Blurred Manuscript
          Container(
            padding: EdgeInsets.all(24.r),
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(24.r),
            ),
            child: Wrap(
              spacing: 6.w,
              runSpacing: 8.h,
              children: words.map((w) {
                final cleanWord = w.replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()!?]'), '').trim();
                double x = (words.indexOf(w) % 5) * 60.w;
                double y = (words.indexOf(w) ~/ 5) * 30.h;
                double dist = (lensPos - Offset(x + 100.w, y + 100.h)).distance;
                bool isFocused = dist < 80.r;
                
                final bool isThisTarget = cleanWord.toLowerCase() == correct.toLowerCase();
                final bool showAsCorrect = isAnswered && isThisTarget;
                
                return GestureDetector(
                  onTap: () => onWordTap(cleanWord),
                  child: Opacity(
                    opacity: isFocused || isAnswered ? 1.0 : (isDark ? 0.3 : 0.15),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color: showAsCorrect 
                            ? Colors.greenAccent.withValues(alpha: isDark ? 0.3 : 0.2) 
                            : (isFocused ? color.withValues(alpha: 0.1) : null),
                        borderRadius: BorderRadius.circular(6.r),
                        border: showAsCorrect 
                            ? Border.all(color: Colors.greenAccent, width: 1.5) 
                            : null,
                      ),
                      child: Text(
                        w, 
                        style: TextStyle(fontFamily: 'Outfit', 
                          fontSize: 18.sp, 
                          color: showAsCorrect 
                              ? (isDark ? Colors.greenAccent : Colors.green) 
                              : (isFocused ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white54 : Colors.black54)), 
                          fontWeight: isFocused || showAsCorrect ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          // The Magnifying Lens
          Positioned(
            left: lensPos.dx - 60.r,
            top: lensPos.dy - 60.r,
            child: GestureDetector(
              onPanUpdate: (details) => onLensMove(lensPos + details.delta),
              child: Container(
                width: 120.r,
                height: 120.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12, width: 2),
                  boxShadow: [
                    BoxShadow(color: isDark ? Colors.black54 : Colors.black12, blurRadius: 20, spreadRadius: 5),
                  ],
                ),
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05), Colors.transparent],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.center_focus_strong_rounded,
                          color: color.withValues(alpha: 0.4),
                          size: 32.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
