import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Practice phase screen for Read and Match mini-game.
/// Provides an interactive "Heading Matcher Gym" allowing students to tap and pair
/// concept terminals with their definitions, receiving immediate feedback on alignment.
class ReadAndMatchPracticeScreen extends StatefulWidget {
  final int level;

  const ReadAndMatchPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadAndMatchPracticeScreen> createState() =>
      _ReadAndMatchPracticeScreenState();
}

class _ReadAndMatchPracticeScreenState
    extends State<ReadAndMatchPracticeScreen> {
  int _questIndex = 0;
  late List<Map<String, dynamic>> _quests;
  bool _isLoading = false;

  String? _selectedSourceKey;
  final Map<String, String> _userMatches = {}; // sourceKey -> targetValue
  bool _isChecked = false;
  bool _isAllCorrect = false;

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
        'assets/curriculum/reading/readAndMatch_practice_${startLevel}_$endLevel.json';

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
      // Retain fallback quests on asset failure (e.g. test environment)
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_READANDMATCH_PRACTICE_FALLBACK_1',
          'level': widget.level,
          'instruction': 'Match each word to the meaning that fits.',
          'paragraphTopic': 'Everyday feelings',
          'pairs': [
            {
              'key': '[L1-Q1-0] Tired',
              'value': 'Needing rest because your energy is low.',
            },
            {
              'key': '[L1-Q1-1] Happy',
              'value': 'Feeling pleased about something good.',
            },
            {
              'key': '[L1-Q1-2] Sad',
              'value': 'Feeling unhappy, often after bad news.',
            },
          ],
          'hint':
              'Two feelings come from news, while the third comes from bodily fatigue.',
          'explanation':
              'Happy and sad are emotional opposites. Tired refers to physical exhaustion.',
        },
      ];

  void _onSourceTap(String key) {
    if (_isChecked && _isAllCorrect) return;
    setState(() {
      if (_selectedSourceKey == key) {
        _selectedSourceKey = null;
      } else {
        _selectedSourceKey = key;
      }
      _isChecked = false;
    });
  }

  void _onTargetTap(String value) {
    if (_isChecked && _isAllCorrect) return;
    if (_selectedSourceKey == null) {
      // If tapped a value that is already matched, clear it
      final matchedKey = _userMatches.entries
          .where((e) => e.value == value)
          .map((e) => e.key)
          .firstOrNull;
      if (matchedKey != null) {
        setState(() {
          _userMatches.remove(matchedKey);
          _selectedSourceKey = matchedKey;
          _isChecked = false;
        });
      }
      return;
    }

    setState(() {
      // Remove any existing match with this value
      _userMatches.removeWhere((k, v) => v == value);
      // Set new match
      _userMatches[_selectedSourceKey!] = value;
      _selectedSourceKey = null;
      _isChecked = false;
    });
  }

  void _checkMatches() {
    final quest = _quests.isNotEmpty ? _quests[_questIndex] : _fallbackQuests.first;
    final pairs = (quest['pairs'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();

    if (_userMatches.length < pairs.length) {
      // Incomplete matches
      setState(() {
        _isChecked = true;
        _isAllCorrect = false;
      });
      return;
    }

    bool allCorrect = true;
    for (final p in pairs) {
      final key = p['key'] as String? ?? '';
      final expectedValue = p['value'] as String? ?? '';
      if (_userMatches[key] != expectedValue) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      _isChecked = true;
      _isAllCorrect = allCorrect;
    });
  }

  void _onNext() {
    if (_questIndex < _quests.length - 1) {
      setState(() {
        _questIndex++;
        _selectedSourceKey = null;
        _userMatches.clear();
        _isChecked = false;
        _isAllCorrect = false;
      });
    } else {
      // Transition to Mastery phase
      final masteryPath =
          '/game?category=reading&gameType=readAndMatch&level=${widget.level}';
      context.pushReplacement(masteryPath);
    }
  }

  static const List<Color> _pairColors = [
    Color(0xFF818CF8), // Indigo
    Color(0xFF2DD4BF), // Teal
    Color(0xFFFBBF24), // Amber
    Color(0xFF4ADE80), // Emerald
    Color(0xFFFB7185), // Rose
    Color(0xFFA78BFA), // Violet
  ];

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return PracticePhaseScaffold(
        title: 'Heading Matcher Gym',
        gameType: 'readAndMatch',
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
    final instruction = quest['instruction'] as String? ?? 'Match each term to its meaning.';
    final paragraphTopic = quest['paragraphTopic'] as String? ?? '';
    final pairs = (quest['pairs'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final explanation = quest['explanation'] as String? ?? '';
    final hint = quest['hint'] as String? ?? '';
    final isLastQuest = _questIndex >= _quests.length - 1;

    // Keys and values
    final keys = pairs.map((p) => p['key'] as String? ?? '').toList();
    final values = pairs.map((p) => p['value'] as String? ?? '').toList();

    return PracticePhaseScaffold(
      title: 'Heading Matcher Gym',
      gameType: 'readAndMatch',
      level: widget.level,
      currentExerciseIndex: _questIndex,
      totalExercises: _quests.length,
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status & Level Header
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
                    Icons.touch_app_rounded,
                    color: AppColors.indigo400,
                    size: 18.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      instruction,
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

            // Theme indicator if present
            if (paragraphTopic.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_open_rounded,
                      color: AppColors.teal400,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        'CATEGORY: ${paragraphTopic.toUpperCase()}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w800,
                          color: AppColors.teal400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // Section 1: Concepts / Terms to select
            Text(
              'CONCEPTS & HEADINGS (TAP TO SELECT)',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.slate400,
              ),
            ),
            SizedBox(height: 8.h),

            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: List.generate(keys.length, (idx) {
                final rawKey = keys[idx];
                final cleanKey =
                    rawKey.replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
                final isSelected = _selectedSourceKey == rawKey;
                final isMatched = _userMatches.containsKey(rawKey);
                final pairColor = _pairColors[idx % _pairColors.length];

                return GestureDetector(
                  onTap: () => _onSourceTap(rawKey),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isMatched
                          ? pairColor.withValues(alpha: 0.2)
                          : (isSelected
                              ? AppColors.indigo500.withValues(alpha: 0.25)
                              : const Color(0xFF1E293B)),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: isMatched
                            ? pairColor
                            : (isSelected
                                ? AppColors.indigo500
                                : AppColors.slate700),
                        width: isSelected || isMatched ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMatched) ...[
                          Icon(Icons.link_rounded,
                              size: 14.r, color: pairColor),
                          SizedBox(width: 4.w),
                        ],
                        Text(
                          cleanKey,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isMatched
                                ? Colors.white
                                : (isSelected
                                    ? AppColors.indigo400
                                    : AppColors.slate200),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 16.h),

            // Section 2: Definitions to match
            Text(
              'DEFINITIONS & MEANINGS',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: AppColors.slate400,
              ),
            ),
            SizedBox(height: 10.h),

            ...List.generate(values.length, (idx) {
              final val = values[idx];
              final matchedEntry = _userMatches.entries
                  .where((e) => e.value == val)
                  .firstOrNull;
              final isMatched = matchedEntry != null;

              int keyIdx = 0;
              String matchedCleanKey = '';
              if (isMatched) {
                keyIdx = keys.indexOf(matchedEntry.key);
                matchedCleanKey = matchedEntry.key
                    .replaceFirst(RegExp(r'^\[.*?\]\s*'), '');
              }
              final pairColor = _pairColors[keyIdx % _pairColors.length];

              return Container(
                margin: EdgeInsets.only(bottom: 10.h),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14.r),
                    onTap: () => _onTargetTap(val),
                    child: Container(
                      padding: EdgeInsets.all(14.r),
                      decoration: BoxDecoration(
                        color: isMatched
                            ? pairColor.withValues(alpha: 0.12)
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: isMatched ? pairColor : AppColors.slate700,
                          width: isMatched ? 1.6 : 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isMatched) ...[
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 8.w, vertical: 2.h),
                                  decoration: BoxDecoration(
                                    color: pairColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6.r),
                                    border: Border.all(
                                      color: pairColor,
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'PAIRED WITH: $matchedCleanKey',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 9.5.sp,
                                      fontWeight: FontWeight.w800,
                                      color: pairColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.h),
                          ],
                          Text(
                            val,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.5.sp,
                              height: 1.45,
                              fontWeight: isMatched
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: isMatched
                                  ? Colors.white
                                  : AppColors.slate200,
                            ),
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
                  color: _isAllCorrect
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.rose500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: _isAllCorrect
                        ? AppColors.emerald500.withValues(alpha: 0.4)
                        : AppColors.rose500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _isAllCorrect
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      color: _isAllCorrect
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
                            _isAllCorrect
                                ? 'ALL PAIRS ACCURATELY MATCHED!'
                                : 'MATCH MISALIGNMENT',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w800,
                              color: _isAllCorrect
                                  ? AppColors.emerald500
                                  : AppColors.rose500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            _isAllCorrect
                                ? explanation
                                : (hint.isNotEmpty
                                    ? hint
                                    : 'Review the anchor keywords in each definition.'),
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
              onPressed: _userMatches.isEmpty
                  ? null
                  : (_isChecked
                      ? (_isAllCorrect ? _onNext : _checkMatches)
                      : _checkMatches),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isChecked
                    ? (_isAllCorrect
                        ? AppColors.emerald500
                        : AppColors.indigo500)
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
                    ? (_isAllCorrect
                        ? (isLastQuest
                            ? 'Complete Gym & Enter Mastery'
                            : 'Next Quest')
                        : 'Re-Check Matches')
                    : 'Check Matches',
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
