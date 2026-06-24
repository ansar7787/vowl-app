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
                instruction.toUpperCase(),
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
