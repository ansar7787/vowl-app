import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AudioFillBlanksJar extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;

  const AudioFillBlanksJar({
    super.key,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        width: 100.r,
        height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 20,
            )
          ],
        ),
        child: Icon(Icons.graphic_eq_rounded, size: 40.r, color: color),
      ),
    );
  }
}
