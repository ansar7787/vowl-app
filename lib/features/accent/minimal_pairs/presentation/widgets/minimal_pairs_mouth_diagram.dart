import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Articulatory anatomical callout explaining tongue, lip, and teeth position for phoneme production.
class MinimalPairsMouthDiagram extends StatelessWidget {
  /// Articulation description note.
  final String? mouthPosition;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Creates a [MinimalPairsMouthDiagram] widget.
  const MinimalPairsMouthDiagram({
    super.key,
    required this.mouthPosition,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (mouthPosition == null || mouthPosition!.isEmpty) {
      return const SizedBox();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.08)
            : color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.face_retouching_natural_rounded,
                color: color,
                size: 24.r,
              ),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr(
                    'games.mouth_position_caps',
                    fallback: 'MOUTH POSITION',
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  mouthPosition!,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF334155),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
