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
  });

  Widget _buildOperator(String symbol, {Color? color}) {
    return Padding(
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
  }

  Widget _buildMorphemeChip({
    required String text,
    required Color color,
    required String label,
  }) {
    return Column(
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
  }

  Widget _buildHighlightedSentence() {
    final lowerSentence = contextSentence.toLowerCase();
    final lowerWord = combinedWord.toLowerCase();
    if (!lowerSentence.contains(lowerWord)) {
      return Text(
        contextSentence,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.slate400,
        ),
      );
    }
    final matchStart = lowerSentence.indexOf(lowerWord);
    final matchEnd = matchStart + lowerWord.length;
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5.sp,
          fontWeight: FontWeight.w400,
          height: 1.45,
          color: AppColors.slate400,
        ),
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

  String _formatSyllabicBreakdown() {
    final cleanAffix = affix.replaceAll('-', '').trim();
    if (affixType.toLowerCase() == 'prefix' &&
        combinedWord.toUpperCase().startsWith(cleanAffix.toUpperCase())) {
      final remainder = combinedWord.substring(cleanAffix.length);
      return '$cleanAffix • $remainder';
    } else if (affixType.toLowerCase() == 'suffix' &&
        combinedWord.toUpperCase().endsWith(cleanAffix.toUpperCase())) {
      final base = combinedWord.substring(
        0,
        combinedWord.length - cleanAffix.length,
      );
      return '$base • $cleanAffix';
    }
    return combinedWord;
  }

  @override
  Widget build(BuildContext context) {
    final isPrefix = affixType.toLowerCase() == 'prefix';
    final syllabicWord = _formatSyllabicBreakdown();

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

            // Grammar Shift & Spelling Mutation Chips
            Wrap(
              spacing: 6.w,
              runSpacing: 4.h,
              alignment: WrapAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6.r),
                    border: Border.all(
                      color: AppColors.indigo400.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'Part of speech: ${PrefixSuffixMorphologyHelper.detectPosShift(affix: affix, affixType: affixType, partOfSpeech: partOfSpeech)}',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10.5.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.indigo400,
                    ),
                  ),
                ),
                if (PrefixSuffixMorphologyHelper.detectSpellingMutation(
                      affix: affix,
                      rootWord: rootWord,
                      combinedWord: combinedWord,
                    ) !=
                    null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 3.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 11.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 3.w),
                        Text(
                          PrefixSuffixMorphologyHelper.detectSpellingMutation(
                            affix: affix,
                            rootWord: rootWord,
                            combinedWord: combinedWord,
                          )!,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.amber500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 10.h),

            // Synthesized Word Display Header with Syllabic Marker & TTS
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  syllabicWord,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: AppColors.slate50,
                  ),
                ),
                if (onPlayTts != null) ...[
                  SizedBox(width: 8.w),
                  IconButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      onPlayTts?.call();
                    },
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.indigo400,
                      size: 22.sp,
                    ),
                    tooltip: 'Listen to pronunciation',
                    splashRadius: 20.r,
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),

            // Affix Meaning Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.violet500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.violet500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 14.sp,
                    color: AppColors.violet500,
                  ),
                  SizedBox(width: 6.w),
                  Flexible(
                    child: Text(
                      'Meaning: $affixMeaning',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.violet500,
                      ),
                    ),
                  ),
                ],
              ),
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
