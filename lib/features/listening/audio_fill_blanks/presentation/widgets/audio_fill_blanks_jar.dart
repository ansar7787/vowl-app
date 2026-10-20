import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

// =============================================================================
// AudioFillBlanksJar
// =============================================================================

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
    return Semantics(
      button: true,
      label: 'Play audio',
      hint: 'Tap to hear the sentence',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: 82.r,
          height: 82.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.32), width: 2.w),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Icon(Icons.graphic_eq_rounded, size: 36.r, color: color),
          ),
        ),
      ),
    );
  }
}
