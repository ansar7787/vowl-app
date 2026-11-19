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

/// Interactive Learn Phase screen for Consonant Clarity ("The Consonant Lab").
///
/// Teaches learners to distinguish subtle English consonants based on voicing (vocal cord vibration)
/// and airflow dynamics (plosive bursts, fricative friction, nasals, approximants, and affricates).
class ConsonantClarityLearnScreen extends StatefulWidget {
  final int level;

  const ConsonantClarityLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<ConsonantClarityLearnScreen> createState() =>
      _ConsonantClarityLearnScreenState();
}

class _ConsonantClarityLearnScreenState
    extends State<ConsonantClarityLearnScreen> {
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
        'assets/curriculum/accent/consonantClarity_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_CONSONANTCLARITY_LEARN_FALLBACK_1',
          'gameType': 'consonantClarity',
          'level': widget.level,
          'word': 'pen',
          'textToSpeak': 'pen',
          'targetConsonant': '/p/',
          'contrastConsonant': '/b/',
          'voicing': 'voiceless',
          'airflow': 'plosive',
          'mouthPosition':
              'Seal both lips, let the air build for a beat, then pop them apart. Your throat stays quiet; the puff should reach your palm before "en" begins.',
          'explanation':
              "'Pen' opens with /p/. Your lips seal, pressure builds, and the release sends a quick puff of breath out before the vowel, with no vibration in your throat.",
          'hint':
              'Hold your palm a few centimetres from your lips. Does the first sound land a small puff of air on your hand?',
          'nativeTip':
              'Place two fingers on your Adam\'s apple. If your throat stays still, it is voiceless. If it buzzes, it is voiced.',
        },
        {
          'id': 'ACC_CONSONANTCLARITY_LEARN_FALLBACK_2',
          'gameType': 'consonantClarity',
          'level': widget.level,
          'word': 'boat',
          'textToSpeak': 'boat',
          'targetConsonant': '/b/',
          'contrastConsonant': '/p/',
          'voicing': 'voiced',
          'airflow': 'plosive',
          'mouthPosition':
              'Press your lips together and start humming in your throat before they open. Let them part gently into "oat" rather than popping them.',
          'explanation':
              "'Boat' starts with /b/, the voiced partner of /p/. Your vocal cords are already vibrating while the lips are closed, so the release is soft and nearly puff-free.",
          'hint':
              'Rest two fingertips on your throat. Do you feel a buzz under your fingers while your lips are still shut?',
          'nativeTip':
              'Voiced plosives like /b/ have minimal aspiration. If you feel a big puff on your hand, you are saying /p/.',
        },
        {
          'id': 'ACC_CONSONANTCLARITY_LEARN_FALLBACK_3',
          'gameType': 'consonantClarity',
          'level': widget.level,
          'word': 'milk',
          'textToSpeak': 'milk',
          'targetConsonant': '/m/',
          'contrastConsonant': '/b/',
          'voicing': 'voiced',
          'airflow': 'nasal',
          'mouthPosition':
              'Close your lips, relax your jaw, and hum so the sound flows out through your nose. Open the lips only when you move into "ilk".',
          'explanation':
              '"Milk" begins with /m/. The lips close exactly as they do for /b/, but the soft palate drops, so voiced air escapes through your nose.',
          'hint':
              'Pinch your nose lightly and say the word. If the first sound gets stuck, your breath was travelling through your nose.',
          'nativeTip':
              'Nasals like /m/ and /n/ can be prolonged indefinitely because airflow continues through the nasal cavity.',
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
    final card = _cards[_cardIndex % _cards.length];
    final word = card['word'] as String? ?? 'pen';
    final textToSpeak = card['textToSpeak'] as String? ?? word;
    final targetConsonant = card['targetConsonant'] as String? ?? '/p/';
    final contrastConsonant = card['contrastConsonant'] as String? ?? '/b/';
    final voicing = (card['voicing'] as String? ?? 'voiceless').toLowerCase();
    final airflow = (card['airflow'] as String? ?? 'plosive').toLowerCase();
    final mouthPosition = card['mouthPosition'] as String? ?? '';
    final explanation = card['explanation'] as String? ?? '';
    final nativeTip = card['nativeTip'] as String? ??
        'Feel the throat vibration and air release on your palm.';

    return LearnPhaseScaffold(
      title: 'The Consonant Lab',
      gameType: 'consonantClarity',
      level: widget.level,
      actionLabel: 'START PRACTICE',
      onComplete: () {
        PhaseProgressRecorder.recordPhaseCompleted(
          context,
          gameType: 'consonantClarity',
          level: widget.level,
          phase: 'learn',
        );
        if (mounted) {
          try {
            context.pushReplacement(
              '/practice?category=accent&gameType=consonantClarity&level=${widget.level}',
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

            // Target Word & Consonant Hero Card
            _buildTargetCard(
                word, textToSpeak, targetConsonant, contrastConsonant),
            SizedBox(height: 20.h),

            // Voicing and Airflow Mechanics Card
            _buildAcousticRadarCard(voicing, airflow),
            SizedBox(height: 20.h),

            // Mouth Position & Articulation Engine
            _buildMouthMechanicsCard(mouthPosition, explanation),
            SizedBox(height: 20.h),

            // Plosives vs Fricatives vs Nasals Matrix
            _buildConsonantClassesMatrix(),
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
                Icons.science_rounded,
                size: 20.sp,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 8.w),
              Text(
                'SOUND ${_cardIndex + 1} OF ${_cards.length}',
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
                  key: const Key('consonant_learn_next_card'),
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

  Widget _buildTargetCard(String word, String textToSpeak,
      String targetConsonant, String contrastConsonant) {
    return Container(
      key: const Key('consonant_learn_target_card'),
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
                key: const Key('consonant_learn_listen_button'),
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
              fontSize: 28.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.slate900,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 14.h),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.w,
            runSpacing: 8.h,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.indigo500.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.indigo500),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Target: ',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.indigo500,
                      ),
                    ),
                    Text(
                      targetConsonant,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Courier',
                        color: AppColors.indigo500,
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
                      contrastConsonant,
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

  Widget _buildAcousticRadarCard(String voicing, String airflow) {
    final bool isVoiced = voicing.contains('voiced') && !voicing.contains('voiceless');

    return Container(
      padding: EdgeInsets.all(18.w),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.graphic_eq_rounded,
                size: 20.sp,
                color: AppColors.indigo500,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  'ACOUSTIC RADAR: VOICING & AIRFLOW',
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
          SizedBox(height: 14.h),
          Wrap(
            spacing: 12.w,
            runSpacing: 10.h,
            children: [
              // Voicing Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isVoiced
                      ? AppColors.emerald500.withValues(alpha: 0.12)
                      : AppColors.amber500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isVoiced ? AppColors.emerald500 : AppColors.amber500,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isVoiced
                          ? Icons.vibration_rounded
                          : Icons.air_rounded,
                      size: 18.sp,
                      color: isVoiced ? AppColors.emerald500 : AppColors.amber500,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isVoiced ? 'VOICED (Vibrating)' : 'VOICELESS (Still)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: isVoiced ? AppColors.emerald500 : AppColors.amber500,
                      ),
                    ),
                  ],
                ),
              ),

              // Airflow Chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.teal500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: AppColors.teal500),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stream_rounded,
                      size: 18.sp,
                      color: AppColors.teal500,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'AIRFLOW: ${airflow.toUpperCase()}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w800,
                        color: AppColors.teal500,
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

  Widget _buildMouthMechanicsCard(String mouthPosition, String explanation) {
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
                  color: AppColors.teal500.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.face_rounded,
                  size: 20.sp,
                  color: AppColors.teal500,
                ),
              ),
              SizedBox(width: 10.w),
              Flexible(
                child: Text(
                  'Mouth Position & Mechanics',
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
          if (mouthPosition.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Text(
              mouthPosition,
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

  Widget _buildConsonantClassesMatrix() {
    final classes = [
      {
        'title': 'Plosives (/p/, /b/, /t/, /d/, /k/, /g/)',
        'desc': 'Complete closure of the vocal tract, pressure build-up, followed by an explosive burst.',
        'icon': Icons.bolt_rounded,
      },
      {
        'title': 'Fricatives (/f/, /v/, /θ/, /ð/, /s/, /z/, /ʃ/, /ʒ/)',
        'desc': 'Narrow constriction causing audible continuous friction of air through teeth or lips.',
        'icon': Icons.air_rounded,
      },
      {
        'title': 'Nasals & Approximants (/m/, /n/, /ŋ/, /l/, /r/, /w/)',
        'desc': 'Soft palate lowers for nasal flow, or smooth glides without frictional turbulence.',
        'icon': Icons.waves_rounded,
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
            'CONSONANT AIRFLOW FAMILIES',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w800,
              color: AppColors.indigo500,
              letterSpacing: 0.8,
            ),
          ),
          SizedBox(height: 12.h),
          ...classes.map((c) => Padding(
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
                        c['icon'] as IconData,
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
                            c['title'] as String,
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            c['desc'] as String,
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
