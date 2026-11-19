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

/// Interactive Learn Phase screen for Detail Spotlight ("Acoustic Detail Spotlight").
///
/// Instructs learners on selective auditory attention, isolating specific target
/// nouns, quantities, locations, or actors while filtering acoustic fluff.
class DetailSpotlightLearnScreen extends StatefulWidget {
  final int level;

  const DetailSpotlightLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<DetailSpotlightLearnScreen> createState() =>
      _DetailSpotlightLearnScreenState();
}

class _DetailSpotlightLearnScreenState
    extends State<DetailSpotlightLearnScreen> {
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
        'assets/curriculum/listening/detailSpotlight_learn_${startLevel}_$endLevel.json';

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
          'id': 'LIS_DETAILSPOTLIGHT_LEARN_FALLBACK_1',
          'gameType': 'detailSpotlight',
          'level': widget.level,
          'concept': 'Acoustic Detail Spotlight',
          'textToSpeak': 'Grandpa is making tea in the kitchen.',
          'targetDetail': 'grandpa',
          'detailCategory': 'Person',
          'instruction': 'Catch who is making the tea.',
          'explanation':
              'Grandpa is correct. The sentence starts with the person and then tells you what he is doing: making tea.',
          'hint':
              'In a short sentence, the person usually comes first. Hold on to that first word.',
          'emoji': '☕',
          'rule':
              "Selective auditory attention requires anchoring to prepositions ('in the...', 'at...'), numbers, or subject pronouns. Tune your ear to the specific category before listening.",
          'proTip':
              'Focus on the target category question word (Where = place noun; Who = person; How many = number). Ignore irrelevant descriptive words.',
          'options': ['grandpa', 'brother', 'neighbor', 'uncle'],
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
        gameType: 'detailSpotlight',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=listening&gameType=detailSpotlight&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];
    final textToSpeak = card['textToSpeak'] as String? ?? '';
    final targetDetail = card['targetDetail'] as String? ?? '';
    final detailCategory = card['detailCategory'] as String? ?? 'Detail';
    final instruction = card['instruction'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final hint = card['hint'] as String? ?? '';
    final rule = card['rule'] as String? ?? '';
    final proTip = card['proTip'] as String? ?? '';
    final emoji = card['emoji'] as String? ?? '🔍';

    final actionLabel = _cardIndex == _cards.length - 1
        ? 'Start Practice'
        : 'Next Spotlight (${_cardIndex + 1}/${_cards.length})';

    return LearnPhaseScaffold(
      title: 'Detail Spotlight',
      gameType: 'detailSpotlight',
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
                          Icons.highlight_rounded,
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
                              'ACOUSTIC SPOTLIGHT STREAM',
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
                              instruction.isNotEmpty
                                  ? instruction
                                  : 'Listen closely for the target detail',
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

                  // Dialogue sentence
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

            // Target Detail & Category Card
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
                        Icons.filter_center_focus_rounded,
                        color: AppColors.indigo500,
                        size: 20.sp,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'SPOTLIGHT DETAIL BREAKDOWN',
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

                  // Detail Pill
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.r),
                    decoration: BoxDecoration(
                      color: AppColors.indigo500.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.indigo500.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            detailCategory.toUpperCase(),
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            targetDetail.isNotEmpty ? targetDetail : 'Detail',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.slate900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Selective Auditory Attention Strategy
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
                          'AUDITORY FOCUS STRATEGY',
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
