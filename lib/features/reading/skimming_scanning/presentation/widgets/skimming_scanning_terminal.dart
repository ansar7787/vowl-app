import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/tech_pattern_overlay.dart';

class SkimmingScanningTerminal extends StatelessWidget {
  final String text;
  final String correct;
  final Color color;
  final ScrollController scrollController;
  final bool isAnswered;
  final Function(String) onTapWord;

  const SkimmingScanningTerminal({
    super.key,
    required this.text,
    required this.correct,
    required this.color,
    required this.scrollController,
    required this.isAnswered,
    required this.onTapWord,
  });

  String _cleanWord(String word) {
    return word
        .replaceAll(RegExp(r'[.,\/#!$%\^&\*;:{}=\-_`~()\[\]]'), '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> words = text.split(RegExp(r'\s+'));

    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white10, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Scrolling Content
          ListView.builder(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            itemCount: (words.length / 4).ceil(),
            itemBuilder: (context, index) {
              int start = index * 4;
              int end = (start + 4).clamp(0, words.length);
              final List<String> rowWords = words.sublist(start, end);

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: rowWords.map((word) {
                    final clean = _cleanWord(word);
                    final isCorrectTarget =
                        clean.toLowerCase() == correct.toLowerCase();
                    final bool isTapped = isAnswered && isCorrectTarget;

                    return GestureDetector(
                      onTap: () => onTapWord(clean),
                      child: AnimatedContainer(
                        duration: 300.milliseconds,
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: isTapped
                              ? Colors.greenAccent.withValues(alpha: 0.25)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: isTapped
                                ? Colors.greenAccent
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          word,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            color: isTapped
                                ? Colors.greenAccent
                                : Colors.greenAccent.withValues(alpha: 0.8),
                            fontWeight: isTapped
                                ? FontWeight.bold
                                : FontWeight.normal,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),

          // CRT Overlay
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.r),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),

          // Scanline
          const Positioned.fill(child: TechPatternOverlay(opacity: 0.05)),
        ],
      ),
    );
  }
}
