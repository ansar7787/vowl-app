import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

/// A button that scales down slightly when pressed, providing organic tactile
/// feedback. Includes a 500 ms debounce guard against accidental double-taps.
///
/// Wraps content in [Semantics] with `button: true` so TalkBack / VoiceOver
/// correctly announces interactive elements to screen-reader users.
class ScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDown;
  final Duration duration;

  const ScaleButton({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<ScaleButton> createState() => _ScaleButtonState();
}

class _ScaleButtonState extends State<ScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant ScaleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.scaleDown != widget.scaleDown) {
      _scaleAnimation = Tween<double>(
        begin: 1.0,
        end: widget.scaleDown,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onTap == null) return;
    final now = clock.now();
    if (_lastTapTime == null ||
        now.difference(_lastTapTime!) > const Duration(milliseconds: 500)) {
      _lastTapTime = now;
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: widget.onTap != null,
      enabled: widget.onTap != null,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onTap != null) _controller.forward();
        },
        onTapUp: (_) {
          if (widget.onTap != null) _controller.reverse();
        },
        onTapCancel: () {
          if (widget.onTap != null) _controller.reverse();
        },
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: ScaleTransition(scale: _scaleAnimation, child: widget.child),
      ),
    );
  }
}
