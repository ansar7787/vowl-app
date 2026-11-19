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

/// Interactive Learn Phase screen for Dialect Drill ("Global Accent Atlas").
///
/// Teaches learners to recognize international pronunciation varieties,
/// rhoticity rules (dropping vs sounding /r/), the Bath-Trap vowel split,
/// and regional lexical differences across UK, US, Australian, and global Englishes.
class DialectDrillLearnScreen extends StatefulWidget {
  final int level;

  const DialectDrillLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<DialectDrillLearnScreen> createState() =>
      _DialectDrillLearnScreenState();
}

class _DialectDrillLearnScreenState extends State<DialectDrillLearnScreen> {
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
        'assets/curriculum/accent/dialectDrill_learn_${startLevel}_$endLevel.json';

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
          'id': 'dialectDrill_learn_fallback_1',
          'gameType': 'dialectDrill',
          'level': widget.level,
          'word': "Can't",
          'textToSpeak': "Can't",
          'dialectRegion': 'United Kingdom',
          'dialectNote':
              "Many Southern British speakers use the long open vowel /ɑː/ in can't ('KAHNT'). Most General American speakers use the short /æ/ ('KANT').",
          'explanation':
              "Same word, different vowel. Southern British stretches the sound with a relaxed, deep jaw drop, while General American keeps it flat and forward like in 'cat'.",
          'hint':
              "Say both aloud and feel the jaw. One vowel is short and flat, like 'cat'. The other is open and deep, like 'father'.",
          'nativeTip':
              'The Bath-Trap split is a core distinguishing marker. British RP uses broad /ɑː/ before /nt/, /ns/, /st/, /f/, and /θ/, while General American uses /æ/.',
        },
        {
          'id': 'dialectDrill_learn_fallback_2',
          'gameType': 'dialectDrill',
          'level': widget.level,
          'word': 'Car',
          'textToSpeak': 'Car',
          'dialectRegion': 'United States',
          'dialectNote':
              "General American is rhotic (the /r/ is strongly pronounced after vowels). Southern British English and Australian are non-rhotic (the /r/ is dropped unless followed by a vowel).",
          'explanation':
              "An American says 'KAR' with the tongue curling back or bunching. A British RP speaker says 'KAH', lengthening the vowel without any consonant /r/ friction.",
          'hint':
              'Listen for whether the speaker curls their tongue to produce an /r/ or leaves the vowel floating smoothly.',
          'nativeTip':
              'Rhoticity divides the English-speaking world. Rhotic accents include US, Canada, Scotland, and Ireland. Non-rhotic accents include England, Australia, New Zealand, and South Africa.',
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
        gameType: 'dialectDrill',
        level: widget.level,
        phase: 'learn',
      );
      try {
        context.pushReplacement(
          '/practice?category=accent&gameType=dialectDrill&level=${widget.level}',
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _cards[_cardIndex.clamp(0, _cards.length - 1)];
    final word = current['word'] as String? ?? "Can't";
    final textToSpeak = current['textToSpeak'] as String? ?? word;
    final region = current['dialectRegion'] as String? ?? 'International English';
    final note = current['dialectNote'] as String? ?? '';
    final explanation = current['explanation'] as String? ?? '';
    final hint = current['hint'] as String? ?? '';
    final nativeTip = current['nativeTip'] as String? ??
        'Understanding rhoticity and vowel shifts unlocks global English comprehension.';

    return LearnPhaseScaffold(
      title: 'Dialect Drill',
      gameType: 'dialectDrill',
      level: widget.level,
      actionLabel: _cardIndex < _cards.length - 1
          ? 'NEXT VARIETY'
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

            // 2. Target Word & Region Card
            _buildTargetCard(word, textToSpeak, region),
            SizedBox(height: 16.h),

            // 3. Dialect Phonetic Contrast Card
            _buildPhoneticContrastCard(word, region, note),
            SizedBox(height: 16.h),

            // 4. Dialect Explanation & Linguistic Rule
            _buildLinguisticRuleCard(explanation, hint),
            SizedBox(height: 16.h),

            // 5. Global Accent Atlas Coaching Tip
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
            'DIALECT ${_cardIndex + 1} OF ${_cards.length}',
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

  Widget _buildTargetCard(
    String word,
    String textToSpeak,
    String region,
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
                    Icon(
                      Icons.public_rounded,
                      size: 14.sp,
                      color: AppColors.teal500,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      region.toUpperCase(),
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
              fontSize: 24.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneticContrastCard(
    String word,
    String region,
    String note,
  ) {
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
              Icon(Icons.compare_arrows_rounded,
                  size: 16.sp, color: AppColors.amber500),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  'REGIONAL PHONETIC VARIATION',
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
          SizedBox(height: 12.h),
          if (note.isNotEmpty)
            Text(
              note,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinguisticRuleCard(
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
                  'DIALECT MECHANICS',
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
          if (explanation.isNotEmpty) ...[
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
                  'GLOBAL ACCENT ATLAS',
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
