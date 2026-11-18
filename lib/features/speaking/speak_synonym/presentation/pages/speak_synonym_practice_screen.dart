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

/// Interactive Practice Phase screen for Speak Synonym ("Synonym Gym").
///
/// Features target lexical substitution prompts with 4 distinct synonym options,
/// instant pedagogical feedback, audio pronunciation playback, and progress recording.
class SpeakSynonymPracticeScreen extends StatefulWidget {
  final int level;

  const SpeakSynonymPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeakSynonymPracticeScreen> createState() =>
      _SpeakSynonymPracticeScreenState();
}

class _SpeakSynonymPracticeScreenState
    extends State<SpeakSynonymPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  bool _isCorrect = false;
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
        'assets/curriculum/speaking/speakSynonym_practice_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SPEAKSYNONYM_PRACTICE_FALLBACK_1',
          'targetWord': 'big',
          'contextSentence': 'Wow, your new apartment is big!',
          'options': ['large', 'swift', 'calm', 'dense'],
          'correctIndex': 0,
          'correctAnswer': 'large',
          'explanation':
              'Keep in mind that "large" is the everyday swap for "big" when you talk about the size of a place or object.',
          'instruction': 'Choose the synonym that best replaces "big".',
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

  void _onOptionSelected(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _onCheckAnswer() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final currentQuest = _quests[_exerciseIndex];
    final correctIndex = currentQuest['correctIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIndex;

    setState(() {
      _hasChecked = true;
      _isCorrect = isCorrect;
      if (isCorrect) {
        _score++;
      }
    });

    if (isCorrect) {
      final correctText =
          currentQuest['correctAnswer'] as String? ??
          currentQuest['options'][correctIndex] as String;
      _playAudio(correctText);
    }
  }

  void _onContinue() {
    if (_exerciseIndex < _quests.length - 1) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
        _isCorrect = false;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'speakSynonym',
        level: widget.level,
        phase: 'practice',
      );
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.slate900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(Icons.stars_rounded, color: AppColors.amber500, size: 28.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'Practice Complete!',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.slate100 : AppColors.slate900,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Great work! You identified $_score out of ${_quests.length} synonyms accurately.',
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Mastery phase is unlocked! Step into the speaking arena to verbalize your synonyms live.',
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.emerald500,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.pushReplacement(
                '/game?category=speaking&gameType=speakSynonym&level=${widget.level}',
              );
            },
            child: Text(
              'Enter Mastery Arena',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_exerciseIndex];
    final targetWord = currentQuest['targetWord'] as String? ?? '';
    final contextSentence = currentQuest['contextSentence'] as String? ?? '';
    final options = (currentQuest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = currentQuest['correctIndex'] as int? ?? 0;
    final explanation = currentQuest['explanation'] as String? ?? '';
    final instruction = currentQuest['instruction'] as String? ??
        'Choose the synonym that best replaces "$targetWord".';

    return PracticePhaseScaffold(
      title: 'Synonym Gym',
      gameType: 'speakSynonym',
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
            // Instruction
            Text(
              instruction,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate300 : AppColors.slate700,
              ),
            ),
            SizedBox(height: 14.h),

            // Target Word Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.indigo500.withValues(alpha: 0.2),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.indigo500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'FIND SYNONYM FOR',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.indigo500,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      GestureDetector(
                        key: const Key('speak_synonym_practice_listen_target'),
                        onTap: () => _playAudio(targetWord),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    targetWord.toUpperCase(),
                    key: const Key('speak_synonym_practice_target_word'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                    ),
                  ),
                  if (contextSentence.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.slate800
                            : AppColors.indigo50.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        '"$contextSentence"',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 18.h),

            // Options List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: options.length,
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, idx) {
                final optionText = options[idx];
                final isSelected = _selectedOptionIndex == idx;
                Color cardBorderColor = isDark
                    ? AppColors.slate800
                    : AppColors.slate200;
                Color cardBgColor = isDark
                    ? AppColors.slate900
                    : Colors.white;
                Color textColor = isDark
                    ? AppColors.slate200
                    : AppColors.slate800;

                if (_hasChecked) {
                  if (idx == correctIndex) {
                    cardBorderColor = AppColors.emerald500;
                    cardBgColor = AppColors.emerald500.withValues(alpha: 0.12);
                    textColor = AppColors.emerald500;
                  } else if (isSelected && !_isCorrect) {
                    cardBorderColor = AppColors.rose500;
                    cardBgColor = AppColors.rose500.withValues(alpha: 0.12);
                    textColor = AppColors.rose500;
                  }
                } else if (isSelected) {
                  cardBorderColor = AppColors.indigo500;
                  cardBgColor = AppColors.indigo500.withValues(alpha: 0.1);
                  textColor = AppColors.indigo500;
                }

                return GestureDetector(
                  key: Key('practice_option_$idx'),
                  onTap: () => _onOptionSelected(idx),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 13.h,
                    ),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: cardBorderColor,
                        width: isSelected || (_hasChecked && idx == correctIndex)
                            ? 2
                            : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28.r,
                          height: 28.r,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (_hasChecked
                                    ? (idx == correctIndex
                                        ? AppColors.emerald500
                                        : AppColors.rose500)
                                    : AppColors.indigo500)
                                : (isDark
                                    ? AppColors.slate800
                                    : AppColors.slate100),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + idx),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
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
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ),
                        if (_hasChecked && idx == correctIndex)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                            size: 22.sp,
                          )
                        else if (_hasChecked && isSelected && !_isCorrect)
                          Icon(
                            Icons.cancel_rounded,
                            color: AppColors.rose500,
                            size: 22.sp,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 18.h),

            // Feedback Card when checked
            if (_hasChecked) ...[
              Container(
                padding: EdgeInsets.all(14.r),
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
                          size: 18.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _isCorrect ? 'EXCELLENT SYNONYM!' : 'KEEP PRACTICING',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: _isCorrect
                                ? AppColors.emerald500
                                : AppColors.rose500,
                          ),
                        ),
                      ],
                    ),
                    if (explanation.isNotEmpty) ...[
                      SizedBox(height: 6.h),
                      Text(
                        explanation,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          height: 1.4,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Action Button
            ElevatedButton(
              key: const Key('practice_check_button'),
              onPressed: _selectedOptionIndex == null
                  ? null
                  : (_hasChecked ? _onContinue : _onCheckAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                disabledBackgroundColor: isDark
                    ? AppColors.slate800
                    : AppColors.slate200,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              child: Text(
                _hasChecked
                    ? (_exerciseIndex == _quests.length - 1
                        ? 'Finish Practice'
                        : 'Next Exercise')
                    : 'Check Answer',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
