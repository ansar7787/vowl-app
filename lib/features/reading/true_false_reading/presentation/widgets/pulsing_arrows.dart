import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Animated directional arrow indicators prompting coin flick or swipe gestures.
class PulsingArrows extends StatefulWidget {
  /// Theme accent color applied to arrows.
  final Color color;

  /// Whether the arrows point left toward the False drop zone.
  final bool isLeft;

  /// Creates a [PulsingArrows] widget.
  const PulsingArrows({super.key, required this.color, this.isLeft = false});

  @override
  State<PulsingArrows> createState() => _PulsingArrowsState();
}

class _PulsingArrowsState extends State<PulsingArrows>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (VowlMotion.shouldReduceMotion(context)) {
      _controller.stop();
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.35 + (_controller.value * 0.45),
          child: Transform.translate(
            offset: Offset((widget.isLeft ? -4.w : 4.w) * _controller.value, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLeft) ...[
                  Icon(
                    Icons.chevron_left_rounded,
                    color: widget.color,
                    size: 22.r,
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: widget.color,
                    size: 22.r,
                  ),
                ] else ...[
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.color,
                    size: 22.r,
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.color,
                    size: 22.r,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
