import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Lightweight, 120Hz-fluid audio resonance equalizer visualizer.
///
/// Features 4 reactive vertical bars that pulse smoothly when audio is actively
/// playing, giving instant tactile visual feedback to pronunciation.
class FlashcardAudioVisualizer extends StatefulWidget {
  /// Whether audio is actively playing or resonating.
  final bool isPlaying;

  /// Custom bar color, defaults to theme primary.
  final Color? color;

  /// Total height of the visualizer container.
  final double? height;

  const FlashcardAudioVisualizer({
    super.key,
    required this.isPlaying,
    this.color,
    this.height,
  });

  @override
  State<FlashcardAudioVisualizer> createState() =>
      _FlashcardAudioVisualizerState();
}

class _FlashcardAudioVisualizerState extends State<FlashcardAudioVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    if (widget.isPlaying) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant FlashcardAudioVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat(reverse: true);
      } else {
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 250));
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
    final activeColor = widget.color ?? AppColors.indigo500;
    final totalH = widget.height ?? 20.h;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          // Staggered sine heights for organic audio wave feel
          final h0 = widget.isPlaying ? (0.35 + 0.65 * (0.5 + 0.5 * t)) : 0.35;
          final h1 = widget.isPlaying
              ? (0.25 + 0.75 * (0.5 + 0.5 * (1.0 - t)))
              : 0.25;
          final h2 = widget.isPlaying
              ? (0.40 + 0.60 * (0.5 + 0.5 * ((t + 0.5) % 1.0)))
              : 0.40;
          final h3 = widget.isPlaying ? (0.30 + 0.70 * (0.5 + 0.5 * t)) : 0.30;

          return SizedBox(
            height: totalH,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar(totalH * h0, activeColor),
                SizedBox(width: 3.w),
                _buildBar(totalH * h1, activeColor),
                SizedBox(width: 3.w),
                _buildBar(totalH * h2, activeColor),
                SizedBox(width: 3.w),
                _buildBar(totalH * h3, activeColor),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBar(double height, Color color) {
    return Container(
      width: 3.5.w,
      height: height.clamp(4.0, 36.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
        boxShadow: widget.isPlaying
            ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 4.r)]
            : null,
      ),
    );
  }
}
