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

/// Interactive Learn Phase screen for Speed Variance ("Tempo Metronome Lab").
///
/// Teaches learners to perceive and modulate conversational speech tempo,
/// understanding why native speakers accelerate through routine function words
/// and decelerate on critical figures, warnings, and empathetic reassurance.
class SpeedVarianceLearnScreen extends StatefulWidget {
  final int level;

  const SpeedVarianceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SpeedVarianceLearnScreen> createState() =>
      _SpeedVarianceLearnScreenState();
}

class _SpeedVarianceLearnScreenState extends State<SpeedVarianceLearnScreen> {
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
        'assets/curriculum/accent/speedVariance_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_SPEEDVARIANCE_LEARN_FALLBACK_1',
          'gameType': 'speedVariance',
          'level': widget.level,
          'word': 'Look out, that shelf is falling!',
          'textToSpeak': 'Look out, that shelf is falling!',
          'targetSpeed': 1.5,
          'tempoCategory': 'Accelerated Tempo (Brisk / High-Energy)',
          'pacingRule':
              'Accelerated Pacing: Sudden danger pushes speech faster because there is no time for slow delivery.',
          'explanation':
              'When something is about to fall, people use short, quick words. Slow speech would arrive after the shelf does.',
          'hint': 'Is there any time to spare in this urgent moment?',
          'nativeTip':
              'Urgent warnings, excitement, and routine phrases naturally trigger faster speech cadence in English.',
        },
        {
          'id': 'ACC_SPEEDVARIANCE_LEARN_FALLBACK_2',
          'gameType': 'speedVariance',
          'level': widget.level,
          'word': "Take your time, there's no pressure.",
          'textToSpeak': "Take your time, there's no pressure.",
          'targetSpeed': 0.7,
          'tempoCategory': 'Decelerated Tempo (Deliberate / Reassuring)',
          'pacingRule':
              'Decelerated Pacing: Calm reassurance is delivered at an easy, unhurried pace.',
          'explanation':
              'Telling someone to relax works best when your voice is relaxed. A fast delivery would add the very pressure you are taking away.',
          'hint': 'What feeling is the speaker trying to give the listener?',
          'nativeTip':
              'Empathy, important instructions, and delicate numbers must be stretched out to allow the listener time to absorb.',
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
        gameType: 'speedVariance',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/practice?category=accent&gameType=speedVariance&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _cards[_cardIndex.clamp(0, _cards.length - 1)];
    final word = current['word'] as String? ?? 'Look out, that shelf is falling!';
    final textToSpeak = current['textToSpeak'] as String? ?? word;
    final tempoCategory = current['tempoCategory'] as String? ?? 'Accelerated Tempo';
    final targetSpeed = (current['targetSpeed'] as num?)?.toDouble() ?? 1.2;
    final pacingRule = current['pacingRule'] as String? ??
        'Adjust pacing to match communicative intention.';
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final nativeTip = current['nativeTip'] as String? ??
        'Varying speed between function and content words creates English rhythm.';

    return LearnPhaseScaffold(
      title: 'Speed Variance',
      gameType: 'speedVariance',
      level: widget.level,
      actionLabel: _cardIndex < _cards.length - 1
          ? 'NEXT TEMPO'
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

            // 2. Target Utterance & Audio Player
            _buildTargetUtteranceCard(word, textToSpeak, tempoCategory, targetSpeed),
            SizedBox(height: 16.h),

            // 3. Tempo Metronome & Speedometer
            _buildTempoMetronomeCard(targetSpeed),
            SizedBox(height: 16.h),

            // 4. Pacing Rule & Mechanics
            _buildPacingRuleCard(pacingRule, explanation, hint),
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
            'PACING ${_cardIndex + 1} OF ${_cards.length}',
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

  Widget _buildTargetUtteranceCard(
    String word,
    String textToSpeak,
    String tempoCategory,
    double targetSpeed,
  ) {
    final isAccelerated = targetSpeed >= 1.05;
    final badgeColor = isAccelerated ? AppColors.amber500 : AppColors.teal500;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: badgeColor.withValues(alpha: 0.08),
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
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAccelerated ? Icons.speed_rounded : Icons.timelapse_rounded,
                      size: 14.sp,
                      color: badgeColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      '${targetSpeed.toStringAsFixed(1)}x SPEED',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
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
          SizedBox(height: 8.h),
          Text(
            tempoCategory,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: badgeColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTempoMetronomeCard(double targetSpeed) {
    final isAccelerated = targetSpeed >= 1.05;

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.slate800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.av_timer_rounded, size: 16.sp, color: AppColors.amber500),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'TEMPO METRONOME PACING',
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

          // Visual Speed Gauge
          SizedBox(
            height: 48.h,
            child: CustomPaint(
              painter: _SpeedGaugePainter(
                speed: targetSpeed,
                accentColor: isAccelerated ? AppColors.amber500 : AppColors.teal500,
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Tempo Zones Explanation
          Wrap(
            alignment: WrapAlignment.spaceAround,
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _buildZoneIndicator(
                'Deliberate (0.6x - 0.8x)',
                'Reassurance & Figures',
                AppColors.teal500,
                !isAccelerated,
              ),
              _buildZoneIndicator(
                'Brisk (1.2x - 1.6x)',
                'Urgency & Routine',
                AppColors.amber500,
                isAccelerated,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildZoneIndicator(
    String label,
    String description,
    Color color,
    bool isActive,
  ) {
    return Container(
      constraints: BoxConstraints(maxWidth: 155.w),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isActive ? color.withValues(alpha: 0.15) : AppColors.slate800.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isActive ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
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
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: isActive ? color : Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPacingRuleCard(
    String rule,
    String explanation,
    String hint,
  ) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.slate800),
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
                  'PACING PRINCIPLE',
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
                  'NATIVE SPEAKER RHYTHM',
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

/// Custom painter rendering a clean horizontal speed gauge / slider track.
class _SpeedGaugePainter extends CustomPainter {
  final double speed;
  final Color accentColor;

  _SpeedGaugePainter({
    required this.speed,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = Colors.white12
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;
    canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), trackPaint);

    // Speed range: 0.5x to 2.0x
    final minSpeed = 0.5;
    final maxSpeed = 2.0;
    final clamped = speed.clamp(minSpeed, maxSpeed);
    final ratio = (clamped - minSpeed) / (maxSpeed - minSpeed);
    final knobX = 12 + ratio * (size.width - 24);

    // Baseline marker at 1.0x
    final baselineRatio = (1.0 - minSpeed) / (maxSpeed - minSpeed);
    final baselineX = 12 + baselineRatio * (size.width - 24);
    final basePaint = Paint()
      ..color = Colors.white38
      ..strokeWidth = 2.0;
    canvas.drawLine(Offset(baselineX, y - 8), Offset(baselineX, y + 8), basePaint);

    // Active speed line from baseline to current speed
    final activePaint = Paint()
      ..color = accentColor
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(baselineX, y), Offset(knobX, y), activePaint);

    // Glowing knob at current speed
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(knobX, y), 12.r, glowPaint);

    final knobPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(knobX, y), 7.r, knobPaint);
  }

  @override
  bool shouldRepaint(covariant _SpeedGaugePainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.accentColor != accentColor;
  }
}
