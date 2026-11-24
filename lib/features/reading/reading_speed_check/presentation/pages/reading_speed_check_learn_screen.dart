import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Learn phase screen for Reading Speed Check mini-game.
/// Trains students in visual chunking, rhythmic fixation, and eliminating sub-vocalization.
class ReadingSpeedCheckLearnScreen extends StatefulWidget {
  final int level;

  const ReadingSpeedCheckLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadingSpeedCheckLearnScreen> createState() =>
      _ReadingSpeedCheckLearnScreenState();
}

class _ReadingSpeedCheckLearnScreenState
    extends State<ReadingSpeedCheckLearnScreen> {
  int _cardIndex = 0;
  List<Map<String, dynamic>> _quests = [];
  bool _isLoading = true;

  int _highlightedChunk = 0;
  Timer? _pacerTimer;
  bool _isPacerActive = false;

  @override
  void initState() {
    super.initState();
    _loadCurriculum();
  }

  @override
  void dispose() {
    _pacerTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/reading/readingSpeedCheck_learn_${startLevel}_$endLevel.json';

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
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = _fallbackQuests;
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _fallbackQuests => [
        {
          'id': 'RDG_READINGSPEEDCHECK_LEARN_FALLBACK_1',
          'level': widget.level,
          'title': 'Pacer & Chunking Trainer',
          'strategyBadge': 'EYE-SPAN CHUNKING',
          'techniqueTitle': '3-Word Fixation & Peripheral Vision',
          'coreRule':
              'Reading in 3-word visual chunks reduces eye saccades and prevents internal vocalization, allowing comprehension at 150+ WPM.',
          'passage':
              'Community pool: open Monday to Friday from 9 a.m. to 6 p.m. The pool is closed on Saturdays and Sundays.',
          'chunks': [
            'Community pool: open',
            'Monday to Friday',
            'from 9 a.m.',
            'to 6 p.m.',
            'The pool is',
            'closed on Saturdays',
            'and Sundays.',
          ],
          'wordCount': 20,
          'wpmTarget': 90,
          'explanation':
              'Focusing on multi-word clusters lets your brain process meaning instantly without pronouncing every syllable.',
          'hint': 'Scan for the core subject and verb simultaneously.',
        },
      ];

  void _togglePacer(List<String> chunks) {
    if (_isPacerActive) {
      _pacerTimer?.cancel();
      setState(() {
        _isPacerActive = false;
      });
    } else {
      setState(() {
        _isPacerActive = true;
        _highlightedChunk = 0;
      });
      _pacerTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
        if (!mounted) return;
        if (ModalRoute.of(context)?.isCurrent != true) return;
        setState(() {
          if (_highlightedChunk < chunks.length - 1) {
            _highlightedChunk++;
          } else {
            _highlightedChunk = 0;
            _isPacerActive = false;
            timer.cancel();
          }
        });
      });
    }
  }

  void _onNext() {
    _pacerTimer?.cancel();
    _isPacerActive = false;
    _highlightedChunk = 0;

    if (_cardIndex < _quests.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      context.pushReplacement(
        '/practice?category=reading&gameType=readingSpeedCheck&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LearnPhaseScaffold(
        title: 'Pacer & Chunking Trainer',
        gameType: 'readingSpeedCheck',
        level: widget.level,
        onComplete: () {},
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_cardIndex] : _fallbackQuests[0];
    final isLastCard = _cardIndex >= _quests.length - 1;
    final strategyBadge =
        quest['strategyBadge'] as String? ?? 'EYE-SPAN CHUNKING';
    final techniqueTitle =
        quest['techniqueTitle'] as String? ?? '3-Word Fixation';
    final coreRule = quest['coreRule'] as String? ?? '';
    final chunks = (quest['chunks'] as List<dynamic>? ?? []).cast<String>();
    final wordCount = quest['wordCount'] as int? ?? 20;
    final wpmTarget = quest['wpmTarget'] as int? ?? 90;
    final explanation = quest['explanation'] as String? ?? '';

    return LearnPhaseScaffold(
      title: 'Pacer & Chunking Trainer',
      gameType: 'readingSpeedCheck',
      level: widget.level,
      actionLabel: isLastCard ? 'Begin Speed Gym' : 'Next Speed Strategy',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator Badge
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
                      strategyBadge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.teal500,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Text(
                  'Card ${_cardIndex + 1} of ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Technique Header & Core Rule Box
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
                        Icons.speed_rounded,
                        color: AppColors.teal500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          techniqueTitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    coreRule,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                      color: AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Interactive Chunking Sandbox Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'RHYTHMIC CHUNKING PACER',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.indigo400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _togglePacer(chunks),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: _isPacerActive
                                ? AppColors.rose500.withValues(alpha: 0.2)
                                : AppColors.emerald500.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: _isPacerActive
                                  ? AppColors.rose500
                                  : AppColors.emerald500,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPacerActive
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                size: 14.r,
                                color: _isPacerActive
                                    ? AppColors.rose500
                                    : AppColors.emerald500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _isPacerActive ? 'PAUSE' : 'TEST PACER',
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: _isPacerActive
                                      ? AppColors.rose500
                                      : AppColors.emerald500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Chunk Flow Wrap
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 10.h,
                    children: List.generate(chunks.length, (idx) {
                      final isCurrent = idx == _highlightedChunk;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? AppColors.teal500.withValues(alpha: 0.25)
                              : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isCurrent
                                ? AppColors.teal500
                                : AppColors.slate700,
                            width: isCurrent ? 1.8 : 1.0,
                          ),
                        ),
                        child: Text(
                          chunks[idx],
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5.sp,
                            fontWeight:
                                isCurrent ? FontWeight.w800 : FontWeight.w500,
                            color: isCurrent ? Colors.white : AppColors.slate300,
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: 12.h),

                  // Word count and WPM targets
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Total: $wordCount words',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            color: AppColors.slate400,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          'Target: $wpmTarget WPM',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // Speed Strategy Breakdown Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.slate700,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.amber500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'PACING BREAKDOWN',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.amber500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    explanation,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      height: 1.45,
                      color: AppColors.slate300,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
