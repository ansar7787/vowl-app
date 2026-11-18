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

/// Data model representing a direct-to-indirect speech learning concept card.
class DirectIndirectSpeechLearnQuest {
  final String id;
  final int level;
  final String conceptTitle;
  final String instruction;
  final String grammarRule;
  final String directSpeech;
  final String reportedSpeech;
  final List<String> changesList;
  final String ruleExplanation;
  final String nativeTip;
  final String backshiftSummary;

  const DirectIndirectSpeechLearnQuest({
    required this.id,
    required this.level,
    required this.conceptTitle,
    required this.instruction,
    required this.grammarRule,
    required this.directSpeech,
    required this.reportedSpeech,
    required this.changesList,
    required this.ruleExplanation,
    required this.nativeTip,
    required this.backshiftSummary,
  });

  factory DirectIndirectSpeechLearnQuest.fromJson(Map<String, dynamic> json) {
    final direct = json['directSpeech'] as String? ??
        (json['sentence'] as String? ?? 'Maria said, "I walk to school every day."');
    final reported = json['reportedSpeech'] as String? ??
        (json['correctAnswer'] as String? ?? 'Maria said that she walked to school every day.');
    final rule = json['grammarRule'] as String? ?? 'Tense Backshift';
    final changes = (json['changesList'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    return DirectIndirectSpeechLearnQuest(
      id: json['id'] as String? ?? 'dis_learn_default',
      level: json['level'] as int? ?? 1,
      conceptTitle: json['conceptTitle'] as String? ??
          'Speech Bubble to Report Converter: $rule',
      instruction: json['instruction'] as String? ?? 'SPEECH BUBBLE TO REPORT CONVERTER',
      grammarRule: rule,
      directSpeech: direct,
      reportedSpeech: reported,
      changesList: changes,
      ruleExplanation: json['ruleExplanation'] as String? ??
          (json['explanation'] as String? ??
              'When converting direct speech into reported speech, tenses shift one step into the past and pronouns align with the narrator.'),
      nativeTip: json['nativeTip'] as String? ??
          (json['hint'] as String? ??
              'Look at the reporting verb and note how verbs step backward in time.'),
      backshiftSummary: json['backshiftSummary'] as String? ??
          '🔄 Quote ➔ Report: "$direct" ➔ "$reported"',
    );
  }
}

/// Rich, interactive Learn Phase screen for Direct & Indirect Speech: "Speech Bubble to Report Converter".
///
/// Features interactive quotation bubble, transformation arrow, reported speech output,
/// backshift token tags, audio articulation, and native speaker alignment tips.
class DirectIndirectSpeechLearnScreen extends StatefulWidget {
  final int level;

  const DirectIndirectSpeechLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<DirectIndirectSpeechLearnScreen> createState() =>
      _DirectIndirectSpeechLearnScreenState();
}

class _DirectIndirectSpeechLearnScreenState
    extends State<DirectIndirectSpeechLearnScreen> {
  List<DirectIndirectSpeechLearnQuest> _quests = const [
    DirectIndirectSpeechLearnQuest(
      id: 'FALLBACK_DIS_L1',
      level: 1,
      conceptTitle: 'Speech Bubble to Report Converter: Tense Backshift',
      instruction: 'SPEECH BUBBLE TO REPORT CONVERTER',
      grammarRule: 'Tense Backshift',
      directSpeech: 'Maria said, "I walk to school every day."',
      reportedSpeech: 'Maria said that she walked to school every day.',
      changesList: [
        "'walk' → 'walked'",
        "'I' → 'she'",
      ],
      ruleExplanation:
          "'Walk' backshifts to 'walked', and 'I' becomes 'she' because Maria is the speaker being reported.",
      nativeTip:
          'Check what happens to the verb tense and to the pronoun when reported.',
      backshiftSummary:
          '🔄 Quote ➔ Report: "Maria said, \\"I walk to school every day.\\"" ➔ "Maria said that she walked to school every day."',
    ),
  ];

  int _currentIndex = 0;
  bool _isLoading = true;
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
          'assets/curriculum/grammar/directIndirectSpeech_learn_${startLevel}_$endLevel.json';

      final content = await rootBundle.loadString(path);
      final data = jsonDecode(content) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelQuests = rawQuests
          .where((q) => (q['level'] as int? ?? startLevel) == widget.level)
          .map((q) => DirectIndirectSpeechLearnQuest.fromJson(q))
          .toList();

      if (mounted) {
        setState(() {
          if (levelQuests.isNotEmpty) {
            _quests = levelQuests;
          } else if (rawQuests.isNotEmpty) {
            _quests = rawQuests
                .take(3)
                .map((q) => DirectIndirectSpeechLearnQuest.fromJson(q))
                .toList();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _speak(String text) async {
    try {
      await _ttsService?.speak(text);
    } catch (_) {}
  }

  Future<void> _onComplete() async {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'directIndirectSpeech',
      level: widget.level,
      phase: 'learn',
    );
    if (!mounted) return;
    context.pushReplacement(
      '/practice?category=grammar&gameType=directIndirectSpeech&level=${widget.level}',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.slate950,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.teal500),
        ),
      );
    }

    final quest = _quests[_currentIndex];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LearnPhaseScaffold(
      title: 'Speech Bubble to Report Converter',
      gameType: 'directIndirectSpeech',
      level: widget.level,
      actionLabel: _currentIndex < _quests.length - 1
          ? 'NEXT CONVERSION CARD'
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
                    'Rule ${_currentIndex + 1} of ${_quests.length}',
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
                      quest.grammarRule,
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
                      Icons.transform_rounded,
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

            // 1. Direct Speech Bubble Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.4),
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
                            color: AppColors.amber500.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 14.r,
                                color: AppColors.amber500,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  'DIRECT SPEECH (QUOTED)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: AppColors.amber500,
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
                          color: AppColors.amber500,
                          size: 20.r,
                        ),
                        onPressed: () => _speak(quest.directSpeech),
                        tooltip: 'Listen to Direct Speech',
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.directSpeech,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate950,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.h),

            // Backshift Engine Transformation Arrow
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sync_alt_rounded,
                      color: AppColors.teal500,
                      size: 16.r,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'Backshift Engine ⬇️',
                      style: TextStyle(
                        color: AppColors.teal500,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10.h),

            // 2. Reported Speech Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.5),
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
                                Icons.record_voice_over_rounded,
                                size: 14.r,
                                color: AppColors.teal500,
                              ),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  'REPORTED SPEECH (INDIRECT)',
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
                        onPressed: () => _speak(quest.reportedSpeech),
                        tooltip: 'Listen to Reported Speech',
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    quest.reportedSpeech,
                    style: TextStyle(
                      color: isDark ? Colors.white : AppColors.slate950,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // 3. Shift Breakdown Chips (changesList)
            if (quest.changesList.isNotEmpty) ...[
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
                          Icons.checklist_rounded,
                          color: AppColors.violet500,
                          size: 16.r,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'SYNTACTIC BACKSHIFTS APPLIED',
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
                      children: quest.changesList.map((change) {
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
                          child: Text(
                            change,
                            style: TextStyle(
                              color: isDark ? Colors.white : AppColors.slate950,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 14.h),
            ],

            // 4. Grammar Principle Card
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
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.teal500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'GRAMMAR PRINCIPLE',
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
                    quest.ruleExplanation,
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

            // 5. Native Speaker Tip
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
                        Icons.star_rounded,
                        color: AppColors.amber500,
                        size: 18.r,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'NATIVE SPEAKER CADENCE TIP',
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
                    quest.nativeTip,
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
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
