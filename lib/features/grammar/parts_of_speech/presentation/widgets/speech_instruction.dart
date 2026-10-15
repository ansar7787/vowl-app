import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Pill-shaped instruction label telling the user to flick the word into a
/// vortex.
class SpeechInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const SpeechInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  static const _label = 'FLICK OR TAP TO ANSWER';

  @override
  Widget build(BuildContext context) {
    final text = instruction ?? _label;
    return Semantics(
      label: text,
      child: Container(
        key: const ValueKey('speech_instruction'),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cyclone_rounded, size: 14.r, color: primaryColor),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w900,
                  color: primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
