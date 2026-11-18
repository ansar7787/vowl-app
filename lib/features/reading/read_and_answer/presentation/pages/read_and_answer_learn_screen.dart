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

/// Model representing a Pre-Reading Schema Activation learning concept card.
class ReadAndAnswerLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String instruction;
  final String passageTopic;
  final String passage;
  final int passageWordCount;
  final List<Map<String, String>> keyVocabulary;
  final String readingStrategy;
  final String evidenceLine;
  final String comprehensionFocus;
  final String targetAnswer;
  final String explanation;
  final String nativeTip;

  const ReadAndAnswerLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.instruction,
    required this.passageTopic,
    required this.passage,
    required this.passageWordCount,
    required this.keyVocabulary,
    required this.readingStrategy,
    required this.evidenceLine,
    required this.comprehensionFocus,
    required this.targetAnswer,
    required this.explanation,
    required this.nativeTip,
  });

  factory ReadAndAnswerLearnQuest.fromJson(Map<String, dynamic> json) {
    final passage = json['passage'] as String? ??
        'The library is open from 9 a.m. to 6 p.m. on weekdays. On Saturday it closes at noon. It is closed on Sunday.';
    final topic = json['passageTopic'] as String? ?? 'Library Notice';
    final vocabRaw = json['keyVocabulary'] as List<dynamic>? ?? [];
    final vocab = vocabRaw.map((item) {
      if (item is Map<String, dynamic>) {
        return item.map((k, v) => MapEntry(k, v.toString()));
      }
      return {'word': item.toString(), 'role': 'Key vocabulary'};
    }).toList();

    return ReadAndAnswerLearnQuest(
      id: json['id'] as String? ?? 'RDG_LEARN_DEFAULT',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Pre-Reading Schema Activation: $topic',
      instruction: json['instruction'] as String? ?? 'PRE-READING SCHEMA ACTIVATION',
      passageTopic: topic,
      passage: passage,
      passageWordCount: json['passageWordCount'] as int? ?? 25,
      keyVocabulary: vocab,
      readingStrategy: json['readingStrategy'] as String? ??
          'Activate your background knowledge before reading: identify the context ($topic) and skim for supporting evidence.',
      evidenceLine: json['evidenceLine'] as String? ??
          'On Saturday it closes at noon',
      comprehensionFocus: json['comprehensionFocus'] as String? ??
          'At what time does the library close on Saturday?',
      targetAnswer: json['targetAnswer'] as String? ?? 'At noon',
      explanation: json['explanation'] as String? ??
          'Pre-reading helps predict content and improves comprehension speed.',
      nativeTip: json['nativeTip'] as String? ??
          'Notice how the passage structure organizes facts from main concept to specific details.',
    );
  }
}

/// Rich, interactive Learn Phase screen for Read & Answer: "Pre-Reading Schema Activation".
///
/// Features topic spotlight, passage preview, key vocabulary breakdown,
/// reading strategy guidance, evidence spotlight, and audio articulation.
class ReadAndAnswerLearnScreen extends StatefulWidget {
  final int level;

  const ReadAndAnswerLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ReadAndAnswerLearnScreen> createState() =>
      _ReadAndAnswerLearnScreenState();
}

class _ReadAndAnswerLearnScreenState extends State<ReadAndAnswerLearnScreen> {
  List<ReadAndAnswerLearnQuest> _quests = const [
    ReadAndAnswerLearnQuest(
      id: 'FALLBACK_RAA_L1',
      level: 1,
      conceptTitle: 'Pre-Reading Schema Activation: Library Notice',
      instruction: 'PRE-READING SCHEMA ACTIVATION',
      passageTopic: 'Library Notice',
      passage:
          'The library is open from 9 a.m. to 6 p.m. on weekdays. On Saturday it closes at noon. It is closed on Sunday.',
      passageWordCount: 25,
      keyVocabulary: [
        {'word': 'Library', 'role': 'Institution'},
        {'word': 'Weekdays', 'role': 'Time frame'},
        {'word': 'Saturday', 'role': 'Specific day'},
      ],
      readingStrategy:
          'Activate your background knowledge before reading: identify the context (Library Notice) and skim for supporting evidence.',
      evidenceLine: 'On Saturday it closes at noon',
      comprehensionFocus: 'At what time does the library close on Saturday?',
      targetAnswer: 'At noon',
      explanation:
          'The notice gives Saturday its own shorter day: the library closes at noon, much earlier than the 6 p.m. weekday closing.',
      nativeTip:
          'Weekdays and Saturday have different closing times, so read the second sentence closely.',
    ),
    ReadAndAnswerLearnQuest(
      id: 'FALLBACK_RAA_L2',
      level: 1,
      conceptTitle: 'Pre-Reading Schema Activation: Office Memo',
      instruction: 'PRE-READING SCHEMA ACTIVATION',
      passageTopic: 'Office Memo',
      passage:
          'Team meetings take place every Monday at 10 a.m. in Room 4B. Please review the agenda prior to attendance.',
      passageWordCount: 22,
      keyVocabulary: [
        {'word': 'Meetings', 'role': 'Event'},
        {'word': 'Agenda', 'role': 'Schedule'},
        {'word': 'Attendance', 'role': 'Participation'},
      ],
      readingStrategy:
          'Scan for time, room numbers, and required preparation steps before arriving.',
      evidenceLine: 'every Monday at 10 a.m. in Room 4B',
      comprehensionFocus: 'Where do team meetings take place?',
      targetAnswer: 'Room 4B',
      explanation:
          'The memo directly designates Room 4B as the meeting location.',
      nativeTip:
          'Notice key prepositions of time (at) and place (in).',
    ),
  ];

  int _currentIndex = 0;
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
    try {
      final batchIndex = ((widget.level - 1) ~/ 10) + 1;
      final startLevel = (batchIndex - 1) * 10 + 1;
      final endLevel = batchIndex * 10;
      final path =
          'assets/curriculum/reading/readAndAnswer_learn_${startLevel}_$endLevel.json';

      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests
          .where((q) => (q['level'] as int? ?? startLevel) == widget.level)
          .map((q) => ReadAndAnswerLearnQuest.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          } else if (rawQuests.isNotEmpty) {
            _quests = rawQuests
                .take(3)
                .map((q) => ReadAndAnswerLearnQuest.fromJson(q))
                .toList();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _ttsService?.speak(text);
    } catch (_) {}
  }

  Future<void> _onComplete() async {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'readAndAnswer',
      level: widget.level,
      phase: 'learn',
    );
    if (!mounted) return;
    context.pushReplacement(
      '/practice?category=reading&gameType=readAndAnswer&level=${widget.level}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final quest = _quests[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LearnPhaseScaffold(
      title: 'Pre-Reading Schema Activation',
      gameType: 'readAndAnswer',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT SCHEMA CARD'
          : 'CONTINUE TO PRACTICE →',
      onComplete: () {
        if (_currentIndex < _quests.length - 1) {
          setState(() => _currentIndex++);
        } else {
          _onComplete();
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress tracker chip row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'Passage ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      color: AppColors.teal500,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.violet500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.violet500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      quest.passageTopic,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.violet500,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Concept Header Banner
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal500.withValues(alpha: 0.15),
                    AppColors.violet500.withValues(alpha: 0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.r),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.teal500,
                      size: 24.r,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.instruction,
                          style: TextStyle(
                            color: AppColors.teal500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          quest.conceptTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : AppColors.slate950,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 1. Passage Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: AppColors.teal500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.article_rounded,
                                size: 14.r,
                                color: AppColors.teal500,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  'PASSAGE PREVIEW (${quest.passageWordCount} WORDS)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.teal500,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        icon: Icon(
                          Icons.volume_up_rounded,
                          color: AppColors.teal500,
                          size: 20.r,
                        ),
                        onPressed: () => _speak(quest.passage),
                        tooltip: 'Listen to Passage',
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    quest.passage,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate950,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 2. Key Vocabulary Cards
            if (quest.keyVocabulary.isNotEmpty) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: AppColors.violet500.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppColors.violet500.withValues(alpha: 0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.spellcheck_rounded,
                          color: AppColors.violet500,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'CORE SCHEMA VOCABULARY',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.violet500,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 6.h,
                      children: quest.keyVocabulary.map((v) {
                        final word = v['word'] ?? '';
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 10.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.slate800 : Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: AppColors.violet500.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                word,
                                style: TextStyle(
                                  color: isDark ? Colors.white : AppColors.slate950,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(width: 4.w),
                              GestureDetector(
                                onTap: () => _speak(word),
                                child: Icon(
                                  Icons.volume_up_rounded,
                                  size: 14.r,
                                  color: AppColors.violet500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // 3. Reading Strategy Guide Card
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
                      Icon(
                        Icons.psychology_rounded,
                        color: AppColors.teal500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'READING STRATEGY',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.teal500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    quest.readingStrategy,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.slate700,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // 4. Evidence Spotlight Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.amber500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'EVIDENCE SPOTLIGHT',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.amber500,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'Supporting Proof in Text: "${quest.evidenceLine}"',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate900,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    quest.nativeTip,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : AppColors.slate700,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
