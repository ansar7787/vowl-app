import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Pronunciation Focus ("Phonetic Articulation Gym").
///
/// Challenges learners to evaluate and identify the correct articulatory mechanics,
/// mouth positioning, and acoustic distinctions of targeted phonemes.
class PronunciationFocusPracticeScreen extends StatefulWidget {
  final int level;

  const PronunciationFocusPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<PronunciationFocusPracticeScreen> createState() =>
      _PronunciationFocusPracticeScreenState();
}

class _PronunciationFocusPracticeScreenState
    extends State<PronunciationFocusPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  bool get isCorrect => _isCorrect;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _resetForCurrentQuest();
    _loadCurriculum();
  }

  void _resetForCurrentQuest() {
    _selectedOptionIndex = null;
    _isChecked = false;
    _isCorrect = false;
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/speaking/pronunciationFocus_practice_${startLevel}_$endLevel.json';

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
          _resetForCurrentQuest();
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'SPK_PRONUNCIATIONFOCUS_PRAC_FALLBACK_1',
          'instruction':
              'Identify the correct articulatory mechanics and acoustic feature for the target sound.',
          'targetPhoneme': '[p]',
          'textToSpeak': 'Please put the pan on the stove.',
          'question':
              'Which articulatory description correctly produces the target sound [p] in: "Please put the pan on the stove."?',
          'options': [
            'Close both lips, let pressure build, then open with a quick puff (Correct: Accurately articulates the [p] target sound)',
            'Voicing it so "pan" sounds like "ban" (Incorrect: Common pronunciation error)',
            'Releasing no air so it sounds like a [b] (Incorrect: Flawed articulatory mechanics)',
            'Articulate with teeth against lower lip (Incorrect: Distorts acoustic precision)',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'Close both lips, let pressure build, then open with a quick puff (Correct: Accurately articulates the [p] target sound)',
          'hint':
              'Hold a hand near your mouth: "please", "put" and "pan" should each push out a small puff of air.',
          'explanation':
              '[p]: Close both lips, let pressure build behind them, then open with a quick burst. Your voice stays off until the vowel begins.',
          'phoneticHint':
              'At the start of a stressed word, English [p] is aspirated, roughly [pʰ]: the burst is followed by a tiny breath.',
          'distractorFeedback': {
            'Voicing it so "pan" sounds like "ban" (Incorrect: Common pronunciation error)':
                'Avoid voicing [p]; vocal fold vibration turns it into [b].',
            'Releasing no air so it sounds like a [b] (Incorrect: Flawed articulatory mechanics)':
                'Unaspirated initial [p] sounds like [b] to English listeners.',
            'Articulate with teeth against lower lip (Incorrect: Distorts acoustic precision)':
                'Teeth on lip produces [f] or [v], not the bilabial stop [p].',
          },
        },
      ];

  void _playAudio(String text, {double speed = 0.5}) {
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: speed);
      }
    } catch (_) {}
  }

  void _onSelectOption(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onAction() {
    if (!_isChecked) {
      if (_selectedOptionIndex == null) return;

      final quest = _quests[_questIndex];
      final correctIndex = quest['correctIndex'] as int? ?? 0;
      final isRight = _selectedOptionIndex == correctIndex;

      setState(() {
        _isChecked = true;
        _isCorrect = isRight;
      });

      try {
        if (di.sl.isRegistered<SoundService>()) {
          if (isRight) {
            di.sl<SoundService>().playCorrect();
          } else {
            di.sl<SoundService>().playWrong();
          }
        }
      } catch (_) {}
    } else {
      // Proceed to next question or mastery
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'pronunciationFocus',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=speaking&gameType=pronunciationFocus&level=${widget.level}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final targetPhoneme = quest['targetPhoneme'] as String? ?? '[sound]';
    final textToSpeak = quest['textToSpeak'] as String? ?? '';
    final question = quest['question'] as String? ??
        'Which articulatory description correctly produces the target sound?';
    final options = (quest['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final phoneticHint = quest['phoneticHint'] as String? ?? '';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString()));

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Pronunciation Gym',
      gameType: 'pronunciationFocus',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: _isChecked
          ? (isLast ? 'Complete & Unlock Mastery' : 'Next Question')
          : 'Check Answer',
      isActionEnabled: _selectedOptionIndex != null,
      onComplete: _onAction,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Progress Pill
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
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'DRILL ${_questIndex + 1} OF ${_quests.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.blue500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Acoustic Precision',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Target Sound & Spoken Sentence Display
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
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          targetPhoneme,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo400,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SPOKEN PROMPT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up_rounded),
                        color: AppColors.indigo500,
                        iconSize: 22.sp,
                        tooltip: 'Play spoken sentence',
                        onPressed: () => _playAudio(textToSpeak),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    textToSpeak,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Question Header
            Text(
              question,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.slate200 : AppColors.slate800,
                height: 1.3,
              ),
            ),
            SizedBox(height: 12.h),

            // Multiple Choice Options
            ...List.generate(options.length, (index) {
              final option = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isTargetCorrect = index == correctIndex;

              Color borderColor =
                  isDark ? AppColors.slate800 : AppColors.slate200;
              Color bgColor = isDark ? AppColors.slate900 : Colors.white;

              if (_isChecked) {
                if (isTargetCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                } else if (isSelected && !isTargetCorrect) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.12);
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.08);
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('practice_option_$index'),
                    onTap: () => _onSelectOption(index),
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isTargetCorrect)
                              ? 2.0
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28.r,
                            height: 28.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (_isChecked
                                      ? (isTargetCorrect
                                          ? AppColors.emerald500
                                          : AppColors.rose500)
                                      : AppColors.indigo500)
                                  : (isDark
                                      ? AppColors.slate800
                                      : AppColors.slate100),
                            ),
                            child: Center(
                              child: Text(
                                String.fromCharCode(65 + index),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                          ? AppColors.slate400
                                          : AppColors.slate600),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate200
                                    : AppColors.slate800,
                                height: 1.3,
                              ),
                            ),
                          ),
                          if (_isChecked) ...[
                            SizedBox(width: 6.w),
                            if (isTargetCorrect)
                              Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.emerald500,
                                size: 20.sp,
                              )
                            else if (isSelected && !isTargetCorrect)
                              Icon(
                                Icons.cancel_rounded,
                                color: AppColors.rose500,
                                size: 20.sp,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Feedback Card when Checked
            if (_isChecked) ...[
              SizedBox(height: 10.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
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
                          _isCorrect
                              ? Icons.check_circle_rounded
                              : Icons.info_outline_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect ? 'EXCELLENT ARTICULATION' : 'PHONETIC CORRECTION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _isCorrect
                          ? explanation
                          : (_selectedOptionIndex != null &&
                                  distractorFeedback.containsKey(
                                      options[_selectedOptionIndex!]))
                              ? distractorFeedback[options[_selectedOptionIndex!]]!
                              : explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.4,
                      ),
                    ),
                    if (phoneticHint.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Phonetic Guide: $phoneticHint',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.slate400
                              : AppColors.slate600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}
