import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Minimal Pairs ("Sound Distinction Telescope").
///
/// Instructs learners on subtle mouth and tongue height differences, articulatory tension,
/// and auditory discrimination between phonetically confusable minimal pairs.
class MinimalPairsLearnScreen extends StatefulWidget {
  final int level;

  const MinimalPairsLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<MinimalPairsLearnScreen> createState() =>
      _MinimalPairsLearnScreenState();
}

class _MinimalPairsLearnScreenState extends State<MinimalPairsLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fallbackCards;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/accent/minimalPairs_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelCards.isNotEmpty) {
        setState(() {
          _cards = levelCards;
        });
      }
    } catch (_) {
      // Retain fallback cards on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackCards => [
        {
          'id': 'ACC_MINIMALPAIRS_LEARN_FALLBACK_1',
          'gameType': 'minimalPairs',
          'level': widget.level,
          'concept': 'Sound Distinction Telescope',
          'instruction':
              'Examine the acoustic and articulatory differences between these two minimal pair sounds.',
          'word1': 'hat',
          'word2': 'hot',
          'ipa1': '/hæt/',
          'ipa2': '/hɒt/',
          'textToSpeak': 'hot',
          'targetWord': 'hot',
          'targetIpa': '/hɒt/',
          'contrastWord': 'hat',
          'contrastIpa': '/hæt/',
          'phoneticFocus': '/hæt/ vs /hɒt/',
          'vowelTensionRule':
              '/æ/ is a front vowel with lips slightly spread; /ɒ/ is a back vowel with the lips rounded a little. The tongue moves from front to back and the lip shape changes with it.',
          'mouthPosition':
              'For /æ/ keep the tongue pushed forward and the lips slightly spread. For /ɒ/ pull the tongue back and round the lips a little.',
          'rule':
              'Minimal pairs differ in only one single phonological element. Isolate the target phoneme, inspect tongue placement and lip spread, and anchor your ear to that acoustic contrast.',
          'proTip':
              'Listen to the vowel brightness and formant frequency. Higher tongue positions produce higher second formants, perceived as brighter or sharper sounds.',
          'explanation':
              'The word was "hot": the lips stay slightly rounded and the vowel comes from further back. "Hat" pulls the mouth wider and sounds brighter.',
          'hint':
              'Only the middle sound changes. Is it deep and rounded, or wide and bright?',
          'options': ['hat', 'hit', 'hot', 'hut'],
          'correctAnswer': 'hot',
          'correctAnswerIndex': 2,
          'emoji': '🔭',
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'minimalPairs',
        level: widget.level,
        phase: 'learn',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/practice?category=accent&gameType=minimalPairs&level=${widget.level}',
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard = _cards.isNotEmpty ? _cards[_cardIndex] : _fallbackCards[0];

    final targetWord = currentCard['targetWord'] as String? ?? 'hot';
    final targetIpa = currentCard['targetIpa'] as String? ?? '/hɒt/';
    final contrastWord = currentCard['contrastWord'] as String? ?? 'hat';
    final contrastIpa = currentCard['contrastIpa'] as String? ?? '/hæt/';
    final phoneticFocus = currentCard['phoneticFocus'] as String? ?? '$targetIpa vs $contrastIpa';
    final vowelTensionRule = currentCard['vowelTensionRule'] as String? ?? '';
    final mouthPosition = currentCard['mouthPosition'] as String? ?? '';
    final rule = currentCard['rule'] as String? ?? '';
    final proTip = currentCard['proTip'] as String? ?? '';
    final explanation = currentCard['explanation'] as String? ?? '';
    final emoji = currentCard['emoji'] as String? ?? '🔭';

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Sound Telescope',
      gameType: 'minimalPairs',
      level: widget.level,
      actionLabel: isLast ? 'Start Practice' : 'Next Concept',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Header info badge
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'CONCEPT ${_cardIndex + 1} OF ${_cards.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.teal500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.indigo500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      'LEVEL ${widget.level}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.indigo500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Hero Audio & Pair Contrast Card
          Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        AppColors.teal500.withValues(alpha: 0.22),
                        AppColors.slate900,
                      ]
                    : [
                        AppColors.teal500.withValues(alpha: 0.08),
                        Colors.white,
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: AppColors.teal500.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal500.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.record_voice_over_rounded,
                        color: AppColors.teal500,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACOUSTIC TELESCOPE CONTRAST',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.teal500,
                              letterSpacing: 0.8,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            phoneticFocus,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),

                // Side-by-side Target vs Contrast Word
                Row(
                  children: [
                    // Target Word
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.emerald500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.emerald500.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'TARGET WORD',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald500,
                                letterSpacing: 0.6,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              targetWord,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color:
                                    isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              targetIpa,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            IconButton(
                              onPressed: () => _playAudio(targetWord),
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.emerald500,
                                size: 22.sp,
                              ),
                              tooltip: 'Listen to $targetWord',
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    // Contrast Word
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 14.h),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.rose500.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'CONTRAST WORD',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.rose500,
                                letterSpacing: 0.6,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              contrastWord,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color:
                                    isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              contrastIpa,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rose500,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            IconButton(
                              onPressed: () => _playAudio(contrastWord),
                              icon: Icon(
                                Icons.volume_up_rounded,
                                color: AppColors.rose500,
                                size: 22.sp,
                              ),
                              tooltip: 'Listen to $contrastWord',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Audio Play Target button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('learn_play_audio_button'),
                    onPressed: () => _playAudio(targetWord),
                    icon: Icon(Icons.play_circle_fill_rounded, size: 22.sp),
                    label: Text(
                      'Listen to Target Word',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal500,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.teal500.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Articulatory Mechanics & Tongue Position Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      color: AppColors.indigo500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'ARTICULATORY MECHANICS & MOUTH SHAPE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.indigo500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),

                // Mouth Position
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('👄', style: TextStyle(fontSize: 16.sp)),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          mouthPosition.isNotEmpty
                              ? mouthPosition
                              : 'Keep tongue height and lip tension calibrated.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate700,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8.h),

                // Vowel Tension Rule
                if (vowelTensionRule.isNotEmpty)
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.amber500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.amber500.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚡', style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            vowelTensionRule,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate300
                                  : AppColors.slate700,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // Phonological Rules & Acoustic Pro-Tip Card
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_rounded,
                      color: AppColors.amber500,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'ACOUSTIC DISCRIMINATION PRINCIPLES',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amber500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  explanation.isNotEmpty ? explanation : rule,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    color: isDark ? AppColors.slate300 : AppColors.slate700,
                    height: 1.4,
                  ),
                ),
                if (proTip.isNotEmpty) ...[
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🔬', style: TextStyle(fontSize: 16.sp)),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            proTip,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.teal500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ),
    ),
  );
  }
}
