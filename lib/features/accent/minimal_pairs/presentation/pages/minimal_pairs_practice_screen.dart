import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Minimal Pairs ("Acoustic Discrimination Gym").
///
/// Prompts learners to listen to spoken minimal pair words and select the exact word
/// from 4 phonetically close candidates with instant feedback and articulatory explanations.
class MinimalPairsPracticeScreen extends StatefulWidget {
  final int level;

  const MinimalPairsPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<MinimalPairsPracticeScreen> createState() =>
      _MinimalPairsPracticeScreenState();
}

class _MinimalPairsPracticeScreenState
    extends State<MinimalPairsPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  int _score = 0;
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
        'assets/curriculum/accent/minimalPairs_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'ACC_MINIMALPAIRS_PRACTICE_FALLBACK_1',
          'gameType': 'minimalPairs',
          'level': widget.level,
          'instruction': 'Listen to the audio and select the exact word spoken.',
          'word1': 'hat',
          'word2': 'hot',
          'ipa1': '/hæt/',
          'ipa2': '/hɒt/',
          'textToSpeak': 'hot',
          'targetWord': 'hot',
          'targetIpa': '/hɒt/',
          'contrastWord': 'hat',
          'contrastIpa': '/hæt/',
          'options': ['hat', 'hit', 'hot', 'hut'],
          'correctAnswer': 'hot',
          'correctAnswerIndex': 2,
          'explanation':
              'The word was "hot" (/hɒt/): the lips stay slightly rounded and the vowel comes from further back. "Hat" pulls the mouth wider and sounds brighter.',
          'hint':
              'Only the middle sound changes. Is it deep and rounded, or wide and bright?',
          'vowelTensionRule':
              '/æ/ is a front vowel with lips slightly spread; /ɒ/ is a back vowel with the lips rounded a little.',
          'mouthPosition':
              'For /æ/ keep the tongue pushed forward and the lips slightly spread. For /ɒ/ pull the tongue back and round the lips a little.',
          'emoji': '🎧',
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

  void _onSelectOption(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _onCheckAnswer() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final quest = _quests.isNotEmpty ? _quests[_exerciseIndex] : _fallbackQuests[0];
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? quest['targetWord'] as String? ?? '';
    final isCorrect = _selectedOptionIndex! < options.length &&
        options[_selectedOptionIndex!] == correctAnswer;

    setState(() {
      _hasChecked = true;
      if (isCorrect) {
        _score += 10;
      }
    });

    try {
      if (di.sl.isRegistered<SoundService>()) {
        if (isCorrect) {
          di.sl<SoundService>().playCorrect();
        } else {
          di.sl<SoundService>().playWrong();
        }
      }
      if (isCorrect) {
        HapticFeedback.mediumImpact();
      } else {
        HapticFeedback.heavyImpact();
      }
    } catch (_) {}
  }

  void _onContinue() {
    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'minimalPairs',
        level: widget.level,
        phase: 'practice',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/game?category=accent&gameType=minimalPairs&level=${widget.level}',
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests.isNotEmpty ? _quests[_exerciseIndex] : _fallbackQuests[0];

    final instruction = quest['instruction'] as String? ??
        'Listen to the audio and select the exact word spoken.';
    final textToSpeak = quest['textToSpeak'] as String? ?? quest['targetWord'] as String? ?? 'hot';
    final targetWord = quest['targetWord'] as String? ?? textToSpeak;
    final targetIpa = quest['targetIpa'] as String? ?? '';
    final contrastWord = quest['contrastWord'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? targetWord;
    final correctIndex = options.indexOf(correctAnswer);

    final explanation = quest['explanation'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final emoji = quest['emoji'] as String? ?? '🎧';

    final isSelectedCorrect =
        _hasChecked && _selectedOptionIndex == correctIndex;

    return PracticePhaseScaffold(
      title: 'Minimal Pairs Gym',
      gameType: 'minimalPairs',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _onContinue,
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
                  'EXERCISE ${_exerciseIndex + 1} OF ${_quests.length}',
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
                  color: AppColors.amber500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: TextStyle(fontSize: 12.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      'SCORE: $_score',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.amber500,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          // Spoken Audio Player Card
          Container(
            padding: EdgeInsets.all(16.r),
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
                        Icons.headphones_rounded,
                        color: AppColors.teal500,
                        size: 20.sp,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        instruction,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),

                // Audio Play button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    key: const Key('practice_audio_play_button'),
                    onPressed: () => _playAudio(textToSpeak),
                    icon: Icon(Icons.volume_up_rounded, size: 22.sp),
                    label: Text(
                      'Play Word Audio',
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

                if (contrastWord.isNotEmpty && !_hasChecked) ...[
                  SizedBox(height: 8.h),
                  Text(
                    'Minimal Contrast: $targetWord vs $contrastWord',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 16.h),

          // Options List
          Text(
            'SELECT RECOGNIZED WORD',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 8.h),

          ...List.generate(options.length, (index) {
            final optionText = options[index];
            final isSelected = _selectedOptionIndex == index;
            final isTargetCorrect = index == correctIndex;

            Color borderColor =
                isDark ? AppColors.slate800 : AppColors.slate200;
            Color bgColor = isDark ? AppColors.slate900 : Colors.white;
            Color textColor = isDark ? Colors.white : AppColors.slate900;
            IconData? statusIcon;
            Color? iconColor;

            if (_hasChecked) {
              if (isTargetCorrect) {
                borderColor = AppColors.emerald500;
                bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                textColor = AppColors.emerald500;
                statusIcon = Icons.check_circle_rounded;
                iconColor = AppColors.emerald500;
              } else if (isSelected) {
                borderColor = AppColors.rose500;
                bgColor = AppColors.rose500.withValues(alpha: 0.12);
                textColor = AppColors.rose500;
                statusIcon = Icons.cancel_rounded;
                iconColor = AppColors.rose500;
              }
            } else if (isSelected) {
              borderColor = AppColors.teal500;
              bgColor = AppColors.teal500.withValues(alpha: 0.1);
              textColor = AppColors.teal500;
            }

            return Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: InkWell(
                key: Key('practice_option_$index'),
                onTap: () => _onSelectOption(index),
                borderRadius: BorderRadius.circular(16.r),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: borderColor,
                      width: isSelected || (_hasChecked && isTargetCorrect)
                          ? 2.0
                          : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? (_hasChecked
                                  ? (isTargetCorrect
                                      ? AppColors.emerald500
                                      : AppColors.rose500)
                                  : AppColors.teal500)
                              : (isDark
                                  ? AppColors.slate800
                                  : AppColors.slate100),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          String.fromCharCode(65 + index),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700),
                          ),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Text(
                          optionText,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (statusIcon != null) ...[
                        SizedBox(width: 8.w),
                        Icon(statusIcon, color: iconColor, size: 20.sp),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),

          // Explanation Card (post check)
          if (_hasChecked) ...[
            SizedBox(height: 10.h),
            Container(
              key: const Key('practice_explanation_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isSelectedCorrect
                    ? AppColors.emerald500.withValues(alpha: 0.08)
                    : AppColors.rose500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelectedCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.3)
                      : AppColors.rose500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSelectedCorrect
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        color: isSelectedCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          isSelectedCorrect
                              ? 'PRECISION MATCH!'
                              : 'ACOUSTIC BREAKDOWN',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: isSelectedCorrect
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    explanation.isNotEmpty
                        ? explanation
                        : 'The spoken word was "$correctAnswer" ($targetIpa).',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                      height: 1.4,
                    ),
                  ),
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      'Hint: $hint',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: 16.h),

          // Primary Action Buttons
          if (!_hasChecked)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheckAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      isDark ? AppColors.slate800 : AppColors.slate200,
                  disabledForegroundColor:
                      isDark ? AppColors.slate600 : AppColors.slate400,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: _selectedOptionIndex != null ? 3 : 0,
                ),
                child: Text(
                  'Check Answer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelectedCorrect
                      ? AppColors.emerald500
                      : AppColors.teal500,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 3,
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'Next Word'
                      : 'Complete Practice',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          SizedBox(height: 16.h),
        ],
      ),
    ),
  );
  }
}
