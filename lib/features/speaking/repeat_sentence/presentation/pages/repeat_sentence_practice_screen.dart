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

/// Interactive Practice Phase screen for Repeat Sentence ("Choral Shadowing & Cadence Gym").
///
/// Challenges learners to evaluate and identify the natural acoustic stress distribution,
/// metric cadence, and connected liaison of spoken English sentences.
class RepeatSentencePracticeScreen extends StatefulWidget {
  final int level;

  const RepeatSentencePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<RepeatSentencePracticeScreen> createState() =>
      _RepeatSentencePracticeScreenState();
}

class _RepeatSentencePracticeScreenState
    extends State<RepeatSentencePracticeScreen> {
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
        'assets/curriculum/speaking/repeatSentence_practice_${startLevel}_$endLevel.json';

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
          'id': 'SPK_REPEATSENTENCE_PRAC_FALLBACK_1',
          'instruction':
              'Select the acoustic pattern that captures native stress-timing and connected speech.',
          'targetSentence': 'I wake up at seven.',
          'question':
              'Which breakdown accurately represents the natural stress rhythm and phonetic linking of: "I wake up at seven."?',
          'options': [
            'i **WAKE** **UP** at **SEVEN** (Natural prosodic flow: content words stressed with smooth phonetic linking)',
            '**I** wake up **AT** seven (Inverted stress: heavy artificial emphasis placed on grammatical particles)',
            'I | WAKE | UP | AT | SEVEN (Robotic staccato: equal exaggerated beat on every single syllable with glottal stops)',
            'i wake up at seven (Flat monotone: zero melodic inflection or rhythmic pitch contour)',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'i **WAKE** **UP** at **SEVEN** (Natural prosodic flow: content words stressed with smooth phonetic linking)',
          'hint':
              'Look for the option highlighting content words and connected transitions.',
          'explanation':
              'Content words carry strong metric stress, while grammatical particles compress into background unstressed syllables.',
          'distractorFeedback': {
            '**I** wake up **AT** seven (Inverted stress: heavy artificial emphasis placed on grammatical particles)':
                'Inverted stress: Function words (prepositions, auxiliary verbs, pronouns) are unstressed in standard declarative cadence.',
            'I | WAKE | UP | AT | SEVEN (Robotic staccato: equal exaggerated beat on every single syllable with glottal stops)':
                'Robotic staccato: English is stress-timed, not syllable-timed; treating every word with equal duration destroys natural cadence.',
            'i wake up at seven (Flat monotone: zero melodic inflection or rhythmic pitch contour)':
                'Flat monotone: Natural English requires pitch dynamism and declination toward the sentence terminus.',
          },
        },
      ];

  void _playAudio(String text, {double speed = 0.4}) {
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: speed);
      }
    } catch (_) {}
  }

  void _onOptionTap(int index) {
    if (_isChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheck() {
    if (_selectedOptionIndex == null) return;

    final quest = _quests[_questIndex];
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final isCorrectMatch = _selectedOptionIndex == correctIndex;

    setState(() {
      _isChecked = true;
      _isCorrect = isCorrectMatch;
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _resetForCurrentQuest();
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'repeatSentence',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/game?category=speaking&gameType=repeatSentence&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final instruction = quest['instruction'] as String? ?? '';
    final targetSentence = quest['targetSentence'] as String? ?? '';
    final question = quest['question'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {});

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Choral Shadowing & Cadence Gym',
      gameType: 'repeatSentence',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      actionLabel: !_isChecked
          ? 'Check Acoustic Pattern'
          : (isLast ? 'Start Mastery Phase' : 'Next Exercise'),
      isActionEnabled: _selectedOptionIndex != null || _isChecked,
      onComplete: _isChecked ? _onNext : _onCheck,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress & Strategy Badge
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
                    'PRACTICE EXERCISE ${_questIndex + 1} OF ${_quests.length}',
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
                    color: AppColors.emerald500.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Acoustic Stress Identification',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.emerald500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Target Sentence Audition Card
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
                        Icons.audiotrack_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'AUDITION TARGET SENTENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    targetSentence,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate100 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 12.h),

                  // TTS Playback Button
                  ElevatedButton.icon(
                    onPressed: () => _playAudio(targetSentence, speed: 0.4),
                    icon: Icon(Icons.volume_up_rounded, size: 18.sp),
                    label: Text(
                      'Listen Before Choosing',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.indigo500,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                  ),
                  if (instruction.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15.sp,
                          color: AppColors.amber500,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Question Prompt
            if (question.isNotEmpty) ...[
              Text(
                question,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.slate100 : AppColors.slate800,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Options List
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;
              final isCorrectOption = index == correctIndex;

              Color borderColor =
                  isDark ? AppColors.slate800 : AppColors.slate200;
              Color cardBg = isDark ? AppColors.slate900 : Colors.white;
              Color indicatorColor =
                  isDark ? AppColors.slate700 : AppColors.slate300;
              IconData indicatorIcon = Icons.circle_outlined;

              if (_isChecked) {
                if (isCorrectOption) {
                  borderColor = AppColors.emerald500;
                  cardBg = AppColors.emerald500.withValues(alpha: 0.08);
                  indicatorColor = AppColors.emerald500;
                  indicatorIcon = Icons.check_circle_rounded;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  cardBg = AppColors.rose500.withValues(alpha: 0.08);
                  indicatorColor = AppColors.rose500;
                  indicatorIcon = Icons.cancel_rounded;
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                cardBg = AppColors.indigo500.withValues(alpha: 0.06);
                indicatorColor = AppColors.indigo500;
                indicatorIcon = Icons.radio_button_checked_rounded;
              }

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('practice_option_$index'),
                    onTap: () => _onOptionTap(index),
                    borderRadius: BorderRadius.circular(14.r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isCorrectOption)
                              ? 1.8
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            indicatorIcon,
                            size: 20.sp,
                            color: indicatorColor,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: isDark
                                    ? AppColors.slate100
                                    : AppColors.slate800,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            // Feedback Card (shown after checking)
            if (_isChecked) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.amber500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect
                              ? Icons.verified_rounded
                              : Icons.info_outline_rounded,
                          size: 20.sp,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.amber500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'EXCELLENT PROSODIC ACUITY!'
                                : 'ACOUSTIC CADENCE FEEDBACK',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark
                            ? AppColors.slate200
                            : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                    if (!_isCorrect &&
                        _selectedOptionIndex != null &&
                        distractorFeedback
                            .containsKey(options[_selectedOptionIndex!])) ...[
                      SizedBox(height: 10.h),
                      Container(
                        padding: EdgeInsets.all(10.r),
                        decoration: BoxDecoration(
                          color: AppColors.rose500.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: AppColors.rose500.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 16.sp,
                              color: AppColors.rose500,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                distractorFeedback[
                                        options[_selectedOptionIndex!]]
                                    .toString(),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 12.sp,
                                  color: AppColors.rose500,
                                  height: 1.3,
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
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
