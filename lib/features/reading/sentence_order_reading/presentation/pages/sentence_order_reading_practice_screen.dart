import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Practice phase screen for Sentence Order Reading mini-game.
/// Provides an interactive transition anchor sandbox to reorder sentences and test cohesion.
class SentenceOrderReadingPracticeScreen extends StatefulWidget {
  final int level;

  const SentenceOrderReadingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SentenceOrderReadingPracticeScreen> createState() =>
      _SentenceOrderReadingPracticeScreenState();
}

class _SentenceOrderReadingPracticeScreenState
    extends State<SentenceOrderReadingPracticeScreen> {
  int _questIndex = 0;
  List<Map<String, dynamic>> _quests = [];
  bool _isLoading = true;

  List<int> _currentOrder = [];
  int? _selectedCardIndex;
  bool _isChecked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/reading/sentenceOrderReading_practice_${startLevel}_$endLevel.json';

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
          _quests = levelQuests.isNotEmpty ? levelQuests : rawQuests;
          _isLoading = false;
          _initQuest();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _fallbackQuests;
          _isLoading = false;
          _initQuest();
        });
      }
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_SENTENCEORDERREADING_PRACTICE_FALLBACK_1',
          'level': widget.level,
          'instruction':
              'Reorder the sentences to establish logical paragraph cohesion.',
          'shuffledSentences': [
            'Kofi gets out of bed.',
            'The alarm clock rings at seven.',
            'After that, he brushes his teeth.',
          ],
          'correctOrder': [1, 0, 2],
          'transitionWords': ['After that'],
          'firstSentenceAnchor': 'The alarm clock rings at seven.',
          'explanation':
              'The alarm triggers the waking sequence. Kofi gets up, then brushes his teeth as signaled by "After that".',
          'hint': 'Think about what causes someone to wake up first.',
        },
      ];

  void _initQuest() {
    if (_quests.isEmpty) return;
    final quest = _quests[_questIndex];
    final shuffled = (quest['shuffledSentences'] as List<dynamic>? ?? []);
    final correctOrder = (quest['correctOrder'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();

    final order = List<int>.generate(shuffled.length, (i) => i);
    // Make sure initial state isn't already the correct order if length > 1
    if (order.length > 1 && correctOrder.isNotEmpty) {
      bool isMatch = true;
      for (int i = 0; i < order.length && i < correctOrder.length; i++) {
        if (order[i] != correctOrder[i]) {
          isMatch = false;
          break;
        }
      }
      if (isMatch) {
        // Swap first two to create practice challenge
        final temp = order[0];
        order[0] = order[1];
        order[1] = temp;
      }
    }

    _currentOrder = order;
    _selectedCardIndex = null;
    _isChecked = false;
    _isCorrect = false;
  }

  void _onCardTap(int index) {
    if (_isChecked && _isCorrect) return;

    setState(() {
      if (_selectedCardIndex == null) {
        _selectedCardIndex = index;
      } else if (_selectedCardIndex == index) {
        _selectedCardIndex = null;
      } else {
        // Swap positions
        final temp = _currentOrder[_selectedCardIndex!];
        _currentOrder[_selectedCardIndex!] = _currentOrder[index];
        _currentOrder[index] = temp;
        _selectedCardIndex = null;
        _isChecked = false;
      }
    });
  }

  void _moveCard(int fromIndex, int delta) {
    if (_isChecked && _isCorrect) return;
    final targetIndex = fromIndex + delta;
    if (targetIndex < 0 || targetIndex >= _currentOrder.length) return;

    setState(() {
      final temp = _currentOrder[fromIndex];
      _currentOrder[fromIndex] = _currentOrder[targetIndex];
      _currentOrder[targetIndex] = temp;
      _selectedCardIndex = null;
      _isChecked = false;
    });
  }

  void _checkOrder() {
    final quest = _quests[_questIndex];
    final correctOrder = (quest['correctOrder'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .toList();

    bool match = true;
    if (_currentOrder.length != correctOrder.length) {
      match = false;
    } else {
      for (int i = 0; i < _currentOrder.length; i++) {
        if (_currentOrder[i] != correctOrder[i]) {
          match = false;
          break;
        }
      }
    }

    setState(() {
      _isChecked = true;
      _isCorrect = match;
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _initQuest();
      });
    } else {
      context.pushReplacement(
        '/game?category=reading&gameType=sentenceOrderReading&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Transition Anchor Gym',
        gameType: 'sentenceOrderReading',
        level: widget.level,
        currentExerciseIndex: 0,
        totalExercises: 1,
        onComplete: () {},
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final quest =
        _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests[0];
    final shuffled = (quest['shuffledSentences'] as List<dynamic>? ?? [])
        .cast<String>();
    final hint = quest['hint'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';
    final isLastQuest = _questIndex >= _quests.length - 1;

    return PracticePhaseScaffold(
      title: 'Transition Anchor Gym',
      gameType: 'sentenceOrderReading',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header & Step Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _isCorrect
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : AppColors.indigo500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: _isCorrect
                            ? AppColors.emerald500.withValues(alpha: 0.4)
                            : AppColors.indigo500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      _isCorrect
                          ? 'SEQUENCE VERIFIED'
                          : (_selectedCardIndex != null
                              ? 'TAP TARGET TO SWAP'
                              : 'ARRANGE SENTENCES'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: _isCorrect
                            ? AppColors.emerald500
                            : AppColors.indigo500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Quest ${_questIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Instruction Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: AppColors.slate700),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort_rounded,
                    color: AppColors.indigo500,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'Tap any sentence to select, then tap another to swap positions into a logical flow.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.5.sp,
                        height: 1.4,
                        color: AppColors.slate300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Interactive Sentence Slabs
            ...List.generate(_currentOrder.length, (displayIndex) {
              final sentenceOriginalIndex = _currentOrder[displayIndex];
              final sentenceText = (sentenceOriginalIndex >= 0 &&
                      sentenceOriginalIndex < shuffled.length)
                  ? shuffled[sentenceOriginalIndex]
                  : '';
              final isSelected = _selectedCardIndex == displayIndex;

              return Padding(
                padding: EdgeInsets.only(bottom: 10.h),
                child: GestureDetector(
                  onTap: () => _onCardTap(displayIndex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.indigo500.withValues(alpha: 0.18)
                          : (_isCorrect
                              ? AppColors.emerald500.withValues(alpha: 0.1)
                              : const Color(0xFF0F172A)),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.indigo500
                            : (_isCorrect
                                ? AppColors.emerald500.withValues(alpha: 0.5)
                                : AppColors.slate700),
                        width: isSelected ? 2.0 : 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.indigo500
                                    .withValues(alpha: 0.25),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Order Number Pip
                        Container(
                          width: 28.r,
                          height: 28.r,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _isCorrect
                                ? AppColors.emerald500
                                : (isSelected
                                    ? AppColors.indigo500
                                    : AppColors.slate800),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${displayIndex + 1}',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),

                        // Sentence Text
                        Expanded(
                          child: Text(
                            sentenceText,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.5.sp,
                              height: 1.45,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.slate200,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),

                        // Up / Down Quick Adjust Buttons
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (displayIndex > 0)
                              GestureDetector(
                                onTap: () => _moveCard(displayIndex, -1),
                                child: Icon(
                                  Icons.keyboard_arrow_up_rounded,
                                  color: AppColors.slate400,
                                  size: 20.r,
                                ),
                              ),
                            if (displayIndex < _currentOrder.length - 1)
                              GestureDetector(
                                onTap: () => _moveCard(displayIndex, 1),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.slate400,
                                  size: 20.r,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            SizedBox(height: 12.h),

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
                                ? 'EXCELLENT COHESION!'
                                : 'SEQUENCE INCOMPLETE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: _isCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _isCorrect
                                ? explanation
                                : (hint.isNotEmpty
                                    ? hint
                                    : 'Examine transition words to determine the proper chronological order.'),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.5.sp,
                              height: 1.4,
                              color: AppColors.slate300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // Action Button
            ElevatedButton(
              onPressed: _isChecked
                  ? (_isCorrect ? _onNext : _checkOrder)
                  : _checkOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isCorrect
                    ? AppColors.emerald500
                    : AppColors.indigo500,
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
                        : 'Re-Check Sequence')
                    : 'Check Sequence',
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
