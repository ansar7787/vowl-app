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

/// Interactive Learn Phase screen for Listening Inference ("Auditory Subtext & Inference Lens").
///
/// Instructs learners on reading between the spoken lines, separating literal
/// statements from implicit meaning and behavioral deduction.
class ListeningInferenceLearnScreen extends StatefulWidget {
  final int level;

  const ListeningInferenceLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ListeningInferenceLearnScreen> createState() =>
      _ListeningInferenceLearnScreenState();
}

class _ListeningInferenceLearnScreenState
    extends State<ListeningInferenceLearnScreen> {
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
        'assets/curriculum/listening/listeningInference_learn_${startLevel}_$endLevel.json';

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
          'id': 'LIS_LISTENINGINFERENCE_LEARN_FALLBACK_1',
          'gameType': 'listeningInference',
          'level': widget.level,
          'concept': 'Auditory Subtext & Inference Lens',
          'textToSpeak': 'She was laughing and clapping her hands.',
          'question': 'How does she feel?',
          'literalMeaning': 'She is laughing and clapping.',
          'impliedMeaning': 'She feels happy.',
          'targetAnswer': 'Happy',
          'explanation':
              "Laughing and clapping are things people do when they feel happy or excited. The sentence never says 'happy' directly, so you infer her feeling from her actions.",
          'hint': 'Think about what laughing and clapping usually show.',
          'emoji': '😊',
          'rule':
              'Native English speakers rarely state obvious conclusions directly. When actions, physical signs, or reactions are described, connect them to human motivations and common sense.',
          'proTip':
              "Separate literal words from implied meaning. Ask yourself: 'Why would someone do or say this?'",
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
      setState(() {
        _cardIndex++;
      });
    } else {
      PhaseProgressRecorder.recordPhaseCompleted(
        context,
        gameType: 'listeningInference',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=listening&gameType=listeningInference&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];
    final textToSpeak = card['textToSpeak'] as String? ?? '';
    final question = card['question'] as String? ?? 'What can you infer?';
    final literalMeaning = card['literalMeaning'] as String? ?? textToSpeak;
    final impliedMeaning = card['impliedMeaning'] as String? ?? '';
    final targetAnswer = card['targetAnswer'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final hint = card['hint'] as String? ?? '';
    final rule = card['rule'] as String? ?? '';
    final proTip = card['proTip'] as String? ?? '';
    final emoji = card['emoji'] as String? ?? '💡';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Inference (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Inference Lens',
      gameType: 'listeningInference',
      level: widget.level,
      actionLabel: actionLabel,
      onComplete: _onNext,
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
                    'MODULE ${_cardIndex + 1} OF ${_cards.length}',
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
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(emoji, style: TextStyle(fontSize: 12.sp)),
                      SizedBox(width: 4.w),
                      Text(
                        'LEVEL ${widget.level}',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.indigo500,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),

            // Hero Audio Player Card
            Container(
              padding: EdgeInsets.all(18.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.teal500.withValues(alpha: 0.22),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.teal500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: AppColors.teal500.withValues(alpha: 0.35),
                  width: 1.5,
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
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: AppColors.teal500.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.radar_rounded,
                          color: AppColors.teal500,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AUDITORY SUBTEXT STREAM',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.teal500,
                                letterSpacing: 0.8,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              question,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),

                  // Dialogue statement
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.slate800
                          : AppColors.slate100.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate700 : AppColors.slate200,
                      ),
                    ),
                    child: Text(
                      '"$textToSpeak"',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.slate900,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(height: 14.h),

                  // Play Button
                  Center(
                    child: ElevatedButton.icon(
                      key: const Key('learn_play_audio_button'),
                      onPressed: () => _playAudio(textToSpeak),
                      icon: Icon(
                        Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      label: Text(
                        'PLAY SPOKEN AUDIO',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal500,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.teal500.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Literal vs Implied Meaning Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
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
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'LITERAL VS. IMPLIED MEANING',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),

                  // Literal
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.slate700.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isDark ? AppColors.slate800 : AppColors.slate200,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHAT WAS SAID (LITERAL)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          literalMeaning,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Implied
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.emerald500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.emerald500.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WHAT IT REALLY MEANS (INFERRED)',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.emerald500,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          impliedMeaning.isNotEmpty
                              ? impliedMeaning
                              : targetAnswer,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Auditory Subtext Strategy Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
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
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: AppColors.teal500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'INFERENCE DECODER STRATEGY',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.teal500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    rule,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        color:
                            isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (proTip.isNotEmpty) ...[
                    SizedBox(height: 12.h),
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: AppColors.emerald500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: AppColors.emerald500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            color: AppColors.emerald500,
                            size: 16.sp,
                          ),
                          SizedBox(width: 6.w),
                          Expanded(
                            child: Text(
                              'PRO-TIP: $proTip',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w600,
                                color: AppColors.emerald500,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(
                          Icons.help_outline_rounded,
                          color: isDark
                              ? AppColors.slate500
                              : AppColors.slate400,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'Hint: $hint',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.slate400
                                  : AppColors.slate600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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
