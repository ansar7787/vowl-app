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

/// Interactive Learn Phase screen for Idioms: "Idiom Anatomy & Origin Explorer".
///
/// Teaches idioms through historical origins, figurative vs. literal breakdown,
/// conversational usage examples, audio pronunciation, and native speaker nuances.
class IdiomsLearnScreen extends StatefulWidget {
  final int level;

  const IdiomsLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<IdiomsLearnScreen> createState() => _IdiomsLearnScreenState();
}

class _IdiomsLearnScreenState extends State<IdiomsLearnScreen> {
  List<PhasedQuest> _quests = const [
    PhasedQuest(
      id: 'FALLBACK_IDIOMS_1',
      level: 1,
      conceptTitle: 'Idiom Anatomy: PIECE OF CAKE',
      word: 'PIECE OF CAKE',
      definition:
          "'Piece of cake' describes a task that takes almost no effort.",
      example:
          'Don\'t stress about the driving test — after all that practice, it\'ll be a piece of cake.',
      nativeTip:
          'Native speakers use this casually to reassure friends. Avoid in overly formal essays.',
      visualAnchor: '🍰😌 PIECE OF CAKE → Figurative Expression',
      rawExtra: {
        'topicEmoji': '🍰😌',
        'origin':
            'Recorded in American English since the 1930s; cake was historically linked to pleasant and effortless rewards.',
        'literalVsFigurative':
            'Literal: A physical slice of baked dessert | Figurative: Something very easy or effortless to do.',
      },
    ),
    PhasedQuest(
      id: 'FALLBACK_IDIOMS_2',
      level: 1,
      conceptTitle: 'Idiom Anatomy: UNDER THE WEATHER',
      word: 'UNDER THE WEATHER',
      definition: "'Under the weather' means feeling slightly unwell or sick.",
      example:
          'I\'m feeling a bit under the weather today, so I\'ll stay home and rest.',
      nativeTip:
          'Use this polite euphemism when you don\'t want to describe specific symptoms.',
      visualAnchor: '🤒🌧️ UNDER THE WEATHER → Mild Illness',
      rawExtra: {
        'topicEmoji': '🤒🌧️',
        'origin':
            'Believed to come from maritime sailing: sick sailors went below deck away from harsh weather.',
        'literalVsFigurative':
            'Literal: Under stormy skies | Figurative: Feeling mildly sick.',
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
          'assets/curriculum/vocabulary/idioms_learn_${startLevel}_$endLevel.json';
      final jsonStr = await rootBundle.loadString(path);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final batch = PhasedQuestBatch.fromJson(data);

      final levelQuests =
          batch.quests.where((q) => q.level == widget.level).toList();

      if (mounted && levelQuests.isNotEmpty) {
        setState(() {
          _quests = levelQuests;
        });
      }
    } catch (_) {
      // Keeps initial fallback quests
    }
  }

  void _speak(String text) {
    if (di.sl.isRegistered<TtsService>()) {
      di.sl<TtsService>().speak(text);
    }
  }

  void _nextIdiom() {
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
      gameType: 'idioms',
      level: widget.level,
      phase: 'learn',
    );
    final target =
        '/practice?category=vocabulary&gameType=idioms&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    if (_quests.isEmpty) {
      return LearnPhaseScaffold(
        title: 'Idioms: Level ${widget.level}',
        gameType: 'idioms',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No learning content available.')),
      );
    }

    final quest = _quests[_currentIndex];
    final word = quest.word ?? 'IDIOM';
    final emoji = quest.topicEmoji ?? '🎭';
    final definition = quest.definition ?? 'A colorful figurative idiom.';
    final origin = quest.origin ??
        'A widely used phrase in modern conversational English.';
    final literalVsFigurative = quest.literalVsFigurative ??
        'Literal: Physical meaning | Figurative: Metaphorical meaning';
    final example = quest.contextSentence ?? quest.example ?? '';
    final nativeTip = quest.nativeTip ??
        'Use this idiom naturally in conversation to sound fluent and expressive.';

    return LearnPhaseScaffold(
      title: 'Idiom Anatomy',
      gameType: 'idioms',
      level: widget.level,
      onComplete: _finishLearnPhase,
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
                  'IDIOM ${_currentIndex + 1} OF ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primaryColor,
                  ),
                ),
                Text(
                  'LEVEL ${widget.level}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate400 : AppColors.slate600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),

            // Emoji Clues & Idiom Title Card
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withValues(alpha: isDark ? 0.25 : 0.15),
                    primaryColor.withValues(alpha: isDark ? 0.08 : 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate900.withValues(alpha: 0.7)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      emoji,
                      style: TextStyle(fontSize: 28.sp),
                    ),
                  ),
                  SizedBox(height: 10.h),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                  SizedBox(height: 6.h),
                  IconButton(
                    onPressed: () => _speak(word),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: primaryColor,
                      size: 24.r,
                    ),
                    tooltip: 'Hear Idiom',
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Core Figurative Meaning Card
            _buildCard(
              isDark: isDark,
              accentColor: primaryColor,
              icon: Icons.lightbulb_rounded,
              badgeText: 'FIGURATIVE MEANING',
              content: definition,
            ),
            SizedBox(height: 12.h),

            // Origin Story Card
            _buildCard(
              isDark: isDark,
              accentColor: AppColors.amber400,
              icon: Icons.history_edu_rounded,
              badgeText: 'ORIGIN STORY',
              content: origin,
            ),
            SizedBox(height: 12.h),

            // Literal vs Figurative Analysis Card
            _buildCard(
              isDark: isDark,
              accentColor: AppColors.violet500,
              icon: Icons.compare_arrows_rounded,
              badgeText: 'LITERAL VS FIGURATIVE',
              content: literalVsFigurative,
            ),
            SizedBox(height: 12.h),

            // Context Sentence & Dialogue Card
            if (example.isNotEmpty) ...[
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
                      blurRadius: 6,
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
                          Icons.chat_bubble_outline_rounded,
                          color: primaryColor,
                          size: 18.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'NATURAL CONVERSATION',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: primaryColor,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.volume_up_rounded,
                            size: 20.r,
                            color: primaryColor,
                          ),
                          onPressed: () => _speak(example),
                          tooltip: 'Listen to sentence',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"$example"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Pro Tip Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.emerald500.withValues(
                  alpha: isDark ? 0.12 : 0.08,
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.emerald500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: AppColors.emerald500,
                    size: 20.r,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      nativeTip,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                        color: isDark
                            ? AppColors.emerald400
                            : AppColors.slate900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // Next / Complete Button
            ElevatedButton(
              onPressed: _nextIdiom,
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
                          ? 'Next Idiom (${_currentIndex + 1}/${_quests.length})'
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
    required String content,
  }) {
    return Container(
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
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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
            content,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: isDark ? AppColors.slate200 : AppColors.slate800,
            ),
          ),
        ],
      ),
    );
  }
}
