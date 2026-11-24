import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Pedagogical widget displaying interactive morphological word family derivations.
///
/// Tapping any word chip triggers native TTS pronunciation with subtle selection haptics.
class WordFormationFamilyTree extends StatelessWidget {
  final List<String> familyTree;
  final Color color;

  const WordFormationFamilyTree({
    super.key,
    required this.familyTree,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.22), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree_rounded, color: color, size: 15.r),
              SizedBox(width: 6.w),
              Text(
                'Word Family',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: familyTree.map((item) {
              final parts = item.split('(');
              final word = parts[0].trim();
              final roleTag = parts.length > 1 ? parts[1].replaceAll(')', '').trim() : null;

              return ScaleButton(
                onTap: () {
                  di.sl<HapticService>().selection();
                  di.sl<TtsService>().speak(word);
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(color: color.withValues(alpha: 0.22)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        word,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                      if (roleTag != null) ...[
                        SizedBox(width: 4.w),
                        Text(
                          '($roleTag)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            color: color,
                          ),
                        ),
                      ],
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.volume_up_rounded,
                        size: 13.r,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
