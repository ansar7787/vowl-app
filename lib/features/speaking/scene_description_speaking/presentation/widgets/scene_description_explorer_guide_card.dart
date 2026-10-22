import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color131326 = Color(0xFF131326);
}

class SceneDescriptionExplorerGuideCard extends StatelessWidget {
  final bool isDark;

  const SceneDescriptionExplorerGuideCard({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Tap any item on the scene above to describe it aloud.',
      child: Container(
        key: const Key('scene_description_explorer_guide_card'),
        width: 1.sw,
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark
              ? _LocalPalette.color131326
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.touch_app_rounded,
              color: isDark ? Colors.white70 : AppColors.slate600,
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                "Tap any item on the scene above to describe it aloud.",
                key: const Key('scene_description_explorer_guide_text'),
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : AppColors.slate800,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
