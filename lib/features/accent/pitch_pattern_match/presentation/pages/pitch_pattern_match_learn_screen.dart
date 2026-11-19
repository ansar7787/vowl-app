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

/// Interactive Learn Phase screen for Pitch Pattern Match ("Musical Prosody Lab").
///
/// Teaches learners to perceive and produce English speech melody, pitch contours,
/// and tonic stress emphasis (where the voice rises and falls across utterances).
class PitchPatternMatchLearnScreen extends StatefulWidget {
  final int level;

  const PitchPatternMatchLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PitchPatternMatchLearnScreen> createState() =>
      _PitchPatternMatchLearnScreenState();
}

class _PitchPatternMatchLearnScreenState
    extends State<PitchPatternMatchLearnScreen> {
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
        'assets/curriculum/accent/pitchPatternMatch_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_PITCHPATTERNMATCH_LEARN_FALLBACK_1',
          'gameType': 'pitchPatternMatch',
          'level': widget.level,
          'word': 'The bus was late.',
          'textToSpeak': 'The bus was late.',
          'pitchPatterns': [1, 1, 2, 3, 1],
          'emphasisRule':
              'In a plain statement, the highest pitch usually lands near the end, on the word that carries the main news.',
          'emotionContext': 'New information',
          'explanation':
              'The news here is how the bus turned out, so the voice climbs on LATE and then steps down. BUS is only the topic being discussed.',
          'hint':
              'Follow the voice as it moves and notice where it reaches its highest peak before dropping to finish.',
          'nativeTip':
              'English uses pitch peaks to spotlight new ideas. Falling pitch at the very end tells the listener: "I am finished speaking."',
        },
        {
          'id': 'ACC_PITCHPATTERNMATCH_LEARN_FALLBACK_2',
          'gameType': 'pitchPatternMatch',
          'level': widget.level,
          'word': 'Is the store open?',
          'textToSpeak': 'Is the store open?',
          'pitchPatterns': [1, 1, 2, 2, 3],
          'emphasisRule':
              'Questions that can be answered with yes or no typically rise at the end, inviting confirmation.',
          'emotionContext': 'Yes/No Question',
          'explanation':
              'The speaker needs only a yes or no, so the voice lifts up on OPEN as though leaving the phrase suspended.',
          'hint':
              'Notice how the last word does not drop; it stays floating high in the air.',
          'nativeTip':
              'Rising intonation at the end of a question signals openness, curiosity, and warmth in English conversation.',
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text);
      }
    } catch (_) {}
  }

  void _onNext() {
    if (_cardIndex < _cards.length - 1) {
      setState(() => _cardIndex++);
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'pitchPatternMatch',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/practice?category=accent&gameType=pitchPatternMatch&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _cards[_cardIndex.clamp(0, _cards.length - 1)];
    final word = current['word'] as String? ?? 'The bus was late.';
    final textToSpeak = current['textToSpeak'] as String? ?? word;
    final emotion = current['emotionContext'] as String? ?? 'Melodic Prosody';
    final emphasisRule = current['emphasisRule'] as String? ??
        'Pitch moves to highlight the key focus word.';
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final nativeTip = current['nativeTip'] as String? ??
        'English intonation changes meaning without changing vocabulary.';
    final pitchPatterns = (current['pitchPatterns'] as List<dynamic>? ?? [1, 2, 3, 1])
        .map((e) => (e as num).toInt())
        .toList();

    return LearnPhaseScaffold(
      title: 'Pitch Pattern Match',
      gameType: 'pitchPatternMatch',
      level: widget.level,
      actionLabel: _cardIndex < _cards.length - 1
          ? 'NEXT PATTERN'
          : 'START PRACTICE',
      onComplete: _onNext,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Stepper dots
            _buildStepperHeader(),
            SizedBox(height: 16.h),

            // 2. Target Sentence & Audio Player
            _buildTargetSentenceCard(word, textToSpeak, emotion),
            SizedBox(height: 16.h),

            // 3. Melodic Prosody Curve
            _buildMelodicCanvasCard(word, pitchPatterns),
            SizedBox(height: 16.h),

            // 4. Prosodic Rule & Mechanics
            _buildEmphasisRuleCard(emphasisRule, explanation, hint),
            SizedBox(height: 16.h),

            // 5. Native Coach Tip
            _buildCoachTipCard(nativeTip),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: AppColors.indigo500.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.indigo500.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'CONTOUR ${_cardIndex + 1} OF ${_cards.length}',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.indigo500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_cards.length, (idx) {
            final active = idx == _cardIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: active ? 22.w : 7.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: active
                    ? AppColors.indigo500
                    : AppColors.slate800.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTargetSentenceCard(
    String word,
    String textToSpeak,
    String emotion,
  ) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.indigo500.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.graphic_eq_rounded,
                        size: 14.sp, color: AppColors.teal500),
                    SizedBox(width: 4.w),
                    Text(
                      emotion.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.teal500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('learn_play_audio_button'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                icon: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AppColors.indigo500.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: AppColors.indigo500,
                    size: 20.sp,
                  ),
                ),
                onPressed: () => _playAudio(textToSpeak),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            '"$word"',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMelodicCanvasCard(
    String sentence,
    List<int> pitchPatterns,
  ) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.slate800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded,
                  size: 16.sp, color: AppColors.amber500),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'MELODIC PITCH CONTOUR',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.amber500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Custom Painted Pitch Contour
          SizedBox(
            height: 100.h,
            child: CustomPaint(
              painter: _MelodicContourPainter(
                pitchPatterns: pitchPatterns,
                primaryColor: AppColors.indigo500,
                peakColor: AppColors.amber500,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Pitch legend
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildLegendPill('Level 1: Baseline', AppColors.slate100),
              _buildLegendPill('Level 2: Mid Step', AppColors.teal500),
              _buildLegendPill('Level 3: Focal Peak', AppColors.amber500),
              _buildLegendPill('Level 4: High Rise', AppColors.rose500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6.w,
            height: 6.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmphasisRuleCard(
    String rule,
    String explanation,
    String hint,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.slate800,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 16.sp, color: AppColors.teal500),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'PROSODIC RULE',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.teal500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            rule,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
          ],
          if (hint.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.hearing_rounded,
                    size: 14.sp, color: AppColors.indigo500),
                SizedBox(width: 6.w),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontStyle: FontStyle.italic,
                      color: AppColors.indigo500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachTipCard(String tip) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.indigo500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.record_voice_over_rounded,
              color: AppColors.indigo500, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NATIVE SPEAKER PROSODY',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.indigo500,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter rendering a smooth melodic curve connecting pitch steps.
class _MelodicContourPainter extends CustomPainter {
  final List<int> pitchPatterns;
  final Color primaryColor;
  final Color peakColor;

  _MelodicContourPainter({
    required this.pitchPatterns,
    required this.primaryColor,
    required this.peakColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (pitchPatterns.isEmpty) return;

    final maxPitch = 4.0;
    final minPitch = 1.0;
    final count = pitchPatterns.length;
    final stepX = count > 1 ? size.width / (count - 1) : size.width;

    // Draw baseline guides
    final guidePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;
    for (int lvl = 1; lvl <= 4; lvl++) {
      final y = size.height -
          ((lvl - minPitch) / (maxPitch - minPitch)) * (size.height - 24) -
          12;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final points = <Offset>[];
    for (int i = 0; i < count; i++) {
      final x = count > 1 ? i * stepX : size.width / 2;
      final pVal = pitchPatterns[i].clamp(1, 4).toDouble();
      final y = size.height -
          ((pVal - minPitch) / (maxPitch - minPitch)) * (size.height - 24) -
          12;
      points.add(Offset(x, y));
    }

    // Draw smooth curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    final linePaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // Draw pitch nodes
    final maxVal = pitchPatterns.reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < points.length; i++) {
      final isPeak = pitchPatterns[i] == maxVal && maxVal > 1;
      final nodePaint = Paint()
        ..color = isPeak ? peakColor : primaryColor
        ..style = PaintingStyle.fill;

      // Glow behind peak
      if (isPeak) {
        final glowPaint = Paint()
          ..color = peakColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(points[i], 12.r, glowPaint);
      }

      canvas.drawCircle(points[i], isPeak ? 6.r : 4.5.r, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MelodicContourPainter oldDelegate) {
    return oldDelegate.pitchPatterns != pitchPatterns;
  }
}
