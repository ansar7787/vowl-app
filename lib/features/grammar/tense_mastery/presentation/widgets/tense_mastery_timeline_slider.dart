import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Interactive timeline slider component for toggling between past, present, and future tenses.
class TenseMasteryTimelineSlider extends StatefulWidget {
  /// The normalized position of the slider knob (0.0 to 1.0).
  final double sliderValue;

  /// The label of the currently selected tense.
  final String currentTense;

  /// Whether the user has answered the current question.
  final bool isAnswered;

  /// Whether the slider knob is actively being dragged.
  final bool isDragging;

  /// Whether dark theme styling is active.
  final bool isDark;

  /// The primary accent color for active timeline tracks and nodes.
  final Color primaryColor;

  /// Callback triggered to produce light haptic feedback.
  final VoidCallback onHapticFeedback;

  /// Callback triggered to produce heavy haptic feedback on snap points.
  final VoidCallback onHeavyHapticFeedback;

  /// Callback invoked when the slider position changes.
  final ValueChanged<double> onSliderChanged;

  /// Callback invoked when dragging state transitions start or end.
  final ValueChanged<bool> onDraggingChanged;

  /// Creates a [TenseMasteryTimelineSlider] widget.
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
    final sphereWidth = 54.r;
    final tenses = ["Past", "Present", "Future"];
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Container(
      height: 110.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                top: (sphereWidth / 2) - 2.5.h,
                left: 10.w,
                right: 10.w,
                child: Container(
                  height: 5.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: widget.isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
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
                        if (widget.isAnswered) {
                          return;
                        }
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
                        width: 72.w,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              height: sphereWidth,
                              alignment: Alignment.center,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isCurrent ? 14.r : 10.r,
                                height: isCurrent ? 14.r : 10.r,
                                decoration: BoxDecoration(
                                  color: isCurrent
                                      ? widget.primaryColor
                                      : (widget.isDark
                                            ? Colors.white24
                                            : Colors.black26),
                                  shape: BoxShape.circle,
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: widget.primaryColor
                                                .withValues(alpha: 0.35),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              tense.toUpperCase(),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: isCurrent
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isCurrent
                                    ? widget.primaryColor
                                    : (widget.isDark
                                          ? Colors.white70
                                          : Colors.black54),
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // The Draggable Slider Handle
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
                      if (widget.isAnswered) {
                        return;
                      }
                      _dragValue = widget.sliderValue;
                      widget.onDraggingChanged(true);
                    },
                    onHorizontalDragUpdate: (details) {
                      if (widget.isAnswered) {
                        return;
                      }
                      widget.onDraggingChanged(true);
                      _dragValue = (_dragValue + details.delta.dx / maxLeft)
                          .clamp(0.0, 1.0);
                      widget.onSliderChanged(_dragValue);

                      if ((_dragValue - 0.0).abs() < 0.02 ||
                          (_dragValue - 0.5).abs() < 0.02 ||
                          (_dragValue - 1.0).abs() < 0.02) {
                        widget.onHapticFeedback();
                      }
                    },
                    onHorizontalDragEnd: (details) {
                      if (widget.isAnswered) {
                        return;
                      }
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
                            color: widget.isDark
                                ? const Color(0xFF1E1E24)
                                : Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 16,
                                spreadRadius: 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                            border: Border.all(
                              color: widget.primaryColor,
                              width: 3.5.r,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.timer_rounded,
                              color: widget.primaryColor,
                              size: 24.r,
                            ),
                          ),
                        );

                        if (reduceMotion) {
                          return sphere;
                        }
                        return sphere
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .shimmer(
                              duration: 1800.ms,
                              color: widget.primaryColor.withValues(
                                alpha: 0.15,
                              ),
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
