import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/phase_progress_recorder.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';

/// Interactive Learn Phase screen for Daily Expression ("Conversational Discovery").
///
/// Instructs learners on colloquial idioms, everyday formulas, situational appropriateness,
/// conversational nuance, and authentic intonation.
class DailyExpressionLearnScreen extends StatefulWidget {
  final int level;

  const DailyExpressionLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<DailyExpressionLearnScreen> createState() =>
      _DailyExpressionLearnScreenState();
}

class _DailyExpressionLearnScreenState
    extends State<DailyExpressionLearnScreen> {
  int _cardIndex = 0;
  late List<Map<String, dynamic>> _cards;

  @override
  void initState() {
    super.initState();
    _cards = _fallbackCards;
    _loadCurriculum();
  }

  Future<void> _loadCurriculum() async {
    final batchIndex = ((widget.level - 1) ~/ 10) + 1;
    final startLevel = (batchIndex - 1) * 10 + 1;
    final endLevel = batchIndex * 10;
    final assetPath =
        'assets/curriculum/speaking/dailyExpression_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_L(\d+)_').firstMatch(id);
        if (match != null) {
          return int.parse(match.group(1)!) == widget.level;
        }
        return false;
      }).toList();

      if (mounted && levelCards.isNotEmpty) {
        setState(() {
          _cards = levelCards;
        });
      }
    } catch (_) {
      // Retain fallback cards on asset failure
    }
  }

  List<Map<String, dynamic>> get _fallbackCards => [
        {
          'id': 'SPK_DAILYEXPRESSION_LEARN_FALLBACK_1',
          'expression': 'Nice to meet you',
          'meaning': 'A polite greeting for the first time you meet someone.',
          'situationExample':
              'A coworker walks you over to the new teammate who just joined your floor.',
          'sampleUsage': 'Hi, I\'m Daniel. It\'s really nice to meet you.',
          'explanation':
              'The standard, friendly reply to a first introduction. It\'s neutral, so it works with anyone, and it usually comes with a smile or a handshake.',
          'instruction': 'Say it warmly, as if you\'re shaking hands.',
          'textToSpeak': 'Nice to meet you',
          'hint': 'What you say right after a stranger is introduced to you.',
        },
        {
          'id': 'SPK_DAILYEXPRESSION_LEARN_FALLBACK_2',
          'expression': 'How\'s it going?',
          'meaning': 'A casual way to ask how someone is doing.',
          'situationExample':
              'You meet your neighbor by the elevator on a Monday morning.',
          'sampleUsage':
              'Hey Sam! How\'s it going? I haven\'t seen you all week.',
          'explanation':
              'It works as a casual hello more than a real question. A short answer like "Pretty good, you?" is all people expect.',
          'instruction': 'Ask it in a relaxed, friendly voice.',
          'textToSpeak': 'How\'s it going?',
          'hint': 'A relaxed question you ask someone you already know.',
        },
      ];

  void _playAudio(String text, {double speed = 0.5}) {
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: speed);
      }
    } catch (_) {}
  }

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'dailyExpression',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=dailyExpression&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final expression = card['expression'] as String? ?? 'Daily Expression';
    final meaning = card['meaning'] as String? ?? '';
    final situationExample = card['situationExample'] as String? ?? '';
    final sampleUsage = card['sampleUsage'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final instruction = card['instruction'] as String? ??
        'Practice natural pronunciation, cadence, and intonation.';
    final hint = card['hint'] as String? ?? '';
    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Daily Expression Discovery',
      gameType: 'dailyExpression',
      level: widget.level,
      actionLabel: isLast ? 'Complete & Start Practice' : 'Next Expression',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.w,
              runSpacing: 6.h,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'EXPRESSION DISCOVERY ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: AppColors.amber500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.amber500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'LEVEL ${widget.level}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.amber500,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Hero Expression Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.indigo500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.indigo500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.forum_rounded,
                          color: AppColors.indigo500,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'DAILY EXPRESSION',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    expression,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      letterSpacing: 0.3,
                      height: 1.3,
                    ),
                  ),
                  if (meaning.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      meaning,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.35,
                      ),
                    ),
                  ],
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo500,
                        side: BorderSide(
                          color: AppColors.indigo500.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => _playAudio(expression),
                      icon: Icon(Icons.volume_up_rounded, size: 18.sp),
                      label: Text(
                        'Listen Expression',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Situational Context Card
            if (situationExample.isNotEmpty)
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.place_rounded,
                          color: AppColors.amber500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'SITUATIONAL CONTEXT & SETTING',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.amber500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      situationExample,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.slate200 : AppColors.slate800,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            if (situationExample.isNotEmpty) SizedBox(height: 12.h),

            // Conversational Usage Sample Card
            if (sampleUsage.isNotEmpty)
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.emerald500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'CONVERSATIONAL USAGE SAMPLE',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.emerald500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '"$sampleUsage"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.slate100 : AppColors.slate900,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.emerald500,
                          side: BorderSide(
                            color: AppColors.emerald500.withValues(alpha: 0.5),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        onPressed: () => _playAudio(sampleUsage),
                        icon: Icon(Icons.volume_up_rounded, size: 16.sp),
                        label: Text(
                          'Listen Sample Sentence',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (sampleUsage.isNotEmpty) SizedBox(height: 12.h),

            // Cultural Nuance & Explanation Card
            if (explanation.isNotEmpty)
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'CULTURAL NUANCE & USAGE EXPLANATION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            if (explanation.isNotEmpty) SizedBox(height: 12.h),

            // Speaking Advice & Tone Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.indigo500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'SPEAKING ADVICE & TONE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      'Hint: $hint',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.indigo400
                            : const Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
