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
      padding: EdgeInsets.all(widget.padding.r),
      borderRadius: BorderRadius.circular(widget.borderRadius.r),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius.r),
        child: Stack(
          children: [
            widget.child,
            // High-Performance Animated Holographic Sheen Layer
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
                              const Color(0xFF60A5FA).withValues(alpha: isDark ? 0.08 : 0.04), // Neon Blue
                              const Color(0xFFC084FC).withValues(alpha: isDark ? 0.12 : 0.06), // Cyber Purple
                              const Color(0xFFF472B6).withValues(alpha: isDark ? 0.08 : 0.04), // Electric Pink
                              const Color(0xFFFBBF24).withValues(alpha: isDark ? 0.06 : 0.03), // Aurora Gold
                              const Color(0xFF34D399).withValues(alpha: isDark ? 0.08 : 0.04), // Cyber Mint
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
          ],
        ),
      ),
    );
  }
}
