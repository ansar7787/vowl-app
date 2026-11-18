import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Practice phase screen for Guess Title mini-game.
/// Provides an interactive "Headline Matcher Gym" challenging students to evaluate
/// and choose the title that accurately captures the whole passage without falling into
/// narrow detail or over-generalized traps.
class GuessTitlePracticeScreen extends StatefulWidget {
  final int level;

  const GuessTitlePracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<GuessTitlePracticeScreen> createState() =>
      _GuessTitlePracticeScreenState();
}

class _GuessTitlePracticeScreenState extends State<GuessTitlePracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;
  bool _isLoading = false;

  int? _selectedOptionIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

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
        'assets/curriculum/reading/guessTitle_practice_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests.where((q) {
        final qLevel = q['level'] as int? ?? 1;
        return qLevel == widget.level;
      }).toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          }
        });
      }
    } catch (_) {
      // Retain fallback quests on asset load failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_GUESSTITLE_PRACTICE_FALLBACK_1',
          'level': widget.level,
          'instruction':
              'Select the title that captures the central thesis without being too broad or too narrow.',
          'passage':
              'Saturday is laundry day at Priya\'s house. She puts white shirts in one pile and dark jeans in another. Colorful towels make a third pile. Sorting first keeps the whites clean and stops colors from running together.',
          'options': [
            'Choosing the Right Soap',
            'Folding Clothes Neatly',
            'Drying Laundry in the Sun',
            'Sorting Clothes Before Washing',
          ],
          'correctAnswer': 'Sorting Clothes Before Washing',
          'hint': 'Focus on the step Priya takes before any water is used.',
          'explanation':
              'The entire paragraph explains making piles by color so clothes stay clean and don\'t bleed.',
          'whyThisTitle':
              'Sorting by color is the sole activity described from start to finish.',
          'distractorAnalysis': [
            {
              'title': 'Choosing the Right Soap',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason': 'Soap is never mentioned in the passage.',
            },
            {
              'title': 'Folding Clothes Neatly',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason': 'The passage is about preparing laundry, not folding.',
            },
            {
              'title': 'Drying Laundry in the Sun',
              'isCorrect': false,
              'category': 'IRRELEVANT DISTRACTOR',
              'reason': 'Drying is not discussed.',
            },
            {
              'title': 'Sorting Clothes Before Washing',
              'isCorrect': true,
              'category': 'BEST TITLE (THESIS)',
              'reason':
                  'Priya\'s piles by color explain sorting before washing.',
            },
          ],
        },
      ];

  void _selectOption(int index) {
    if (_isChecked && _isCorrect) return;
    setState(() {
      _selectedOptionIndex = index;
      _isChecked = false;
    });
  }

  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;

    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final chosenAnswer = options[_selectedOptionIndex!];

    setState(() {
      _isChecked = true;
      _isCorrect = chosenAnswer.trim() == correctAnswer.trim();
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _selectedOptionIndex = null;
        _isChecked = false;
        _isCorrect = false;
      });
    } else {
      // Transition to Mastery phase
      final masteryPath =
          '/game?category=reading&gameType=guessTitle&level=${widget.level}';
      context.pushReplacement(masteryPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Headline Matcher Gym',
        gameType: 'guessTitle',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: () {},
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final passage = quest['passage'] as String? ?? '';
    final options = (quest['options'] as List<dynamic>? ?? []).cast<String>();
    final correctAnswer = quest['correctAnswer'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final whyThisTitle = quest['whyThisTitle'] as String? ?? explanation;
    final distractorAnalysis =
        (quest['distractorAnalysis'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
    final isLastQuest = _questIndex >= _quests.length - 1;

    // Retrieve feedback rationale for selected option
    String selectedFeedback = whyThisTitle;
    if (_selectedOptionIndex != null &&
        _selectedOptionIndex! < options.length) {
      final chosen = options[_selectedOptionIndex!];
      final match = distractorAnalysis.firstWhere(
        (d) => (d['title'] as String?)?.trim() == chosen.trim(),
        orElse: () => <String, dynamic>{},
      );
      if (match.isNotEmpty && match['reason'] != null) {
        selectedFeedback = match['reason'] as String;
      }
    }

    return PracticePhaseScaffold(
      title: 'Headline Matcher Gym',
      gameType: 'guessTitle',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'QUEST ${_questIndex + 1} OF ${_quests.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.teal400,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    'Level ${widget.level}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate400,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Instruction Card
            Container(
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.help_outline_rounded,
                    color: AppColors.indigo400,
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Select the title that captures the central thesis without being too broad or too narrow.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        fontWeight: FontWeight.w500,
                        color: AppColors.slate300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.article_rounded,
                        color: AppColors.teal500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'PASSAGE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.teal400,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    passage,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.5.sp,
                      height: 1.55,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Option Cards
            Text(
              'CANDIDATE HEADLINES',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.slate400,
              ),
            ),
            SizedBox(height: 10.h),

            ...List.generate(options.length, (idx) {
              final opt = options[idx];
              final isSelected = _selectedOptionIndex == idx;
              final isThisCorrect = opt.trim() == correctAnswer.trim();

              Color borderColor = AppColors.slate700;
              Color bgColor = const Color(0xFF1E293B);

              if (_isChecked) {
                if (isThisCorrect) {
                  borderColor = AppColors.emerald500;
                  bgColor = AppColors.emerald500.withValues(alpha: 0.15);
                } else if (isSelected) {
                  borderColor = AppColors.rose500;
                  bgColor = AppColors.rose500.withValues(alpha: 0.15);
                }
              } else if (isSelected) {
                borderColor = AppColors.indigo500;
                bgColor = AppColors.indigo500.withValues(alpha: 0.15);
              }

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => _selectOption(idx),
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: borderColor,
                          width: isSelected || (_isChecked && isThisCorrect)
                              ? 1.8
                              : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26.r,
                            height: 26.r,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? (_isChecked
                                      ? (_isCorrect
                                          ? AppColors.emerald500
                                          : AppColors.rose500)
                                      : AppColors.indigo500)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.transparent
                                    : AppColors.slate600,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              String.fromCharCode(65 + idx),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.slate400,
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              opt,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.5.sp,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (_isChecked && isThisCorrect)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.emerald500,
                              size: 20.r,
                            )
                          else if (_isChecked && isSelected && !_isCorrect)
                            Icon(
                              Icons.cancel_rounded,
                              color: AppColors.rose500,
                              size: 20.r,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 10.h),

            // Feedback Card
            if (_isChecked) ...[
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isCorrect
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: _isCorrect
                          ? AppColors.emerald500
                          : AppColors.rose500,
                      size: 22.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCorrect
                                ? 'THESIS ACCURATELY IDENTIFIED!'
                                : 'SCOPE MISMATCH',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _isCorrect
                                ? selectedFeedback
                                : (selectedFeedback.isNotEmpty
                                    ? selectedFeedback
                                    : (hint.isNotEmpty
                                        ? hint
                                        : 'A good title names the central plan that unites all sentences.')),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              height: 1.4,
                              color: AppColors.slate200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Action Button
            ElevatedButton(
              onPressed: _selectedOptionIndex == null
                  ? null
                  : (_isChecked
                      ? (_isCorrect ? _onNext : _checkAnswer)
                      : _checkAnswer),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked
                    ? (_isCorrect ? AppColors.emerald500 : AppColors.indigo500)
                    : AppColors.indigo500,
                disabledBackgroundColor:
                    AppColors.indigo500.withValues(alpha: 0.3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                elevation: 0,
              ),
              child: Text(
                _isChecked
                    ? (_isCorrect
                        ? (isLastQuest
                            ? 'Complete Gym & Enter Mastery'
                            : 'Next Quest')
                        : 'Re-Check Answer')
                    : 'Check Answer',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
