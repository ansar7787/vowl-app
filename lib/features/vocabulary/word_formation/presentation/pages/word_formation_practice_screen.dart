import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/word_formation/data/services/word_formation_curriculum_service.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_4way_launcher.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_family_tree.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_morph_core.dart';
import 'package:vowl/features/vocabulary/word_formation/presentation/widgets/word_formation_sentence_slot.dart';

/// Practice Phase screen for Word Formation: The Directional Morph Launcher.
class WordFormationPracticeScreen extends StatefulWidget {
  final int level;

  const WordFormationPracticeScreen({super.key, required this.level});

  @override
  State<WordFormationPracticeScreen> createState() =>
      _WordFormationPracticeScreenState();
}

class _WordFormationPracticeScreenState
    extends State<WordFormationPracticeScreen> {
  List<PhasedQuest> _quests = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  String? _selectedDirection;
  bool _isAnswered = false;
  bool? _isCorrect;
  int _shakeCount = 0;
  int _comboStreak = 0;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    final quests =
        await WordFormationCurriculumService().getPracticeQuests(widget.level);
    if (mounted) {
      setState(() {
        _quests = quests;
        _isLoading = false;
      });
    }
  }

  void _onDirectionSelected(String direction) {
    if (_isAnswered && _isCorrect == true) return;

    final quest = _quests[_currentIndex];
    final extra = quest.rawExtra;
    final correctDir = (extra['correctDirection'] as String? ?? 'north')
        .trim()
        .toLowerCase();
    final isMatch = direction.trim().toLowerCase() == correctDir;

    setState(() {
      _selectedDirection = direction;
      _isAnswered = true;
      _isCorrect = isMatch;
      if (!isMatch) {
        _shakeCount++;
      }
    });

    if (isMatch) {
      _comboStreak++;
      di.sl<HapticService>().success();
      di.sl<SoundService>().playCorrect();
      final sentence = extra['sentence'] as String? ?? quest.example ?? '';
      final target =
          extra['targetWord'] as String? ?? quest.correctAnswer ?? '';
      if (sentence.isNotEmpty && target.isNotEmpty) {
        final fullText = sentence.replaceAll('_______', target);
        di.sl<TtsService>().speak(fullText);
      }
    } else {
      _comboStreak = 0;
      di.sl<HapticService>().error();
      di.sl<SoundService>().playWrong();
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedDirection = null;
        _isAnswered = false;
        _isCorrect = null;
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
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Practice: Word Forms',
        gameType: 'wordFormation',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 3,
        onComplete: _onNext,
        child: GameShimmerLoading(primaryColor: primaryColor),
      );
    }

    final quest = _quests[_currentIndex];
    final extra = quest.rawExtra;
    final rootWord = (extra['rootWord'] as String?) ?? quest.word ?? 'ROOT';
    final rootMeaning = (extra['rootMeaning'] as String?) ?? quest.definition;
    final sentence =
        (extra['sentence'] as String?) ??
        quest.example ??
        'Sentence with _______';
    final targetWord =
        (extra['targetWord'] as String?) ?? quest.correctAnswer ?? 'TARGET';
    final targetRole = (extra['targetRole'] as String?) ?? 'Target';
    final roleClue = extra['roleClue'] as String?;
    final correctDir = extra['correctDirection'] as String? ?? 'north';
    final bounceFeedback = extra['bounceFeedback'] as String?;
    final explanation = extra['explanation'] as String?;
    final familyTree = (extra['familyTree'] is List)
        ? (extra['familyTree'] as List).map((e) => e.toString()).toList()
        : <String>[];

    final northWord = (extra['northNoun'] as String?) ?? '${rootWord}_NOUN';
    final eastWord = (extra['eastAdjective'] as String?) ?? '${rootWord}_ADJ';
    final southWord = (extra['southAdverb'] as String?) ?? '${rootWord}_ADV';
    final westWord = (extra['westOpposite'] as String?) ?? '${rootWord}_OPP';

    return PracticePhaseScaffold(
      title: 'Practice: $rootWord',
      gameType: 'wordFormation',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _onNext,
      isActionEnabled: _isAnswered && _isCorrect == true,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Exercise'
          : 'Start Mastery Challenge',
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: 8.h),
                    WordFormationSentenceSlot(
                      sentence: sentence,
                      formedWord: _isAnswered && _isCorrect == true
                          ? targetWord
                          : null,
                      rootWord: rootWord,
                      targetRole: targetRole,
                      roleClue: roleClue,
                      isAnswered: _isAnswered,
                      isCorrect: _isCorrect,
                      primaryColor: primaryColor,
                      bounceFeedback: bounceFeedback,
                      shakeCount: _shakeCount,
                    ),
                    SizedBox(height: 12.h),
                    WordFormationMorphCore(
                      rootWord: rootWord,
                      rootMeaning: rootMeaning,
                      primaryColor: primaryColor,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12.h),
                    WordFormation4WayLauncher(
                      northWord: northWord,
                      eastWord: eastWord,
                      southWord: southWord,
                      westWord: westWord,
                      selectedDirection: _selectedDirection,
                      correctDirection: _isAnswered ? correctDir : null,
                      isAnswered: _isAnswered,
                      primaryColor: primaryColor,
                      comboStreak: _comboStreak,
                      onDirectionSelected: _onDirectionSelected,
                    ),
                    if (_isAnswered &&
                        _isCorrect == true &&
                        familyTree.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      WordFormationFamilyTree(
                        familyTree: familyTree,
                        color: primaryColor,
                      ),
                    ],
                    if (_isAnswered &&
                        _isCorrect == true &&
                        explanation != null &&
                        explanation.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gameCorrect.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: AppColors.gameCorrect.withValues(
                              alpha: 0.25,
                            ),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_rounded,
                              color: AppColors.gameCorrect,
                              size: 18.r,
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Grammar Insight',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gameCorrect,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    explanation,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 13.sp,
                                      fontWeight: FontWeight.w400,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 16.h),
                  ],
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 16.h, top: 8.h),
                child: ScaleButton(
                  onTap: _isAnswered && _isCorrect == true ? _onNext : null,
                  child: Container(
                    width: double.infinity,
                    height: 52.h,
                    decoration: BoxDecoration(
                      color: _isAnswered && _isCorrect == true
                          ? primaryColor
                          : primaryColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16.r),
                      boxShadow: [
                        if (_isAnswered && _isCorrect == true)
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentIndex < _quests.length - 1
                              ? 'Next Exercise'
                              : 'Start Mastery Challenge',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
