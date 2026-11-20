import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'flashcard_echo_pronunciation.dart';
import 'flashcard_learn_back_face.dart';
import 'flashcard_syllable_chips.dart';

/// Tactile 3D discovery deck for the Flashcard Learn Phase.
class FlashcardLearnView extends StatelessWidget {
  final PhasedQuest quest;
  final bool isFlipped;
  final bool isSpeaking;
  final bool isDark;
  final VoidCallback onFlip;
  final void Function(String syllable) onSpeakSyllable;
  final VoidCallback onSpeakFullWord;
  final VoidCallback? onSpeakExample;
  final int clusterIndex;
  final int clusterTotal;

  const FlashcardLearnView({
    super.key,
    required this.quest,
    required this.isFlipped,
    required this.isSpeaking,
    required this.isDark,
    required this.onFlip,
    required this.onSpeakSyllable,
    required this.onSpeakFullWord,
    this.onSpeakExample,
    this.clusterIndex = 0,
    this.clusterTotal = 3,
  });

  IconData _resolveMnemonicIcon(String domain) {
    final d = domain.toLowerCase();
    if (d.contains('culin') ||
        d.contains('food') ||
        d.contains('tradition') ||
        d.contains('recipe')) {
      return Icons.restaurant_rounded;
    }
    if (d.contains('legal') ||
        d.contains('law') ||
        d.contains('procedur') ||
        d.contains('court')) {
      return Icons.gavel_rounded;
    }
    if (d.contains('emotion') ||
        d.contains('feel') ||
        d.contains('charact') ||
        d.contains('sincer')) {
      return Icons.favorite_rounded;
    }
    if (d.contains('sci') ||
        d.contains('tech') ||
        d.contains('data') ||
        d.contains('comput')) {
      return Icons.biotech_rounded;
    }
    if (d.contains('art') ||
        d.contains('design') ||
        d.contains('creat') ||
        d.contains('cultur')) {
      return Icons.palette_rounded;
    }
    if (d.contains('business') ||
        d.contains('work') ||
        d.contains('lead') ||
        d.contains('finan')) {
      return Icons.business_center_rounded;
    }
    if (d.contains('nature') ||
        d.contains('eco') ||
        d.contains('plant') ||
        d.contains('wild')) {
      return Icons.eco_rounded;
    }
    return Icons.lightbulb_outline_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final rawSyllables = quest.rawExtra['syllables'] as List<dynamic>?;
    final syllables = rawSyllables != null
        ? rawSyllables.map((e) => e.toString()).toList()
        : (quest.word != null ? [quest.word!] : <String>[]);
    final stressedIndex =
        (quest.rawExtra['stressedSyllableIndex'] as num?)?.toInt() ?? 0;
    final contextDomain =
        quest.rawExtra['contextDomain'] as String? ?? 'Real-World Context';
    final collocations =
        (quest.rawExtra['collocations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        quest.familyWords;
    final commonMistake =
        quest.commonMistake ??
        quest.rawExtra['commonConfusionAlert'] as String?;

    final phonetic =
        quest.pronunciation ?? quest.rawExtra['phonetic'] as String?;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: isFlipped ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      builder: (context, val, child) {
        final isBack = val >= 0.5;
        return GestureDetector(
          onTap: onFlip,
          behavior: HitTestBehavior.opaque,
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(val * pi),
            alignment: Alignment.center,
            child: isBack
                ? Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: FlashcardLearnBackFace(
                      quest: quest,
                      isDark: isDark,
                      onFlip: onFlip,
                      collocations: collocations,
                      commonMistake: commonMistake,
                      contextDomain: contextDomain,
                      onSpeakExample: onSpeakExample,
                    ),
                  )
                : _buildFrontFace(
                    context,
                    syllables: syllables,
                    stressedIndex: stressedIndex,
                    contextDomain: contextDomain,
                    phonetic: phonetic,
                  ),
          ),
        );
      },
    );
  }

  Widget _buildFrontFace(
    BuildContext context, {
    required List<String> syllables,
    required int stressedIndex,
    required String contextDomain,
    String? phonetic,
  }) {
    final mnemonicIcon = _resolveMnemonicIcon(contextDomain);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row: Cluster Progress Pills & 3D Interactive Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Cluster Progress Indicators
              Row(
                children: List.generate(clusterTotal, (idx) {
                  final isActive = idx == clusterIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: EdgeInsets.only(right: 5.w),
                    width: isActive ? 20.w : 7.w,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.indigo500
                          : (isDark ? AppColors.slate800 : AppColors.slate300),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  );
                }),
              ),
              // Tap to Flip Cue Badge
              ScaleButton(
                onTap: onFlip,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.indigo500.withValues(alpha: 0.18)
                        : AppColors.indigo500.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isDark
                          ? AppColors.indigo500.withValues(alpha: 0.35)
                          : AppColors.indigo500.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        size: 13.r,
                        color: isDark
                            ? AppColors.indigo400
                            : AppColors.indigo600,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Tap to Flip',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: isDark
                              ? AppColors.indigo400
                              : AppColors.indigo600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Mnemonic Visual Anchor Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.indigo500.withValues(alpha: 0.2)
                  : AppColors.indigo500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  mnemonicIcon,
                  size: 15.r,
                  color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      contextDomain,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.indigo400
                            : AppColors.indigo600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 18.h),

          // Target Word
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              quest.word ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 32.sp,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark ? Colors.white : AppColors.slate950,
              ),
            ),
          ),

          SizedBox(height: 6.h),

          // Phonetic IPA
          if (phonetic != null)
            Text(
              phonetic,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 17.sp,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),

          SizedBox(height: 14.h),

          // Tap-to-Speak Syllable Chips
          FlashcardSyllableChips(
            syllables: syllables,
            stressedIndex: stressedIndex,
            isSpeaking: isSpeaking,
            isDark: isDark,
            onSpeakSyllable: onSpeakSyllable,
            onSpeakFullWord: onSpeakFullWord,
          ),

          SizedBox(height: 10.h),

          // Echo Pronunciation / Speech Validation
          FlashcardEchoPronunciation(
            targetWord: quest.word ?? '',
            syllables: syllables,
            stressedIndex: stressedIndex,
            isDark: isDark,
          ),

          SizedBox(height: 18.h),

          // Flip Button Cue
          ScaleButton(
            onTap: onFlip,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate100,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate700 : AppColors.slate300,
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.flip_rounded,
                      size: 18.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Flip for Meaning & Context',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.indigo400
                            : AppColors.indigo600,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12.r,
                      color: isDark ? AppColors.indigo400 : AppColors.indigo600,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
