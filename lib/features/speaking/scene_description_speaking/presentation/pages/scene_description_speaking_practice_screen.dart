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

/// Interactive Practice Phase screen for Scene Description Speaking ("Spatial Description Gym").
///
/// Challenges learners to evaluate environmental visual scenes, analyze spatial relationships,
/// and identify the most accurate spoken descriptive formulations.
class SceneDescriptionSpeakingPracticeScreen extends StatefulWidget {
  final int level;

  const SceneDescriptionSpeakingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SceneDescriptionSpeakingPracticeScreen> createState() =>
      _SceneDescriptionSpeakingPracticeScreenState();
}

class _SceneDescriptionSpeakingPracticeScreenState
    extends State<SceneDescriptionSpeakingPracticeScreen> {
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
        'assets/curriculum/speaking/sceneDescriptionSpeaking_practice_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SCENEDESCRIPTIONSPEAKING_PRAC_FALLBACK_1',
          'sceneTitle': 'Bedroom Corner',
          'sceneElements': [
            'blue pillow on the bed',
            'lamp on the bedside table',
            'pair of slippers on the floor',
          ],
          'sceneText':
              'Bedroom Corner|blue pillow on the bed|lamp on the bedside table|pair of slippers on the floor',
          'instruction':
              'Find the object that gives light. Say what it is and where it is.',
          'question':
              'Which descriptive statement accurately answers: "Find the object that gives light. Say what it is and where it is." for the scene "Bedroom Corner"?',
          'options': [
            'It is a lamp. It is on the small table next to the bed.',
            'There is a wooden chair in the corner of the room.',
            'A large mirror hangs directly above the fireplace.',
            'Several books are neatly arranged across the bookshelf.',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'It is a lamp. It is on the small table next to the bed.',
          'explanation':
              'This is the first step in describing a scene: name one object, then say where it is with a short "It is on..." sentence.',
          'hint':
              'Name the object first, then add one short place word like on or next to.',
          'keyVocabulary': [
            'lamp',
            'bedside table',
            'on',
            'next to',
            'small',
          ],
          'distractorFeedback': {
            'There is a wooden chair in the corner of the room.':
                'Incorrect: This statement describes an unrelated furniture item not present in the focal description.',
            'A large mirror hangs directly above the fireplace.':
                'Incorrect: This describes a living room fixture, not the bedroom bedside lamp.',
            'Several books are neatly arranged across the bookshelf.':
                'Incorrect: Books do not answer the question about the light source.',
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
      // Advance or complete
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'sceneDescriptionSpeaking',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=speaking&gameType=sceneDescriptionSpeaking&level=${widget.level}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_questIndex];

    final sceneTitle = quest['sceneTitle'] as String? ?? 'Environmental Scene';
    final sceneElements = (quest['sceneElements'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final instruction = quest['instruction'] as String? ?? 'Describe the scene.';
    final question = quest['question'] as String? ??
        'Which statement accurately describes this scene?';
    final options = (quest['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = quest['correctIndex'] as int? ?? 0;
    final explanation = quest['explanation'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final keyVocabulary = (quest['keyVocabulary'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final distractorFeedback =
        (quest['distractorFeedback'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, v.toString()));

    final isLast = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Spatial Description Gym',
      gameType: 'sceneDescriptionSpeaking',
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
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'LEVEL ${widget.level}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Scene Overview Box
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.landscape_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SCENE LAYOUT: $sceneTitle',
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
                  if (sceneElements.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 6.h,
                      children: sceneElements.map((elem) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.slate800
                                : AppColors.slate100,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            elem,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
                      onPressed: () => _playAudio(
                          '$sceneTitle. Features include: ${sceneElements.join(', ')}'),
                      icon: Icon(Icons.volume_up_rounded, size: 16.sp),
                      label: Text(
                        'Listen Scene Context',
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

            // Hint & Key Vocabulary Banner
            if (hint.isNotEmpty || keyVocabulary.isNotEmpty)
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
                        keyVocabulary.isNotEmpty
                            ? 'Goal: $instruction\nVocabulary: ${keyVocabulary.join(', ')}'
                            : 'Goal: $instruction (Hint: $hint)',
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
            SizedBox(height: 12.h),

            // Question Text
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
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
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
                    bgColor = isDark ? AppColors.slate900 : Colors.white;
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
                                fontSize: 14.sp,
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

            // Feedback Card (Mounted upon answer check)
            if (_isChecked)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                ? 'EXCELLENT DESCRIPTION'
                                : 'SPATIAL CORRECTION',
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
                    Text(
                      _isCorrect
                          ? (explanation.isNotEmpty
                              ? explanation
                              : 'Accurate description! "${options[correctIndex]}" correctly identifies the target object and its spatial relation.')
                          : (_selectedOptionIndex != null &&
                                  distractorFeedback.containsKey(
                                      options[_selectedOptionIndex!]))
                              ? distractorFeedback[
                                  options[_selectedOptionIndex!]]!
                              : 'Remember: In this scene, "${options[correctIndex]}" is the correct descriptive formulation.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
