import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// =============================================================================
// AudioFillBlanksInstruction
// =============================================================================

class AudioFillBlanksInstruction extends StatelessWidget {
  final String instruction;
  final Color color;

  const AudioFillBlanksInstruction({
    super.key,
    required this.instruction,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: instruction,
      excludeSemantics: true, // children already covered by parent label
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              instruction.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'SCRATCH THE INK TO REVEAL TRANSCRIPTION',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.7),
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
