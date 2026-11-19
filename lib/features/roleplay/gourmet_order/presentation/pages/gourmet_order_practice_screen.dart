import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Practice Phase screen for Gourmet Order ("Restaurant Interaction Gym").
///
/// Gives learners rapid, low-stakes drills selecting articulate and culturally
/// respectful patron phrasing for complex ordering, dietary inquiries, and bill handling.
class GourmetOrderPracticeScreen extends StatefulWidget {
  final int level;

  const GourmetOrderPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<GourmetOrderPracticeScreen> createState() =>
      _GourmetOrderPracticeScreenState();
}

class _GourmetOrderPracticeScreenState
    extends State<GourmetOrderPracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
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
        'assets/curriculum/roleplay/gourmetOrder_practice_${startLevel}_$endLevel.json';

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
      // Fallback quests maintain continuity during testing or missing assets.
    }
  }

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
    try {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
      }
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playClick();
      }
    } catch (_) {}
  }

  void _onCheck() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final isCorrect = _selectedOptionIndex == correctIdx;

    setState(() {
      _hasChecked = true;
    });

    try {
      if (di.sl.isRegistered<HapticService>()) {
        if (isCorrect) {
          di.sl<HapticService>().success();
        } else {
          di.sl<HapticService>().error();
        }
      }
      if (di.sl.isRegistered<SoundService>()) {
        if (isCorrect) {
          di.sl<SoundService>().playCorrect();
        } else {
          di.sl<SoundService>().playWrong();
        }
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
      try {
        if (di.sl.isRegistered<HapticService>()) {
          di.sl<HapticService>().light();
        }
        if (di.sl.isRegistered<SoundService>()) {
          di.sl<SoundService>().playClick();
        }
      } catch (_) {}
    } else {
      _finishPractice();
    }
  }

  void _finishPractice() {
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
      gameType: 'gourmetOrder',
      level: widget.level,
      phase: 'practice',
    );

    try {
      context.pushReplacement(
        '/game?category=roleplay&gameType=gourmetOrder&level=${widget.level}',
      );
    } catch (_) {}
  }

  static final List<Map<String, dynamic>> _fallbackQuests = [
    {
      'id': 'go_practice_l1_q1',
      'level': 1,
      'diningContext': 'CASUAL BISTRO & DRINKS',
      'waiterPrompt':
          'Good evening, welcome to the Bistro! Can I start you off with something to drink while you look over the menu?',
      'question': 'Select the most articulate and polite patron response:',
      'options': [
        'Good evening! Could we please start with a bottle of sparkling water with lime, and two draft lagers?',
        'Bring us water and two beers right away.',
        'We need liquids before looking at food stuff.'
      ],
      'correctAnswerIndex': 0,
      'correctAnswer':
          'Good evening! Could we please start with a bottle of sparkling water with lime, and two draft lagers?',
      'explanation':
          'Greeting the server and phrasing the drink order with "Could we please start with..." is standard, courteous dining etiquette.',
      'diningScore': 5
    },
    {
      'id': 'go_practice_l1_q2',
      'level': 1,
      'diningContext': 'FINE DINING & SOMMELIER',
      'waiterPrompt':
          'Would you care for wine pairings tonight, or should I recommend a vintage for your braised beef cheek?',
      'question': 'Select the most articulate and polite patron response:',
      'options': [
        'Just give us the most expensive red bottle you have.',
        'We would love a recommendation. We generally prefer full-bodied reds with subtle oak and low acidity.',
        'Wine doesn\'t matter, just make sure it is red and has alcohol.'
      ],
      'correctAnswerIndex': 1,
      'correctAnswer':
          'We would love a recommendation. We generally prefer full-bodied reds with subtle oak and low acidity.',
      'explanation':
          'Describing flavor profiles ("full-bodied reds with subtle oak") allows precision sommelier service.',
      'diningScore': 5
    },
    {
      'id': 'go_practice_l1_q3',
      'level': 1,
      'diningContext': 'STEAKHOUSE PREPARATION',
      'waiterPrompt':
          'And how would you like the ribeye prepared, and would you like truffle fries or roasted asparagus as your side?',
      'question': 'Select the most articulate and polite patron response:',
      'options': [
        'Cook it medium-rare, please. And would it be possible to substitute the fries with roasted asparagus?',
        'Give me medium-rare and swap fries for asparagus, no charge.',
        'I want pink meat inside and green veggies instead of potato.'
      ],
      'correctAnswerIndex': 0,
      'correctAnswer':
          'Cook it medium-rare, please. And would it be possible to substitute the fries with roasted asparagus?',
      'explanation':
          '"Would it be possible to substitute..." is respectful and clearly articulates both the desired doneness and side.',
      'diningScore': 5
    },
  ];

  @override
  Widget build(BuildContext context) {
    final current = _quests[_exerciseIndex.clamp(0, _quests.length - 1)];
    final diningContext =
        current['diningContext'] as String? ?? 'DINING SETTING';
    final waiterPrompt = current['waiterPrompt'] as String? ?? '';
    final question = current['question'] as String? ??
        'Select the most articulate and polite patron response:';
    final options = (current['options'] as List<dynamic>? ?? []).cast<String>();
    final correctIdx = current['correctAnswerIndex'] as int? ?? 0;
    final explanation = current['explanation'] as String? ?? '';
    final isCorrect = _selectedOptionIndex == correctIdx;

    return PracticePhaseScaffold(
      title: 'Gourmet Order',
      gameType: 'gourmetOrder',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex + 1,
      totalExercises: _quests.length,
      onComplete: _onContinue,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Waiter Prompt Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.slate900,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.restaurant_rounded,
                              size: 14.sp,
                              color: AppColors.amber500,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'SERVER PROMPT',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: AppColors.amber500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.slate800,
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          diningContext,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.amber400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '"$waiterPrompt"',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate100,
                            height: 1.4,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const Key('practice_audio_button'),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.amber400,
                          size: 20.sp,
                        ),
                        onPressed: () => _playAudio(waiterPrompt),
                        tooltip: 'Listen to server prompt',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Instructions / Drill prompt
            Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14.sp,
                  color: AppColors.amber400,
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'RESTAURANT CONSULTATION',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.amber400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4.h),
            Text(
              question,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.slate300,
              ),
            ),
            SizedBox(height: 12.h),

            // Options List
            ...List.generate(options.length, (index) {
              final optionText = options[index];
              final isSelected = _selectedOptionIndex == index;

              Color borderColor = AppColors.slate800;
              Color bgColor = AppColors.slate900;
              Color textColor = AppColors.slate100;

              if (_hasChecked) {
                if (index == correctIdx) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.15);
                  textColor = AppColors.emerald400;
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.15);
                  textColor = AppColors.rose500;
                }
              } else if (isSelected) {
                borderColor = AppColors.amber500;
                bgColor = AppColors.amber500.withValues(alpha: 0.15);
                textColor = AppColors.amber400;
              }

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: borderColor,
                    width: isSelected || (_hasChecked && index == correctIdx)
                        ? 2
                        : 1,
                  ),
                ),
                child: InkWell(
                  key: Key('practice_option_$index'),
                  onTap: () => _onOptionSelected(index),
                  borderRadius: BorderRadius.circular(12.r),
                  child: Padding(
                    padding: EdgeInsets.all(14.r),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24.r,
                          height: 24.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? borderColor
                                  : AppColors.slate600,
                              width: 1.5,
                            ),
                            color: isSelected
                                ? borderColor.withValues(alpha: 0.2)
                                : Colors.transparent,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? borderColor
                                  : AppColors.slate400,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              height: 1.4,
                              color: textColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (_hasChecked && index == correctIdx)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.emerald500,
                            size: 20.sp,
                          ),
                        if (_hasChecked && isSelected && index != correctIdx)
                          Icon(
                            Icons.cancel_rounded,
                            color: AppColors.rose500,
                            size: 20.sp,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 14.h),

            // Check / Evaluate Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed: _selectedOptionIndex != null ? _onCheck : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber500,
                  disabledBackgroundColor: AppColors.slate800,
                  foregroundColor: AppColors.slate950,
                  disabledForegroundColor: AppColors.slate600,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'EVALUATE RESPONSE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

            // Feedback Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: AppColors.slate900,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.amber500.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle_outline_rounded
                              : Icons.info_outline_rounded,
                          size: 18.sp,
                          color: isCorrect
                              ? AppColors.emerald500
                              : AppColors.amber500,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            isCorrect
                                ? 'PERFECT PATRON PHRASING!'
                                : 'DINING ETIQUETTE FEEDBACK',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.amber500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColors.slate200,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber500,
                  foregroundColor: AppColors.slate950,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _exerciseIndex == _quests.length - 1
                      ? 'COMPLETE PRACTICE'
                      : 'NEXT EXERCISE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
