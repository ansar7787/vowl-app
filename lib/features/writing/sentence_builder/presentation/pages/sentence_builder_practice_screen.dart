import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Interactive Practice Phase screen for Sentence Builder ("Slot Filling Gym").
///
/// Exercises syntactic argument mapping by prompting learners to assemble
/// phrase blocks into designated semantic slots before checking sequence accuracy.
class SentenceBuilderPracticeScreen extends StatefulWidget {
  final int level;

  const SentenceBuilderPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<SentenceBuilderPracticeScreen> createState() =>
      _SentenceBuilderPracticeScreenState();
}

class _SentenceBuilderPracticeScreenState
    extends State<SentenceBuilderPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;

  // Selected sequence: list of strings placed in slots
  final List<String?> _placedChips = [];
  final Set<int> _usedChipIndices = {};

  bool _isChecked = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _quests = _fallbackQuests;
    _resetForCurrentQuest();
    _loadCurriculum();
  }

  void _resetForCurrentQuest() {
    _placedChips.clear();
    _usedChipIndices.clear();
    _isChecked = false;
    _isCorrect = false;

    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final targetSlots = (quest['targetSlots'] as List<dynamic>? ?? []);
    for (int i = 0; i < targetSlots.length; i++) {
      _placedChips.add(null);
    }
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/writing/sentenceBuilder_practice_${startLevel}_$endLevel.json';

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
            _resetForCurrentQuest();
          }
        });
      }
    } catch (_) {
      // Retain fallback quests on asset failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'WRT_SENTENCEBUILDER_PRAC_FALLBACK_1',
          'level': widget.level,
          'instruction': 'Assemble phrase blocks into syntactic order.',
          'prompt':
              'Construct a fluent English sentence specifying who, action, what, and context.',
          'targetSlots': [
            {'role': 'Subject', 'label': 'Who performs?'},
            {'role': 'Verb', 'label': 'Action / State?'},
            {'role': 'Object', 'label': 'Target / Recipient?'},
            {'role': 'Adverbial', 'label': 'Context / Where?'},
          ],
          'correctSequence': [
            'The curious astronomer',
            'observed',
            'distant galaxies',
            'through the observatory lens',
          ],
          'chips': [
            'through the observatory lens',
            'The curious astronomer',
            'distant galaxies',
            'observed',
          ],
          'completeSentence':
              'The curious astronomer observed distant galaxies through the observatory lens.',
          'explanation':
              'Subject precedes transitive verb, followed by direct object and prepositional phrase of instrument.',
        },
      ];

  void _onChipTapped(int chipIndex, String chipText) {
    if (_isChecked || _usedChipIndices.contains(chipIndex)) return;

    // Find first vacant slot
    final emptySlotIndex = _placedChips.indexOf(null);
    if (emptySlotIndex != -1) {
      setState(() {
        _placedChips[emptySlotIndex] = chipText;
        _usedChipIndices.add(chipIndex);
      });
    }
  }

  void _onSlotTapped(int slotIndex, List<String> chips) {
    if (_isChecked) return;
    final chipText = _placedChips[slotIndex];
    if (chipText == null) return;

    final originalChipIndex = chips.indexOf(chipText);
    setState(() {
      _placedChips[slotIndex] = null;
      if (originalChipIndex != -1) {
        _usedChipIndices.remove(originalChipIndex);
      }
    });
  }

  void _onCheck() {
    if (_isChecked) {
      // Advance to next quest or mastery
      if (_questIndex < _quests.length - 1) {
        setState(() {
          _questIndex++;
          _resetForCurrentQuest();
        });
      } else {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'sentenceBuilder',
          level: widget.level,
          phase: 'practice',
        );
        context.pushReplacement(
          '/game?category=writing&gameType=sentenceBuilder&level=${widget.level}',
        );
      }
      return;
    }

    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final correctSequence =
        (quest['correctSequence'] as List<dynamic>? ?? []).cast<String>();

    bool correct = true;
    if (_placedChips.length != correctSequence.length) {
      correct = false;
    } else {
      for (int i = 0; i < correctSequence.length; i++) {
        if (_placedChips[i] != correctSequence[i]) {
          correct = false;
          break;
        }
      }
    }

    setState(() {
      _isChecked = true;
      _isCorrect = correct;
    });
  }

  void _onReset() {
    setState(() {
      _resetForCurrentQuest();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;

    final instruction =
        quest['instruction'] as String? ?? 'Assemble phrase blocks into syntactic order.';
    final prompt = quest['prompt'] as String? ?? '';
    final targetSlots =
        (quest['targetSlots'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final chips = (quest['chips'] as List<dynamic>? ?? []).cast<String>();
    final completeSentence = quest['completeSentence'] as String? ?? '';
    final explanation = quest['explanation'] as String? ?? '';

    final allSlotsFilled = !_placedChips.contains(null) && _placedChips.isNotEmpty;

    return PracticePhaseScaffold(
      title: 'Slot Filling Gym',
      gameType: 'sentenceBuilder',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _onCheck,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header instruction & prompt
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : AppColors.indigo50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.indigo500.withValues(alpha: 0.3)
                      : AppColors.indigo500.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'SYNTACTIC GYM',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'EXERCISE ${_questIndex + 1} OF ${_quests.length}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    instruction,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                  ),
                  if (prompt.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      prompt,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate700,
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            SizedBox(height: 18.h),

            // Target Slots Container
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'TARGET SLOTS (IN SYNTACTIC ORDER)',
                    style: TextStyle(
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!_isChecked && _placedChips.any((c) => c != null)) ...[
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: _onReset,
                    child: Text(
                      'Clear Slots',
                      style: TextStyle(
                        color: AppColors.rose500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 8.h),

            ...List.generate(targetSlots.length, (slotIdx) {
              final slot = targetSlots[slotIdx];
              final role = slot['role'] as String? ?? 'Slot';
              final label = slot['label'] as String? ?? '';
              final placed = slotIdx < _placedChips.length ? _placedChips[slotIdx] : null;

              Color slotBorderColor;
              if (_isChecked) {
                slotBorderColor = _isCorrect ? AppColors.emerald500 : AppColors.rose500;
              } else if (placed != null) {
                slotBorderColor = AppColors.indigo500;
              } else {
                slotBorderColor = isDark ? AppColors.slate800 : AppColors.slate300;
              }

              return GestureDetector(
                onTap: () => _onSlotTapped(slotIdx, chips),
                child: Container(
                  margin: EdgeInsets.only(bottom: 10.h),
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: placed != null
                        ? (isDark ? AppColors.slate800 : AppColors.indigo50.withValues(alpha: 0.5))
                        : (isDark ? AppColors.slate900 : Colors.white),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: slotBorderColor,
                      width: placed != null ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.slate800 : AppColors.slate200,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          '${slotIdx + 1}',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.slate300
                                : AppColors.slate700,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$role: $label',
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              placed ?? 'Tap phrase block below to place here...',
                              style: TextStyle(
                                color: placed != null
                                    ? (isDark ? Colors.white : AppColors.slate900)
                                    : (isDark ? AppColors.slate600 : AppColors.slate400),
                                fontSize: 13.sp,
                                fontWeight: placed != null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontStyle: placed != null
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (placed != null && !_isChecked)
                        Icon(
                          Icons.cancel_rounded,
                          size: 16.sp,
                          color: isDark
                              ? AppColors.slate500
                              : AppColors.slate400,
                        ),
                    ],
                  ),
                ),
              );
            }),

            SizedBox(height: 16.h),

            // Available Phrase Chips Rack
            Text(
              'AVAILABLE PHRASE BLOCKS',
              style: TextStyle(
                color: isDark ? AppColors.slate400 : AppColors.slate600,
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(height: 8.h),

            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(chips.length, (chipIdx) {
                final chipText = chips[chipIdx];
                final isUsed = _usedChipIndices.contains(chipIdx);

                return GestureDetector(
                  onTap: () => _onChipTapped(chipIdx, chipText),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: EdgeInsets.symmetric(
                        horizontal: 14.w, vertical: 10.h),
                    decoration: BoxDecoration(
                      color: isUsed
                          ? (isDark ? AppColors.slate800 : AppColors.slate200)
                          : (isDark ? AppColors.slate900 : Colors.white),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isUsed
                            ? (isDark ? AppColors.slate800 : AppColors.slate300)
                            : AppColors.indigo500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      chipText,
                      style: TextStyle(
                        color: isUsed
                            ? (isDark ? AppColors.slate600 : AppColors.slate400)
                            : (isDark ? Colors.white : AppColors.slate900),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            ),

            SizedBox(height: 20.h),

            // Feedback Card when checked
            if (_isChecked)
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? (_isDarkBg(isDark)
                          ? AppColors.emerald500.withValues(alpha: 0.15)
                          : AppColors.emerald50)
                      : (_isDarkBg(isDark)
                          ? AppColors.rose500.withValues(alpha: 0.15)
                          : AppColors.rose500.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isCorrect ? AppColors.emerald500 : AppColors.rose500,
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
                              : Icons.error_outline_rounded,
                          color: _isCorrect
                              ? AppColors.emerald500
                              : AppColors.rose500,
                          size: 22.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _isCorrect
                              ? 'EXCELLENT SYNTAX!'
                              : 'SYNTAX SEQUENCE MISMATCH',
                          style: TextStyle(
                            color: _isCorrect
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"$completeSentence"',
                      style: TextStyle(
                        color: isDark ? Colors.white : AppColors.slate900,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate700,
                        fontSize: 12.sp,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 20.h),

            // Action / Check button
            ElevatedButton(
              onPressed: (allSlotsFilled || _isChecked) ? _onCheck : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.indigo500,
                disabledBackgroundColor:
                    isDark ? AppColors.slate800 : AppColors.slate300,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                _isChecked
                    ? (_questIndex < _quests.length - 1
                        ? 'Next Exercise'
                        : 'Proceed to Mastery')
                    : 'Check Sentence Syntax',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  bool _isDarkBg(bool isDark) => isDark;
}
