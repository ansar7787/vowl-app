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

/// Model representing a Fact vs Inference learning concept card.
class TrueFalseReadingLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String instruction;
  final String passage;
  final String statement;
  final String verdict;
  final String classification;
  final String evidenceLine;
  final String explanation;
  final String readingRule;
  final String hint;
  final String nativeTip;

  const TrueFalseReadingLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.instruction,
    required this.passage,
    required this.statement,
    required this.verdict,
    required this.classification,
    required this.evidenceLine,
    required this.explanation,
    required this.readingRule,
    required this.hint,
    required this.nativeTip,
  });

  factory TrueFalseReadingLearnQuest.fromJson(Map<String, dynamic> json) {
    final verdict = (json['verdict'] as String? ?? 'TRUE').toUpperCase();
    final isTrue = verdict == 'TRUE';

    return TrueFalseReadingLearnQuest(
      id: json['id'] as String? ?? 'RDG_TFR_LEARN_DEFAULT',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          (isTrue
              ? 'Fact vs Inference: Explicitly Stated (TRUE)'
              : 'Fact vs Inference: Contradiction (FALSE)'),
      instruction: json['instruction'] as String? ?? 'FACT VS INFERENCE GUIDE',
      passage: json['passage'] as String? ??
          'Mia has a small garden. She grows tomatoes and beans there.',
      statement: json['statement'] as String? ?? 'Mia grows beans in her garden.',
      verdict: verdict,
      classification: json['classification'] as String? ??
          (isTrue
              ? 'Explicitly Stated in Passage'
              : 'Directly Contradicts Passage Facts'),
      evidenceLine: json['evidenceLine'] as String? ??
          'She grows tomatoes and beans there.',
      explanation: json['explanation'] as String? ??
          'The second sentence says she grows tomatoes and beans, so beans are in her garden.',
      readingRule: json['readingRule'] as String? ??
          (isTrue
              ? 'A statement is TRUE when direct evidence in the text confirms the claim with identical or synonymous terms.'
              : 'A statement is FALSE when the text explicitly contradicts the claim with opposing facts.'),
      hint: json['hint'] as String? ?? 'Find what Mia grows.',
      nativeTip: json['nativeTip'] as String? ??
          'Stick strictly to the author\'s words. Never assume outside knowledge or extrapolate beyond stated facts.',
    );
  }
}

/// Rich, interactive Learn Phase screen for True/False Reading: "Fact vs Inference Guide".
///
/// Features truth classification, passage evidence mapping, statement breakdown,
/// fact verification rules, and audio articulation.
class TrueFalseReadingLearnScreen extends StatefulWidget {
  final int level;

  const TrueFalseReadingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<TrueFalseReadingLearnScreen> createState() =>
      _TrueFalseReadingLearnScreenState();
}

class _TrueFalseReadingLearnScreenState
    extends State<TrueFalseReadingLearnScreen> {
  List<TrueFalseReadingLearnQuest> _quests = const [
    TrueFalseReadingLearnQuest(
      id: 'FALLBACK_TFR_L1',
      level: 1,
      conceptTitle: 'Fact vs Inference: Explicitly Stated (TRUE)',
      instruction: 'FACT VS INFERENCE GUIDE',
      passage:
          'Mia has a small garden. She grows tomatoes and beans there.',
      statement: 'Mia grows beans in her garden.',
      verdict: 'TRUE',
      classification: 'Explicitly Stated in Passage',
      evidenceLine: 'She grows tomatoes and beans there.',
      explanation:
          'The second sentence explicitly notes that she grows tomatoes and beans, confirming the statement directly.',
      readingRule:
          'A statement is TRUE when direct evidence in the text confirms the claim with identical or synonymous terms.',
      hint: 'Find what Mia grows.',
      nativeTip:
          'Stick strictly to the author\'s words. If direct evidence exists, it is TRUE.',
    ),
    TrueFalseReadingLearnQuest(
      id: 'FALLBACK_TFR_L2',
      level: 1,
      conceptTitle: 'Fact vs Inference: Contradiction (FALSE)',
      instruction: 'FACT VS INFERENCE GUIDE',
      passage:
          'Lena wears a helmet when she rides her bike. The helmet is bright yellow.',
      statement: 'Lena\'s helmet is red.',
      verdict: 'FALSE',
      classification: 'Directly Contradicts Passage Facts',
      evidenceLine: 'The helmet is bright yellow.',
      explanation:
          'The passage explicitly states that the helmet is bright yellow, which contradicts the claim that it is red.',
      readingRule:
          'A statement is FALSE when the text explicitly contradicts the claim with opposing facts.',
      hint: 'Look for the color of the helmet.',
      nativeTip:
          'Do not assume or allow alternatives. Opposing evidence makes the statement FALSE.',
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
        'assets/curriculum/reading/trueFalseReading_learn_${startLevel}_$endLevel.json';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final questsRaw = data['quests'] as List<dynamic>? ?? [];

      final loadedQuests = questsRaw
          .whereType<Map<String, dynamic>>()
          .map((q) => TrueFalseReadingLearnQuest.fromJson(q))
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
        gameType: 'trueFalseReading',
        level: widget.level,
        phase: 'learn',
      );

      context.pushReplacement(
        '/practice?category=reading&gameType=trueFalseReading&level=${widget.level}',
      );
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
    final isTrue = quest.verdict == 'TRUE';
    final accentColor = isTrue ? const Color(0xFF34D399) : const Color(0xFFF87171);

    return LearnPhaseScaffold(
      title: 'Fact vs Inference Guide',
      gameType: 'trueFalseReading',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT GUIDE CARD'
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

            // 1. Verdict & Classification Banner
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isTrue ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: accentColor,
                      size: 22.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${quest.verdict} • ${quest.classification.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: accentColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          isTrue
                              ? 'Direct proof matches the text claim.'
                              : 'Information directly contradicts the claim.',
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

            // 2. Evaluated Statement Card
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
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.assignment_outlined, color: AppColors.indigo500, size: 16.sp),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'STATEMENT TO EVALUATE',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.volume_up_rounded, color: AppColors.indigo500, size: 18.sp),
                        onPressed: () => _ttsService?.speak(quest.statement),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    '"${quest.statement}"',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTrue ? Icons.check_circle_outline : Icons.highlight_off,
                          size: 16.sp,
                          color: accentColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Evaluated as: ${quest.verdict}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 3. Passage & Evidence Spotlight Card
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.menu_book_rounded, color: AppColors.teal500, size: 16.sp),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: Text(
                                'READING PASSAGE',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(Icons.volume_up_rounded, color: AppColors.teal500, size: 18.sp),
                        onPressed: () => _ttsService?.speak(quest.passage),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  _buildHighlightedPassage(quest.passage, quest.evidenceLine, accentColor, isDark),
                  SizedBox(height: 12.h),
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.search_rounded, color: accentColor, size: 16.sp),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Direct Evidence: "${quest.evidenceLine}"',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontStyle: FontStyle.italic,
                              height: 1.3,
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

            // 4. Detailed Rationale
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
                      Icon(Icons.lightbulb_outline_rounded, color: const Color(0xFFFBBF24), size: 16.sp),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'WHY THIS VERDICT IS ACCURATE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: const Color(0xFFFBBF24),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    quest.explanation,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? Colors.white70 : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 5. Reading Rule & Native Tip
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.indigo500.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_rounded, color: AppColors.indigo500, size: 20.sp),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'READING COMPREHENSION RULE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppColors.indigo500,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          quest.readingRule,
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
    String evidenceLine,
    Color accentColor,
    bool isDark,
  ) {
    if (evidenceLine.isEmpty ||
        !passage.toLowerCase().contains(evidenceLine.toLowerCase())) {
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
    final lowerEvidence = evidenceLine.toLowerCase();
    final index = lowerPassage.indexOf(lowerEvidence);

    final before = passage.substring(0, index);
    final match = passage.substring(index, index + evidenceLine.length);
    final after = passage.substring(index + evidenceLine.length);

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
                color: accentColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6.r),
                border: Border.all(color: accentColor, width: 1.5),
              ),
              child: Text(
                match,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
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
