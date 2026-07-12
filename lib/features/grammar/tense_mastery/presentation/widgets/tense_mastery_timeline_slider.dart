import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TenseMasteryTimelineSlider extends StatelessWidget {
  final double sliderValue;
  final String currentTense;
  final bool isAnswered;
  final bool isDragging;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onHapticFeedback;
  final VoidCallback onHeavyHapticFeedback;
  final ValueChanged<double> onSliderChanged;
  final ValueChanged<bool> onDraggingChanged;

  const TenseMasteryTimelineSlider({
    super.key,
    required this.sliderValue,
    required this.currentTense,
    required this.isAnswered,
    required this.isDragging,
    required this.isDark,
    required this.primaryColor,
    required this.onHapticFeedback,
    required this.onHeavyHapticFeedback,
    required this.onSliderChanged,
    required this.onDraggingChanged,
  });

  @override
  Widget build(BuildContext context) {
    final sphereWidth = 60.r;
    final tenses = ["Past", "Present", "Future"];

    return Container(
      height: 120.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final maxLeft = trackWidth - sphereWidth;
          final leftPos = sliderValue * maxLeft;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // The Track
              Container(
                height: 6.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),

              // The Timeline Nodes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tenses.map((tense) {
                  final isCurrent = currentTense == tense;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (isAnswered) return;
                      onHapticFeedback();
                      onDraggingChanged(false);
                      if (tense == "Past") {
                        onSliderChanged(0.0);
                      } else if (tense == "Future") {
                        onSliderChanged(1.0);
                      } else {
                        onSliderChanged(0.5);
                      }
                    },
                    child: SizedBox(
                      width: sphereWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 14.r,
                            height: 14.r,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? primaryColor
                                  : (isDark ? Colors.white10 : Colors.black12),
                              shape: BoxShape.circle,
                              boxShadow: isCurrent
                                  ? [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 15,
                                        spreadRadius: 4,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                          SizedBox(height: 28.h),
                          Text(
                            tense.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: isCurrent
                                  ? FontWeight.w900
                                  : FontWeight.w600,
                              color: isCurrent
                                  ? primaryColor
                                  : (isDark ? Colors.white24 : Colors.black26),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // The Draggable Chrono-Sphere
              AnimatedPositioned(
                duration: isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: leftPos,
                child: GestureDetector(
                  onHorizontalDragStart: (_) {
                    if (isAnswered) return;
                    onDraggingChanged(true);
                  },
                  onHorizontalDragUpdate: (details) {
                    if (isAnswered) return;
                    onDraggingChanged(true);
                    final newValue = (sliderValue + details.delta.dx / maxLeft)
                        .clamp(0.0, 1.0);
                    onSliderChanged(newValue);

                    if ((newValue - 0.0).abs() < 0.02 ||
                        (newValue - 0.5).abs() < 0.02 ||
                        (newValue - 1.0).abs() < 0.02) {
                      onHapticFeedback();
                    }
                  },
                  onHorizontalDragEnd: (details) {
                    if (isAnswered) return;
                    onDraggingChanged(false);
                    if (sliderValue < 0.25) {
                      onSliderChanged(0.0);
                    } else if (sliderValue > 0.75) {
                      onSliderChanged(1.0);
                    } else {
                      onSliderChanged(0.5);
                    }
                    onHeavyHapticFeedback();
                  },
                  child:
                      Container(
                            width: sphereWidth,
                            height: sphereWidth,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.4),
                                  blurRadius: 25,
                                  spreadRadius: 5,
                                ),
                              ],
                              border: Border.all(
                                color: primaryColor,
                                width: 6.r,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.timer_rounded,
                                color: primaryColor,
                                size: 28.r,
                              ),
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .shimmer(
                            duration: 1500.ms,
                            color: primaryColor.withValues(alpha: 0.2),
                          ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
