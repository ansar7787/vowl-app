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

/// Interactive Practice Phase screen for Shadowing Challenge ("Shadowing Calibration Gym").
///
/// Prompts learners to listen to spoken sentences and identify the correct connected speech,
/// rhythm, or flow feature across 4 distinct options with instant feedback.
class ShadowingChallengePracticeScreen extends StatefulWidget {
  final int level;

  const ShadowingChallengePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ShadowingChallengePracticeScreen> createState() =>
      _ShadowingChallengePracticeScreenState();
}

class _ShadowingChallengePracticeScreenState
    extends State<ShadowingChallengePracticeScreen> {
  int _exerciseIndex = 0;
  int? _selectedOptionIndex;
  bool _hasChecked = false;
  int _score = 0;
  final double _selectedSpeed = 1.0;
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
        'assets/curriculum/accent/shadowingChallenge_practice_${startLevel}_$endLevel.json';

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
          'id': 'ACC_SHADOWINGCHALLENGE_PRACTICE_FALLBACK_1',
          'gameType': 'shadowingChallenge',
          'level': widget.level,
          'instruction': 'Identify the speech flow rule in this sentence',
          'word': 'My brother works out every evening.',
          'textToSpeak': 'My brother works out every evening.',
          'ipa': '/maɪ ˈbrʌðə wɜːks‿aʊt ˈevri ˈiːvnɪŋ/',
          'options': [
            "Linking: the final consonant sound of 'works' glides directly into the vowel sound that opens 'out'.",
            "Pausing: a short, deliberate pause separates 'works' from 'out', so the sounds don't connect.",
            "Full Citation Form: Every word is pronounced individually with crisp, isolated citation boundaries.",
            "Glottal Stop Insertion: An abrupt vocal cord stop cuts off each syllable before the next sound.",
          ],
          'correctAnswer':
              "Linking: the final consonant sound of 'works' glides directly into the vowel sound that opens 'out'.",
          'correctAnswerIndex': 0,
          'explanation':
              "'works' ends in a consonant sound and 'out' begins with a vowel sound, so in fluent speech they link smoothly into one flowing unit.",
          'flowRule':
              "Consonant-to-Vowel Linking: when a word ends in a consonant sound and the next begins with a vowel sound, they link together smoothly without a pause.",
        },
        {
          'id': 'ACC_SHADOWINGCHALLENGE_PRACTICE_FALLBACK_2',
          'gameType': 'shadowingChallenge',
          'level': widget.level,
          'instruction': 'Identify the speech flow rule in this sentence',
          'word': 'I locked the office early.',
          'textToSpeak': 'I locked the office early.',
          'ipa': '/aɪ lɒkt ði ˈɒfɪs ˈɜːli/',
          'options': [
            "Here, 'the' is pronounced /ðiː/ because 'office' begins with a vowel sound.",
            "Here, 'the' is pronounced /ðə/ because 'office' begins with a consonant sound.",
            "Stressed Articulation: Equal high pitch and primary stress are placed across all syllables.",
            "Formal Pacing: The speaker pauses deliberately at every grammatical word boundary.",
          ],
          'correctAnswer':
              "Here, 'the' is pronounced /ðiː/ because 'office' begins with a vowel sound.",
          'correctAnswerIndex': 0,
          'explanation':
              "English speakers change how they say 'the' depending on the next sound: /ðə/ before a consonant sound, /ðiː/ before a vowel sound.",
          'flowRule':
              "Vowel Sound Anticipation: 'the' is pronounced /ðiː/ before a vowel sound and /ðə/ before a consonant sound.",
        },
        {
          'id': 'ACC_SHADOWINGCHALLENGE_PRACTICE_FALLBACK_3',
          'gameType': 'shadowingChallenge',
          'level': widget.level,
          'instruction': 'Identify the speech flow rule in this sentence',
          'word': 'She brought an umbrella today.',
          'textToSpeak': 'She brought an umbrella today.',
          'ipa': '/ʃiː brɔːt ən ʌmˈbrelə təˈdeɪ/',
          'options': [
            "'an' is used here because 'umbrella' begins with a vowel sound.",
            "'a' would be used here because 'umbrella' begins with a consonant sound.",
            "Spelling Pronunciation: Each letter is sounded out according to its literal spelling rather than phonetic flow.",
            "Over-Enunciation: Unstressed function words are amplified with full non-reduced vowels.",
          ],
          'correctAnswer':
              "'an' is used here because 'umbrella' begins with a vowel sound.",
          'correctAnswerIndex': 0,
          'explanation':
              "'A' and 'an' are chosen by sound, not spelling. 'umbrella' starts with a vowel sound, so 'an' is the natural, correct choice.",
          'flowRule':
              "Article Sound Agreement: 'an' is used before a word that begins with a vowel sound, based on sound, not spelling.",
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: 0.4 * _selectedSpeed);
      }
    } catch (_) {}
  }

  void _selectOption(int index) {
    if (_hasChecked) return;
    HapticFeedback.selectionClick();
    setState(() {
      _selectedOptionIndex = index;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null || _hasChecked) return;

    final quest = _quests[_exerciseIndex % _quests.length];
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final isCorrect = options.isNotEmpty &&
        _selectedOptionIndex! < options.length &&
        options[_selectedOptionIndex!] == correctAnswer;

    setState(() {
      _hasChecked = true;
      if (isCorrect) _score++;
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

  void _nextExercise() {
    if (_exerciseIndex + 1 < _quests.length) {
      setState(() {
        _exerciseIndex++;
        _selectedOptionIndex = null;
        _hasChecked = false;
      });
    } else {
      _onPracticeComplete();
    }
  }

  void _onPracticeComplete() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'shadowingChallenge',
      level: widget.level,
      phase: 'practice',
    );

    if (mounted) {
      try {
        context.pushReplacement(
          '/mastery?category=accent&gameType=shadowingChallenge&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests[_exerciseIndex % _quests.length];
    final word = quest['word'] as String? ?? 'Target sentence';
    final textToSpeak = quest['textToSpeak'] as String? ?? word;
    final ipa = quest['ipa'] as String? ?? '';
    final instruction = quest['instruction'] as String? ??
        'Identify the speech flow rule in this sentence';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final flowRule = quest['flowRule'] as String? ?? '';

    final isCorrect = _hasChecked &&
        _selectedOptionIndex != null &&
        _selectedOptionIndex! < options.length &&
        options[_selectedOptionIndex!] == correctAnswer;

    return PracticePhaseScaffold(
      title: 'Shadowing Calibration Gym',
      gameType: 'shadowingChallenge',
      level: widget.level,
      currentExerciseIndex: _exerciseIndex,
      totalExercises: _quests.length,
      onComplete: _onPracticeComplete,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Score and Progress Header
            _buildScoreHeader(),
            SizedBox(height: 16.h),

            // Instruction Card
            _buildInstructionCard(instruction),
            SizedBox(height: 16.h),

            // Target Spoken Phrase Card
            _buildTargetPhraseCard(word, textToSpeak, ipa),
            SizedBox(height: 20.h),

            // Option Selection Grid
            _buildOptionsList(options, correctAnswer),
            SizedBox(height: 24.h),

            // Check Answer Button (only before checking)
            if (!_hasChecked) _buildCheckButton(),

            // Feedback and Explanation Card (after checking)
            if (_hasChecked) ...[
              _buildFeedbackCard(isCorrect, flowRule, explanation),
              SizedBox(height: 20.h),
              _buildContinueButton(),
            ],
            SizedBox(height: 32.h),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.w,
        runSpacing: 6.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_rounded,
                size: 18.sp,
                color: AppColors.teal500,
              ),
              SizedBox(width: 8.w),
              Text(
                'EXERCISE ${_exerciseIndex + 1} OF ${_quests.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate200,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: AppColors.teal500.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              'SCORE: $_score',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w800,
                color: AppColors.teal500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard(String instruction) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.indigo500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.headphones_rounded,
            size: 22.sp,
            color: AppColors.indigo500,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.indigo500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPhraseCard(
      String word, String textToSpeak, String ipa) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Text(
                'TARGET SENTENCE',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate400,
                  letterSpacing: 0.8,
                ),
              ),
              ElevatedButton.icon(
                key: const Key('practice_listen_button'),
                onPressed: () => _playAudio(textToSpeak),
                icon: Icon(
                  Icons.volume_up_rounded,
                  size: 18.sp,
                  color: AppColors.white,
                ),
                label: Text(
                  'Listen (${_selectedSpeed}x)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            '“$word”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              height: 1.35,
            ),
          ),
          if (ipa.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Center(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  ipa,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionsList(List<String> options, String correctAnswer) {
    return Column(
      children: List.generate(options.length, (index) {
        final opt = options[index];
        final isSelected = _selectedOptionIndex == index;
        final isAnswer = opt == correctAnswer;

        Color borderColor = AppColors.slate200;
        Color bgColor = AppColors.white;
        Color textColor = AppColors.slate800;

        if (_hasChecked) {
          if (isAnswer) {
            borderColor = AppColors.emerald500;
            bgColor = AppColors.emerald500.withValues(alpha: 0.1);
            textColor = AppColors.emerald500;
          } else if (isSelected && !isAnswer) {
            borderColor = AppColors.rose500;
            bgColor = AppColors.rose500.withValues(alpha: 0.1);
            textColor = AppColors.rose500;
          }
        } else if (isSelected) {
          borderColor = AppColors.indigo500;
          bgColor = AppColors.indigo500.withValues(alpha: 0.08);
          textColor = AppColors.indigo500;
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GestureDetector(
            key: Key('practice_option_$index'),
            onTap: () => _selectOption(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: borderColor,
                  width: isSelected || (_hasChecked && isAnswer) ? 2 : 1,
                ),
                boxShadow: [
                  if (!isSelected && !_hasChecked)
                    BoxShadow(
                      color: AppColors.slate900.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28.w,
                    height: 28.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? borderColor
                          : AppColors.slate100,
                    ),
                    child: Center(
                      child: Text(
                        String.fromCharCode(65 + index),
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: isSelected
                              ? AppColors.white
                              : AppColors.slate600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (_hasChecked && isAnswer)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 22.sp,
                      color: AppColors.emerald500,
                    )
                  else if (_hasChecked && isSelected && !isAnswer)
                    Icon(
                      Icons.cancel_rounded,
                      size: 22.sp,
                      color: AppColors.rose500,
                    ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCheckButton() {
    final isEnabled = _selectedOptionIndex != null;

    return ElevatedButton(
      key: const Key('practice_check_button'),
      onPressed: isEnabled ? _checkAnswer : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo500,
        disabledBackgroundColor: AppColors.slate200,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        elevation: isEnabled ? 3 : 0,
      ),
      child: Text(
        'CHECK ANSWER',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: isEnabled ? AppColors.white : AppColors.slate400,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(
      bool isCorrect, String flowRule, String explanation) {
    return Container(
      key: const Key('practice_explanation_card'),
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.emerald500.withValues(alpha: 0.1)
            : AppColors.rose500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
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
                    ? Icons.check_circle_rounded
                    : Icons.error_outline_rounded,
                size: 24.sp,
                color: isCorrect ? AppColors.emerald500 : AppColors.rose500,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  isCorrect
                      ? 'EXCELLENT FLOW SENSE!'
                      : 'KEEP PRACTICING',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                    color: isCorrect
                        ? AppColors.emerald500
                        : AppColors.rose500,
                  ),
                ),
              ),
            ],
          ),
          if (flowRule.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              flowRule,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
                height: 1.35,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.slate700,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContinueButton() {
    return ElevatedButton(
      key: const Key('practice_continue_button'),
      onPressed: _nextExercise,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.indigo500,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
      child: Text(
        _exerciseIndex + 1 < _quests.length
            ? 'CONTINUE TO NEXT PHRASE'
            : 'COMPLETE PRACTICE',
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w800,
          color: AppColors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
