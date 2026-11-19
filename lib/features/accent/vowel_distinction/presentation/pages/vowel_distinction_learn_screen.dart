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
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_trapezoid_chart.dart';

/// Interactive Learn Phase screen for Vowel Distinction ("The Vowel Quadrilateral").
///
/// Teaches learners to distinguish subtle English vowel phonemes based on tongue height,
/// horizontal backness, lip rounding, and muscular tension.
class VowelDistinctionLearnScreen extends StatefulWidget {
  final int level;

  const VowelDistinctionLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<VowelDistinctionLearnScreen> createState() =>
      _VowelDistinctionLearnScreenState();
}

class _VowelDistinctionLearnScreenState
    extends State<VowelDistinctionLearnScreen> {
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
        'assets/curriculum/accent/vowelDistinction_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_VOWELDISTINCTION_LEARN_FALLBACK_1',
          'gameType': 'vowelDistinction',
          'level': widget.level,
          'word': 'ship',
          'textToSpeak': 'ship',
          'targetVowel': '/ɪ/',
          'contrastVowel': '/iː/',
          'vowelChart': {'x': 0.25, 'y': 0.2},
          'vowelTensionRule':
              '/ɪ/ is lax and slightly lowered; /iː/ is higher and tenser with spread lips. Quality carries the contrast, and length only reinforces it.',
          'explanation':
              "Relaxed lips and a quick vowel make 'ship'. Stretch it into a held smile and the same letters turn into 'sheep'.",
          'hint':
              "Say 'ship' and 'sheep' back to back. One needs a wide held smile, the other a quick loose vowel.",
          'nativeTip':
              'Lax vowels like /ɪ/ require relaxed facial muscles. Do not tense your tongue or pull your lips back into a smile.',
        },
        {
          'id': 'ACC_VOWELDISTINCTION_LEARN_FALLBACK_2',
          'gameType': 'vowelDistinction',
          'level': widget.level,
          'word': 'green',
          'textToSpeak': 'green',
          'targetVowel': '/iː/',
          'contrastVowel': '/ɪ/',
          'vowelChart': {'x': 0.1, 'y': 0.1},
          'vowelTensionRule':
              'Smile and press the tongue high behind the lower teeth for /iː/. For /ɪ/ let tongue and jaw relax a touch lower, lips neutral.',
          'explanation':
              "You can hold the vowel in 'green' as long as you like with spread lips, and that sustainability is typical of /iː/.",
          'hint':
              "Hold the vowel in 'green' for a full second. If it stays steady with your lips spread, you have found it.",
          'nativeTip':
              'Anchor the sides of your tongue against your upper molars to produce a crisp, pure /iː/.',
        },
        {
          'id': 'ACC_VOWELDISTINCTION_LEARN_FALLBACK_3',
          'gameType': 'vowelDistinction',
          'level': widget.level,
          'word': 'lid',
          'textToSpeak': 'lid',
          'targetVowel': '/ɪ/',
          'contrastVowel': '/iː/',
          'vowelChart': {'x': 0.25, 'y': 0.2},
          'vowelTensionRule':
              'Length misleads here: both vowels lengthen before voiced consonants. Listen for the brighter, tenser colour of /iː/ against the looser /ɪ/.',
          'explanation':
              "'Lid' needs only a small mouth movement: tongue slightly lower, lips neutral, and the /d/ closes it fast.",
          'hint':
              "'Lid' and 'lead' differ by a small mouth adjustment: one is quick and loose, the other tense.",
          'nativeTip':
              'Focus on vowel color rather than pure duration; acoustic quality is the key distinction for native listeners.',
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex % _cards.length];
    final word = card['word'] as String? ?? 'ship';
    final textToSpeak = card['textToSpeak'] as String? ?? word;
    final targetVowel = card['targetVowel'] as String? ?? '/ɪ/';
    final contrastVowel = card['contrastVowel'] as String? ?? '/iː/';
    final vowelTensionRule = card['vowelTensionRule'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final nativeTip = card['nativeTip'] as String? ??
        'Focus on tongue height and lip shape to master vowel color.';
    final vowelChart = (card['vowelChart'] as Map<String, dynamic>?) ??
        {'x': 0.25, 'y': 0.2};

    return LearnPhaseScaffold(
      title: 'The Vowel Quadrilateral',
      gameType: 'vowelDistinction',
      level: widget.level,
      actionLabel: 'START PRACTICE',
      onComplete: () {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'vowelDistinction',
          level: widget.level,
          phase: 'learn',
        );
        if (mounted) {
          try {
            context.pushReplacement(
              '/practice?category=accent&gameType=vowelDistinction&level=${widget.level}',
            );
          } catch (_) {}
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper Header
            _buildStepperHeader(),
            SizedBox(height: 16.h),

            // Target Word & Vowel Hero Card
            _buildTargetCard(word, textToSpeak, targetVowel, contrastVowel),
            SizedBox(height: 20.h),

            // Acoustic Vowel Chart (Quadrilateral)
            _buildChartCard(vowelChart, isDark),
            SizedBox(height: 20.h),

            // Vowel Tension & Articulation Rule Card
            _buildTensionRuleCard(vowelTensionRule, explanation),
            SizedBox(height: 20.h),

            // Articulation Dimensions Matrix
            _buildArticulationMatrix(),
            SizedBox(height: 20.h),

            // Coach Advice Card
            _buildCoachCard(nativeTip),
            SizedBox(height: 28.h),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.teal500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.25),
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.w,
        runSpacing: 6.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 20.sp,
                color: AppColors.teal500,
              ),
              SizedBox(width: 8.w),
              Text(
                'SOUND ${_cardIndex + 1} OF ${_cards.length}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.teal500,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          if (_cards.length > 1)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left_rounded,
                    size: 24.sp,
                    color: _cardIndex > 0
                        ? AppColors.teal500
                        : AppColors.slate400,
                  ),
                  onPressed: _cardIndex > 0
                      ? () => setState(() => _cardIndex--)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                SizedBox(width: 12.w),
                IconButton(
                  key: const Key('vowel_learn_next_card'),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 24.sp,
                    color: _cardIndex < _cards.length - 1
                        ? AppColors.teal500
                        : AppColors.slate400,
                  ),
                  onPressed: _cardIndex < _cards.length - 1
                      ? () => setState(() => _cardIndex++)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTargetCard(String word, String textToSpeak, String targetVowel,
      String contrastVowel) {
    return Container(
      key: const Key('vowel_learn_target_card'),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.teal500.withValues(alpha: 0.12),
            AppColors.indigo500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.teal500.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'TARGET WORD',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('vowel_learn_listen_button'),
                onPressed: () => _playAudio(textToSpeak),
                icon: Icon(
                  Icons.volume_up_rounded,
                  size: 18.sp,
                  color: AppColors.white,
                ),
                label: Text(
                  'Hear Word',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal500,
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '“$word”',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 12.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.teal500),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Target: ',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.teal500,
                      ),
                    ),
                    Text(
                      targetVowel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Courier',
                        color: AppColors.teal500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.slate300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Contrast: ',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate600,
                      ),
                    ),
                    Text(
                      contrastVowel,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Courier',
                        color: AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(Map<String, dynamic> vowelChart, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.slate200),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.grid_on_rounded,
                size: 20.sp,
                color: AppColors.teal500,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'VOWEL QUADRILATERAL POSITION',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.slate800,
                    letterSpacing: 0.6,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          VowelTrapezoidChart(
            vowelChart: vowelChart,
            color: AppColors.teal500,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildTensionRuleCard(String rule, String explanation) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.psychology_alt_rounded,
                  size: 20.sp,
                  color: AppColors.indigo500,
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  'Vowel Tension & Articulation',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.slate900,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (rule.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              rule,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.indigo500,
                height: 1.4,
              ),
            ),
          ],
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Text(
              explanation,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppColors.slate700,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticulationMatrix() {
    final dimensions = [
      {
        'title': '1. Tongue Height',
        'desc': 'High (Close) vs Mid vs Low (Open). Determines vowel frequency formant 1 (F1).',
        'icon': Icons.height_rounded,
      },
      {
        'title': '2. Tongue Backness',
        'desc': 'Front (/iː/, /ɪ/) vs Central (/ə/, /ɜː/) vs Back (/uː/, /ɑː/). Governs formant 2 (F2).',
        'icon': Icons.swap_horiz_rounded,
      },
      {
        'title': '3. Muscular Tension',
        'desc': 'Tense vowels require held muscle activation. Lax vowels are short, relaxed, and centralized.',
        'icon': Icons.fitness_center_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'THE THREE ACOUSTIC DIMENSIONS',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.teal500,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          ...dimensions.map((d) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        d['icon'] as IconData,
                        size: 16.sp,
                        color: AppColors.teal500,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d['title'] as String,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            d['desc'] as String,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: AppColors.slate600,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCoachCard(String tip) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.amber500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.amber500.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_rounded,
            size: 22.sp,
            color: AppColors.amber500,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHONETIC COACH TIP',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amber500,
                    letterSpacing: 0.6,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  tip,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: AppColors.slate800,
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
