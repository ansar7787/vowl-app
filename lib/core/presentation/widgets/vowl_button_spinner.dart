import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VowlButtonSpinner extends StatelessWidget {
  final Color color;
  final double size;

  const VowlButtonSpinner({
    super.key,
    this.color = Colors.white,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return Container(
          margin: EdgeInsets.symmetric(horizontal: size * 0.05),
          width: size * 0.2,
          height: size * 0.2,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ).animate(
          onPlay: (controller) => controller.repeat(),
          delay: (index * 150).ms,
        ).scale(
          begin: const Offset(0.6, 0.6),
          end: const Offset(1.2, 1.2),
          duration: 500.ms,
          curve: Curves.easeInOut,
        ).then().scale(
          begin: const Offset(1.2, 1.2),
          end: const Offset(0.6, 0.6),
          duration: 500.ms,
          curve: Curves.easeInOut,
        );
      }),
    );
  }
}
