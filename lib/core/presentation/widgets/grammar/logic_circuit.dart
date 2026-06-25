import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A performance-optimized background logic circuit decoration for grammar maps.
class LogicCircuit extends StatelessWidget {
  final Color color;
  const LogicCircuit({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: List.generate(6, (index) {
          final isVertical = index % 2 == 0;
          final startPos = (index * 0.15) * (isVertical ? 1.sw : 1.sh);

          return PositionedDirectional(
            start: isVertical ? startPos : 0,
            top: isVertical ? 0 : startPos,
            end: isVertical ? null : 0,
            bottom: isVertical ? 0 : null,
            child: Opacity(
              opacity: 0.1,
              child: Container(
                // BUG FIX: the horizontal-line branch used `1.sh` (screen
                // *height*) as the line's *width* — should be `1.sw`.
                // This was masked because the PositionedDirectional above
                // already sets both `start:0` and `end:0` for horizontal
                // lines, which forces a tight full-width constraint that
                // overrides whatever width the Container itself requests —
                // so visually nothing was wrong today, but the moment
                // those constraints ever change (e.g. someone adds inset
                // padding here), this would have silently rendered a line
                // sized to the screen's height instead of its width.
                width: isVertical ? 2.w : 1.sw,
                height: isVertical ? 1.sh : 2.w,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: isVertical
                        ? Alignment.topCenter
                        : Alignment.centerLeft,
                    end: isVertical
                        ? Alignment.bottomCenter
                        : Alignment.centerRight,
                    colors: [
                      color.withValues(alpha: 0),
                      color.withValues(alpha: 0.5),
                      color.withValues(alpha: 0),
                    ],
                  ),
                ),
                child: Stack(
                  children: List.generate(3, (pIndex) {
                    return Positioned(
                          left: isVertical ? 0 : (pIndex * 0.3).sw,
                          top: isVertical ? (pIndex * 0.3).sh : 0,
                          child: Container(
                            width: 6.r,
                            height: 6.r,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat())
                        .move(
                          begin: isVertical
                              ? const Offset(0, -200)
                              : const Offset(-200, 0),
                          end: isVertical ? Offset(0, 1.sh) : Offset(1.sw, 0),
                          duration: (2000 + index * 500).ms,
                          curve: Curves.linear,
                        );
                  }),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
