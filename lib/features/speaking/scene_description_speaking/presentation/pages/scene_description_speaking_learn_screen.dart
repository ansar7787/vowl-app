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

/// Interactive Learn Phase screen for Scene Description Speaking ("Visual & Spatial Discovery").
///
/// Instructs learners on environmental scene observation, spatial prepositions,
/// descriptive noun phrases, and structured oral formulation.
class SceneDescriptionSpeakingLearnScreen extends StatefulWidget {
  final int level;

  const SceneDescriptionSpeakingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SceneDescriptionSpeakingLearnScreen> createState() =>
      _SceneDescriptionSpeakingLearnScreenState();
}

class _SceneDescriptionSpeakingLearnScreenState
    extends State<SceneDescriptionSpeakingLearnScreen> {
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
        'assets/curriculum/speaking/sceneDescriptionSpeaking_learn_${startLevel}_$endLevel.json';

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
          'id': 'SPK_SCENEDESCRIPTIONSPEAKING_LEARN_FALLBACK_1',
          'sceneTitle': 'Bedroom Corner',
          'sceneElements': [
            'blue pillow on the bed',
            'lamp on the bedside table',
            'pair of slippers on the floor',
          ],
          'sceneText':
              'Bedroom Corner|blue pillow on the bed|lamp on the bedside table|pair of slippers on the floor',
          'instruction':
              'Find the object that gives light. Say what it is and where it is.',
          'targetObject': 'Bedside lamp',
          'sampleAnswer':
              'It is a lamp. It is on the small table next to the bed.',
          'keyVocabulary': [
            'lamp',
            'bedside table',
            'on',
            'next to',
            'small',
          ],
          'explanation':
              'This is the first step in describing a scene: name one object, then say where it is with a short "It is on..." sentence.',
          'hint':
              'Name the object first, then add one short place word like on or next to.',
          'descriptiveTip':
              'Specify the focal item clearly, establish spatial context using prepositions, and describe supporting elements in full sentences.',
        },
        {
          'id': 'SPK_SCENEDESCRIPTIONSPEAKING_LEARN_FALLBACK_2',
          'sceneTitle': 'Kitchen Counter',
          'sceneElements': [
            'electric kettle by the sink',
            'cutting board with bread',
            'bowl of red apples',
          ],
          'sceneText':
              'Kitchen Counter|electric kettle by the sink|cutting board with bread|bowl of red apples',
          'instruction':
              'Find the fruit. Tell us what color it is and what it is in.',
          'targetObject': 'Bowl of red apples',
          'sampleAnswer':
              'The apples are red. They are in a white bowl on the counter.',
          'keyVocabulary': [
            'apples',
            'red',
            'bowl',
            'in',
            'counter',
          ],
          'explanation':
              'Putting a color adjective before a noun ("red apples") makes the description precise, while "in" shows container containment.',
          'hint':
              'Use a color word before the noun, then say the container with "in".',
          'descriptiveTip':
              'Notice how combining color adjectives with spatial prepositions produces precise spoken descriptions.',
        },
      ];

  void _playAudio(String text, {double speed = 0.5}) {
    try {
      if (di.sl.isRegistered<SoundService>()) {
        di.sl<SoundService>().playTts(text, speed: speed);
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
        gameType: 'sceneDescriptionSpeaking',
        level: widget.level,
        phase: 'learn',
      );
      context.pushReplacement(
        '/practice?category=speaking&gameType=sceneDescriptionSpeaking&level=${widget.level}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = _cards[_cardIndex];

    final sceneTitle = card['sceneTitle'] as String? ?? 'Environmental Scene';
    final sceneElements = (card['sceneElements'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final instruction = card['instruction'] as String? ??
        'Observe the scene and describe the target feature.';
    final targetObject = card['targetObject'] as String? ?? '';
    final sampleAnswer = card['sampleAnswer'] as String? ?? '';
    final keyVocabulary = (card['keyVocabulary'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();
    final explanation = card['explanation'] as String? ?? '';
    final hint = card['hint'] as String? ?? '';
    final descriptiveTip = card['descriptiveTip'] as String? ??
        'Specify the focal item clearly and establish spatial location with prepositions.';
    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'Scene Description Discovery',
      gameType: 'sceneDescriptionSpeaking',
      level: widget.level,
      actionLabel: isLast ? 'Complete & Start Practice' : 'Next Scene',
      onComplete: _onNext,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Header
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
                    color: AppColors.indigo500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.indigo500.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    'SCENE DISCOVERY ${_cardIndex + 1} OF ${_cards.length}',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: AppColors.indigo500,
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

            // Scene Atmosphere & Environmental Title Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          AppColors.indigo500.withValues(alpha: 0.25),
                          AppColors.slate900,
                        ]
                      : [
                          AppColors.indigo500.withValues(alpha: 0.08),
                          Colors.white,
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.landscape_rounded,
                          color: AppColors.indigo500,
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'ENVIRONMENTAL SCENE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    sceneTitle,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (sceneElements.isNotEmpty) ...[
                    SizedBox(height: 10.h),
                    Column(
                      children: sceneElements.map((elem) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 6.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.only(top: 4.h),
                                child: Icon(
                                  Icons.circle,
                                  size: 6.sp,
                                  color: AppColors.indigo500,
                                ),
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  elem,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.slate300
                                        : AppColors.slate700,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.indigo500,
                        side: BorderSide(
                          color: AppColors.indigo500.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                      ),
                      onPressed: () => _playAudio(
                          '$sceneTitle: ${sceneElements.join(', ')}'),
                      icon: Icon(Icons.volume_up_rounded, size: 18.sp),
                      label: Text(
                        'Listen Scene Layout',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Descriptive Goal & Target Object Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.center_focus_strong_rounded,
                        color: AppColors.emerald500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'DESCRIPTIVE GOAL & TARGET OBJECT',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.emerald500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    instruction,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  if (targetObject.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Text(
                          'Focal Target: ',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColors.emerald500,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            targetObject,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.slate100
                                  : AppColors.slate900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: 10.h),
                  Text(
                    '"$sampleAnswer"',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.slate100 : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.emerald500,
                        side: BorderSide(
                          color: AppColors.emerald500.withValues(alpha: 0.5),
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 6.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                      onPressed: () => _playAudio(sampleAnswer),
                      icon: Icon(Icons.volume_up_rounded, size: 16.sp),
                      label: Text(
                        'Listen Target Description',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Spatial Vocabulary Chips Card
            if (keyVocabulary.isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.layers_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'TARGET SPATIAL VOCABULARY',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.indigo500,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: keyVocabulary.map((word) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: AppColors.indigo500.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10.r),
                            border: Border.all(
                              color:
                                  AppColors.indigo500.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.slate200
                                  : AppColors.slate800,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (keyVocabulary.isNotEmpty) SizedBox(height: 12.h),

            // Spatial Grammar & Structure Card
            if (explanation.isNotEmpty)
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : Colors.white,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.amber500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            'SPATIAL GRAMMAR & STRUCTURE',
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
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark ? AppColors.slate300 : AppColors.slate700,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            if (explanation.isNotEmpty) SizedBox(height: 12.h),

            // Speaking Advice Card
            Container(
              padding: EdgeInsets.all(14.r),
              decoration: BoxDecoration(
                color: AppColors.indigo500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: AppColors.indigo500.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.indigo500,
                        size: 16.sp,
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          'DESCRIPTIVE SPEAKING ADVICE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    descriptiveTip,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate200 : AppColors.slate800,
                      height: 1.35,
                    ),
                  ),
                  if (hint.isNotEmpty) ...[
                    SizedBox(height: 6.h),
                    Text(
                      'Hint: $hint',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.indigo400
                            : const Color(0xFF4338CA),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
