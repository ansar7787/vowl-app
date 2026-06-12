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
      label: 'Play audio clip',
      hint: 'Tap to hear the phrase you need to transcribe',
      child: ScaleButton(
        onTap: onTap,
        child: Container(
          width: 100.r,
          height: 100.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 3),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20),
            ],
          ),
          // Icon sized at 40 % of the 100.r container diameter so it
          // scales correctly in both standard and FittedBox-compact modes.
          child: Center(
            child: Icon(Icons.graphic_eq_rounded, size: 40.r, color: color),
          ),
        ),
      ),
    );
  }
}
