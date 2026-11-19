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

/// Interactive Learn Phase screen for Word Linking ("The Word Bridge").
///
/// Teaches learners how fluent native speakers connect word boundaries in spoken English:
/// consonant-to-vowel linking, vowel-to-vowel linking, and eliminating unnatural pauses.
class WordLinkingLearnScreen extends StatefulWidget {
  final int level;

  const WordLinkingLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<WordLinkingLearnScreen> createState() => _WordLinkingLearnScreenState();
}

class _WordLinkingLearnScreenState extends State<WordLinkingLearnScreen> {
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
        'assets/curriculum/accent/wordLinking_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_WORDLINKING_LEARN_FALLBACK_1',
          'gameType': 'wordLinking',
          'level': widget.level,
          'concept': 'The Word Bridge: Connected Speech',
          'instruction':
              'Listen to how fluent native speech links word boundaries smoothly without choppy gaps.',
          'words': ['pick', 'up', 'the', 'phone'],
          'sentence': 'pick up the phone',
          'textToSpeak': 'pick up the phone',
          'linkedPair': 'pick up',
          'linkingType': 'consonant_to_vowel',
          'flowRule':
              'Consonant-to-Vowel Linking: When a word ends with a consonant and the next starts with a vowel, the consonant jumps over to start the next syllable.',
          'explanation':
              "'Pick' ends in /k/ and 'up' begins with a vowel sound, so the words fuse seamlessly into 'pi-ckup' with no pause between them.",
          'proTip':
              'In natural English, word boundaries disappear within a phrase. A final consonant sound jumps across to the next vowel, turning separate words into one continuous breath stream.',
          'hint':
              'Listen for where the voice moves without stopping between two words.',
          'options': [
            '“pick” ➔ “up”',
            '“up” ➔ “the”',
            '“the” ➔ “phone”',
            'No connected boundary (Full Pause)'
          ],
          'correctAnswer': '“pick” ➔ “up”',
          'correctAnswerIndex': 0,
          'emoji': '🔗',
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
        gameType: 'wordLinking',
        level: widget.level,
        phase: 'learn',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/practice?category=accent&gameType=wordLinking&level=${widget.level}',
          );
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentCard =
        _cards.isNotEmpty ? _cards[_cardIndex] : _fallbackCards[0];

    final words = (currentCard['words'] as List<dynamic>? ?? ['pick', 'up', 'the', 'phone'])
        .cast<String>();
    final sentence = currentCard['sentence'] as String? ?? words.join(' ');
    final textToSpeak = currentCard['textToSpeak'] as String? ?? sentence;
    final linkedPair = currentCard['linkedPair'] as String? ?? 'pick up';
    final linkingType = currentCard['linkingType'] as String? ?? 'consonant_to_vowel';
    final flowRule = currentCard['flowRule'] as String? ?? '';
    final explanation = currentCard['explanation'] as String? ?? '';
    final proTip = currentCard['proTip'] as String? ?? '';
    final hint = currentCard['hint'] as String? ?? '';
    final emoji = currentCard['emoji'] as String? ?? '🔗';

    final isLast = _cardIndex >= _cards.length - 1;

    // Format human-readable linking type label
    final formattedType = linkingType == 'vowel_to_vowel'
        ? 'Vowel-to-Vowel Glide (V ➔ V)'
        : 'Consonant-to-Vowel Bridge (C ➔ V)';

    return LearnPhaseScaffold(
      title: 'The Word Bridge',
      gameType: 'wordLinking',
      level: widget.level,
      actionLabel: isLast ? 'Start Practice' : 'Next Concept',
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
                    'BRIDGE ${_cardIndex + 1} OF ${_cards.length}',
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

            // Hero Sentence & Word Bridge Visualizer Card
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
                  // Full Spoken Sentence
                  Text(
                    '"$sentence"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  // Active Linked Pair Spotlight
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: AppColors.teal500.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_rounded,
                          color: AppColors.teal500,
                          size: 16.sp,
                        ),
                        SizedBox(width: 6.w),
                        Flexible(
                          child: Text(
                            'Linked: “$linkedPair”',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w800,
                              color: AppColors.teal500,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Connected Speech Flow Tokens / Bridge Map
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 8.h,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: List.generate(words.length, (idx) {
                      final word = words[idx];
                      final isFirstOfPair =
                          idx < words.length - 1 &&
                          "${words[idx]} ${words[idx + 1]}".toLowerCase().trim() ==
                              linkedPair.toLowerCase().trim();
                      final isSecondOfPair =
                          idx > 0 &&
                          "${words[idx - 1]} ${words[idx]}".toLowerCase().trim() ==
                              linkedPair.toLowerCase().trim();
                      final isPartOfLink = isFirstOfPair || isSecondOfPair;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isPartOfLink ? 12.w : 10.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: isPartOfLink
                                  ? AppColors.teal500
                                  : (isDark
                                      ? AppColors.slate800
                                      : AppColors.slate100),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isPartOfLink
                                    ? AppColors.teal500
                                    : (isDark
                                        ? AppColors.slate700
                                        : AppColors.slate300),
                              ),
                              boxShadow: isPartOfLink
                                  ? [
                                      BoxShadow(
                                        color: AppColors.teal500
                                            .withValues(alpha: 0.35),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              word,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: isPartOfLink
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isPartOfLink
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.slate200
                                        : AppColors.slate800),
                              ),
                            ),
                          ),
                          if (isFirstOfPair) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              child: Container(
                                padding: EdgeInsets.all(4.r),
                                decoration: BoxDecoration(
                                  color: AppColors.amber500,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.link_rounded,
                                  color: Colors.white,
                                  size: 12.sp,
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    }),
                  ),
                  SizedBox(height: 18.h),

                  // Listen Button
                  InkWell(
                    key: const Key('learn_listen_button'),
                    onTap: () => _playAudio(textToSpeak),
                    borderRadius: BorderRadius.circular(14.r),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: AppColors.teal500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14.r),
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
                            size: 20.sp,
                          ),
                          SizedBox(width: 8.w),
                          Flexible(
                            child: Text(
                              'Listen to Connected Flow',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                color: AppColors.teal500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 14.h),

            // Connected Speech Flow Rule Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate900 : Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark ? AppColors.slate800 : AppColors.slate200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.indigo500.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          Icons.alt_route_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'CONNECTED FLOW PRINCIPLE: $formattedType',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.indigo500,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    flowRule,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate900,
                      height: 1.4,
                    ),
                  ),
                  if (explanation.isNotEmpty) ...[
                    SizedBox(height: 8.h),
                    Text(
                      explanation,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: 12.h),

            // Pro Tip Card
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: AppColors.amber500.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: AppColors.amber500.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💡', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WORD BRIDGE PRO-TIP',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w800,
                            color: AppColors.amber500,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          proTip,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.slate200
                                : AppColors.slate800,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (hint.isNotEmpty) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(14.r),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.slate900 : AppColors.slate100,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: isDark ? AppColors.slate800 : AppColors.slate200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      color: AppColors.teal500,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        hint,
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
              ),
            ],
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }
}
