import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/glass_tile.dart';

class HolographicCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GlassTile(
      padding: EdgeInsets.all(padding.r),
      borderRadius: BorderRadius.circular(borderRadius.r),
      child: child,
    );
  }
}
