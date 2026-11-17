import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Interactive Learn Phase screen for Word Formation: "Morphology & Word Formation Lab".
///
/// Explores root words, morphological affixes (prefixes & suffixes), and word family trees
/// (e.g., HELP -> HELPER, HELPFUL, HELPLESS), allowing learners to preview and test affix synthesis.
class WordFormationLearnScreen extends StatefulWidget {
  final int level;

  const WordFormationLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<WordFormationLearnScreen> createState() =>
      _WordFormationLearnScreenState();
}

class _WordFormationLearnScreenState extends State<WordFormationLearnScreen> {
  List<PhasedQuest> _quests = const [
    PhasedQuest(
      id: 'FALLBACK_WF_1',
      level: 1,
      conceptTitle: 'Root Morphology: HELP',
      word: 'HELP',
      definition:
          'HELP + -FUL = HELPFUL. The suffix -FUL means "full of" and turns the noun HELP into an adjective describing someone who gives support.',
      example: 'My neighbor was very helpful when I was moving furniture.',
      nativeTip:
          'Suffixes alter grammatical roles; -ful creates adjectives, -er creates agent nouns.',
      visualAnchor: '🔬 Morphological Synthesis • HELP',
      rawExtra: {
        'rootWord': 'HELP',
        'correctAnswer': 'HELPFUL',
        'options': ['-FUL', '-ISH', '-ORY', '-IST'],
        'familyTree': ['HELP', 'HELPER', 'HELPFUL', 'HELPLESS'],
        'targetAffix': '-FUL',
      },
    ),
    PhasedQuest(
      id: 'FALLBACK_WF_2',
      level: 1,
      conceptTitle: 'Root Morphology: CARE',
      word: 'CARE',
      definition:
          'CARE + -LESS = CARELESS. The suffix -LESS means "without", describing someone acting without enough care or attention.',
      example: 'He crossed the busy street without looking, which was very careless.',
      nativeTip:
          '-less is the opposite of -ful, indicating the total lack of an attribute.',
      visualAnchor: '🔬 Morphological Synthesis • CARE',
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

  @override
  void initState() {
    super.initState();
    _loadLearnQuests();
  }

  Future<void> _loadLearnQuests() async {
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/vocabulary/wordFormation_learn_${startLevel}_$endLevel.json';
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

  void _onAffixTapped(String affix, String correctAnswer) {
    final clean = affix.replaceAll('-', '').trim().toLowerCase();
    final correct = correctAnswer.trim().toLowerCase();
    final matches = correct.endsWith(clean) || correct.startsWith(clean);

    setState(() {
      _selectedAffix = affix;
      _isAffixCorrect = matches;
    });

    if (matches) {
      di.sl<TtsService>().speak(correctAnswer);
    }
  }

  void _onNext() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAffix = null;
        _isAffixCorrect = null;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'wordFormation',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=vocabulary&gameType=wordFormation&level=${widget.level}',
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
    final familyTree = (quest.rawExtra['familyTree'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[rootWord, correctAnswer];

    return LearnPhaseScaffold(
      title: 'Morphology & Word Formation Lab',
      gameType: 'wordFormation',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'Next Root (${_currentIndex + 1}/${_quests.length})'
          : 'Start Morphology Gym 🏋️',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Bar & Counter
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

            // Visual Anchor Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: isDark ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.biotech_rounded, color: primaryColor, size: 22.r),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      quest.visualAnchor ??
                          '🔬 Morphological Synthesis • $rootWord',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded,
                        color: primaryColor, size: 20.r),
                    tooltip: 'Listen to target word',
                    onPressed: () => di.sl<TtsService>().speak(correctAnswer),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Concept Header & Base Root Hub
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    quest.conceptTitle ?? 'Root Morphology: $rootWord',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildPill(
                          label: 'BASE ROOT',
                          text: rootWord,
                          color: primaryColor,
                          isDark: isDark,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          Icons.add_circle_rounded,
                          color: primaryColor,
                          size: 20.r,
                        ),
                      ),
                      Expanded(
                        child: _buildPill(
                          label: 'AFFIX',
                          text: _selectedAffix ?? '?',
                          color: _isAffixCorrect == true
                              ? AppColors.emerald500
                              : AppColors.amber500,
                          isDark: isDark,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          color: primaryColor,
                          size: 20.r,
                        ),
                      ),
                      Expanded(
                        child: _buildPill(
                          label: 'RESULT',
                          text: _isAffixCorrect == true ? correctAnswer : '???',
                          color: _isAffixCorrect == true
                              ? AppColors.emerald500
                              : AppColors.slate500,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Morphological Definition Card
            _buildCard(
              isDark: isDark,
              accentColor: primaryColor,
              icon: Icons.menu_book_rounded,
              badgeText: 'MORPHOLOGICAL FORMATION',
              body: quest.definition ??
                  'Combining the base root with an affix synthesizes new parts of speech and nuances.',
            ),
            SizedBox(height: 12.h),

            // Word Family Tree Explorer
            if (familyTree.isNotEmpty) ...[
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
                        Icon(Icons.account_tree_rounded,
                            color: primaryColor, size: 18.r),
                        SizedBox(width: 8.w),
                        Text(
                          'WORD FAMILY TREE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: familyTree.map((member) {
                        return ActionChip(
                          avatar: Icon(
                            Icons.volume_up_rounded,
                            size: 14.r,
                            color: primaryColor,
                          ),
                          label: Text(
                            member,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                          backgroundColor: primaryColor.withValues(
                            alpha: isDark ? 0.2 : 0.08,
                          ),
                          side: BorderSide(
                            color: primaryColor.withValues(alpha: 0.3),
                          ),
                          onPressed: () => di.sl<TtsService>().speak(member),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Interactive Affix Fusion Tryout
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: _isAffixCorrect == true
                      ? AppColors.emerald500
                      : (isDark ? AppColors.slate800 : AppColors.slate200),
                  width: _isAffixCorrect == true ? 2.0 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.science_rounded,
                        color: _isAffixCorrect == true
                            ? AppColors.emerald500
                            : primaryColor,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'INTERACTIVE AFFIX FUSION TRYOUT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: _isAffixCorrect == true
                                ? AppColors.emerald500
                                : primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Tap the correct affix to synthesize "$correctAnswer":',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    children: options.map((affix) {
                      final isSelected = _selectedAffix == affix;
                      final isCorrect = isSelected && _isAffixCorrect == true;
                      final isWrong = isSelected && _isAffixCorrect == false;

                      Color chipColor = isDark
                          ? AppColors.slate800
                          : AppColors.slate100;
                      if (isCorrect) chipColor = AppColors.emerald500;
                      if (isWrong) chipColor = AppColors.rose500;

                      return GestureDetector(
                        onTap: () => _onAffixTapped(affix, correctAnswer),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          decoration: BoxDecoration(
                            color: chipColor,
                            borderRadius: BorderRadius.circular(12.r),
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
                  if (_isAffixCorrect == true) ...[
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.emerald500,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Perfect! $rootWord + $_selectedAffix ➔ $correctAnswer',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald500,
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
          ],
        ),
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required String text,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({
    required bool isDark,
    required Color accentColor,
    required IconData icon,
    required String badgeText,
    required String body,
  }) {
    return Container(
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
              Icon(icon, color: accentColor, size: 16.r),
              SizedBox(width: 8.w),
              Text(
                badgeText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: accentColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            body,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              height: 1.45,
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}
