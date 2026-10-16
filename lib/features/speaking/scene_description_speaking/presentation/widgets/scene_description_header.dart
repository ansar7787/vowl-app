import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SceneDescriptionHeader extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

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
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.gps_fixed_rounded, size: 14.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                instruction.toUpperCase(),
                key: const Key('scene_description_header_text'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
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
