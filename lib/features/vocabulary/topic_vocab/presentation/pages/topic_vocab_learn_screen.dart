import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Interactive Learn Phase screen for Topic Vocab: "Thematic Category & Lexicon Explorer".
///
/// Explores categorical classification themes (e.g. Hot vs Cold, Science vs Art, Animals vs Plants),
/// breaking down word definitions, semantic associations, and classification logic.
class TopicVocabLearnScreen extends StatefulWidget {
  final int level;

  const TopicVocabLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<TopicVocabLearnScreen> createState() => _TopicVocabLearnScreenState();
}

class _TopicVocabLearnScreenState extends State<TopicVocabLearnScreen> {
  List<PhasedQuest> _quests = const [
    PhasedQuest(
      id: 'FALLBACK_TV_1',
      level: 1,
      conceptTitle: 'Thematic Category: Hot vs Cold',
      word: 'Boiling',
      definition:
          'Boiling and steaming both describe intense heat. Freezing and icy describe zero or sub-zero temperature.',
      example:
          'Boiling: heated until it bubbles rapidly | Freezing: cold enough for water to turn to ice',
      nativeTip:
          'Think about what happens to skin near each one — a burn, or a shiver.',
      visualAnchor: '🌡️ Thematic Sorting • Hot vs Cold',
      rawExtra: {
        'topicBuckets': ['Hot', 'Cold'],
        'topicEmoji': '🌡️',
        'options': ['Boiling', 'Freezing', 'Steaming', 'Icy', 'Scorching'],
        'relatedWords': [
          'Boiling: heated until it bubbles rapidly, 100°C for water',
          'Freezing: cold enough for water to turn to ice, 0°C',
          'Steaming: giving off visible hot vapor',
          'Icy: covered in ice, or very cold to the touch',
          'Scorching: extremely hot, especially from the sun',
        ],
      },
    ),
    PhasedQuest(
      id: 'FALLBACK_TV_2',
      level: 1,
      conceptTitle: 'Thematic Category: Weather Warmth vs Chill',
      word: 'Sweltering',
      definition:
          'Sweltering and toasty describe warm conditions. Chilly and frosty describe cold weather sensations.',
      example:
          'Sweltering: unpleasantly hot and humid | Frosty: cold enough for frost to form',
      nativeTip:
          'Notice which ones apply to cozy blankets vs oppressive summer afternoons.',
      visualAnchor: '☀️ Thematic Sorting • Hot vs Cold Weather',
      rawExtra: {
        'topicBuckets': ['Hot', 'Cold'],
        'topicEmoji': '☀️',
        'options': ['Sweltering', 'Chilly', 'Cool', 'Toasty', 'Frosty'],
        'relatedWords': [
          'Sweltering: unpleasantly hot, often humid',
          'Chilly: uncomfortably cool, but not freezing',
          'Cool: mildly cold, often refreshing',
          'Toasty: pleasantly warm and cozy',
          'Frosty: cold enough for frost to form on windows',
        ],
      },
    ),
  ];
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
          'assets/curriculum/vocabulary/topicVocab_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
          _currentIndex = 0;
        });
      }
    } catch (_) {
      // Keeps fallback items
    }
  }

  void _nextTheme() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      _startPractice();
    }
  }

  void _startPractice() {
    final target =
        '/practice?category=vocabulary&gameType=topicVocab&level=${widget.level}';
    context.pushReplacement(target);
  }

  void _speak(String text) {
    try {
      if (di.sl.isRegistered<TtsService>()) {
        di.sl<TtsService>().speak(text);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    if (_quests.isEmpty) {
      return LearnPhaseScaffold(
        title: 'Topic Categorization: Level ${widget.level}',
        gameType: 'topicVocab',
        level: widget.level,
        onComplete: _startPractice,
        child: const Center(child: Text('No learning content available.')),
      );
    }

    final quest = _quests[_currentIndex];
    final buckets = (quest.rawExtra['topicBuckets'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        ['Category A', 'Category B'];
    final relatedWords = (quest.rawExtra['relatedWords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    final emoji = (quest.rawExtra['topicEmoji'] as String?) ?? '🏷️';

    return LearnPhaseScaffold(
      title: 'Thematic Category Explorer',
      gameType: 'topicVocab',
      level: widget.level,
      onComplete: _startPractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'THEME ${_currentIndex + 1} OF ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(emoji, style: TextStyle(fontSize: 13.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        buckets.join(' / ').toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Visual Anchor Banner
            if (quest.visualAnchor != null)
              Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(
                    alpha: isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.category_rounded,
                        color: primaryColor, size: 20.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.visualAnchor!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.slate900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Concept Header Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    quest.conceptTitle ?? 'Thematic Category',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Wrap(
                    spacing: 8.w,
                    children: buckets.map((bucket) {
                      return Chip(
                        label: Text(
                          bucket,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Category Overview Card
            _buildCard(
              isDark: isDark,
              accentColor: primaryColor,
              icon: Icons.hub_rounded,
              badgeText: 'CATEGORY OVERVIEW',
              body: quest.definition ?? '',
            ),
            SizedBox(height: 12.h),

            // Semantic Word Definitions Card
            if (relatedWords.isNotEmpty) ...[
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
                        Icon(Icons.menu_book_rounded,
                            color: AppColors.amber400, size: 18.r),
                        SizedBox(width: 8.w),
                        Text(
                          'WORD DEFINITIONS & LINKAGES',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: AppColors.amber400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    for (final rw in relatedWords) ...[
                      Builder(
                        builder: (context) {
                          final match =
                              RegExp(r'^(.*?)(?:[:\-])(.*)$').firstMatch(rw);
                          final wordPart =
                              match != null ? match.group(1)?.trim() ?? rw : rw;
                          final defPart =
                              match != null ? match.group(2)?.trim() ?? '' : '';

                          return Padding(
                            padding: EdgeInsets.only(bottom: 8.h),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: Icon(
                                    Icons.volume_up_rounded,
                                    size: 16.r,
                                    color: primaryColor,
                                  ),
                                  onPressed: () => _speak(wordPart),
                                ),
                                SizedBox(width: 6.w),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '$wordPart: ',
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                        TextSpan(
                                          text: defPart,
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 13.sp,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? AppColors.slate300
                                                : AppColors.slate700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Sorting Strategy Tip Card
            if (quest.nativeTip != null && quest.nativeTip!.isNotEmpty) ...[
              _buildCard(
                isDark: isDark,
                accentColor: AppColors.emerald500,
                icon: Icons.lightbulb_rounded,
                badgeText: 'SORTING STRATEGY',
                body: quest.nativeTip!,
              ),
              SizedBox(height: 12.h),
            ],

            SizedBox(height: 16.h),

            // Next / Complete Button
            ElevatedButton(
              onPressed: _nextTheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 2,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentIndex < _quests.length - 1
                          ? 'Next Topic (${_currentIndex + 1}/${_quests.length})'
                          : 'Complete Learn & Start Practice 🚀',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    const Icon(Icons.arrow_forward_rounded, size: 18),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
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
              Icon(icon, color: accentColor, size: 18.r),
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
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isDark ? AppColors.slate300 : AppColors.slate700,
            ),
          ),
        ],
      ),
    );
  }
}
