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

/// Interactive Learn Phase screen for Audio True/False ("Distractor & Trap Alert").
///
/// Instructs learners on identifying spoken polarity reversals, restrictive adverbs
/// (such as hardly, scarcely, barely), and entity distractor swaps in spoken assertions.
class AudioTrueFalseLearnScreen extends StatefulWidget {
  final int level;

  const AudioTrueFalseLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<AudioTrueFalseLearnScreen> createState() =>
      _AudioTrueFalseLearnScreenState();
}

class _AudioTrueFalseLearnScreenState extends State<AudioTrueFalseLearnScreen> {
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
        'assets/curriculum/listening/audioTrueFalse_learn_${startLevel}_$endLevel.json';

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
          'id': 'LIS_AUDIOTRUEFALSE_LEARN_FALLBACK_1',
          'textToSpeak': 'My sister plays the guitar after dinner.',
          'statement': 'My brother plays the guitar after dinner.',
          'correctAnswer': 'false',
          'evidenceQuote': 'My sister plays the guitar',
          'trapType': 'Entity & Detail Swap',
          'trapAlert':
              'The speaker clearly said "sister", but the written assertion swapped it with "brother". Plausible family noun substitutions are a classic listening distractor.',
          'explanation':
              'It is the speaker\'s sister who plays. A brother is a different person, rendering the claim false.',
          'hint': 'Think about which family member is playing.',
          'rule':
              'Anchor your judgment directly to the exact spoken noun. Do not assume generalized equivalences across family members or objects.',
          'proTip':
              'Read the statement before the audio plays to lock in the key noun or verb being asserted.',
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

  void _onComplete() {
    if (_cardIndex < _cards.length - 1) {
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'audioTrueFalse',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=listening&gameType=audioTrueFalse&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard = _cards[_cardIndex];
    final textToSpeak = currentCard['textToSpeak'] as String? ?? '';
    final statement = currentCard['statement'] as String? ?? '';
    final correctAnswer =
        (currentCard['correctAnswer'] as String? ?? 'true').toLowerCase();
    final isTrue = correctAnswer == 'true' ||
        correctAnswer == '1' ||
        correctAnswer == 'yes';
    final evidenceQuote = currentCard['evidenceQuote'] as String? ?? '';
    final trapType =
        currentCard['trapType'] as String? ?? 'Distractor Alert';
    final trapAlert = currentCard['trapAlert'] as String? ?? '';
    final explanation = currentCard['explanation'] as String? ?? '';
    final rule = currentCard['rule'] as String? ??
        'Anchor your evaluation to what was literally spoken.';
    final proTip = currentCard['proTip'] as String? ??
        'Read the statement first so you know which specific detail to listen for.';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Sample (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Distractor & Trap Alert',
      gameType: 'audioTrueFalse',
      level: widget.level,
      actionLabel: actionLabel,
      onComplete: _onComplete,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Badges
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
                    color: AppColors.teal500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.teal500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'AUDIO SAMPLE ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.teal500,
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

            // Audio Player & Spoken Text Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.teal500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.teal500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.headphones_rounded,
                        color: AppColors.teal500,
                        size: 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SPOKEN AUDIO STREAM',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: AppColors.teal500,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        key: const Key('audio_true_false_learn_audio_btn'),
                        onPressed: () => _playAudio(textToSpeak),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.teal500,
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          elevation: 0,
                        ),
                        icon: Icon(
                          Icons.volume_up_rounded,
                          size: 16.sp,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Play Audio',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate800.withValues(alpha: 0.6)
                          : AppColors.slate100,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      textToSpeak.isNotEmpty ? textToSpeak : 'Listen closely...',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.slate900,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Evaluated Statement Card
            Container(
              key: const Key('audio_true_false_learn_statement_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.5)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isTrue
                      ? AppColors.emerald500.withValues(alpha: 0.4)
                      : AppColors.rose500.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8.w,
                    runSpacing: 6.h,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fact_check_rounded,
                            size: 16.sp,
                            color: AppColors.slate400,
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            'CLAIM UNDER EVALUATION',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: isTrue
                              ? AppColors.emerald500.withValues(alpha: 0.15)
                              : AppColors.rose500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(
                            color: isTrue
                                ? AppColors.emerald500
                                : AppColors.rose500,
                          ),
                        ),
                        child: Text(
                          isTrue ? 'VERDICT: TRUE' : 'VERDICT: FALSE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: isTrue
                                ? AppColors.emerald500
                                : AppColors.rose500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    statement,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Trap Alert & Evidence Breakdown Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.amber500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.radar_rounded,
                          size: 16.sp,
                          color: AppColors.amber500,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'TRAP RADAR: $trapType',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.amber500,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  if (evidenceQuote.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.teal500.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.format_quote_rounded,
                            size: 16.sp,
                            color: AppColors.teal500,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 13.sp,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate800,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'Spoken Proof: ',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.teal500,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '"$evidenceQuote"',
                                    style: const TextStyle(
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10.h),
                  ],
                  Text(
                    trapAlert.isNotEmpty ? trapAlert : explanation,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      color: isDark ? AppColors.slate300 : AppColors.slate700,
                      height: 1.4,
                    ),
                  ),
                  if (explanation.isNotEmpty && trapAlert.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.slate400 : AppColors.slate600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Rule & Pro Tip Card
            Container(
              key: const Key('audio_true_false_learn_rule_card'),
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.slate800.withValues(alpha: 0.6)
                    : AppColors.slate50,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        size: 16.sp,
                        color: AppColors.indigo500,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'LISTENING STRATEGY RULE',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: AppColors.indigo500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    rule,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate800,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💡 Pro Tip: ',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.amber500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          proTip,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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
}
