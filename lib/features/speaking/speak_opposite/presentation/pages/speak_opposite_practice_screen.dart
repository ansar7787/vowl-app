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

/// Interactive Practice Phase screen for Speak Opposite ("Antonym Gym").
///
/// Features target lexical polarity prompts with 4 distinct antonym options,
/// instant pedagogical feedback, audio pronunciation playback, and progress recording.
class SpeakOppositePracticeScreen extends StatefulWidget {
  final int level;

  const SpeakOppositePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeakOppositePracticeScreen> createState() =>
      _SpeakOppositePracticeScreenState();
}

class _SpeakOppositePracticeScreenState
    extends State<SpeakOppositePracticeScreen> {
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
        'assets/curriculum/speaking/speakOpposite_practice_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SPEAKOPPOSITE_PRACTICE_FALLBACK_1',
          'targetWord': 'hot',
          'contextSentence': "Don't touch the pan yet — it's still hot.",
          'options': ['cold', 'hot', 'slow', 'warm'],
          'correctIndex': 0,
          'correctAnswer': 'cold',
          'explanation':
              "'Cool' and 'chilly' sit in between, so 'cold' is the clearest opposite when no warmth remains.",
          'instruction': 'Choose the exact opposite of "hot".',
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
        gameType: 'speakOpposite',
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
              'Great work! You identified $_score out of ${_quests.length} antonyms accurately.',
              style: TextStyle(
                fontSize: 14.sp,
                height: 1.4,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'Mastery phase is unlocked! Step into the speaking arena to verbalize your antonyms live.',
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
                '/game?category=speaking&gameType=speakOpposite&level=${widget.level}',
              );
            },
            child: Text(
              'Start Mastery',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
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
    final options =
        (currentQuest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIndex = currentQuest['correctIndex'] as int? ?? 0;
    final explanation = currentQuest['explanation'] as String? ?? '';
    final instruction = currentQuest['instruction'] as String? ??
        'Choose the exact opposite of "$targetWord".';

    return PracticePhaseScaffold(
      title: 'Antonym Gym',
      gameType: 'speakOpposite',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      onHint: () {},
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Instruction Banner
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          size: 16.sp,
                          color: AppColors.indigo500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            instruction,
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: AppColors.indigo500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Target Word & Context Card
                  Container(
                    padding: EdgeInsets.all(16.r),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              size: 18.sp,
                              color: AppColors.indigo500,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              'FIND THE OPPOSITE OF',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: AppColors.indigo500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Text(
                          targetWord.toUpperCase(),
                          key: const Key('speak_opposite_practice_target_word'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.slate100
                                : AppColors.slate900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        if (contextSentence.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          Text(
                            '"$contextSentence"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontStyle: FontStyle.italic,
                              height: 1.35,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

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

                      Color borderColor = isDark
                          ? AppColors.slate800
                          : AppColors.slate200;
                      Color backgroundColor = isDark
                          ? AppColors.slate900
                          : Colors.white;
                      Widget? trailingIcon;

                      if (_hasChecked) {
                        if (isThisCorrect) {
                          borderColor = AppColors.emerald500;
                          backgroundColor =
                              AppColors.emerald500.withValues(alpha: 0.12);
                          trailingIcon = Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                            size: 20.sp,
                          );
                        } else if (isSelected && !isThisCorrect) {
                          borderColor = AppColors.rose500;
                          backgroundColor =
                              AppColors.rose500.withValues(alpha: 0.12);
                          trailingIcon = Icon(
                            Icons.cancel_rounded,
                            color: AppColors.rose500,
                            size: 20.sp,
                          );
                        }
                      } else if (isSelected) {
                        borderColor = AppColors.indigo500;
                        backgroundColor =
                            AppColors.indigo500.withValues(alpha: 0.1);
                      }

                      return InkWell(
                        key: Key('practice_option_$index'),
                        borderRadius: BorderRadius.circular(12.r),
                        onTap: () => _onOptionSelected(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 14.h,
                          ),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: borderColor,
                              width: isSelected || (_hasChecked && isThisCorrect)
                                  ? 2.0
                                  : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 26.w,
                                height: 26.w,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.indigo500
                                      : (isDark
                                          ? AppColors.slate800
                                          : AppColors.slate200),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
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
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  optionText,
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    height: 1.35,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isDark
                                        ? AppColors.slate100
                                        : AppColors.slate900,
                                  ),
                                ),
                              ),
                              if (trailingIcon != null) ...[
                                SizedBox(width: 8.w),
                                trailingIcon,
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Feedback Card
                  if (_hasChecked)
                    Container(
                      padding: EdgeInsets.all(14.r),
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
                                      ? 'Exact Antonym!'
                                      : 'Not the Opposite',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: _isCorrect
                                        ? AppColors.emerald500
                                        : AppColors.rose500,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.volume_up_rounded,
                                  color: AppColors.indigo500,
                                  size: 22.sp,
                                ),
                                onPressed: () => _playAudio(
                                  options[correctIndex],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6.h),
                          Text(
                            explanation,
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.slate100
                                  : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(height: 20.h),
                ],
              ),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate900 : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: Key(
                    _hasChecked
                        ? 'practice_continue_btn'
                        : 'practice_check_btn',
                  ),
                  onPressed: _selectedOptionIndex == null
                      ? null
                      : (_hasChecked ? _onContinue : _onCheckAnswer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _hasChecked
                        ? AppColors.indigo500
                        : AppColors.emerald500,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _hasChecked ? 'Continue' : 'Check Answer',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
