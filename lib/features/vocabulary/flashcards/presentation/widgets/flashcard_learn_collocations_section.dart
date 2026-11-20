import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Natural collocations chip list with instant tap-to-speak audio narration.
class FlashcardLearnCollocationsSection extends StatelessWidget {
  final List<String> collocations;
  final bool isDark;
  final void Function(String text) onSpeak;

  const FlashcardLearnCollocationsSection({
    super.key,
    required this.collocations,
    required this.isDark,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    if (collocations.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'NATURAL COLLOCATIONS',
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? AppColors.slate400 : AppColors.slate600,
          ),
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          children: collocations.map((col) {
            return ScaleButton(
              onTap: () => onSpeak(col),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate800 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate700 : AppColors.slate300,
                  ),
                ),
                child: Text(
                  col,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate200 : AppColors.slate800,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
