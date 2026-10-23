import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color0f0f1a = Color(0xFF0F0F1A);
}

/// Prompt card displaying the focused scenic hotspot item to describe orally.
class SceneDescriptionActivePromptCard extends StatelessWidget {
  /// Index of the active environmental hotspot.
  final int activeHotspot;

  /// Prompt text describing the element to verbalize.
  final String activePrompt;

  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [SceneDescriptionActivePromptCard].
  const SceneDescriptionActivePromptCard({
    super.key,
    required this.activeHotspot,
    required this.activePrompt,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Describe this item: $activePrompt',
      child: Container(
        key: const Key('scene_description_active_prompt_card'),
        width: 1.sw,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark
              ? _LocalPalette.color0f0f1a
              : primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.25),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.record_voice_over_rounded,
                  color: primaryColor,
                  size: 16.r,
                ),
                SizedBox(width: 8.w),
                Text(
                  "DESCRIBE THIS ITEM",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
            Text(
              activePrompt,
              key: const Key('scene_description_active_prompt_text'),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
