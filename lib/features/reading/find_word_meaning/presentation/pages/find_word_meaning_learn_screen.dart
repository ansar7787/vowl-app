import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';

/// Model representing a Context Clue Detective learning card.
class FindWordMeaningLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String instruction;
  final String targetWord;
  final String meaning;
  final String passage;
  final String clueType;
  final String clueDescription;
  final String clueAnalysis;
  final String wordInContext;
  final String hint;
  final String nativeTip;

  const FindWordMeaningLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.instruction,
    required this.targetWord,
    required this.meaning,
    required this.passage,
    required this.clueType,
    required this.clueDescription,
    required this.clueAnalysis,
    required this.wordInContext,
    required this.hint,
    required this.nativeTip,
  });

  factory FindWordMeaningLearnQuest.fromJson(Map<String, dynamic> json) {
    final target = json['targetWord'] as String? ?? 'happy';
    final clue = json['clueType'] as String? ?? 'Inference Clue';

    return FindWordMeaningLearnQuest(
      id: json['id'] as String? ?? 'RDG_FWM_LEARN_DEFAULT',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Context Clue Detective: "$target"',
      instruction: json['instruction'] as String? ?? 'CONTEXT CLUE DETECTIVE',
      targetWord: target,
      meaning: json['meaning'] as String? ?? 'feeling pleased or glad',
      passage: json['passage'] as String? ??
          'Maria felt happy all through dinner because her brother was finally coming home for the weekend.',
      clueType: clue,
      clueDescription: json['clueDescription'] as String? ??
          'Surrounding context, actions, and consequences reveal the implicit meaning.',
      clueAnalysis: json['clueAnalysis'] as String? ??
          "'Happy' describes a good feeling you get when something pleasant happens.",
      wordInContext: json['wordInContext'] as String? ??
          'Grandma looked happy the moment she opened the door and saw her grandchildren.',
      hint: json['hint'] as String? ??
          'Look at how Maria is feeling about her brother\'s visit.',
      nativeTip: json['nativeTip'] as String? ??
          'Active readers look for $clue indicators to deduce unfamiliar vocabulary on the fly.',
    );
  }
}

/// Rich, interactive Learn Phase screen for Find Word Meaning: "Context Clue Detective".
///
/// Features 4 Context Clue Types (Definition, Synonym, Contrast, Inference),
/// passage highlighting, target word pronunciation, and real-world deduction guidance.
class FindWordMeaningLearnScreen extends StatefulWidget {
  final int level;

  const FindWordMeaningLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<FindWordMeaningLearnScreen> createState() =>
      _FindWordMeaningLearnScreenState();
}

class _FindWordMeaningLearnScreenState extends State<FindWordMeaningLearnScreen> {
  List<FindWordMeaningLearnQuest> _quests = const [
    FindWordMeaningLearnQuest(
      id: 'FALLBACK_FWM_L1',
      level: 1,
      conceptTitle: 'Context Clue Detective: "happy"',
      instruction: 'CONTEXT CLUE DETECTIVE',
      targetWord: 'happy',
      meaning: 'feeling pleased or glad',
      passage:
          'Maria felt happy all through dinner because her brother was finally coming home for the weekend.',
      clueType: 'Inference Clue',
      clueDescription:
          'Surrounding context, actions, and consequences reveal the implicit meaning.',
      clueAnalysis:
          'The cause ("her brother was finally coming home") produces a joyful emotional reaction, revealing that "happy" means feeling pleased or glad.',
      wordInContext:
          'Grandma looked happy the moment she opened the door and saw her grandchildren.',
      hint: 'Look at how Maria is feeling about her brother\'s visit.',
      nativeTip:
          'Active readers look for Inference Clue indicators to deduce unfamiliar vocabulary on the fly.',
    ),
    FindWordMeaningLearnQuest(
      id: 'FALLBACK_FWM_L2',
      level: 1,
      conceptTitle: 'Context Clue Detective: "difficult"',
      instruction: 'CONTEXT CLUE DETECTIVE',
      targetWord: 'difficult',
      meaning: 'hard to do or understand',
      passage:
          'The last question on the test was so difficult that half the class left it blank.',
      clueType: 'Definition Clue',
      clueDescription:
          'The sentence directly elaborates on the challenging nature of the task.',
      clueAnalysis:
          'Notice what the students did — half the class left it blank because it was not easy.',
      wordInContext:
          'Learning to ride a bike felt difficult at first, but it got easier with practice.',
      hint: 'Notice what the students did — they couldn\'t finish this part.',
      nativeTip:
          'When you see test-taking struggles, the word usually describes severe challenge.',
    ),
  ];

  int _currentIndex = 0;
  bool _isLoading = false;
  TtsService? _ttsService;

  @override
  void initState() {
    super.initState();
    try {
      if (di.sl.isRegistered<TtsService>()) {
        _ttsService = di.sl<TtsService>();
      }
    } catch (_) {}
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/reading/findWordMeaning_learn_${startLevel}_$endLevel.json';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final questsRaw = data['quests'] as List<dynamic>? ?? [];

      final loadedQuests = questsRaw
          .whereType<Map<String, dynamic>>()
          .map((q) => FindWordMeaningLearnQuest.fromJson(q))
          .where((q) => q.level == widget.level)
          .toList();

      if (loadedQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = loadedQuests;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback quests remain visible
    }
  }

  void _nextCard() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'findWordMeaning',
        level: widget.level,
        phase: 'learn',
      );

      context.pushReplacement(
        '/practice?category=reading&gameType=findWordMeaning&level=${widget.level}',
      );
    }
  }

  Color _getClueColor(String clueType) {
    if (clueType.contains('Definition')) {
      return const Color(0xFF38BDF8); // Sky blue
    } else if (clueType.contains('Synonym')) {
      return const Color(0xFF34D399); // Emerald
    } else if (clueType.contains('Contrast')) {
      return const Color(0xFFF472B6); // Rose
    } else {
      return const Color(0xFFA78BFA); // Violet (Inference)
    }
  }

  IconData _getClueIcon(String clueType) {
    if (clueType.contains('Definition')) {
      return Icons.menu_book_rounded;
    } else if (clueType.contains('Synonym')) {
      return Icons.compare_arrows_rounded;
    } else if (clueType.contains('Contrast')) {
      return Icons.flaky_rounded;
    } else {
      return Icons.psychology_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.slate950,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quest = _quests[_currentIndex];
    final clueColor = _getClueColor(quest.clueType);
    final clueIcon = _getClueIcon(quest.clueType);

    return LearnPhaseScaffold(
      title: 'Context Clue Detective',
      gameType: 'findWordMeaning',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT CLUE CARD'
          : 'CONTINUE TO PRACTICE →',
      onComplete: _nextCard,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card indicator
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Text(
                'Card ${_currentIndex + 1} of ${_quests.length}',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ),

            // 1. Clue Type Header Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: clueColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: clueColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: clueColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(clueIcon, color: clueColor, size: 22.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.clueType.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: clueColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          quest.clueDescription,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 2. Target Word & Definition Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [Colors.white, const Color(0xFFF8FAFC)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
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
                      Row(
                        children: [
                          Icon(Icons.key_rounded, color: clueColor, size: 18.sp),
                          SizedBox(width: 6.w),
                          Text(
                            'TARGET VOCABULARY',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.volume_up_rounded, color: clueColor, size: 20.sp),
                        onPressed: () => _ttsService?.speak(quest.targetWord),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    quest.targetWord,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w800,
                      color: clueColor,
                      letterSpacing: 0.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meaning: ',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            quest.meaning,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 3. Highlighted Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.search_rounded, color: clueColor, size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        'CONTEXT IN PASSAGE',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  _buildHighlightedPassage(quest.passage, quest.targetWord, clueColor, isDark),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 4. Clue Analysis & Deduction Breakdown
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline_rounded, color: const Color(0xFFFBBF24), size: 18.sp),
                      SizedBox(width: 6.w),
                      Text(
                        'DETECTIVE CLUE BREAKDOWN',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: const Color(0xFFFBBF24),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.clueAnalysis,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  if (quest.wordInContext.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Divider(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Icon(Icons.auto_stories_rounded, color: const Color(0xFF34D399), size: 16.sp),
                        SizedBox(width: 6.w),
                        Text(
                          'ANOTHER EXAMPLE IN CONTEXT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: const Color(0xFF34D399),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      '"${quest.wordInContext}"',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark ? Colors.white60 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 5. Native Detective Tip
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: clueColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: clueColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_rounded, color: clueColor, size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'READING STRATEGY',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: clueColor,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          quest.nativeTip,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: isDark ? Colors.white70 : Colors.black87,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlightedPassage(
    String passage,
    String targetWord,
    Color clueColor,
    bool isDark,
  ) {
    if (targetWord.isEmpty || !passage.toLowerCase().contains(targetWord.toLowerCase())) {
      return Text(
        passage,
        style: TextStyle(
          fontSize: 14.sp,
          height: 1.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
      );
    }

    final lowerPassage = passage.toLowerCase();
    final lowerTarget = targetWord.toLowerCase();
    final index = lowerPassage.indexOf(lowerTarget);

    final before = passage.substring(0, index);
    final match = passage.substring(index, index + targetWord.length);
    final after = passage.substring(index + targetWord.length);

    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14.sp,
          height: 1.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
        children: [
          TextSpan(text: before),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              decoration: BoxDecoration(
                color: clueColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: clueColor, width: 1.5),
              ),
              child: Text(
                match,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  color: clueColor,
                ),
              ),
            ),
          ),
          TextSpan(text: after),
        ],
      ),
    );
  }
}
