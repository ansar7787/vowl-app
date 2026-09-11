import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/gestures.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';

class EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'eagerPan';
}

class DetailSpotlightDarkField extends StatefulWidget {
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
  State<DetailSpotlightDarkField> createState() =>
      _DetailSpotlightDarkFieldState();
}

class _DetailSpotlightDarkFieldState extends State<DetailSpotlightDarkField> {
  final _hapticService = di.sl<HapticService>();
  final Set<int> _litIndices = {};

  @override
  void initState() {
    super.initState();
    widget.spotlightPos.addListener(_checkHaptics);
  }

  @override
  void dispose() {
    widget.spotlightPos.removeListener(_checkHaptics);
    super.dispose();
  }

  void _checkHaptics() {
    if (!mounted) return;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final constraints = renderBox.size;
    final pos = widget.spotlightPos.value;

    for (int index = 0; index < widget.options.length; index++) {
      double tileW = (constraints.width - 48.w) / 2;
      double tileH = 80.h;

      double x = (index % 2 == 0) ? 16.w : (constraints.width / 2 + 8.w);

      double y;
      if (index < 2) {
        y = 40.h;
      } else if (index < 4) {
        y = constraints.height - 120.h;
      } else {
        y = constraints.height / 2 - (tileH / 2);
      }

      double dist = (pos - Offset(x + tileW / 2, y + tileH / 2)).distance;
      bool isLit = dist < 85.r;

      if (isLit && !_litIndices.contains(index)) {
        _litIndices.add(index);
        _hapticService.light();
      } else if (!isLit && _litIndices.contains(index)) {
        _litIndices.remove(index);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (widget.spotlightPos.value == const Offset(0, 0)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.spotlightPos.value == const Offset(0, 0)) {
              widget.spotlightPos.value = Offset(
                constraints.maxWidth / 2,
                constraints.maxHeight / 2,
              );
            }
          });
        }

        return ValueListenableBuilder<Offset>(
          valueListenable: widget.spotlightPos,
          builder: (context, pos, _) {
            final safePos = pos == const Offset(0, 0)
                ? Offset(constraints.maxWidth / 2, constraints.maxHeight / 2)
                : pos;

            return Stack(
              children: [
                // The Shadow Layer (Captures Drags Everywhere and blocks ScrollView)
                RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    EagerPanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          EagerPanGestureRecognizer
                        >(() => EagerPanGestureRecognizer(), (
                          EagerPanGestureRecognizer instance,
                        ) {
                          instance.onDown = (details) {
                            double nextX = details.localPosition.dx.clamp(
                              40.r,
                              constraints.maxWidth - 40.r,
                            );
                            double nextY = details.localPosition.dy.clamp(
                              40.r,
                              constraints.maxHeight - 40.r,
                            );
                            widget.onSearch(Offset(nextX, nextY));
                          };
                          instance.onUpdate = (details) {
                            double nextX = details.localPosition.dx.clamp(
                              40.r,
                              constraints.maxWidth - 40.r,
                            );
                            double nextY = details.localPosition.dy.clamp(
                              40.r,
                              constraints.maxHeight - 40.r,
                            );
                            widget.onSearch(Offset(nextX, nextY));
                          };
                        }),
                  },
                  child: Container(
                    width: double.infinity,
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(
                        color: widget.color.withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                ),

                ...List.generate(widget.options.length, (index) {
                  double tileW = (constraints.maxWidth - 48.w) / 2;
                  double tileH = 80.h;

                  double x = (index % 2 == 0)
                      ? 16.w
                      : (constraints.maxWidth / 2 + 8.w);

                  double y;
                  if (index < 2) {
                    y = 40.h;
                  } else if (index < 4) {
                    y = constraints.maxHeight - 120.h;
                  } else {
                    y = constraints.maxHeight / 2 - (tileH / 2);
                  }

                  double dist =
                      (safePos - Offset(x + tileW / 2, y + tileH / 2)).distance;
                  bool isLit = dist < 85.r;

                  return Positioned(
                    left: x,
                    top: y,
                    child: GestureDetector(
                      onTap: () => widget.onSelect(index),
                      child: Builder(
                        builder: (context) {
                          bool isSelected = widget.selectedIndex == index;
                          bool isActuallyCorrect =
                              index == widget.correctAnswerIndex;

                          bool isCorrectStateUI =
                              widget.isAnswered &&
                              isActuallyCorrect &&
                              widget.selectedIndex == index;

                          bool isWrongStateUI =
                              widget.isAnswered &&
                              isSelected &&
                              widget.isCorrectState == false;

                          Color tileColor = isCorrectStateUI
                              ? Colors.greenAccent
                              : (isWrongStateUI
                                    ? Colors.redAccent
                                    : Colors.white);

                          bool shouldReveal =
                              isLit ||
                              isCorrectStateUI ||
                              isWrongStateUI ||
                              (widget.isAnswered && isActuallyCorrect);

                          return Opacity(
                            opacity: shouldReveal ? 1.0 : 0.05,
                            child: AnimatedContainer(
                              duration: 300.ms,
                              width: tileW,
                              height: tileH,
                              decoration: BoxDecoration(
                                color: shouldReveal
                                    ? tileColor.withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20.r),
                                border: Border.all(
                                  color: shouldReveal
                                      ? tileColor.withValues(alpha: 0.4)
                                      : Colors.transparent,
                                  width:
                                      (isCorrectStateUI ||
                                          isWrongStateUI ||
                                          (widget.isAnswered &&
                                              isActuallyCorrect))
                                      ? 2
                                      : 1,
                                ),
                              ),
                              child: Center(
                                child: FittedBox(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.r),
                                    child: Text(
                                      widget.options[index],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
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

                AnimatedPositioned(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  left: safePos.dx - 40.r,
                  top: safePos.dy - 40.r,
                  child: IgnorePointer(
                    child: Container(
                      width: 80.r,
                      height: 80.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        border: Border.all(
                          color: Colors.yellowAccent,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.yellowAccent.withValues(alpha: 0.4),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.yellowAccent.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child:
                            Icon(
                                  Icons.flare_rounded,
                                  color: Colors.yellowAccent,
                                  size: 28.r,
                                )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scale(
                                  begin: const Offset(0.8, 0.8),
                                  end: const Offset(1.1, 1.1),
                                  duration: 1000.ms,
                                ),
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
