import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

/// A premium, state-of-the-art interactive card widget presenting a gorgeous,
/// slow-drifting holographic neon pastel gradient sheen on top of a Frosted Glass base,
/// highly optimized to isolate rendering ticks via a RepaintBoundary.
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
          // 1. High-Performance Animated Holographic Sheen Layer (Behind Content)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final double progress = _controller.value;
                    
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.08 : 0.04), // Brand Indigo
                            const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.10 : 0.05), // Sky Blue
                            const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.04), // Brand Emerald
                            const Color(0xFF38BDF8).withValues(alpha: isDark ? 0.10 : 0.05), // Sky Blue
                            const Color(0xFF4F46E5).withValues(alpha: isDark ? 0.08 : 0.04), // Brand Indigo
                          ],
                          stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                          begin: Alignment(-2.0 + progress * 2.0, -1.0),
                          end: Alignment(-1.0 + progress * 2.0, 1.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // 2. Unclipped Content Layer (On Top)
          Padding(
            padding: EdgeInsets.all(widget.padding.r),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
