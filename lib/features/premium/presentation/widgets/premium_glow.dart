import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StaticGlow extends StatelessWidget {
  final Color color;
  final double? radius;
  
  const StaticGlow({super.key, required this.color, this.radius});

  @override
  Widget build(BuildContext context) {
    final size = radius ?? 350.r;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: size * 0.25, spreadRadius: size * 0.1)],
      ),
    );
  }
}
