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

/// Interactive Learn Phase screen for Academic Word: "Academic Register & Lexicon Explorer".
///
/// Explores formal academic terms across disciplinary fields (Biology, Economics, etc.),
/// contrasting casual vs scholarly register, providing collocations and authentic scholarly context.
class AcademicWordLearnScreen extends StatefulWidget {
  final int level;

  const AcademicWordLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<AcademicWordLearnScreen> createState() =>
      _AcademicWordLearnScreenState();
}

class _AcademicWordLearnScreenState extends State<AcademicWordLearnScreen> {
  List<PhasedQuest> _quests = const [
    PhasedQuest(
      id: 'FALLBACK_AW_1',
      level: 1,
      conceptTitle: 'Academic Register: ANALYZE',
      word: 'ANALYZE',
      definition: 'To examine something in detail in order to understand it.',
      example:
          'Marine biologists carefully analyze water samples to determine how pollution levels have changed over the decade.',
      nativeTip:
          'Essential scholarly verb across scientific reports and methodology chapters.',
      visualAnchor: '🔬 Biology • ANALYZE → Systematic Investigation',
      rawExtra: {
        'academicField': 'Biology',
        'collocations': [
          'analyze data',
          'closely analyze',
          'analyze the results'
        ],
        'casualVsAcademic':
            'Casual: Look at closely | Academic: ANALYZE data with methodological rigor.',
      },
    ),
    PhasedQuest(
      id: 'FALLBACK_AW_2',
      level: 1,
      conceptTitle: 'Academic Register: APPROACH',
      word: 'APPROACH',
      definition: 'A way of dealing with or thinking about something.',
      example:
          'The researcher adopted a novel approach to investigating cognitive development.',
      nativeTip:
          'Use to discuss research methodology and conceptual frameworks.',
      visualAnchor: '📚 Education • APPROACH → Theoretical Framework',
      rawExtra: {
        'academicField': 'Education',
        'collocations': [
          'take a new approach',
          'methodological approach',
          'approach to learning'
        ],
        'casualVsAcademic':
            'Casual: Way of doing things | Academic: Methodological APPROACH.',
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
          'assets/curriculum/vocabulary/academicWord_learn_${startLevel}_$endLevel.json';
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

  void _nextWord() {
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
        '/practice?category=vocabulary&gameType=academicWord&level=${widget.level}';
    context.pushReplacement(target);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('vocabulary', level: widget.level);
    final primaryColor = theme.primaryColor;

    if (_quests.isEmpty) {
      return LearnPhaseScaffold(
        title: 'Academic Register: Level ${widget.level}',
        gameType: 'academicWord',
        level: widget.level,
        onComplete: _finishLearnPhase,
        child: const Center(child: Text('No learning content available.')),
      );
    }

    final quest = _quests[_currentIndex];
    final word = quest.word ?? 'TERM';
    final field = (quest.rawExtra['academicField'] as String?) ?? 'Scholarship';
    final definition = quest.definition ?? 'A key formal academic term.';
    final rawColls = (quest.rawExtra['collocations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    final passage = quest.contextSentence ?? quest.example ?? '';
    final casualVsAcademic = (quest.rawExtra['casualVsAcademic'] as String?) ??
        'Casual phrasing vs Formal Academic precision.';
    final nativeTip = quest.nativeTip ??
        'Mastering this term provides precision in academic papers and formal discourse.';

    return LearnPhaseScaffold(
      title: 'Academic Register',
      gameType: 'academicWord',
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
                  'TERM ${_currentIndex + 1} OF ${_quests.length}',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: primaryColor,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school_rounded,
                          size: 13.r, color: primaryColor),
                      SizedBox(width: 4.w),
                      Text(
                        field.toUpperCase(),
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

            // Target Word Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
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
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      word,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                        color: isDark ? Colors.white : AppColors.slate900,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  IconButton(
                    onPressed: () => _speak(word),
                    icon: Icon(
                      Icons.volume_up_rounded,
                      color: primaryColor,
                      size: 24.r,
                    ),
                    tooltip: 'Hear Pronunciation',
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Academic Definition Card
            _buildCard(
              isDark: isDark,
              accentColor: primaryColor,
              icon: Icons.menu_book_rounded,
              badgeText: 'ACADEMIC DEFINITION',
              content: definition,
            ),
            SizedBox(height: 12.h),

            // Standard Collocations Card
            if (rawColls.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.r),
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
                    Row(
                      children: [
                        Icon(Icons.link_rounded,
                            color: AppColors.amber400, size: 18.r),
                        SizedBox(width: 8.w),
                        Text(
                          'STANDARD COLLOCATIONS',
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
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: rawColls.map((col) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber500.withValues(
                              alpha: isDark ? 0.12 : 0.08,
                            ),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.amber500.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            col,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.amber200
                                  : AppColors.amber900,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Scholarly Context Passage Card
            if (passage.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(16.r),
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
                    Row(
                      children: [
                        Icon(
                          Icons.article_rounded,
                          color: primaryColor,
                          size: 18.r,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          'SCHOLARLY DISCOURSE',
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
                          onPressed: () => _speak(passage),
                          tooltip: 'Listen to passage',
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"$passage"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        height: 1.45,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],

            // Casual vs Academic Register Comparison
            _buildCard(
              isDark: isDark,
              accentColor: AppColors.violet500,
              icon: Icons.compare_arrows_rounded,
              badgeText: 'REGISTER CONTRAST',
              content: casualVsAcademic,
            ),
            SizedBox(height: 12.h),

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
              onPressed: _nextWord,
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
                          ? 'Next Academic Word (${_currentIndex + 1}/${_quests.length})'
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
