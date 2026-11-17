import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

/// Interactive Practice Phase screen for Word Formation: "Affix Association Gym".
///
/// Drills learners on identifying roots, injecting correct affixes into sentence contexts,
/// and typing the newly formed words with immediate feedback and explanation.
class WordFormationPracticeScreen extends StatefulWidget {
  final int level;

  const WordFormationPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<WordFormationPracticeScreen> createState() =>
      _WordFormationPracticeScreenState();
}

class _WordFormationPracticeScreenState
    extends State<WordFormationPracticeScreen> {
  List<PhasedQuest> _quests = const [
    PhasedQuest(
      id: 'FALLBACK_WF_P1',
      level: 1,
      conceptTitle: 'Morphology Gym: HELP',
      word: 'HELP',
      definition:
          'HELP + -FUL = HELPFUL. Suffix -FUL turns HELP into an adjective meaning supportive.',
      example: 'My neighbor was very ____ when I was moving furniture.',
      nativeTip: '-ful forms adjectives meaning full of something.',
      visualAnchor: '🏋️ Word Formation Gym • HELP',
      rawExtra: {
        'rootWord': 'HELP',
        'correctAnswer': 'HELPFUL',
        'options': ['-FUL', '-ISH', '-ORY', '-IST'],
        'familyTree': ['HELP', 'HELPER', 'HELPFUL', 'HELPLESS'],
        'targetAffix': '-FUL',
      },
    ),
    PhasedQuest(
      id: 'FALLBACK_WF_P2',
      level: 1,
      conceptTitle: 'Morphology Gym: CARE',
      word: 'CARE',
      definition:
          'CARE + -LESS = CARELESS. Suffix -LESS forms an adjective meaning without care.',
      example: 'He crossed the street without looking, which was ____.',
      nativeTip: '-less creates an adjective meaning lacking that quality.',
      visualAnchor: '🏋️ Word Formation Gym • CARE',
      rawExtra: {
        'rootWord': 'CARE',
        'correctAnswer': 'CARELESS',
        'options': ['-FUL', '-ISH', '-MENT', '-LESS'],
        'familyTree': ['CARE', 'CAREFUL', 'CARELESS', 'CARETAKER'],
        'targetAffix': '-LESS',
      },
    ),
  ];

  int _currentIndex = 0;
  String? _selectedAffix;
  bool? _isAffixCorrect;
  bool _showExplanation = false;

  final TextEditingController _typingController = TextEditingController();
  bool _isTypingCorrect = false;
  bool _typingValidated = false;

  @override
  void initState() {
    super.initState();
    _loadPracticeQuests();
  }

  @override
  void dispose() {
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _loadPracticeQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/wordFormation_practice_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);
      if (batch.quests.isNotEmpty && mounted) {
        setState(() {
          _quests = batch.quests;
        });
      }
    } catch (_) {
      // Fallback quests are already initialized
    }
  }

  void _onAffixChosen(String affix, String correctAnswer) {
    if (_isAffixCorrect == true) return;

    final clean = affix.replaceAll('-', '').trim().toLowerCase();
    final correct = correctAnswer.trim().toLowerCase();
    final isMatch = correct.endsWith(clean) || correct.startsWith(clean);

    setState(() {
      _selectedAffix = affix;
      _isAffixCorrect = isMatch;
      _showExplanation = true;
    });

    if (isMatch) {
      di.sl<HapticService>().success();
      di.sl<SoundService>().playCorrect();
      di.sl<TtsService>().speak(correctAnswer);
    } else {
      di.sl<HapticService>().error();
      di.sl<SoundService>().playWrong();
    }
  }

  void _validateTyping(String targetWord) {
    final input = _typingController.text.trim().toLowerCase();
    final target = targetWord.trim().toLowerCase();
    final isMatch = input == target;

    setState(() {
      _isTypingCorrect = isMatch;
      _typingValidated = true;
    });

    if (isMatch) {
      di.sl<HapticService>().success();
      di.sl<SoundService>().playCorrect();
      di.sl<TtsService>().speak(targetWord);
    } else {
      di.sl<HapticService>().error();
      di.sl<SoundService>().playWrong();
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAffix = null;
        _isAffixCorrect = null;
        _showExplanation = false;
        _typingController.clear();
        _isTypingCorrect = false;
        _typingValidated = false;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'wordFormation',
        level: widget.level,
        phase: 'practice',
      );
      context.pushReplacement(
        '/game?category=vocabulary&gameType=wordFormation&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests[_currentIndex];
    final theme = LevelThemeHelper.getTheme(
      'vocabulary',
      level: widget.level,
    );
    final primaryColor = theme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rootWord = (quest.rawExtra['rootWord'] as String?) ??
        ((quest.word?.isNotEmpty == true) ? quest.word! : 'ROOT');
    final correctAnswer =
        (quest.rawExtra['correctAnswer'] as String?) ?? 'FORMED WORD';
    final options = (quest.rawExtra['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['-FUL', '-LESS', '-ABLE', '-NESS'];

    return PracticePhaseScaffold(
      title: 'Word Formation Gym',
      gameType: 'wordFormation',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Practice (${_currentIndex + 1}/${_quests.length})'
          : 'Proceed to Mastery Exam 🏆',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6.r),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / _quests.length,
                      backgroundColor: isDark
                          ? AppColors.slate800
                          : AppColors.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      minHeight: 8.h,
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Text(
                  '${_currentIndex + 1} / ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // Drill 1: Context Sentence & Base Root
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(
                                alpha: isDark ? 0.2 : 0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'DRILL 1: AFFIX INJECTION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'BASE: $rootWord',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    quest.example ??
                        'Synthesize the appropriate word using root "$rootWord":',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    'Select the matching affix:',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: options.map((affix) {
                      final isChosen = _selectedAffix == affix;
                      final isCorrect = isChosen && _isAffixCorrect == true;
                      final isWrong = isChosen && _isAffixCorrect == false;

                      Color bg =
                          isDark ? AppColors.slate800 : AppColors.slate100;
                      if (isCorrect) bg = AppColors.emerald500;
                      if (isWrong) bg = AppColors.rose500;

                      return GestureDetector(
                        onTap: () => _onAffixChosen(affix, correctAnswer),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color: isCorrect
                                  ? AppColors.emerald400
                                  : isWrong
                                      ? AppColors.rose500
                                      : primaryColor.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            affix,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w800,
                              color: (isCorrect || isWrong)
                                  ? Colors.white
                                  : (isDark
                                      ? Colors.white
                                      : AppColors.slate900),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Drill 2: Spelling Confirmation & Gap-Fill
            if (_isAffixCorrect == true) ...[
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _typingValidated
                        ? (_isTypingCorrect
                            ? AppColors.emerald500
                            : AppColors.rose500)
                        : (isDark ? AppColors.slate800 : AppColors.slate200),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: AppColors.amber500.withValues(
                            alpha: isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'DRILL 2: SPELLING SOLIDIFICATION',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.amber500,
                        ),
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      'Type the full synthesized word ($rootWord + $_selectedAffix):',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('wf_practice_typing_field'),
                            controller: _typingController,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. $correctAnswer',
                              hintStyle: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                color: isDark
                                    ? AppColors.slate600
                                    : AppColors.slate400,
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12.w,
                                vertical: 10.h,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? AppColors.slate800
                                  : AppColors.slate100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.r),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onSubmitted: (_) => _validateTyping(correctAnswer),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        ElevatedButton(
                          key: const Key('wf_practice_typing_check_button'),
                          onPressed: () => _validateTyping(correctAnswer),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 14.w,
                              vertical: 12.h,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: const Text('Check'),
                        ),
                      ],
                    ),
                    if (_typingValidated) ...[
                      SizedBox(height: 8.h),
                      Text(
                        _isTypingCorrect
                            ? '✅ Excellent spelling!'
                            : '❌ Expected: $correctAnswer',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: _isTypingCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Explanation Card
            if (_showExplanation) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded,
                            color: primaryColor, size: 16.r),
                        SizedBox(width: 6.w),
                        Text(
                          'MORPHOLOGY EXPLANATION',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      quest.definition ??
                          'Formed word "$correctAnswer" derives from base "$rootWord".',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        height: 1.4,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            SizedBox(height: 16.h),
          ],
        ),
      ),
    );
  }
}
