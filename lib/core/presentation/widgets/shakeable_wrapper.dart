import 'package:flutter/material.dart';

/// Plays a physically-damped horizontal shake when [shakeCount] increments,
/// while perfectly preserving child widget state, text-input focus, and
/// keyboard visibility.
///
/// The child is wrapped in a [RepaintBoundary] so its repaints do not
/// propagate into the transform layer, and vice-versa.
class ShakeableWrapper extends StatefulWidget {
  final int shakeCount;
  final Widget child;
  final Duration duration;
  final double offset;

  const ShakeableWrapper({
    super.key,
    required this.shakeCount,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.offset = 8.0,
  });

  @override
  State<ShakeableWrapper> createState() => _ShakeableWrapperState();
}

class _ShakeableWrapperState extends State<ShakeableWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _initAnimation();
  }

  void _initAnimation() {
    // Decaying oscillation sequence simulating a horizontal spring damping.
    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: -0.8,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.8,
          end: 0.6,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: -0.4,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.4,
          end: 0.2,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.2,
          end: -0.1,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.1,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant ShakeableWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    if (widget.shakeCount != oldWidget.shakeCount && widget.shakeCount > 0) {
      _controller.forward(from: 0.0);
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
      animation: _offsetAnimation,
      // Wrapping child in RepaintBoundary isolates its repaints from the
      // transform layer, preventing child rebuilds from invalidating the
      // shake animation compositing layer.
      child: RepaintBoundary(child: widget.child),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_offsetAnimation.value * widget.offset, 0.0),
          child: child,
        );
      },
    );
  }
}
