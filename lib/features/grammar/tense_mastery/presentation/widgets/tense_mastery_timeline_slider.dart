import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class TenseMasteryTimelineSlider extends StatefulWidget {
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
  State<TenseMasteryTimelineSlider> createState() =>
      _TenseMasteryTimelineSliderState();
}

class _TenseMasteryTimelineSliderState
    extends State<TenseMasteryTimelineSlider> {
  late double _dragValue;

  @override
  void initState() {
    super.initState();
    _dragValue = widget.sliderValue;
  }

  @override
  void didUpdateWidget(covariant TenseMasteryTimelineSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isDragging) {
      _dragValue = widget.sliderValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sphereWidth = 60.r;
    final tenses = ["Past", "Present", "Future"];
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Container(
      height: 120.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 30.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final maxLeft = trackWidth - sphereWidth;
          final leftPos = widget.sliderValue * maxLeft;

          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // The Track
              Positioned(
                top: (sphereWidth / 2) - 3.h,
                left: 0,
                right: 0,
                child: Container(
                  height: 6.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
              ),

              // The Timeline Nodes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: tenses.map((tense) {
                  final isCurrent = widget.currentTense == tense;
                  return Semantics(
                    label: '$tense Tense',
                    hint: isCurrent
                        ? 'Currently selected'
                        : 'Double tap to select $tense tense',
                    selected: isCurrent,
                    button: true,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('tense_node_${tense.toLowerCase()}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (widget.isAnswered) return;
                        widget.onHapticFeedback();
                        widget.onDraggingChanged(false);
                        if (tense == "Past") {
                          _dragValue = 0.0;
                          widget.onSliderChanged(0.0);
                        } else if (tense == "Future") {
                          _dragValue = 1.0;
                          widget.onSliderChanged(1.0);
                        } else {
                          _dragValue = 0.5;
                          widget.onSliderChanged(0.5);
                        }
                      },
                      child: SizedBox(
                        width: sphereWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: sphereWidth,
                              alignment: Alignment.center,
                              child: Container(
                                width: 14.r,
                                height: 14.r,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? widget.primaryColor
                                      : (widget.isDark
                                            ? Colors.white10
                                            : Colors.black12),
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: widget.primaryColor.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 15,
                                            spreadRadius: 4,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                            SizedBox(height: 8.h),
                            SizedBox(
                              width: sphereWidth,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  tense.toUpperCase(),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: isCurrent
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: isCurrent
                                        ? widget.primaryColor
                                        : (widget.isDark
                                              ? Colors.white24
                                              : Colors.black26),
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // The Draggable Chrono-Sphere
              AnimatedPositioned(
                duration: widget.isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: leftPos,
                top: 0,
                child: Semantics(
                  label: 'Timeline Slider',
                  hint:
                      'Drag left for Past, right for Future, center for Present',
                  value: widget.currentTense,
                  slider: true,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) {
                      if (widget.isAnswered) return;
                      _dragValue = widget.sliderValue;
                      widget.onDraggingChanged(true);
                    },
                    onHorizontalDragUpdate: (details) {
                      if (widget.isAnswered) return;
                      widget.onDraggingChanged(true);
                      _dragValue =
                          (_dragValue + details.delta.dx / maxLeft).clamp(
                            0.0,
                            1.0,
                          );
                      widget.onSliderChanged(_dragValue);

                      if ((_dragValue - 0.0).abs() < 0.02 ||
                          (_dragValue - 0.5).abs() < 0.02 ||
                          (_dragValue - 1.0).abs() < 0.02) {
                        widget.onHapticFeedback();
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      if (widget.isAnswered) return;
                      widget.onDraggingChanged(false);
                      if (_dragValue < 0.25) {
                        _dragValue = 0.0;
                        widget.onSliderChanged(0.0);
                      } else if (_dragValue > 0.75) {
                        _dragValue = 1.0;
                        widget.onSliderChanged(1.0);
                      } else {
                        _dragValue = 0.5;
                        widget.onSliderChanged(0.5);
                      }
                      widget.onHeavyHapticFeedback();
                    },
                    child: Builder(
                      builder: (context) {
                        final sphere = Container(
                          key: const ValueKey('tense_chrono_sphere'),
                          width: sphereWidth,
                          height: sphereWidth,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 25,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: widget.primaryColor,
                              width: 6.r,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.timer_rounded,
                              color: widget.primaryColor,
                              size: 28.r,
                            ),
                          ),
                        );

                        if (reduceMotion) return sphere;
                        return sphere
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              duration: 1500.ms,
                              color: widget.primaryColor.withValues(alpha: 0.2),
                            );
                      },
                    ),
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
