import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Related cousin word chip strip displayed below makeovers in Learn Phase.
///
/// Selecting any cousin reveals its IPA, tone tag, real sentence context,
/// and pronunciation audio without crowding initial load.
class SynonymCousinPreviewStrip extends StatelessWidget {
  final List<SynonymCousinWord> cousins;
  final int? selectedIndex;
  final Color primaryColor;
  final ValueChanged<int> onSelectCousin;

  const SynonymCousinPreviewStrip({
    super.key,
    required this.cousins,
    required this.selectedIndex,
    required this.primaryColor,
    required this.onSelectCousin,
  });

  @override
  Widget build(BuildContext context) {
    if (cousins.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? AppColors.slate800.withValues(alpha: 0.85)
        : Colors.white;
    final labelColor = isDark ? AppColors.slate300 : AppColors.slate600;
    final selectedCousin =
        (selectedIndex != null &&
            selectedIndex! >= 0 &&
            selectedIndex! < cousins.length)
        ? cousins[selectedIndex!]
        : null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: isDark ? AppColors.slate700 : AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WORD FAMILY COUSINS',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
              color: isDark ? AppColors.indigo400 : primaryColor,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Tap a related synonym to hear its tone and example.',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              color: labelColor,
              height: 1.35,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              for (int i = 0; i < cousins.length; i++)
                _CousinChip(
                  key: Key('cousin_chip_$i'),
                  cousin: cousins[i],
                  isSelected: selectedIndex == i,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () => onSelectCousin(i),
                ),
            ],
          ),
          if (selectedCousin != null) ...[
            SizedBox(height: 12.h),
            _CousinDetailPanel(
              cousin: selectedCousin,
              primaryColor: primaryColor,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }
}

class _CousinChip extends StatelessWidget {
  final SynonymCousinWord cousin;
  final bool isSelected;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  const _CousinChip({
    super.key,
    required this.cousin,
    required this.isSelected,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? primaryColor.withValues(alpha: isDark ? 0.30 : 0.14)
        : (isDark ? AppColors.slate900 : AppColors.slate50);
    final border = isSelected
        ? primaryColor
        : (isDark ? AppColors.slate700 : AppColors.slate300);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${cousin.word}, ${cousin.toneTag}',
      child: ScaleButton(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: VowlMotion.shouldReduceMotion(context)
                ? Duration.zero
                : VowlMotion.fast,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: border, width: isSelected ? 1.8 : 1.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cousin.word,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate50 : AppColors.slate900,
                  ),
                ),
                if (cousin.toneTag.isNotEmpty) ...[
                  SizedBox(width: 6.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      cousin.toneTag,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.slate200 : primaryColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CousinDetailPanel extends StatelessWidget {
  final SynonymCousinWord cousin;
  final Color primaryColor;
  final bool isDark;

  const _CousinDetailPanel({
    required this.cousin,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8.w,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      cousin.word,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    if (cousin.ipa.isNotEmpty)
                      Text(
                        cousin.ipa,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate600,
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 6.h),
                Text(
                  cousin.miniContext,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.slate100 : AppColors.slate800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          TtsSpeakerButtonWidget(
            text: '${cousin.word}. ${cousin.miniContext}',
            color: primaryColor,
            size: 20,
          ),
        ],
      ),
    );
  }
}
