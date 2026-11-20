import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Real-world sentence in context card with inline quote styling and dedicated audio button.
class FlashcardLearnExampleBox extends StatelessWidget {
  final String exampleText;
  final bool isDark;
  final VoidCallback onSpeak;

  const FlashcardLearnExampleBox({
    super.key,
    required this.exampleText,
    required this.isDark,
    required this.onSpeak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.slate800.withValues(alpha: 0.6)
            : AppColors.slate50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 20.r,
            color: isDark ? AppColors.indigo400 : AppColors.indigo600,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              exampleText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.35,
                color: isDark ? AppColors.slate200 : AppColors.slate800,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          ScaleButton(
            onTap: onSpeak,
            child: Container(
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate700 : AppColors.slate200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 16.r,
                color: isDark ? AppColors.indigo400 : AppColors.indigo600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
