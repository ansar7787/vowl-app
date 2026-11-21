import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive syllable stress chips supporting individual tap-to-speak audio.
class FlashcardSyllableChips extends StatelessWidget {
  final List<String> syllables;
  final int stressedIndex;
  final bool isSpeaking;
  final bool isDark;
  final void Function(String syllable) onSpeakSyllable;
  final VoidCallback onSpeakFullWord;
  final VoidCallback? onSpeakSlowWord;

  const FlashcardSyllableChips({
    super.key,
    required this.syllables,
    required this.stressedIndex,
    required this.isSpeaking,
    required this.isDark,
    required this.onSpeakSyllable,
    required this.onSpeakFullWord,
    this.onSpeakSlowWord,
  });

  @override
  Widget build(BuildContext context) {
    if (syllables.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Syllable Chips Row
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          alignment: WrapAlignment.center,
          children: List.generate(syllables.length, (idx) {
            final isStressed = idx == stressedIndex;
            final syllable = syllables[idx];

            return ScaleButton(
              onTap: () {
                HapticFeedback.selectionClick();
                onSpeakSyllable(syllable);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isStressed
                      ? (isDark
                            ? Colors.amber.withValues(alpha: 0.25)
                            : Colors.amber.withValues(alpha: 0.18))
                      : (isDark
                            ? AppColors.slate800.withValues(alpha: 0.6)
                            : AppColors.slate100),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isStressed
                        ? Colors.amber
                        : (isDark ? AppColors.slate700 : AppColors.slate300),
                    width: isStressed ? 2.0 : 1.0,
                  ),
                  boxShadow: isStressed
                      ? [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.2),
                            blurRadius: 8.r,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      syllable.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: isStressed
                            ? FontWeight.w900
                            : FontWeight.w600,
                        letterSpacing: 1.1,
                        color: isStressed
                            ? (isDark
                                  ? Colors.amberAccent
                                  : Colors.amber.shade900)
                            : (isDark ? Colors.white : AppColors.slate900),
                      ),
                    ),
                    if (isStressed) ...[
                      SizedBox(width: 4.w),
                      Icon(
                        Icons.bolt_rounded,
                        size: 14.r,
                        color: isDark
                            ? Colors.amberAccent
                            : Colors.amber.shade900,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),

        SizedBox(height: 12.h),

        // Dual-cadence audio controls: Normal full audio & 🐢 Slow phoneme audio
        Wrap(
          spacing: 8.w,
          runSpacing: 6.h,
          alignment: WrapAlignment.center,
          children: [
            ScaleButton(
              key: const ValueKey('btn_full_audio'),
              onTap: () {
                HapticFeedback.lightImpact();
                onSpeakFullWord();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: isSpeaking
                      ? AppColors.indigo500.withValues(alpha: 0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: isSpeaking
                        ? AppColors.indigo500
                        : (isDark ? AppColors.slate700 : AppColors.slate300),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSpeaking
                          ? Icons.volume_up_rounded
                          : Icons.volume_down_rounded,
                      size: 16.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isSpeaking ? 'Playing...' : 'Normal',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onSpeakSlowWord != null)
              ScaleButton(
                key: const ValueKey('btn_slow_audio'),
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSpeakSlowWord!();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate800 : AppColors.slate100,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🐢', style: TextStyle(fontSize: 13.sp)),
                      SizedBox(width: 5.w),
                      Text(
                        'Slow (0.3x)',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
