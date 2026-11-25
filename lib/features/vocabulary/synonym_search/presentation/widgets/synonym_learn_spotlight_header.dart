import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_spacing.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

/// Spotlight banner at the top of Learn Phase displaying the base ↔ synonym pair,
/// CEFR band, interactive makeover progress dots/meter, core meaning, and TTS audio.
class SynonymLearnSpotlightHeader extends StatelessWidget {
  final SynonymLearnItem item;
  final int pairIndex;
  final int totalPairs;
  final int testedMakeovers;
  final Color primaryColor;

  const SynonymLearnSpotlightHeader({
    super.key,
    required this.item,
    required this.pairIndex,
    required this.totalPairs,
    required this.testedMakeovers,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalMakeovers = item.makeovers.length;
    final allTested = totalMakeovers > 0 && testedMakeovers >= totalMakeovers;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.card),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [primaryColor.withValues(alpha: 0.28), AppColors.slate800]
              : [primaryColor.withValues(alpha: 0.14), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.50 : 0.30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SpotlightChip(
                text: '${item.cefr} • ${item.partOfSpeech}',
                color: primaryColor,
                isDark: isDark,
              ),
              _SpotlightChip(
                text: 'Pair ${pairIndex + 1} of $totalPairs',
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                isDark: isDark,
              ),
              _SpotlightChip(
                text: allTested
                    ? 'Makeovers Tested ✓'
                    : 'Tested $testedMakeovers/$totalMakeovers',
                color: allTested ? AppColors.emerald600 : primaryColor,
                isDark: isDark,
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      item.baseWord,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.slate50 : AppColors.slate900,
                      ),
                    ),
                    Icon(
                      Icons.compare_arrows_rounded,
                      size: 20.sp,
                      color: primaryColor,
                    ),
                    Text(
                      item.synonym,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppColors.indigo400 : primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              TtsSpeakerButtonWidget(
                text: '${item.baseWord}. ${item.synonym}. ${item.coreMeaning}',
                color: primaryColor,
                size: 22,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            item.coreMeaning,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.5.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.slate100 : AppColors.slate800,
              height: 1.4,
            ),
          ),
          if (item.whyDifferent.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate900.withValues(alpha: 0.72)
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                item.whyDifferent,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.slate200 : AppColors.slate700,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SpotlightChip extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _SpotlightChip({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.24 : 0.12),
        borderRadius: BorderRadius.circular(9.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.slate50 : color,
        ),
      ),
    );
  }
}
