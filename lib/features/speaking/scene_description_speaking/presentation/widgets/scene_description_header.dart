import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction pill header at the top of the scene description challenge.
class SceneDescriptionHeader extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Specific pedagogical instruction text.
  final String instruction;

  /// Creates a [SceneDescriptionHeader].
  const SceneDescriptionHeader({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: instruction,
      child: Container(
        key: const Key('scene_description_header'),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.gps_fixed_rounded, size: 16.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                instruction,
                key: const Key('scene_description_header_text'),
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
