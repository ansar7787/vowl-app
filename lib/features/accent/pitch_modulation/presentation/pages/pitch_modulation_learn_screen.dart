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

/// Interactive Learn Phase screen for Pitch Modulation ("Vocal Energy & Dynamics Lab").
///
/// Teaches learners how vocal pitch range, melodic glides, and contour inflections
/// convey emotion, attitude, and conversational engagement in natural English.
class PitchModulationLearnScreen extends StatefulWidget {
  final int level;

  const PitchModulationLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<PitchModulationLearnScreen> createState() =>
      _PitchModulationLearnScreenState();
}

class _PitchModulationLearnScreenState
    extends State<PitchModulationLearnScreen> {
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
        'assets/curriculum/accent/pitchModulation_learn_${startLevel}_$endLevel.json';

    try {
      final jsonStr = await rootBundle.loadString(assetPath);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final rawQuests =
          (data['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

      final levelCards = rawQuests.where((q) {
        final id = q['id'] as String? ?? '';
        final match = RegExp(r'_l(\d+)_', caseSensitive: false).firstMatch(id);
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
          'id': 'pitchModulation_learn_fallback_1',
          'gameType': 'pitchModulation',
          'level': widget.level,
          'word': 'Thank you.',
          'textToSpeak': 'Thank you.',
          'modulationPattern':
              "Falling: pitch peaks early on 'thank' and settles low by the end of 'you'.",
          'meaningShift':
              'A dropping finish sounds complete and settled; a lifted finish would leave the phrase feeling unfinished or questioning.',
          'explanation':
              "In a plain thank-you the pitch peaks on 'thank' and then settles down through 'you'. That drop gives the reply a finished, closed feel.",
          'hint':
              'Compare the very first syllable with the very last one. Which sits higher?',
          'nativeTip':
              'Falling pitch conveys finality, certainty, and sincerity. Dropping your pitch at the end of statements prevents you from sounding unsure or apologetic.',
        },
        {
          'id': 'pitchModulation_learn_fallback_2',
          'gameType': 'pitchModulation',
          'level': widget.level,
          'word': 'Are you coming?',
          'textToSpeak': 'Are you coming?',
          'modulationPattern':
              'Rising: pitch climbs through the last stressed syllable and stays high.',
          'meaningShift':
              'A lifted ending asks and waits for a reply; a sinking ending would sound like a statement of something already known.',
          'explanation':
              "Yes/no questions climb through the last stressed syllable, 'com-', and stay up. That upward finish tells the listener an answer is wanted.",
          'hint':
              "Follow 'coming' from its first sound to its last note.",
          'nativeTip':
              'Rising pitch opens conversational space. Lifting pitch invites dialogue and collaboration, whereas a flat ending creates an emotional barrier.',
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
        gameType: 'pitchModulation',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/practice?category=accent&gameType=pitchModulation&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _cards[_cardIndex.clamp(0, _cards.length - 1)];
    final word = current['word'] as String? ?? 'Thank you.';
    final textToSpeak = current['textToSpeak'] as String? ?? word;
    final pattern = current['modulationPattern'] as String? ?? 'Dynamic Pitch';
    final meaning = current['meaningShift'] as String? ?? '';
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final nativeTip = current['nativeTip'] as String? ??
        'Pitch modulation brings vitality and confidence to spoken English.';

    return LearnPhaseScaffold(
      title: 'Pitch Modulation',
      gameType: 'pitchModulation',
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
            // 1. Stepper dots header
            _buildStepperHeader(),
            SizedBox(height: 16.h),

            // 2. Utterance & Audio Card
            _buildTargetCard(word, textToSpeak),
            SizedBox(height: 16.h),

            // 3. Modulation Contour & Attitude Card
            _buildContourCard(pattern, meaning),
            SizedBox(height: 16.h),

            // 4. Acoustic Mechanism & Perception Hint
            _buildMechanismCard(explanation, hint),
            SizedBox(height: 16.h),

            // 5. Vocal Energy Coach Tip
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
            color: AppColors.teal500.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.teal500.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            'VOCAL ENERGY LAB',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: AppColors.teal500,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_cards.length, (index) {
            final isActive = index == _cardIndex;
            return Container(
              margin: EdgeInsets.symmetric(horizontal: 3.w),
              width: isActive ? 20.w : 6.w,
              height: 6.h,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.teal500
                    : AppColors.slate800.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildTargetCard(String word, String textToSpeak) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.25),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal500.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.teal500,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Spoken Utterance Pitch',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal500,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Center(
            child: Text(
              '“$word”',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          Center(
            child: InkWell(
              key: const Key('learn_play_audio_button'),
              onTap: () => _playAudio(textToSpeak),
              borderRadius: BorderRadius.circular(24.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppColors.teal500.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: AppColors.teal500,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'Listen Pitch Motion',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContourCard(String pattern, String meaning) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: AppColors.indigo500,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'MODULATION PATTERN & MEANING',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.indigo500,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: AppColors.indigo500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: AppColors.indigo500.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              pattern,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
          if (meaning.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              meaning,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.slate100.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMechanismCard(String explanation, String hint) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.slate800.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                color: AppColors.amber500,
                size: 18.sp,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'PERCEPTUAL MECHANISM',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.amber500,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 12.sp,
                color: AppColors.slate100.withValues(alpha: 0.9),
                height: 1.4,
              ),
            ),
          ],
          if (hint.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.amber500,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      hint,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.slate100,
                        fontStyle: FontStyle.italic,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCoachTipCard(String nativeTip) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.emerald500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.emerald500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: AppColors.emerald500.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.emerald500,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COACHING TIP',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald500,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  nativeTip,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.slate100.withValues(alpha: 0.9),
                    height: 1.4,
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
