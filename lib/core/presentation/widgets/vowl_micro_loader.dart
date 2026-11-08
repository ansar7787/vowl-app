import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Modern, sleek 3-dot animated micro-loader for buttons and inline status indicators.
/// Replaces outdated CircularProgressIndicators with a smooth pulsing wave.
class VowlMicroLoader extends StatelessWidget {
  final Color color;
  final double size;

  const VowlMicroLoader({super.key, this.color = Colors.white, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final dotSize = (size / 3.2).clamp(3.0, 8.0);
    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          return Container(
                width: dotSize,
                height: dotSize,
                margin: EdgeInsets.symmetric(horizontal: dotSize * 0.3),
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                delay: Duration(milliseconds: index * 150),
                duration: const Duration(milliseconds: 350),
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.15, 1.15),
              )
              .fade(
                delay: Duration(milliseconds: index * 150),
                duration: const Duration(milliseconds: 350),
                begin: 0.3,
                end: 1.0,
              );
        }),
      ),
    );
  }
}
