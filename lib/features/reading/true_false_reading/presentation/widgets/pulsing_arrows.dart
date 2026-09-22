import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PulsingArrows extends StatefulWidget {
  final Color color;
  final bool isLeft;

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
    )..repeat(reverse: true);
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
          opacity: 0.3 + (_controller.value * 0.5),
          child: Transform.translate(
            offset: Offset((widget.isLeft ? -5.w : 5.w) * _controller.value, 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLeft) ...[
                  Icon(
                    Icons.chevron_left_rounded,
                    color: widget.color,
                    size: 28.r,
                  ),
                  Icon(
                    Icons.chevron_left_rounded,
                    color: widget.color,
                    size: 28.r,
                  ),
                ] else ...[
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.color,
                    size: 28.r,
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: widget.color,
                    size: 28.r,
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
