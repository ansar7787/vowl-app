import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_morphology_helper.dart';

/// Accessible Scissor Pad and Pure Root Shield for Morpheme Slicing.
class PrefixSuffixScissorPad extends StatelessWidget {
  final List<String> letters;
  final int correctCutIndex;
  final int? secondaryCutIndex;
  final int? lastCut;
  final bool isSliced;
  final bool isWrongCut;
  final bool isAnswered;
  final ValueChanged<int> onSlice;

  const PrefixSuffixScissorPad({
    super.key,
    required this.letters,
    required this.correctCutIndex,
    this.secondaryCutIndex,
    this.lastCut,
    required this.isSliced,
    required this.isWrongCut,
    required this.isAnswered,
    required this.onSlice,
  });

  Widget _buildScissorButton(int seam, bool isDark) {
    final isCorrect =
        isSliced &&
        (seam == correctCutIndex ||
            (secondaryCutIndex != null && seam == secondaryCutIndex));
    final isWrong = isWrongCut && lastCut == seam;
    final activeColor = isCorrect
        ? AppColors.emerald500
        : (isWrong ? AppColors.red500 : null);

    return OutlinedButton.icon(
      onPressed: isAnswered
          ? null
          : () {
              HapticFeedback.selectionClick();
              onSlice(seam);
            },
      style: OutlinedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        minimumSize: Size(44.w, 36.h),
        backgroundColor: isWrong
            ? AppColors.red500.withValues(alpha: 0.15)
            : (isDark ? AppColors.slate800 : Colors.white),
        side: BorderSide(
          color:
              activeColor ?? (isDark ? AppColors.slate700 : AppColors.slate300),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      icon: Icon(
        Icons.content_cut_rounded,
        size: 14.sp,
        color:
            activeColor ?? (isDark ? AppColors.slate400 : AppColors.slate500),
      ),
      label: Text(
        '${letters.sublist(0, seam).join()}|${letters.sublist(seam).join()}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.slate50 : AppColors.slate900,
        ),
      ),
    );
  }

  Widget _buildShieldButton(bool isDark) {
    final isCorrect = isSliced && correctCutIndex == 0;
    final isWrong = isWrongCut && lastCut == 0;
    final bg = isCorrect
        ? AppColors.emerald500.withValues(alpha: 0.15)
        : (isWrong
              ? AppColors.red500.withValues(alpha: 0.15)
              : (isDark ? AppColors.slate800 : Colors.white));
    final border = isCorrect
        ? AppColors.emerald500
        : (isWrong
              ? AppColors.red500
              : (isDark ? AppColors.slate700 : AppColors.slate300));
    final text = isCorrect
        ? AppColors.emerald500
        : (isWrong
              ? AppColors.red500
              : (isDark ? AppColors.slate300 : AppColors.slate700));

    return OutlinedButton.icon(
      onPressed: isAnswered
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onSlice(0);
            },
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        side: BorderSide(color: border, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      icon: Icon(Icons.shield_outlined, size: 14.sp, color: text),
      label: Text(
        'Pure Root (No Affix)',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
          color: text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 6.w,
          runSpacing: 6.h,
          alignment: WrapAlignment.center,
          children: [
            for (int seam = 1; seam < letters.length; seam++)
              _buildScissorButton(seam, isDark),
          ],
        ),
        SizedBox(height: 8.h),
        _buildShieldButton(isDark),
        if (isWrongCut && lastCut != null) ...[
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.red500.withValues(alpha: 0.12)
                  : AppColors.red500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: AppColors.red500.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13.sp,
                  color: AppColors.red500,
                ),
                SizedBox(width: 5.w),
                Flexible(
                  child: Text(
                    PrefixSuffixMorphologyHelper.formatSeamDiagnostic(
                      attemptedCut: lastCut,
                      correctCut: correctCutIndex,
                      secondaryCut: secondaryCutIndex,
                    ),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.red500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
