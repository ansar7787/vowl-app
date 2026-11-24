import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Discovery Card for Prefix & Suffix Learn Phase ("Affix Tumbler Sandbox").
///
/// Features:
/// - Morpheme synthesis equation: `[ AFFIX ] + [ ROOT ] = [ SYNTHESIZED WORD ]`.
/// - Morphological metadata badges (Affix Type, Semantic Shift, Part of Speech).
/// - Comprehensive definition and contextual sentence with typographic emphasis.
/// - Native Text-to-Speech audio audition button.
class PrefixSuffixDiscoveryCard extends StatelessWidget {
  /// The combined vocabulary word (e.g. "PREVIEW").
  final String combinedWord;

  /// The base root word (e.g. "VIEW").
  final String rootWord;

  /// The active bound affix (e.g. "PRE-").
  final String affix;

  /// Whether the affix is a 'prefix' or 'suffix'.
  final String affixType;

  /// Semantic meaning of the affix (e.g. "Before / In advance").
  final String affixMeaning;

  /// Full definition of the combined word.
  final String definition;

  /// Illustrative sentence showing proper usage.
  final String contextSentence;

  /// Part of speech of the root or combined word.
  final String? partOfSpeech;

  /// Optional callback to trigger native TTS audio pronunciation.
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
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 9.sp,
            fontWeight: FontWeight.w700,
            color: AppColors.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightedSentence() {
    if (!contextSentence.toUpperCase().contains(combinedWord.toUpperCase())) {
      return Text(
        contextSentence,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.sp,
          height: 1.45,
          color: AppColors.slate400,
        ),
      );
    }

    final lowerSentence = contextSentence.toLowerCase();
    final lowerWord = combinedWord.toLowerCase();
    final matchStart = lowerSentence.indexOf(lowerWord);
    final matchEnd = matchStart + lowerWord.length;

    final before = contextSentence.substring(0, matchStart);
    final match = contextSentence.substring(matchStart, matchEnd);
    final after = contextSentence.substring(matchEnd);

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14.sp,
          height: 1.45,
          color: AppColors.slate400,
        ),
        children: [
          TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.indigo400,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.indigo500.withValues(alpha: 0.6),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPrefix = affixType.toLowerCase() == 'prefix';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.slate800,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.slate700, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
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
                if (isPrefix) ...[
                  _buildMorphemeChip(
                    text: affix,
                    color: AppColors.violet500,
                    label: 'PREFIX',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                  _buildMorphemeChip(
                    text: rootWord,
                    color: AppColors.indigo400,
                    label: 'ROOT',
                  ),
                ] else ...[
                  _buildMorphemeChip(
                    text: rootWord,
                    color: AppColors.indigo400,
                    label: 'ROOT',
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6.w),
                    child: Text(
                      '+',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                  _buildMorphemeChip(
                    text: affix,
                    color: AppColors.violet500,
                    label: 'SUFFIX',
                  ),
                ],
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Text(
                    '➔',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
                _buildMorphemeChip(
                  text: combinedWord,
                  color: AppColors.emerald500,
                  label: 'SYNTHESIS',
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Synthesized Word Display Header with TTS
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                combinedWord,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.slate50,
                ),
              ),
              if (onPlayTts != null) ...[
                SizedBox(width: 8.w),
                IconButton(
                  onPressed: onPlayTts,
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
                    'Affix Meaning: $affixMeaning',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
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
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AppColors.slate50,
            ),
          ),
          SizedBox(height: 10.h),

          // Context Sentence
          _buildHighlightedSentence(),
        ],
      ),
    );
  }
}
