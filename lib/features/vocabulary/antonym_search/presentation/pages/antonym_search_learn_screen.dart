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

/// Interactive Learn Phase screen for Antonym Search: "Contrast Explorer".
///
/// Explores polar opposites, conceptual spectrum dimensions, native nuances,
/// and common grammatical pitfalls before proceeding to practice.
class AntonymSearchLearnScreen extends StatefulWidget {
  final int level;

  const AntonymSearchLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<AntonymSearchLearnScreen> createState() =>
      _AntonymSearchLearnScreenState();
}

class _AntonymSearchLearnScreenState extends State<AntonymSearchLearnScreen> {
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
          'assets/curriculum/vocabulary/antonymSearch_learn_${startLevel}_$endLevel.json';
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
              id: 'FALLBACK_ANT_L${widget.level}_1',
              level: widget.level,
              conceptTitle: 'Polar Opposite: Here ↔ There',
              word: 'Here ↔ There',
              pronunciation: '/hɪər/ ↔ /ðeər/',
              definition:
                  "Location contrast: 'Here' indicates proximity to the speaker; 'There' marks distance away from the speaker.",
              example: 'Please come over here and sit next to me.',
              usageExample: 'Put the delivery boxes over there near the garage.',
              nativeTip:
                  "'Here' is anchored to the speaker's current spot. 'There' always points outward to another location.",
              visualAnchor:
                  '📍 HERE = Right with speaker | 🗺️ THERE = Away at a distance',
              commonMistake:
                  "Don't confuse 'there' with 'their' (ownership) or 'they're' (they are).",
              familyWords: const ['Near', 'Far', 'Nearby', 'Distant'],
              rawExtra: const {
                'baseWord': 'HERE',
                'antonym': 'THERE',
                'contrastDimension': 'Spatial Proximity',
                'gradientScale': [
                  'HERE',
                  'strong HERE',
                  'neutral',
                  'a trace of there',
                  'THERE'
                ]
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
    final target =
        '/practice?category=vocabulary&gameType=antonymSearch&level=${widget.level}';
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
        title: 'Contrast Explorer',
        gameType: 'antonymSearch',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No content available.')),
      );
    }

    final extra = quest.rawExtra['rawExtra'] as Map<String, dynamic>? ??
        quest.rawExtra;
    final baseWord = extra['baseWord'] as String? ?? 'Word';
    final antonymWord = extra['antonym'] as String? ?? 'Antonym';
    final dimension = extra['contrastDimension'] as String? ?? 'Polar Opposite';
    final gradient = (extra['gradientScale'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [baseWord, 'Opposite', antonymWord];
    final isLast = _currentIndex == _quests.length - 1;

    return LearnPhaseScaffold(
      title: 'Contrast Explorer (${_currentIndex + 1}/${_quests.length})',
      gameType: 'antonymSearch',
      level: widget.level,
      onComplete: _nextPair,
      actionLabel: isLast ? 'Start Practice 🏋️' : 'Next Opposite Pair ➔',
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
                  color: AppColors.blue500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppColors.blue500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.blue500,
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

            // ── Side-by-Side Polar Opposites ───────────────────────
            Row(
              children: [
                Expanded(
                  child: _buildPolarTile(
                    title: 'Target Word',
                    word: baseWord,
                    color: AppColors.teal400,
                    isDark: isDark,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: Container(
                    width: 36.w,
                    height: 36.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.teal400, AppColors.rose500],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.rose500.withValues(alpha: 0.3),
                          blurRadius: 8.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '⚡',
                        style: TextStyle(fontSize: 16.sp),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _buildPolarTile(
                    title: 'Polar Antonym',
                    word: antonymWord,
                    color: AppColors.rose500,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // ── Spectrum Dimension Gradient Scale ──────────────────
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.linear_scale_rounded,
                        color: AppColors.blue500,
                        size: 16.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'CONTRAST SPECTRUM: $dimension',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.blue500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 6.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3.r),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.teal400,
                          AppColors.indigo500,
                          AppColors.rose500,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: gradient.map((step) {
                      final isEndpoint =
                          step == gradient.first || step == gradient.last;
                      return Flexible(
                        child: Text(
                          step,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isEndpoint ? 10.sp : 8.sp,
                            fontWeight: isEndpoint
                                ? FontWeight.w800
                                : FontWeight.w500,
                            color: isEndpoint
                                ? (isDark ? Colors.white : AppColors.slate900)
                                : (isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
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
                          color:
                              isDark ? AppColors.amber400 : AppColors.amber600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16.h),
            ],

            // ── Polar Contrast Insight Card ────────────────────────
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
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10.r,
                    offset: Offset(0, 4.h),
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
                        color: AppColors.blue500,
                        size: 20.r,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'The Fundamental Opposition',
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
                    quest.definition ??
                        'These two terms occupy polar extremes along the spectrum.',
                    style: TextStyle(
                      fontSize: 13.sp,
                      height: 1.4,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                    ),
                  ),
                  if (quest.nativeTip != null) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: AppColors.blue500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: AppColors.blue500.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎯', style: TextStyle(fontSize: 14.sp)),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              quest.nativeTip!,
                              style: TextStyle(
                                fontSize: 12.sp,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.blue300
                                    : AppColors.blue500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Contextual Sentences in Contrast ───────────────────
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CONTRASTING CONTEXTS',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate400 : AppColors.slate500,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  if (quest.example != null)
                    _buildSentenceRow(
                      label: baseWord,
                      sentence: quest.example!,
                      color: AppColors.teal400,
                      isDark: isDark,
                    ),
                  if (quest.example != null && quest.usageExample != null)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Divider(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                        height: 1,
                      ),
                    ),
                  if (quest.usageExample != null)
                    _buildSentenceRow(
                      label: antonymWord,
                      sentence: quest.usageExample!,
                      color: AppColors.rose500,
                      isDark: isDark,
                    ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // ── Common Pitfall ─────────────────────────────────────
            if (quest.commonMistake != null) ...[
              Container(
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppColors.rose500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.rose500.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'COMMON BEGINNER PITFALL',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.rose500,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(
                            quest.commonMistake!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              height: 1.35,
                              color: isDark
                                  ? AppColors.rose500
                                  : AppColors.rose700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPolarTile({
    required String title,
    required String word,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            children: [
              Expanded(
                child: Text(
                  word,
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : AppColors.slate900,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _speak(word),
                child: Container(
                  padding: EdgeInsets.all(4.r),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: color,
                    size: 16.r,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentenceRow({
    required String label,
    required String sentence,
    required Color color,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4.r),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 1,
            ),
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          '"$sentence"',
          style: TextStyle(
            fontSize: 13.sp,
            fontStyle: FontStyle.italic,
            height: 1.35,
            color: isDark ? AppColors.slate300 : AppColors.slate800,
          ),
        ),
      ],
    );
  }
}
