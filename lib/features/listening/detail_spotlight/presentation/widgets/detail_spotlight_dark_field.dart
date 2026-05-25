import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailSpotlightDarkField extends StatelessWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final ValueNotifier<Offset> spotlightPos;
  final Function(Offset) onSearch;
  final Function(int) onSelect;

  const DetailSpotlightDarkField({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.spotlightPos,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Initialize position to center if it was reset
        if (spotlightPos.value == const Offset(0, 0)) {
          spotlightPos.value = Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
        }

        return ValueListenableBuilder<Offset>(
          valueListenable: spotlightPos,
          builder: (context, pos, _) {
            return Stack(
              children: [
                // The Shadow Layer (Captures Drags Everywhere)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    double nextX = (pos.dx + details.delta.dx).clamp(40.r, constraints.maxWidth - 40.r);
                    double nextY = (pos.dy + details.delta.dy).clamp(40.r, constraints.maxHeight - 40.r);
                    onSearch(Offset(nextX, nextY));
                  },
                  child: Container(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: color.withValues(alpha: 0.1)),
                    ),
                  ),
                ),
                
                // Hidden Options
                ...List.generate(options.length, (index) {
                  double tileW = (constraints.maxWidth - 48.w) / 2;
                  double tileH = 80.h;
                  
                  double x = (index % 2 == 0) ? 16.w : (constraints.maxWidth / 2 + 8.w);
                  double y = (index < 2) ? 40.h : (constraints.maxHeight - 120.h);
                  
                  double dist = (pos - Offset(x + tileW / 2, y + tileH / 2)).distance;
                  bool isLit = dist < 80.r;
                  
                  return Positioned(
                    left: x,
                    top: y,
                    child: GestureDetector(
                      onTap: () => onSelect(index),
                      child: Builder(
                        builder: (context) {
                          bool isSelected = selectedIndex == index;
                          bool isCorrect = isAnswered && index == correctAnswerIndex && selectedIndex == index;
                          bool isWrong = isAnswered && isSelected && isCorrectState == false;
                          Color tileColor = isCorrect
                              ? Colors.greenAccent
                              : (isWrong ? Colors.redAccent : Colors.white);
                          
                          return Opacity(
                            opacity: isLit || isCorrect || isWrong ? 1.0 : 0.05,
                            child: AnimatedContainer(
                              duration: 300.ms,
                              width: tileW,
                              height: tileH,
                              decoration: BoxDecoration(
                                color: (isLit || isCorrect || isWrong) ? tileColor.withValues(alpha: 0.1) : Colors.transparent,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: (isLit || isCorrect || isWrong) ? tileColor.withValues(alpha: 0.4) : Colors.transparent,
                                  width: (isCorrect || isWrong) ? 2 : 1,
                                ),
                              ),
                              child: Center(
                                child: FittedBox(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.r),
                                    child: Text(
                                      options[index],
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.outfit(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w700,
                                        color: tileColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }),
                
                // Spotlight Outer Lens Indicator
                Positioned(
                  left: pos.dx - 40.r,
                  top: pos.dy - 40.r,
                  child: IgnorePointer(
                    child: Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(color: Colors.yellowAccent, width: 3),
                        boxShadow: [
                          BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.4), blurRadius: 40, spreadRadius: 10),
                          BoxShadow(color: Colors.yellowAccent.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Center(
                        child: Icon(Icons.flash_on_rounded, color: Colors.yellowAccent, size: 24.r)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.1, 1.1), duration: 1000.ms),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
