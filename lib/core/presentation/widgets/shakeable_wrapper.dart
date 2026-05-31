import 'package:flutter/material.dart';

/// A wrapper widget that plays a premium, physically-damped horizontal shake animation
/// when [shakeCount] increments, while perfectly preserving child widget state,
/// text input focus, and keyboard states.
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
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _initAnimation();
  }

  void _initAnimation() {
    // Premium decaying oscillation sequence simulating a physical horizontal spring damping effect
    _offsetAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 10),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: -0.8).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.8, end: 0.6).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: -0.4).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.4, end: 0.2).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: -0.1).chain(CurveTween(curve: Curves.easeInOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant ShakeableWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.duration != oldWidget.duration) {
      _controller.duration = widget.duration;
    }
    // Trigger shake only if the shakeCount increases
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
      builder: (context, child) {
        final dx = _offsetAnimation.value * widget.offset;
        return Transform.translate(
          offset: Offset(dx, 0.0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
