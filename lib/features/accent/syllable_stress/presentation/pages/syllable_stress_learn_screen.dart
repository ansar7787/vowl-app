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

/// Interactive Learn Phase screen for Syllable Stress ("The Beat Box").
///
/// Teaches learners to recognize and internalize English metrical stress beats:
/// stressed syllables are longer, louder, and higher in pitch, while unstressed
/// syllables reduce their vowels to short neutral sounds (schwa /ə/).
class SyllableStressLearnScreen extends StatefulWidget {
  final int level;

  const SyllableStressLearnScreen({
    super.key,
    required this.level,
  });

  @override
  State<SyllableStressLearnScreen> createState() =>
      _SyllableStressLearnScreenState();
}

class _SyllableStressLearnScreenState extends State<SyllableStressLearnScreen> {
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
        'assets/curriculum/accent/syllableStress_learn_${startLevel}_$endLevel.json';

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
          'id': 'ACC_SYLLABLESTRESS_LEARN_FALLBACK_1',
          'gameType': 'syllableStress',
          'level': widget.level,
          'concept': 'The Beat Box: Rhythmic Word Stress',
          'instruction':
              'Listen to the rhythm of the syllables. Identify which syllable carries the primary stress beat.',
          'word': 'paper',
          'textToSpeak': 'paper',
          'syllables': ['pa', 'per'],
          'stressIndex': 0,
          'stressedSyllable': 'pa',
          'capitalizedPattern': 'PAY-per',
          'stressRule':
              'Most two-syllable English nouns have primary stress on the FIRST syllable.',
          'explanation':
              "'paper' starts strong and then falls away: PAY-per. The second syllable is quick and weak.",
          'proTip':
              'In English, stressed syllables are LONGER, LOUDER, and HIGHER in pitch. Unstressed syllables often reduce their vowels to /ə/ (schwa). Tap your foot or drum pad with the beat!',
          'hint':
              'Clap once for each beat as you say the word, then notice which clap feels bigger.',
          'options': [
            "1st Syllable: 'pa' (PAY-per)",
            "2nd Syllable: 'per' (pay-PER)",
            'Both Syllables Equal (Compound Stress)',
            'No Stressed Syllable (Flat Monotone)'
          ],
          'correctAnswer': "1st Syllable: 'pa' (PAY-per)",
          'correctAnswerIndex': 0,
          'emoji': '🥁',
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
        gameType: 'syllableStress',
        level: widget.level,
        phase: 'learn',
      );
      if (mounted) {
        try {
          context.pushReplacement(
            '/practice?category=accent&gameType=syllableStress&level=${widget.level}',
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

    final word = currentCard['word'] as String? ?? 'paper';
    final textToSpeak = currentCard['textToSpeak'] as String? ?? word;
    final syllables = (currentCard['syllables'] as List<dynamic>? ?? ['pa', 'per'])
        .cast<String>();
    final stressIndex = currentCard['stressIndex'] as int? ?? 0;
    final capPattern = currentCard['capitalizedPattern'] as String? ?? 'PAY-per';
    final stressRule = currentCard['stressRule'] as String? ?? '';
    final explanation = currentCard['explanation'] as String? ?? '';
    final proTip = currentCard['proTip'] as String? ?? '';
    final hint = currentCard['hint'] as String? ?? '';
    final emoji = currentCard['emoji'] as String? ?? '🥁';

    final isLast = _cardIndex >= _cards.length - 1;

    return LearnPhaseScaffold(
      title: 'The Beat Box',
      gameType: 'syllableStress',
      level: widget.level,
      actionLabel: isLast ? 'Start Practice' : 'Next Word',
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
                    'WORD ${_cardIndex + 1} OF ${_cards.length}',
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

            // Hero Word & Rhythmic Beat Box Card
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
                  // Full word header
                  Text(
                    word,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28.sp,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.slate900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.teal500.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      'Stress Beat: $capPattern',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.teal500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Syllable Drum Pad Grid / Beat Visualizer
                  Wrap(
                    spacing: 10.w,
                    runSpacing: 10.h,
                    alignment: WrapAlignment.center,
                    children: List.generate(syllables.length, (idx) {
                      final isStressed = idx == stressIndex;
                      final sylText = syllables[idx];

                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isStressed ? 16.w : 12.w,
                          vertical: isStressed ? 12.h : 10.h,
                        ),
                        decoration: BoxDecoration(
                          gradient: isStressed
                              ? LinearGradient(
                                  colors: [
                                    AppColors.teal500,
                                    AppColors.teal500.withValues(alpha: 0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: isStressed
                              ? null
                              : (isDark
                                  ? AppColors.slate800
                                  : AppColors.slate100),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isStressed
                                ? AppColors.teal500
                                : (isDark
                                    ? AppColors.slate700
                                    : AppColors.slate300),
                            width: isStressed ? 2.0 : 1.0,
                          ),
                          boxShadow: isStressed
                              ? [
                                  BoxShadow(
                                    color: AppColors.teal500
                                        .withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isStressed) ...[
                                  Text(
                                    '🥁',
                                    style: TextStyle(fontSize: 14.sp),
                                  ),
                                  SizedBox(width: 4.w),
                                ],
                                Text(
                                  isStressed
                                      ? sylText.toUpperCase()
                                      : sylText.toLowerCase(),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: isStressed ? 18.sp : 15.sp,
                                    fontWeight: isStressed
                                        ? FontWeight.w900
                                        : FontWeight.w600,
                                    color: isStressed
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.slate300
                                            : AppColors.slate700),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              isStressed ? 'STRESSED' : 'beat ${idx + 1}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 9.sp,
                                fontWeight: isStressed
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isStressed
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : (isDark
                                        ? AppColors.slate400
                                        : AppColors.slate500),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
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
                          Text(
                            'Listen to Rhythm',
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w700,
                              color: AppColors.teal500,
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

            // Metrical Rule Card
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
                          Icons.menu_book_rounded,
                          color: AppColors.indigo500,
                          size: 16.sp,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'METRICAL STRESS RULE',
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
                    stressRule,
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
                          'BEAT BOX PRO-TIP',
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
