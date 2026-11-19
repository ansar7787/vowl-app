import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Speed Spelling ("Orthography & Morphology Vault").
///
/// Instructs learners on phoneme-grapheme correspondences, morphemic roots,
/// etymological patterns, and silent letter conventions for rapid orthographic decoding.
class SpeedSpellingLearnScreen extends StatefulWidget {
  final int level;

  const SpeedSpellingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeedSpellingLearnScreen> createState() => _SpeedSpellingLearnScreenState();
}

class _SpeedSpellingLearnScreenState extends State<SpeedSpellingLearnScreen> {
  int _currentIndex = 0;
  late List<Map<String, dynamic>> _quests;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/elite_mastery/speedSpelling_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (levelQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Fallback maintains continuity during testing.
    }
  }

  void _onNext() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}

    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _markCompleteAndNavigate();
    }
  }

  void _markCompleteAndNavigate() {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playCorrect();
      }
    } catch (_) {}

    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'speedSpelling',
      level: widget.level,
      phase: 'learn',
    );

    context.pushReplacement(
      '/practice?category=elite_mastery&gameType=speedSpelling&level=${widget.level}',
    );
  }

  void _playAudio(String text) {
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final current =
        _quests.isNotEmpty ? _quests[_currentIndex] : _fallbackQuests.first;

    final targetWord = current['targetWord'] as String? ??
        current['word'] as String? ??
        'Target Word';
    final spellingRule = current['spellingRule'] as String? ?? 'Pattern: Orthography';
    final difficultyTier = current['difficultyTier'] as String? ?? 'Common';
    final syllableBreakdown = current['syllableBreakdown'] as String? ?? targetWord;
    final instruction = current['instruction'] as String? ??
        'Master the phoneme-grapheme correspondences, morphology, and orthographic patterns.';
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final orthographyTip = current['orthographyTip'] as String? ??
        'Analyze the root morpheme and etymological spelling pattern: $spellingRule.';
    final authorInsight = current['authorInsight'] as String? ??
        'Orthographic mastery requires understanding morphemic roots and historical phonology rather than relying solely on acoustic memory.';

    return LearnPhaseScaffold(
      title: 'Speed Spelling',
      gameType: 'speedSpelling',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1 ? 'NEXT WORD' : 'START SPELLING SPRINT',
      onComplete: _onNext,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator Badge
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ORTHOGRAPHY VAULT: ${_currentIndex + 1} OF ${_quests.length}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.indigo400,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emerald500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    difficultyTier.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16.h),

            // Target Word & Syllable Hero Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.slate900,
                    AppColors.indigo500.withValues(alpha: 0.25),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.spellcheck_rounded,
                              size: 13.sp,
                              color: AppColors.amber400,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'ORTHOGRAPHY PATTERN',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.amber400,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        constraints: BoxConstraints(maxWidth: 180.w),
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cyan400.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          spellingRule.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instruction,
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate400,
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              targetWord,
                              style: TextStyle(
                                fontSize: 24.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              syllableBreakdown,
                              style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.cyan400,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('learn_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 22.sp,
                          color: AppColors.amber400,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _playAudio(targetWord),
                        tooltip: 'Listen to word pronunciation',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Phoneme-Grapheme & Explanation Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.indigo400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 15.sp,
                        color: AppColors.indigo400,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'PHONEME-GRAPHEME ANALYSIS',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo400,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 14.h),

            // Orthography Tip & Rule Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.cyan400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.rule_rounded,
                        size: 15.sp,
                        color: AppColors.cyan400,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'ORTHOGRAPHY DECODING TIP',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.cyan400,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    orthographyTip,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            if (hint.isNotEmpty) ...[
              SizedBox(height: 14.h),
              // Memory Anchor & Hint Card
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.emerald500.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_alt_rounded,
                          size: 15.sp,
                          color: AppColors.emerald500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'AUDITORY & MNEMONIC ANCHOR',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.emerald500,
                              letterSpacing: 0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white,
                        height: 1.45,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            SizedBox(height: 14.h),

            // Mental Model Insight Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber400.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.psychology_rounded,
                    size: 18.sp,
                    color: AppColors.amber400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MENTAL MODEL INSIGHT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber400,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          authorInsight,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.slate300,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),

            // Advance Button
            ElevatedButton(
              key: const Key('learn_continue_button'),
              onPressed: _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
              child: Text(
                _currentIndex < _quests.length - 1 ? 'NEXT WORD' : 'START SPELLING SPRINT',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }

  static const List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'ELT_SPEEDSPELLING_L1_LEARN_Q1',
      'targetWord': 'pen',
      'word': 'pen',
      'spellingRule': 'Pattern: Short Vowel',
      'difficultyTier': 'Common',
      'syllableBreakdown': 'pen',
      'instruction': 'Master the phoneme-grapheme correspondences, morphology, and orthographic patterns.',
      'explanation': 'In three-letter words, the short /e/ sound is spelled with the letter e: pen, net, red. The vowel sits between two consonants.',
      'hint': 'The vowel sounds like the one in \'bed\'. Three letters in all.',
      'orthographyTip': 'Analyze the root morpheme and etymological spelling pattern: Pattern: Short Vowel.',
      'authorInsight': 'Orthographic mastery requires understanding morphemic roots and historical phonology rather than relying solely on acoustic memory.'
    },
    {
      'id': 'ELT_SPEEDSPELLING_L1_LEARN_Q2',
      'targetWord': 'bus',
      'word': 'bus',
      'spellingRule': 'Pattern: Short Vowel',
      'difficultyTier': 'Common',
      'syllableBreakdown': 'bus',
      'instruction': 'Master the phoneme-grapheme correspondences, morphology, and orthographic patterns.',
      'explanation': 'Short /ʌ/ in a small word is spelled u: bus, cup, sun. The closing /s/ is written with a plain s, not z or c.',
      'hint': 'Its vowel matches \'cup\' and \'sun\'; the final sound is /s/.',
      'orthographyTip': 'Analyze the root morpheme and etymological spelling pattern: Pattern: Short Vowel.',
      'authorInsight': 'Orthographic mastery requires understanding morphemic roots and historical phonology rather than relying solely on acoustic memory.'
    },
    {
      'id': 'ELT_SPEEDSPELLING_L1_LEARN_Q3',
      'targetWord': 'job',
      'word': 'job',
      'spellingRule': 'Pattern: Short Vowel',
      'difficultyTier': 'Common',
      'syllableBreakdown': 'job',
      'instruction': 'Master the phoneme-grapheme correspondences, morphology, and orthographic patterns.',
      'explanation': 'Short /o/ is spelled o in words like job, hot and top. Some accents say it closer to /ɑ/, which can tempt you toward \'a\', but the spelling stays o.',
      'hint': 'Short /o/ as in \'hot\' and \'top\'. The middle letter isn\'t an a.',
      'orthographyTip': 'Analyze the root morpheme and etymological spelling pattern: Pattern: Short Vowel.',
      'authorInsight': 'Orthographic mastery requires understanding morphemic roots and historical phonology rather than relying solely on acoustic memory.'
    },
  ];
}
