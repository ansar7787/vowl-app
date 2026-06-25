import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// Interactive card with a slow-drifting holographic neon-pastel gradient
/// sheen over a frosted-glass base. Rendering ticks are isolated behind a
/// [RepaintBoundary] so the gradient animation never invalidates the child.
class HolographicCard extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double padding;

  const HolographicCard({
    super.key,
    required this.child,
    this.borderRadius = 40,
    this.padding = 24,
  });

  @override
  State<HolographicCard> createState() => _HolographicCardState();
}

class _HolographicCardState extends State<HolographicCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Static gradient colour stops — const to avoid per-frame allocation.
  static const List<Color> _darkColors = [
    Color(0x144F46E5), // Brand Indigo  @ 0.08 alpha
    Color(0x1A38BDF8), // Sky Blue      @ 0.10 alpha
    Color(0x1410B981), // Brand Emerald @ 0.08 alpha
    Color(0x1A38BDF8), // Sky Blue      @ 0.10 alpha
    Color(0x144F46E5), // Brand Indigo  @ 0.08 alpha
  ];
  static const List<Color> _lightColors = [
    Color(0x0A4F46E5),
    Color(0x0D38BDF8),
    Color(0x0A10B981),
    Color(0x0D38BDF8),
    Color(0x0A4F46E5),
  ];
  static const List<double> _colorStops = [0.0, 0.25, 0.5, 0.75, 1.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassTile(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(widget.borderRadius.r),
      child: Stack(
        children: [
          // 1. Holographic sheen layer — isolated to prevent child repaints.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) {
                    final p = _controller.value;
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark ? _darkColors : _lightColors,
                          stops: _colorStops,
                          begin: Alignment(-2.0 + p * 2.0, -1.0),
                          end: Alignment(-1.0 + p * 2.0, 1.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 2. Content layer.
          Padding(
            padding: EdgeInsets.all(widget.padding.r),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
