import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StaticGlow extends StatelessWidget {
  final Color color;
  const StaticGlow({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350.r,
      height: 350.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 40)],
      ),
    );
  }
}
