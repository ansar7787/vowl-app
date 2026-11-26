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
    final isThisSeamCorrect =
        seam == correctCutIndex ||
        (secondaryCutIndex != null && seam == secondaryCutIndex);
    final isUserPicked = isWrongCut && lastCut == seam;
    final isCorrectRevealed = (isSliced || isWrongCut) && isThisSeamCorrect;

    Color? activeColor;
    Color? btnBg;
    IconData icon = Icons.content_cut_rounded;

    if (isCorrectRevealed) {
      activeColor = AppColors.emerald500;
      btnBg = AppColors.emerald500.withValues(alpha: isDark ? 0.20 : 0.12);
      icon = Icons.check_circle_outline_rounded;
    } else if (isUserPicked) {
      activeColor = AppColors.red500;
      btnBg = AppColors.red500.withValues(alpha: isDark ? 0.20 : 0.12);
      icon = Icons.cancel_outlined;
    } else {
      btnBg = isDark ? AppColors.slate800 : Colors.white;
    }

    final borderColor =
        activeColor ?? (isDark ? AppColors.slate700 : AppColors.slate300);
    final labelColor =
        activeColor ?? (isDark ? AppColors.slate50 : AppColors.slate900);
    final iconColor =
        activeColor ?? (isDark ? AppColors.slate400 : AppColors.slate500);

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
        backgroundColor: btnBg,
        side: BorderSide(
          color: borderColor,
          width: (isCorrectRevealed || isUserPicked) ? 1.8 : 1.0,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
      icon: Icon(icon, size: 14.sp, color: iconColor),
      label: Text(
        '${letters.sublist(0, seam).join()}|${letters.sublist(seam).join()}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
      ),
    );
  }

  Widget _buildShieldButton(bool isDark) {
    final isShieldCorrect = correctCutIndex == 0;
    final isUserPicked = isWrongCut && lastCut == 0;
    final isCorrectRevealed = (isSliced || isWrongCut) && isShieldCorrect;

    Color border;
    Color bg;
    Color text;
    IconData icon = Icons.shield_outlined;

    if (isCorrectRevealed) {
      border = AppColors.emerald500;
      bg = AppColors.emerald500.withValues(alpha: isDark ? 0.20 : 0.12);
      text = AppColors.emerald500;
      icon = Icons.verified_user_rounded;
    } else if (isUserPicked) {
      border = AppColors.red500;
      bg = AppColors.red500.withValues(alpha: isDark ? 0.20 : 0.12);
      text = AppColors.red500;
      icon = Icons.gpp_bad_rounded;
    } else {
      border = isDark ? AppColors.slate700 : AppColors.slate300;
      bg = isDark ? AppColors.slate800 : Colors.white;
      text = isDark ? AppColors.slate300 : AppColors.slate700;
    }

    return OutlinedButton.icon(
      onPressed: isAnswered
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onSlice(0);
            },
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        side: BorderSide(
          color: border,
          width: (isCorrectRevealed || isUserPicked) ? 1.8 : 1.5,
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      icon: Icon(icon, size: 14.sp, color: text),
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
