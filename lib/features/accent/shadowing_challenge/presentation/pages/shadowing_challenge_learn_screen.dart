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

/// Interactive Learn Phase screen for Shadowing Challenge ("The Echo Chamber").
///
/// Teaches learners how immediate oral shadowing automates native speech motor habits,
/// cadence, rhythm, weak forms, liaisons, and natural inflection.
class ShadowingChallengeLearnScreen extends StatefulWidget {
  final int level;

  const ShadowingChallengeLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ShadowingChallengeLearnScreen> createState() =>
      _ShadowingChallengeLearnScreenState();
}

class _ShadowingChallengeLearnScreenState
    extends State<ShadowingChallengeLearnScreen> {
  int _cardIndex = 0;
  double _selectedSpeed = 1.0;
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
        'assets/curriculum/accent/shadowingChallenge_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_SHADOWINGCHALLENGE_LEARN_FALLBACK_1',
          'gameType': 'shadowingChallenge',
          'level': widget.level,
          'word': 'My brother works out every evening.',
          'textToSpeak': 'My brother works out every evening.',
          'ipa': '/maɪ ˈbrʌðə wɜːks‿aʊt ˈevri ˈiːvnɪŋ/',
          'ruleCategory': 'Consonant-to-Vowel Linking',
          'flowRule':
              'Consonant-to-Vowel Linking: When a word ends with a consonant and the next begins with a vowel sound, they link together smoothly without a pause.',
          'explanation':
              "'works' ends with the consonant /s/ and 'out' begins with the vowel /aʊ/. Fluent speech fuses them into 'work-sout', maintaining an unbroken vocal stream.",
          'nativeTip':
              'Begin shadowing 0.2 seconds after the speaker. Do not wait for the sentence to finish; glide along in real-time.',
        },
        {
          'id': 'ACC_SHADOWINGCHALLENGE_LEARN_FALLBACK_2',
          'gameType': 'shadowingChallenge',
          'level': widget.level,
          'word': 'I locked the office early.',
          'textToSpeak': 'I locked the office early.',
          'ipa': '/aɪ lɒkt ði ˈɒfɪs ˈɜːli/',
          'ruleCategory': 'Vowel Sound Anticipation',
          'flowRule':
              "Vowel Sound Anticipation: 'the' is pronounced /ðiː/ before a vowel sound and /ðə/ before a consonant sound.",
          'explanation':
              "Because 'office' opens with the short vowel /ɒ/, 'the' is articulated as /ðiː/ with a subtle glide to ensure vocal clarity.",
          'nativeTip':
              'Pay attention to the transition between /ðiː/ and /ɒfɪs/. Let the vocal cords hum continuously without a glottal stop.',
        },
        {
          'id': 'ACC_SHADOWINGCHALLENGE_LEARN_FALLBACK_3',
          'gameType': 'shadowingChallenge',
          'level': widget.level,
          'word': 'She brought an umbrella today.',
          'textToSpeak': 'She brought an umbrella today.',
          'ipa': '/ʃiː brɔːt ən ʌmˈbrelə təˈdeɪ/',
          'ruleCategory': 'Article Sound Agreement',
          'flowRule':
              "Article Sound Agreement: 'an' is used before vowel sounds, reducing to a quick, unstressed /ən/ that attaches to the following noun.",
          'explanation':
              "'umbrella' starts with /ʌ/, so 'an' glides seamlessly into the noun as 'a-num-brel-la' with no audible pause.",
          'nativeTip':
              'Keep the unstressed /ən/ very short and quiet; reserve your vocal energy for the stressed syllable /brel/.',
        },
      ];

  void _playAudio(String text) {
    if (text.isEmpty) return;
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: 0.4 * _selectedSpeed);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final card = _cards[_cardIndex % _cards.length];
    final word = card['word'] as String? ?? 'Speech Shadowing Practice';
    final textToSpeak = card['textToSpeak'] as String? ?? word;
    final ipa = card['ipa'] as String? ?? '';
    final ruleCategory =
        card['ruleCategory'] as String? ?? 'Connected Speech Rule';
    final flowRule = card['flowRule'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final nativeTip = card['nativeTip'] as String? ??
        'Shadow 0.2s behind the audio to build vocal muscle memory.';

    return LearnPhaseScaffold(
      title: 'The Echo Chamber',
      gameType: 'shadowingChallenge',
      level: widget.level,
      actionLabel: 'START PRACTICE',
      onComplete: () {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'shadowingChallenge',
          level: widget.level,
          phase: 'learn',
        );
        if (mounted) {
          try {
            context.pushReplacement(
              '/practice?category=accent&gameType=shadowingChallenge&level=${widget.level}',
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

            // Target Phrase Hero Card
            _buildTargetCard(word, textToSpeak, ipa),
            SizedBox(height: 20.h),

            // Speed Calibration Selector
            _buildSpeedSelector(textToSpeak),
            SizedBox(height: 20.h),

            // Speech Flow Rule & Breakdown
            _buildFlowRuleCard(ruleCategory, flowRule, explanation),
            SizedBox(height: 20.h),

            // The 0.2-Second Protocol
            _buildProtocolCard(),
            SizedBox(height: 20.h),

            // Tri-Pillar Checklist
            _buildTriPillarChecklist(),
            SizedBox(height: 20.h),

            // Coach Pro-Tip Card
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
        color: AppColors.indigo500.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.25),
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
                Icons.record_voice_over_rounded,
                size: 20.sp,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 8.w),
              Text(
                'PHRASE ${_cardIndex + 1} OF ${_cards.length}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.indigo500,
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
                        ? AppColors.indigo500
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
                  key: const Key('shadowing_learn_next_card'),
                  icon: Icon(
                    Icons.chevron_right_rounded,
                    size: 24.sp,
                    color: _cardIndex < _cards.length - 1
                        ? AppColors.indigo500
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

  Widget _buildTargetCard(String word, String textToSpeak, String ipa) {
    return Container(
      key: const Key('shadowing_learn_target_card'),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.indigo500.withValues(alpha: 0.12),
            AppColors.teal500.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: AppColors.indigo500.withValues(alpha: 0.35),
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
                  color: AppColors.indigo500,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'TARGET PHRASE',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w800,
                    color: AppColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              ElevatedButton.icon(
                key: const Key('shadowing_learn_listen_button'),
                onPressed: () => _playAudio(textToSpeak),
                icon: Icon(
                  Icons.volume_up_rounded,
                  size: 18.sp,
                  color: AppColors.white,
                ),
                label: Text(
                  'Listen (${_selectedSpeed}x)',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo500,
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
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              height: 1.35,
            ),
          ),
          if (ipa.isNotEmpty) ...[
            SizedBox(height: 10.h),
            Center(
              child: Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
                decoration: BoxDecoration(
                  color: AppColors.slate800.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  ipa,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSpeedSelector(String textToSpeak) {
    final speeds = [0.75, 1.0, 1.25];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.slate200,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.speed_rounded,
                size: 20.sp,
                color: AppColors.slate700,
              ),
              SizedBox(width: 8.w),
              Text(
                'Playback Speed:',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate800,
                ),
              ),
            ],
          ),
          Wrap(
            spacing: 8.w,
            children: speeds.map((speed) {
              final isSelected = _selectedSpeed == speed;
              return GestureDetector(
                key: Key('shadowing_learn_speed_chip_$speed'),
                onTap: () {
                  setState(() => _selectedSpeed = speed);
                  _playAudio(textToSpeak);
                },
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.indigo500
                        : AppColors.slate100,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.indigo500
                          : AppColors.slate300,
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? AppColors.white : AppColors.slate700,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowRuleCard(
      String category, String flowRule, String explanation) {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.slate900.withValues(alpha: 0.04),
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
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.waves_rounded,
                  size: 20.sp,
                  color: AppColors.teal500,
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  category,
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
          if (flowRule.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              flowRule,
              style: TextStyle(
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.teal500,
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

  Widget _buildProtocolCard() {
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 22.sp,
                color: AppColors.amber500,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'The 0.2s Shadowing Protocol',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Neuroscience shows that trailing 0.2 to 0.4 seconds behind a native speaker engages auditory cortex mirror neurons, automating rhythm and mouth posture without mental translation.',
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.slate300,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriPillarChecklist() {
    final pillars = [
      {
        'title': '1. Immediate Vocal Tracking',
        'desc': 'Start shadowing the moment the first syllable sounds. Do not wait for the phrase to finish.',
        'icon': Icons.timer_outlined,
      },
      {
        'title': '2. Continuous Breath Stream',
        'desc': 'Keep your airflow steady through liaisons and weak words without creating false pauses.',
        'icon': Icons.air_rounded,
      },
      {
        'title': '3. Melodic Inflection',
        'desc': 'Match the natural rising or falling musical contours rather than flat monotonic volume.',
        'icon': Icons.music_note_rounded,
      },
    ];

    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: AppColors.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TRI-PILLAR SHADOWING RULES',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.indigo500,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          ...pillars.map((p) => Padding(
                padding: EdgeInsets.only(bottom: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.w),
                      decoration: BoxDecoration(
                        color: AppColors.indigo500.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        size: 16.sp,
                        color: AppColors.indigo500,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['title'] as String,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            p['desc'] as String,
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
                  'COACH ADVICE',
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
