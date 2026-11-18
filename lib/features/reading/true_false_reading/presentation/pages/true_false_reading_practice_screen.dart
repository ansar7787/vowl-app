import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';

/// Data model representing a True/False reading practice exercise with evidence highlighting.
class TrueFalseReadingPracticeQuest {
  final String id;
  final int level;
  final String instruction;
  final String passage;
  final List<String> sentences;
  final String statement;
  final String correctAnswer; // 'true' or 'false'
  final String evidenceLine;
  final int correctSentenceIndex;
  final String hint;
  final String explanation;

  const TrueFalseReadingPracticeQuest({
    required this.id,
    required this.level,
    required this.instruction,
    required this.passage,
    required this.sentences,
    required this.statement,
    required this.correctAnswer,
    required this.evidenceLine,
    required this.correctSentenceIndex,
    required this.hint,
    required this.explanation,
  });

  factory TrueFalseReadingPracticeQuest.fromJson(Map<String, dynamic> json) {
    final passage = json['passage'] as String? ??
        'Mia has a small garden. She grows tomatoes and beans there.';
    final sentenceList = (json['sentences'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final sentences = sentenceList.isNotEmpty
        ? sentenceList
        : passage
            .split(RegExp(r'(?<=[.!?])\s+'))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();

    final evidence = json['evidenceLine'] as String? ??
        (sentences.isNotEmpty ? sentences.last : passage);

    int targetIdx = json['correctSentenceIndex'] as int? ?? 0;
    if (json['correctSentenceIndex'] == null && sentences.isNotEmpty) {
      for (int i = 0; i < sentences.length; i++) {
        if (sentences[i].toLowerCase().contains(evidence.toLowerCase()) ||
            evidence.toLowerCase().contains(sentences[i].toLowerCase())) {
          targetIdx = i;
          break;
        }
      }
    }

    return TrueFalseReadingPracticeQuest(
      id: json['id'] as String? ?? 'RDG_TFR_PRACTICE_DEFAULT',
      level: json['level'] as int? ?? 1,
      instruction: json['instruction'] as String? ??
          'Evaluate the statement and select the supporting evidence sentence:',
      passage: passage,
      sentences: sentences,
      statement: json['statement'] as String? ?? 'Mia grows beans in her garden.',
      correctAnswer: (json['correctAnswer'] as String? ?? 'true').toLowerCase().trim(),
      evidenceLine: evidence,
      correctSentenceIndex: targetIdx,
      hint: json['hint'] as String? ?? 'Find what Mia grows.',
      explanation: json['explanation'] as String? ??
          'The second sentence says she grows tomatoes and beans, so beans are in her garden.',
    );
  }
}

/// Interactive Practice Phase screen for True/False Reading: "Evidence Highlighter Gym".
///
/// Features statement evaluation (True/False), interactive passage sentence evidence selection,
/// unverified submission blocker, proof confirmation, and audio scaffolding.
class TrueFalseReadingPracticeScreen extends StatefulWidget {
  final int level;

  const TrueFalseReadingPracticeScreen({
    super.key,
    required this.level,
  });

  @override
  State<TrueFalseReadingPracticeScreen> createState() =>
      _TrueFalseReadingPracticeScreenState();
}

class _TrueFalseReadingPracticeScreenState
    extends State<TrueFalseReadingPracticeScreen> {
  List<TrueFalseReadingPracticeQuest> _quests = const [
    TrueFalseReadingPracticeQuest(
      id: 'FALLBACK_TFR_P1',
      level: 1,
      instruction:
          'Evaluate the statement and select the supporting evidence sentence:',
      passage: 'Mia has a small garden. She grows tomatoes and beans there.',
      sentences: [
        'Mia has a small garden.',
        'She grows tomatoes and beans there.',
      ],
      statement: 'Mia grows beans in her garden.',
      correctAnswer: 'true',
      evidenceLine: 'She grows tomatoes and beans there.',
      correctSentenceIndex: 1,
      hint: 'Find what Mia grows.',
      explanation:
          'The second sentence explicitly notes she grows tomatoes and beans, proving the statement TRUE.',
    ),
    TrueFalseReadingPracticeQuest(
      id: 'FALLBACK_TFR_P2',
      level: 1,
      instruction:
          'Evaluate the statement and select the supporting evidence sentence:',
      passage:
          'Lena wears a helmet when she rides her bike. The helmet is bright yellow.',
      sentences: [
        'Lena wears a helmet when she rides her bike.',
        'The helmet is bright yellow.',
      ],
      statement: 'Lena\'s helmet is red.',
      correctAnswer: 'false',
      evidenceLine: 'The helmet is bright yellow.',
      correctSentenceIndex: 1,
      hint: 'Look for the color of the helmet.',
      explanation:
          'The helmet is bright yellow, which contradicts the claim that it is red, proving the statement FALSE.',
    ),
  ];

  int _currentIndex = 0;
  String? _selectedVerdict; // 'true' or 'false'
  int? _selectedSentenceIndex;
  bool _hasChecked = false;
  bool _isCorrect = false;
  int _score = 0;
  bool _showHint = false;
  String? _validationWarning;
  bool _isLoading = false;

  HapticService? _hapticService;
  SoundService? _soundService;
  TtsService? _ttsService;

  @override
  void initState() {
    super.initState();
    try {
      if (di.sl.isRegistered<HapticService>()) {
        _hapticService = di.sl<HapticService>();
      }
      if (di.sl.isRegistered<SoundService>()) {
        _soundService = di.sl<SoundService>();
      }
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
        'assets/curriculum/reading/trueFalseReading_practice_${startLevel}_$endLevel.json';

    try {
      final jsonString = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final questsRaw = data['quests'] as List<dynamic>? ?? [];

      final loadedQuests = questsRaw
          .whereType<Map<String, dynamic>>()
          .map((q) => TrueFalseReadingPracticeQuest.fromJson(q))
          .where((q) => q.level == widget.level)
          .toList();

      if (loadedQuests.isNotEmpty && mounted) {
        setState(() {
          _quests = loadedQuests;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallbacks remain active
    }
  }

  void _chooseVerdict(String verdict) {
    if (_hasChecked) return;
    setState(() {
      _selectedVerdict = verdict;
      _validationWarning = null;
    });
    _hapticService?.selection();
  }

  void _selectSentence(int index) {
    if (_hasChecked) return;
    setState(() {
      _selectedSentenceIndex = index;
      _validationWarning = null;
    });
    _hapticService?.selection();
  }

  void _checkAnswer() {
    if (_hasChecked) return;

    if (_selectedVerdict == null) {
      setState(() {
        _validationWarning = 'Please choose TRUE or FALSE first.';
      });
      _hapticService?.error();
      return;
    }

    if (_selectedSentenceIndex == null) {
      setState(() {
        _validationWarning =
            'Submission blocked: Tap the sentence in the passage that PROVES your answer!';
      });
      _hapticService?.error();
      return;
    }

    final quest = _quests[_currentIndex];
    final isVerdictRight =
        _selectedVerdict?.toLowerCase() == quest.correctAnswer.toLowerCase();
    final isEvidenceRight =
        _selectedSentenceIndex == quest.correctSentenceIndex;

    final overallCorrect = isVerdictRight && isEvidenceRight;

    setState(() {
      _hasChecked = true;
      _isCorrect = overallCorrect;
      _validationWarning = null;
      if (overallCorrect) {
        _score++;
        _soundService?.playCorrect();
        _hapticService?.success();
      } else {
        _soundService?.playWrong();
        _hapticService?.error();
      }
    });
  }

  void _nextExercise() {
    if (_currentIndex < _quests.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedVerdict = null;
        _selectedSentenceIndex = null;
        _hasChecked = false;
        _isCorrect = false;
        _showHint = false;
        _validationWarning = null;
      });
    } else {
      _completePractice();
    }
  }

  void _completePractice() {
    PhaseProgressRecorder.recordPhaseCompleted(
      context,
      gameType: 'trueFalseReading',
      level: widget.level,
      phase: 'practice',
    );

    context.pushReplacement(
      '/game?category=reading&gameType=trueFalseReading&level=${widget.level}',
    );
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

    return PracticePhaseScaffold(
      title: 'Evidence Highlighter',
      gameType: 'trueFalseReading',
      level: widget.level,
      currentExerciseIndex: _currentIndex,
      totalExercises: _quests.length,
      onComplete: _completePractice,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Banner
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.teal500.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: AppColors.teal500.withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fact_check_rounded, size: 13.sp, color: AppColors.teal500),
                      SizedBox(width: 4.w),
                      Text(
                        'EVIDENCE GYM',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.teal500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    'Quest ${_currentIndex + 1} of ${_quests.length}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _showHint ? Icons.lightbulb_rounded : Icons.lightbulb_outline_rounded,
                    color: _showHint ? const Color(0xFFFBBF24) : (isDark ? Colors.white60 : Colors.black45),
                    size: 18.sp,
                  ),
                  tooltip: 'Evidence Hint',
                  onPressed: () {
                    setState(() {
                      _showHint = !_showHint;
                    });
                    _hapticService?.selection();
                  },
                ),
                if (_ttsService != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(Icons.volume_up_rounded,
                        color: isDark ? Colors.white60 : Colors.black45, size: 18.sp),
                    tooltip: 'Listen to passage',
                    onPressed: () => _ttsService?.speak(quest.passage),
                  ),
              ],
            ),
            SizedBox(height: 12.h),

            // 2. Hint Banner (if toggled)
            if (_showHint) ...[
              Container(
                padding: EdgeInsets.all(12.r),
                margin: EdgeInsets.only(bottom: 12.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFFBBF24).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_rounded,
                        color: const Color(0xFFFBBF24), size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        quest.hint,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 3. Statement to Evaluate Card with True/False Chips
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
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.help_outline_rounded, color: AppColors.indigo500, size: 16.sp),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: Text(
                          'STEP 1: EVALUATE THE STATEMENT',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppColors.indigo500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    '"${quest.statement}"',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  // True / False Selector
                  Row(
                    children: [
                      Expanded(
                        child: _buildVerdictButton(
                          label: 'TRUE',
                          value: 'true',
                          color: const Color(0xFF34D399),
                          icon: Icons.check_circle_outline,
                          quest: quest,
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildVerdictButton(
                          label: 'FALSE',
                          value: 'false',
                          color: const Color(0xFFF87171),
                          icon: Icons.highlight_off,
                          quest: quest,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),

            // 4. Passage Card with Interactive Sentence Highlighting
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
                      Icon(Icons.touch_app_rounded, color: AppColors.teal500, size: 16.sp),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'STEP 2: TAP SUPPORTING SENTENCE IN PASSAGE',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                            color: AppColors.teal500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  // Interactive Sentences
                  ...List.generate(quest.sentences.length, (sIndex) {
                    final sentence = quest.sentences[sIndex];
                    return _buildSentenceTile(
                      sentence: sentence,
                      index: sIndex,
                      quest: quest,
                      isDark: isDark,
                    );
                  }),
                ],
              ),
            ),

            // 5. Validation Warning Banner (if blocked)
            if (_validationWarning != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: const Color(0xFFF59E0B), size: 18.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _validationWarning!,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 6. Rationale / Explanation Card (after checked)
            if (_hasChecked) ...[
              SizedBox(height: 14.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? const Color(0xFF34D399).withOpacity(0.12)
                      : const Color(0xFFF87171).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: _isCorrect
                        ? const Color(0xFF34D399).withOpacity(0.4)
                        : const Color(0xFFF87171).withOpacity(0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isCorrect ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                          color: _isCorrect ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          size: 18.sp,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          _isCorrect ? 'EVIDENCE VERIFIED!' : 'EVIDENCE MISMATCH',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: _isCorrect ? const Color(0xFF34D399) : const Color(0xFFF87171),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      quest.explanation,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: 16.h),

            // 7. Action Button (Check Answer / Continue)
            ElevatedButton(
              onPressed: !_hasChecked ? _checkAnswer : _nextExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal500,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                !_hasChecked
                    ? 'CHECK ANSWER'
                    : (_currentIndex < _quests.length - 1
                        ? 'NEXT QUESTION →'
                        : 'FINISH PRACTICE →'),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictButton({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required TrueFalseReadingPracticeQuest quest,
    required bool isDark,
  }) {
    final isSelected = _selectedVerdict == value;
    final isCorrectChoice = quest.correctAnswer == value;

    Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);
    Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1);
    Color textColor = isDark ? Colors.white70 : Colors.black87;

    if (_hasChecked) {
      if (isCorrectChoice) {
        bgColor = color.withOpacity(0.2);
        borderColor = color;
        textColor = color;
      } else if (isSelected) {
        bgColor = const Color(0xFFF87171).withOpacity(0.2);
        borderColor = const Color(0xFFF87171);
        textColor = const Color(0xFFF87171);
      }
    } else if (isSelected) {
      bgColor = color.withOpacity(0.18);
      borderColor = color;
      textColor = color;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12.r),
      onTap: () => _chooseVerdict(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: borderColor,
            width: isSelected || (_hasChecked && isCorrectChoice) ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.sp, color: textColor),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentenceTile({
    required String sentence,
    required int index,
    required TrueFalseReadingPracticeQuest quest,
    required bool isDark,
  }) {
    final isSelected = _selectedSentenceIndex == index;
    final isCorrectEvidence = index == quest.correctSentenceIndex;

    Color bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    Color borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    Color textColor = isDark ? Colors.white : Colors.black87;

    if (_hasChecked) {
      if (isCorrectEvidence) {
        bgColor = const Color(0xFF34D399).withOpacity(0.18);
        borderColor = const Color(0xFF34D399);
      } else if (isSelected) {
        bgColor = const Color(0xFFF87171).withOpacity(0.15);
        borderColor = const Color(0xFFF87171);
      }
    } else if (isSelected) {
      bgColor = AppColors.teal500.withOpacity(0.15);
      borderColor = AppColors.teal500;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () => _selectSentence(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: borderColor,
              width: isSelected || (_hasChecked && isCorrectEvidence) ? 2.0 : 1.0,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  '[${index + 1}]',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  sentence,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: textColor,
                    height: 1.4,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (_hasChecked && isCorrectEvidence)
                Icon(Icons.verified_rounded, color: const Color(0xFF34D399), size: 18.sp),
            ],
          ),
        ),
      ),
    );
  }
}
