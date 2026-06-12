import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Pill-shaped instruction label telling the user to flick the word into a
/// vortex.
class SpeechInstruction extends StatelessWidget {
  final Color primaryColor;

  const SpeechInstruction({super.key, required this.primaryColor});

  static const _label = 'FLICK INTO THE VORTEX';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: _label,
      child: Container(
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
            Text(
              _label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
