import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// =============================================================================
// AudioFillBlanksInstruction
// =============================================================================

class AudioFillBlanksInstruction extends StatelessWidget {
  final Color color;

  const AudioFillBlanksInstruction({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Smear the ink to reveal the transcription',
      excludeSemantics: true, // children already covered by parent label
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative icon — semantics provided by parent container.
            ExcludeSemantics(
              child: Icon(Icons.water_drop_rounded, size: 14.r, color: color),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                'SMEAR THE INK TO REVEAL TRANSCRIPTION',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: color,
                  letterSpacing: 1.2,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
