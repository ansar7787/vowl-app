import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Rich, interactive Learn Phase screen for Synonym Search: "Nuance Explorer".
///
/// Teaches learners WHY two words are synonyms and the critical native distinctions
/// between them (emotional vs factual, formal vs casual, collocations) before practice.
class SynonymSearchLearnScreen extends StatefulWidget {
  final int level;

  const SynonymSearchLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SynonymSearchLearnScreen> createState() =>
      _SynonymSearchLearnScreenState();
}

class _SynonymSearchLearnScreenState extends State<SynonymSearchLearnScreen> {
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
          'assets/curriculum/vocabulary/synonymSearch_learn_${startLevel}_$endLevel.json';
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
              id: 'FALLBACK_SYN_L${widget.level}_1',
              level: widget.level,
              conceptTitle: 'Nuance Explorer: Big ↔ Large',
              word: 'Big',
              pronunciation: '/bɪɡ/ ↔ /lɑːrdʒ/',
              definition:
                  'Both words describe large size, but large sounds more formal and factual.',
              example: "That is a big deal — we need to celebrate!",
              usageExample: 'The elephant is a very large animal.',
              nativeTip:
                  "'Big' carries emotional weight. 'Large' is neutral and measurable.",
              visualAnchor: '🎉 Big = Emotional | 📊 Large = Factual',
              commonMistake: "Never say 'large mistake' — say 'big mistake'.",
              familyWords: const ['Huge', 'Giant', 'Massive'],
              rawExtra: const {'baseWord': 'Big', 'synonym': 'Large'},
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

  void _nextPair() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _finishLearnPhase();
    }
  }

  void _finishLearnPhase() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'synonymSearch',
      level: widget.level,
      phase: 'learn',
    );
    final target =
        '/practice?category=vocabulary&gameType=synonymSearch&level=${widget.level}';
    context.pushReplacement(target);
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
        title: 'Nuance Explorer',
        gameType: 'synonymSearch',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No content available.')),
      );
    }

    final extra = quest.rawExtra['rawExtra'] as Map<String, dynamic>? ?? quest.rawExtra;
    final baseWord = quest.word ?? extra['baseWord'] as String? ?? '';
    final synonymWord = extra['synonym'] as String? ?? 'Synonym';
    final isLast = _currentIndex == _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Nuance Explorer (${_currentIndex + 1}/${_quests.length})',
      gameType: 'synonymSearch',
      level: widget.level,
      onComplete: _nextPair,
      actionLabel: isLast ? 'Start Practice 🏋️' : 'Next Synonym Pair ➔',
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Concept Header Banner ──────────────────────────────
            if (quest.conceptTitle != null) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.violet500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.violet500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.compare_arrows_rounded,
                      color: AppColors.violet500,
                      size: 20.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.conceptTitle!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ── Side-by-Side Word Cards ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildWordTile(
                    title: 'Word',
                    word: baseWord,
                    color: AppColors.teal400,
                    isDark: isDark,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? AppColors.slate800 : AppColors.slate200,
                    ),
                    child: Center(
                      child: Text(
                        '↔',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : AppColors.slate800,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildWordTile(
                    title: 'Synonym',
                    word: synonymWord,
                    color: AppColors.violet500,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Visual Anchor / Mnemonic ───────────────────────────
            if (quest.visualAnchor != null) ...[
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.amber500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.amber500.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Text('💡', style: TextStyle(fontSize: 18.sp)),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        quest.visualAnchor!,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.amber400 : AppColors.amber600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ── Nuance Insight Card ────────────────────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.psychology_rounded,
                        color: AppColors.violet500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'The Native Distinction',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.nativeTip ??
                        quest.definition ??
                        'These words share the core meaning, but each fits distinct real-world situations.',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      height: 1.45,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Real-World Context Demonstrations ──────────────────
            Text(
              'Real-World Contexts',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: isDark ? AppColors.slate400 : AppColors.slate600,
              ),
            ),
            SizedBox(height: 8.h),
            if (quest.example != null)
              _buildContextCard(
                word: baseWord,
                sentence: quest.example!,
                color: AppColors.teal400,
                isDark: isDark,
              ),
            SizedBox(height: 8.h),
            if (quest.usageExample != null)
              _buildContextCard(
                word: synonymWord,
                sentence: quest.usageExample!,
                color: AppColors.violet500,
                isDark: isDark,
              ),
            SizedBox(height: 16.h),

            // ── Common Mistake / Trap Alert ────────────────────────
            if (quest.commonMistake != null) ...[
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.rose500.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.rose500,
                      size: 20.r,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Common Native Trap',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rose500,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            quest.commonMistake!,
                            style: TextStyle(
                              fontSize: 12.5.sp,
                              height: 1.4,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate800,
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

            // ── Synonym Family Cloud ───────────────────────────────
            if (quest.familyWords.isNotEmpty) ...[
              Text(
                'Related Synonym Family',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: quest.familyWords.map((family) {
                  return Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate900 : AppColors.slate100,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color:
                            isDark ? AppColors.slate800 : AppColors.slate300,
                      ),
                    ),
                    child: Text(
                      family,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? AppColors.slate300 : AppColors.slate700,
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWordTile({
    required String title,
    required String word,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            word,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppColors.slate900,
            ),
          ),
          SizedBox(height: 8.h),
          IconButton(
            onPressed: () => _speak(word),
            icon: Icon(Icons.volume_up_rounded, color: color, size: 20.r),
            visualDensity: VisualDensity.compact,
            tooltip: 'Listen to $word',
          ),
        ],
      ),
    );
  }

  Widget _buildContextCard({
    required String word,
    required String sentence,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : AppColors.slate50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isDark ? AppColors.slate800 : AppColors.slate200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              word,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              sentence,
              style: TextStyle(
                fontSize: 13.sp,
                height: 1.4,
                color: isDark ? AppColors.slate200 : AppColors.slate800,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _speak(sentence),
            icon: Icon(
              Icons.volume_up_rounded,
              size: 18.r,
              color: isDark ? AppColors.slate400 : AppColors.slate600,
            ),
            visualDensity: VisualDensity.compact,
            tooltip: 'Listen to sentence',
          ),
        ],
      ),
    );
  }
}
