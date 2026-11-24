import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_morphology_helper.dart';

/// Interactive Discovery Card for Prefix & Suffix Learn Phase ("Affix Tumbler Sandbox").
class PrefixSuffixDiscoveryCard extends StatelessWidget {
  final String combinedWord;
  final String rootWord;
  final String affix;
  final String affixType;
  final String affixMeaning;
  final String definition;
  final String contextSentence;
  final String? partOfSpeech;
  final VoidCallback? onPlayTts;
  final VoidCallback? onPlayRootTts;

  const PrefixSuffixDiscoveryCard({
    super.key,
    required this.combinedWord,
    required this.rootWord,
    required this.affix,
    this.affixType = 'prefix',
    required this.affixMeaning,
    required this.definition,
    required this.contextSentence,
    this.partOfSpeech,
    this.onPlayTts,
    this.onPlayRootTts,
  });

  Widget _buildTag({
    required String text,
    required Color color,
    IconData? icon,
  }) {
    return Container(
      constraints: BoxConstraints(maxWidth: 256.w),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11.sp, color: color),
            SizedBox(width: 4.w),
          ],
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperator(String symbol, {Color? color}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: 6.w),
    child: Text(
      symbol,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 16.sp,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.slate500,
      ),
    ),
  );

  Widget _buildMorphemeChip({
    required String text,
    required Color color,
    required String label,
  }) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: color,
          ),
        ),
      ),
      SizedBox(height: 3.h),
      Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: AppColors.slate400,
        ),
      ),
    ],
  );

  Widget _buildAudioBtn({
    required VoidCallback? onTap,
    required IconData icon,
    required String tip,
    Color? color,
    double size = 22,
  }) {
    if (onTap == null) return const SizedBox.shrink();
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      icon: Icon(icon, color: color ?? AppColors.indigo400, size: size.sp),
      tooltip: tip,
      splashRadius: 20.r,
    );
  }

  Widget _buildHighlightedSentence() {
    final lowerSentence = contextSentence.toLowerCase();
    final lowerWord = combinedWord.toLowerCase();
    final baseStyle = TextStyle(
      fontFamily: 'Inter',
      fontSize: 13.5.sp,
      fontWeight: FontWeight.w400,
      height: 1.45,
      color: AppColors.slate400,
    );
    if (!lowerSentence.contains(lowerWord)) {
      return Text(
        contextSentence,
        textAlign: TextAlign.center,
        style: baseStyle,
      );
    }
    final matchStart = lowerSentence.indexOf(lowerWord);
    final matchEnd = matchStart + lowerWord.length;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          TextSpan(text: contextSentence.substring(0, matchStart)),
          TextSpan(
            text: contextSentence.substring(matchStart, matchEnd),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.indigo400,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.indigo500.withValues(alpha: 0.6),
            ),
          ),
          TextSpan(text: contextSentence.substring(matchEnd)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPrefix = affixType.toLowerCase() == 'prefix';
    final syllabicWord = PrefixSuffixMorphologyHelper.formatSyllabicBreakdown(
      combinedWord: combinedWord,
      affix: affix,
      affixType: affixType,
    );
    final mutation = PrefixSuffixMorphologyHelper.detectSpellingMutation(
      affix: affix,
      rootWord: rootWord,
      combinedWord: combinedWord,
    );
    final antonym = PrefixSuffixMorphologyHelper.detectAntonymShift(
      affix: affix,
    );
    final pos = PrefixSuffixMorphologyHelper.detectPosShift(
      affix: affix,
      affixType: affixType,
      partOfSpeech: partOfSpeech,
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(combinedWord),
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: AppColors.slate700, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Morpheme Bonding Equation
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMorphemeChip(
                    text: isPrefix ? affix : rootWord,
                    color: isPrefix ? AppColors.violet500 : AppColors.indigo400,
                    label: isPrefix ? 'Prefix' : 'Root',
                  ),
                  _buildOperator('+'),
                  _buildMorphemeChip(
                    text: isPrefix ? rootWord : affix,
                    color: isPrefix ? AppColors.indigo400 : AppColors.violet500,
                    label: isPrefix ? 'Root' : 'Suffix',
                  ),
                  _buildOperator('➔', color: AppColors.emerald500),
                  _buildMorphemeChip(
                    text: combinedWord,
                    color: AppColors.emerald500,
                    label: 'New Word',
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // Grammar Shift, Spelling Mutation & Antonym Chips
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              alignment: WrapAlignment.center,
              children: [
                _buildTag(
                  text: 'Part of speech: $pos',
                  color: AppColors.indigo400,
                ),
                if (mutation != null)
                  _buildTag(
                    text: mutation,
                    color: AppColors.amber500,
                    icon: Icons.lightbulb_outline_rounded,
                  ),
                if (antonym != null)
                  _buildTag(
                    text: antonym,
                    color: AppColors.violet500,
                    icon: Icons.swap_horiz_rounded,
                  ),
              ],
            ),
            SizedBox(height: 10.h),

            // Synthesized Word Display Header with Syllabic Marker & Dual Audio (Word & Root)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      syllabicWord,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 22.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.slate50,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                _buildAudioBtn(
                  onTap: onPlayTts,
                  icon: Icons.volume_up_rounded,
                  tip: 'Listen to $combinedWord',
                ),
                _buildAudioBtn(
                  onTap: onPlayRootTts,
                  icon: Icons.record_voice_over_outlined,
                  color: AppColors.slate400,
                  size: 20,
                  tip: 'Listen to root $rootWord',
                ),
              ],
            ),
            SizedBox(height: 2.h),

            // Acoustic Syllabic Stress Subtitle
            Text(
              PrefixSuffixMorphologyHelper.formatPhoneticStress(
                combinedWord: combinedWord,
                affix: affix,
                affixType: affixType,
              ),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5.sp,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.5,
                color: AppColors.slate400,
              ),
            ),
            SizedBox(height: 8.h),

            // Affix Meaning Banner
            _buildTag(
              text: 'Meaning: $affixMeaning',
              color: AppColors.violet500,
              icon: Icons.auto_awesome,
            ),
            SizedBox(height: 12.h),

            // Definition
            Text(
              definition,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: AppColors.slate100,
              ),
            ),
            SizedBox(height: 10.h),

            // Context Sentence
            _buildHighlightedSentence(),
          ],
        ),
      ),
    );
  }
}
