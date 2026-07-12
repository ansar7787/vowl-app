import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class DetailSpotlightEmitter extends StatelessWidget {
  final VoidCallback onTap;
  final Color color;
  final String? emoji;
  final bool? isCorrectState;

  const DetailSpotlightEmitter({
    super.key,
    required this.onTap,
    required this.color,
    this.emoji,
    this.isCorrectState,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: isCorrectState == true && emoji != null
            ? Text(
                emoji!,
                style: TextStyle(fontSize: 48.r),
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
            : Icon(Icons.graphic_eq_rounded, color: color, size: 48.r),
      ),
    );
  }
}
