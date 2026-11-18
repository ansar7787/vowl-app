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

/// Interactive Practice Phase screen for Speak Missing Word ("Context & Articulation Gym").
///
/// Challenges learners to evaluate lexical options against situational clues,
/// cementing syntactic, semantic, and phonetic suitability before oral mastery.
class SpeakMissingWordPracticeScreen extends StatefulWidget {
  final int level;

  const SpeakMissingWordPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeakMissingWordPracticeScreen> createState() =>
      _SpeakMissingWordPracticeScreenState();
}

class _SpeakMissingWordPracticeScreenState
    extends State<SpeakMissingWordPracticeScreen> {
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
        'assets/curriculum/speaking/speakMissingWord_practice_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SPEAKMISSINGWORD_PRAC_FALLBACK_1',
          'instruction':
              'Select the word that accurately completes the context and exhibits correct oral collocation.',
          'textWithBlank':
              'I left my ___ on the kitchen table, so I couldn\'t lock the door when I went out.',
          'question':
              'Which word correctly fills the blank in: "I left my ___ on the kitchen table, so I couldn\'t lock the door when I went out."?',
          'options': [
            'keys (Correct: Accurately completes the situational context)',
            'water (Incorrect: Does not fit the situational premise)',
            'umbrella (Incorrect: Incompatible with the sentence meaning)',
            'window (Incorrect: Creates an illogical statement in this context)',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'keys (Correct: Accurately completes the situational context)',
          'hint':
              'Small metal things on a ring that you carry in your pocket or bag.',
          'explanation':
              'keys: Keys are usually plural because most people carry a set: \'my keys\', \'car keys\', \'house keys\'. Say \'a key\' only for one single key.',
          'contextClue':
              '\'Lock the door\' points to the thing that opens and closes it.',
          'distractorFeedback': {
            'water (Incorrect: Does not fit the situational premise)':
                '"water" does not fit the context: \'Lock the door\' points to the thing that opens and closes it.',
            'umbrella (Incorrect: Incompatible with the sentence meaning)':
                '"umbrella" contradicts the logical meaning of this sentence.',
            'window (Incorrect: Creates an illogical statement in this context)':
                '"window" is semantically incompatible with the action described.',
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
          gameType: 'speakMissingWord',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=speaking&gameType=speakMissingWord&level=${widget.level}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final textWithBlank = quest['textWithBlank'] as String? ?? '';
    final question = quest['question'] as String? ??
        'Which word correctly completes this context?';
    final options = (quest['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final contextClue = quest['contextClue'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString()));

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Context & Articulation Gym',
      gameType: 'speakMissingWord',
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
                    'PRACTICE CHALLENGE ${_questIndex + 1} OF ${_quests.length}',
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
                    color: AppColors.amber500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    'Precision Selection',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.amber500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Sentence with Blank Card
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
                        Icons.record_voice_over_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SPOKEN SENTENCE WITH MISSING BLANK',
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
                  SizedBox(height: 12.h),
                  Text(
                    textWithBlank,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo500,
                        side: BorderSide(
                          color: AppColors.indigo500.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () =>
                          _playAudio(textWithBlank.replaceAll('___', 'blank')),
                      icon: Icon(Icons.volume_up_rounded, size: 16.sp),
                      label: Text(
                        'Listen Sentence Context',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Context Clue Anchor Banner
            if (contextClue.isNotEmpty || hint.isNotEmpty)
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AppColors.amber500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        contextClue.isNotEmpty
                            ? 'Clue: $contextClue'
                            : 'Hint: $hint',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.amber400
                              : const Color(0xFFB45309),
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 14.h),

            // Question Prompt
            Text(
              question,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate200 : AppColors.slate800,
              ),
            ),
            SizedBox(height: 10.h),

            // 4 Option Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final optionText = options[index];
                final isSelected = _selectedOptionIndex == index;
                final isThisCorrect = index == correctIndex;

                Color borderColor;
                Color bgColor;
                Widget? statusIcon;

                if (_isChecked) {
                  if (isThisCorrect) {
                    borderColor = AppColors.emerald500;
                    bgColor = AppColors.emerald500.withValues(alpha: 0.12);
                    statusIcon = Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.emerald500,
                      size: 20.sp,
                    );
                  } else if (isSelected) {
                    borderColor = AppColors.rose500;
                    bgColor = AppColors.rose500.withValues(alpha: 0.12);
                    statusIcon = Icon(
                      Icons.cancel_rounded,
                      color: AppColors.rose500,
                      size: 20.sp,
                    );
                  } else {
                    borderColor =
                        isDark ? AppColors.slate800 : AppColors.slate200;
                    bgColor =
                        isDark ? AppColors.slate900 : Colors.white;
                  }
                } else if (isSelected) {
                  borderColor = AppColors.indigo500;
                  bgColor = AppColors.indigo500.withValues(alpha: 0.08);
                } else {
                  borderColor =
                      isDark ? AppColors.slate800 : AppColors.slate200;
                  bgColor = isDark ? AppColors.slate900 : Colors.white;
                }

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('practice_option_$index'),
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => _onSelectOption(index),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isThisCorrect)
                              ? 2.0
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.indigo500
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.indigo500
                                    : (isDark
                                        ? AppColors.slate700
                                        : AppColors.slate300),
                                width: 1.5,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              String.fromCharCode(65 + index),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w700,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.slate400
                                        : AppColors.slate600),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              optionText,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isDark
                                    ? AppColors.slate200
                                    : AppColors.slate800,
                                height: 1.35,
                              ),
                            ),
                          ),
                          if (statusIcon != null) ...[
                            SizedBox(width: 8.w),
                            statusIcon,
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 14.h),

            // Feedback Card When Checked
            if (_isChecked) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
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
                            _isCorrect
                                ? 'EXCELLENT! ACCURATE VOCAL FIT'
                                : 'NEEDS ADJUSTMENT',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    if (!_isCorrect &&
                        _selectedOptionIndex != null &&
                        _selectedOptionIndex! < options.length) ...[
                      Text(
                        distractorFeedback[options[_selectedOptionIndex!]] ??
                            'Selected word does not fit the situational clues.',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                          height: 1.35,
                        ),
                      ),
                      SizedBox(height: 6.h),
                    ],
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
