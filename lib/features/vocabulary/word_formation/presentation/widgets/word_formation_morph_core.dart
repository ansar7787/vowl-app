import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Central interactive hub displaying the base morphological root word.
class WordFormationMorphCore extends StatelessWidget {
  final String rootWord;
  final String? rootMeaning;
  final Color primaryColor;
  final bool isDark;

  const WordFormationMorphCore({
    super.key,
    required this.rootWord,
    this.rootMeaning,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'BASE ROOT',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 6.w),
              ScaleButton(
                onTap: () {
                  di.sl<TtsService>().speak(rootWord);
                },
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: primaryColor,
                    size: 15.r,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Large Root Word
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              rootWord.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
                letterSpacing: 2.0,
              ),
            ),
          ),

          if (rootMeaning != null && rootMeaning!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              rootMeaning!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
