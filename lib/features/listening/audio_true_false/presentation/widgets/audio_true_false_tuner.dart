import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class AudioTrueFalseTuner extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final bool? isCorrectState;

  const AudioTrueFalseTuner({
    super.key,
    required this.onTap,
    required this.color,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.15),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 16,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Icon(Icons.graphic_eq_rounded, color: color, size: 48.r),
      ),
    );
  }
}
