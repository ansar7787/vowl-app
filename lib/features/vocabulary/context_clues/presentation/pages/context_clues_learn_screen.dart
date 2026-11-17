import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Interactive Learn Phase screen for Context Clues: "Forensic Clue Strategy".
///
/// Teaches learners how to systematically deduce unknown words using 5 core
/// context clue archetypes (Definition, Synonym, Antonym, Example, Inference).
class ContextCluesLearnScreen extends StatefulWidget {
  final int level;

  const ContextCluesLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ContextCluesLearnScreen> createState() =>
      _ContextCluesLearnScreenState();
}

class _ContextCluesLearnScreenState extends State<ContextCluesLearnScreen> {
  List<PhasedQuest> _quests = [];
  bool _isLoading = true;
  int _currentIndex = 0;

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
          'assets/curriculum/vocabulary/contextClues_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();

      if (mounted) {
        setState(() {
          _quests = levelQuests.isNotEmpty ? levelQuests : batch.quests;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _quests = [
            PhasedQuest(
              id: 'FALLBACK_CC_L${widget.level}_1',
              level: widget.level,
              conceptTitle: 'Forensic Clue Strategy: AMAZING (definition)',
              word: 'AMAZING',
              definition: "In this passage, 'AMAZING' translates to 'Wonderful'.",
              example:
                  "The magician's final trick was AMAZING — meaning it was truly wonderful — and the whole audience jumped up to cheer.",
              nativeTip:
                  "Look for punctuation markers like dashes (—) or appositives that restate the word immediately.",
              visualAnchor:
                  '📖 DEFINITION CLUE = Direct meaning stated in the sentence',
              rawExtra: const {
                'target': 'Wonderful',
                'clueType': 'definition',
                'evidenceWords': ['wonderful', 'cheer'],
              },
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  void _speak(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
    }
  }

  void _nextCase() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishLearnPhase();
    }
  }

  void _finishLearnPhase() {
    final target =
        '/practice?category=vocabulary&gameType=contextClues&level=${widget.level}';
    context.pushReplacement(target);
  }

  Color _getClueTypeColor(String clueType) {
    switch (clueType.toLowerCase()) {
      case 'definition':
        return AppColors.indigo500;
      case 'synonym':
        return AppColors.emerald500;
      case 'antonym':
        return AppColors.rose500;
      case 'example':
        return AppColors.amber500;
      default:
        return AppColors.blue500;
    }
  }

  IconData _getClueTypeIcon(String clueType) {
    switch (clueType.toLowerCase()) {
      case 'definition':
        return Icons.menu_book_rounded;
      case 'synonym':
        return Icons.compare_arrows_rounded;
      case 'antonym':
        return Icons.swap_horiz_rounded;
      case 'example':
        return Icons.lightbulb_outline_rounded;
      default:
        return Icons.search_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.slate950 : AppColors.slate50,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final quest = _quests.isNotEmpty ? _quests[_currentIndex] : null;
    if (quest == null) {
      return LearnPhaseScaffold(
        title: 'Forensic Clue Strategy',
        gameType: 'contextClues',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No content available.')),
      );
    }

    final extra = quest.rawExtra['rawExtra'] as Map<String, dynamic>? ??
        quest.rawExtra;
    final targetMeaning = extra['target'] as String? ?? 'Meaning';
    final clueType = extra['clueType'] as String? ?? 'inference';
    final evidenceWords = (extra['evidenceWords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final isLast = _currentIndex == _quests.length - 1;
    final clueColor = _getClueTypeColor(clueType);

    return LearnPhaseScaffold(
      title: 'Forensic Clue Strategy (${_currentIndex + 1}/${_quests.length})',
      gameType: 'contextClues',
      level: widget.level,
      onComplete: _nextCase,
      actionLabel: isLast ? 'Start Practice 🏋️' : 'Next Clue Case ➔',
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Clue Type Badge Header ─────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: clueColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: clueColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _getClueTypeIcon(clueType),
                    color: clueColor,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'CLUE ARCHETYPE: ${clueType.toUpperCase()} CLUE',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: clueColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Forensic Dossier Card ──────────────────────────────
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TARGET MYSTERY WORD',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.slate400,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            quest.word ?? 'UNKNOWN',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : AppColors.slate900,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => _speak(quest.word ?? ''),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: clueColor,
                          size: 24.r,
                        ),
                      ),
                    ],
                  ),
                  Divider(
                    height: 24.h,
                    color: isDark ? AppColors.slate800 : AppColors.slate100,
                  ),
                  Text(
                    'DEDUCED CORE MEANING',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: AppColors.slate400,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      '🎯 $targetMeaning',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Context Sentence & Evidence Highlighting ───────────
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CASE EVIDENCE PASSAGE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColors.slate400,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _speak(quest.example ?? ''),
                        icon: Icon(
                          Icons.volume_up_outlined,
                          color: clueColor,
                          size: 20.r,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    quest.example ?? '',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                    ),
                  ),
                  if (evidenceWords.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: evidenceWords.map((word) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber400.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                            border: Border.all(
                              color: AppColors.amber400.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            '🔍 Clue: $word',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.amber200
                                  : AppColors.amber900,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Detective Anchor Tip ───────────────────────────────
            if (quest.visualAnchor != null) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: clueColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: clueColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tips_and_updates_rounded,
                      color: clueColor,
                      size: 22.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        quest.visualAnchor!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ── Native Speaker Detective Tip ───────────────────────
            if (quest.nativeTip != null) ...[
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.slate900
                      : AppColors.slate100.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('💡', style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        quest.nativeTip!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.slate300
                              : AppColors.slate700,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
            ],
          ],
        ),
      ),
    );
  }
}
