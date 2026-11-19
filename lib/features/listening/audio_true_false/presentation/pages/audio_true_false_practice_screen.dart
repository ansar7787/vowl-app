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

/// Interactive Practice Phase screen for Audio True/False ("Claim Verification Gym").
///
/// Learners listen to spoken audio statements, evaluate factual assertions,
/// and select the rigorous claim verification with supporting evidence.
class AudioTrueFalsePracticeScreen extends StatefulWidget {
  final int level;

  const AudioTrueFalsePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<AudioTrueFalsePracticeScreen> createState() =>
      _AudioTrueFalsePracticeScreenState();
}

class _AudioTrueFalsePracticeScreenState
    extends State<AudioTrueFalsePracticeScreen> {
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
        'assets/curriculum/listening/audioTrueFalse_practice_${startLevel}_$endLevel.json';

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
          'id': 'LIS_AUDIOTRUEFALSE_PRACTICE_FALLBACK_1',
          'textToSpeak': 'My sister plays the guitar after dinner.',
          'statement': 'My brother plays the guitar after dinner.',
          'instruction':
              'Listen to the audio and verify the statement with evidence:',
          'options': [
            'FALSE: Contradicted by the spoken audio "My sister plays the guitar".',
            'TRUE: The speaker directly affirmed this claim.',
            'TRUE: The statement matches the spoken audio exactly.',
            'UNCLEAR: The audio lacks sufficient information to verify.',
          ],
          'correctIndex': 0,
          'correctAnswer':
              'FALSE: Contradicted by the spoken audio "My sister plays the guitar".',
          'verdict': 'false',
          'evidenceQuote': 'My sister plays the guitar',
          'hint': 'Think about which family member is playing.',
          'explanation':
              'It is the speaker\'s sister who plays. A brother is a different person.',
          'emoji': '🎸',
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
    } catch (_) {}
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
        gameType: 'audioTrueFalse',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/mastery?category=listening&gameType=audioTrueFalse&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentQuest = _quests[_exerciseIndex];
    final textToSpeak = currentQuest['textToSpeak'] as String? ?? '';
    final statement = currentQuest['statement'] as String? ?? '';
    final instruction = currentQuest['instruction'] as String? ??
        'Listen to the audio and verify the statement with evidence:';
    final options = (currentQuest['options'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final correctIndex = currentQuest['correctIndex'] as int? ?? 0;
    final evidenceQuote = currentQuest['evidenceQuote'] as String? ?? '';
    final explanation = currentQuest['explanation'] as String? ?? '';
    final hint = currentQuest['hint'] as String? ?? '';

    return PracticePhaseScaffold(
      title: 'Claim Verification',
      gameType: 'audioTrueFalse',
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
            // Top Badges
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
                  child: Text(
                    'SCORE: $_score',
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

            // Spoken Audio Player Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.teal500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.teal500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
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
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SPOKEN EVIDENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.teal500,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Tap to hear the speaker',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    key: const Key('practice_audio_play_button'),
                    onPressed: () => _playAudio(textToSpeak),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal500,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 10.h,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      elevation: 0,
                    ),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      size: 18.sp,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Listen',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Instruction Text
            Text(
              instruction,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.slate300 : AppColors.slate700,
              ),
            ),
            SizedBox(height: 8.h),

            // Evaluated Statement Card
            Container(
              key: const Key('practice_statement_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fact_check_rounded,
                        size: 16.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'ASSERTION TO VERIFY',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    statement,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 4 Distinct Practice Options
            for (int i = 0; i < options.length; i++) ...[
              _buildOptionTile(
                index: i,
                text: options[i],
                isSelected: _selectedOptionIndex == i,
                isCorrect: i == correctIndex,
                hasChecked: _hasChecked,
                isDark: isDark,
              ),
              SizedBox(height: 10.h),
            ],
            SizedBox(height: 8.h),

            // Check Answer Button
            if (!_hasChecked)
              ElevatedButton(
                key: const Key('practice_check_button'),
                onPressed:
                    _selectedOptionIndex != null ? _onCheckAnswer : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  disabledBackgroundColor:
                      AppColors.teal500.withValues(alpha: 0.3),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Check Answer',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),

            // Explanation & Continue Card
            if (_hasChecked) ...[
              Container(
                key: const Key('practice_explanation_card'),
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.1)
                      : AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? AppColors.emerald500
                        : AppColors.rose500,
                    width: 1.5,
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
                              : Icons.cancel_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 20.sp,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Text(
                            _isCorrect
                                ? 'EXCELLENT VERIFICATION (+10 PTS)'
                                : 'INCORRECT EVALUATION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    if (evidenceQuote.isNotEmpty) ...[
                      Text(
                        'Spoken Evidence: "$evidenceQuote"',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate800,
                        ),
                      ),
                      SizedBox(height: 6.h),
                    ],
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate700,
                        height: 1.4,
                      ),
                    ),
                    if (hint.isNotEmpty && !_isCorrect) ...[
                      SizedBox(height: 6.h),
                      Text(
                        'Hint: $hint',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontStyle: FontStyle.italic,
                          color: AppColors.amber500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
              ElevatedButton(
                key: const Key('practice_continue_button'),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _exerciseIndex < _quests.length - 1
                      ? 'Next Question'
                      : 'Complete Practice',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required int index,
    required String text,
    required bool isSelected,
    required bool isCorrect,
    required bool hasChecked,
    required bool isDark,
  }) {
    Color borderColor;
    Color bgColor;

    if (!hasChecked) {
      if (isSelected) {
        borderColor = AppColors.teal500;
        bgColor = AppColors.teal500.withValues(alpha: 0.12);
      } else {
        borderColor = isDark ? AppColors.slate700 : AppColors.slate200;
        bgColor = isDark ? AppColors.slate800 : Colors.white;
      }
    } else {
      if (isCorrect) {
        borderColor = AppColors.emerald500;
        bgColor = AppColors.emerald500.withValues(alpha: 0.15);
      } else if (isSelected && !isCorrect) {
        borderColor = AppColors.rose500;
        bgColor = AppColors.rose500.withValues(alpha: 0.15);
      } else {
        borderColor = isDark ? AppColors.slate700 : AppColors.slate200;
        bgColor = isDark ? AppColors.slate800 : Colors.white;
      }
    }

    return InkWell(
      key: Key('practice_option_$index'),
      onTap: () => _onOptionSelected(index),
      borderRadius: BorderRadius.circular(14.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: borderColor,
            width: isSelected || (hasChecked && isCorrect) ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasChecked
                    ? (isCorrect
                        ? AppColors.emerald500
                        : (isSelected ? AppColors.rose500 : Colors.transparent))
                    : (isSelected ? AppColors.teal500 : Colors.transparent),
                border: Border.all(
                  color: hasChecked
                      ? (isCorrect
                          ? AppColors.emerald500
                          : (isSelected
                              ? AppColors.rose500
                              : AppColors.slate400))
                      : (isSelected ? AppColors.teal500 : AppColors.slate400),
                  width: 1.5,
                ),
              ),
              child: hasChecked
                  ? Icon(
                      isCorrect
                          ? Icons.check_rounded
                          : (isSelected
                              ? Icons.close_rounded
                              : Icons.circle_outlined),
                      size: 16.sp,
                      color: isCorrect || isSelected
                          ? Colors.white
                          : AppColors.slate400,
                    )
                  : Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppColors.slate400,
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate900,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
