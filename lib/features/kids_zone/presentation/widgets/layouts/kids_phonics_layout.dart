import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/illustration_colors.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color09090b = Color(0xFF09090B);
  static const Color color52525b = Color(0xFF52525B);
  static const Color color818cf8 = Color(0xFF818CF8);
  static const Color color22c55e = Color(0xFF22C55E);
  static const Color color18181b = Color(0xFF18181B);
  static const Color color3f3f46 = Color(0xFF3F3F46);
  static const Color color27272a = Color(0xFF27272A);
  static const Color studioDeck = Color(0xFF1E293B);
  static const Color studioDeckBorder = Color(0xFF334155);
}

/// Helper to extract educational phonics clues from quest instruction without modifying JSON
class _PhonicsClueHelper {
  static final RegExp _blankPattern = RegExp(r'[A-Za-z]+_{1,4}[A-Za-z]*|_{1,4}[A-Za-z]+|_{2,4}');
  static final RegExp _quotedPattern = RegExp(r'[“"«]([^”"»]+)[”"»]');
  static final RegExp _phonemePattern = RegExp(r'\/([^\/]+)\/');

  /// Detects target word blank like 'tr__n' or 'b__'
  static String? extractBlankWord(String instruction) {
    final match = _blankPattern.firstMatch(instruction);
    return match?.group(0);
  }

  /// Detects target quoted word like '“moon”' or '“pear”'
  static String? extractTargetWord(String instruction) {
    final match = _quotedPattern.firstMatch(instruction);
    return match?.group(1);
  }

  /// Detects phoneme sound like '/m/' or '/ar/'
  static String? extractPhoneme(String instruction) {
    final match = _phonemePattern.firstMatch(instruction);
    return match?.group(1);
  }
}

/// Music Studio Theme for Phonics Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (N <= 4)
class KidsPhonicsLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsPhonicsLayout] widget.
  const KidsPhonicsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsPhonicsLayout> createState() => _KidsPhonicsLayoutState();
}

class _KidsPhonicsLayoutState extends State<KidsPhonicsLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
        try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  void _submitAnswer(
    BuildContext context,
    KidsLoaded state,
    String selectedOption,
  ) {
    if (state.answerStatus.isAnswered) return;

    final quest = state.currentQuest;
    final isCorrect = (selectedOption == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsPhonicsLayout: Submitted option "$selectedOption" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsPhonics',
      );
    }

    // Provide immediate auditory & haptic feedback
    if (isCorrect) {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
      // Speak the correct phoneme / word for reinforcement
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(selectedOption);
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(selectedOption);
      }
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _speakInstruction(KidsQuest quest) {
    final text = InstructionHelper.getInstruction(quest);
    if (text.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsPhonicsLayout: Playing audio instruction for quest "${quest.id}"',
          tag: 'KidsPhonics',
        );
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().light();
      }
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(text, force: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'phonics',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final options = quest.options ?? const <String>[];
        final isAnswered = state.answerStatus.isAnswered;
        final bool isAllShort = options.every((opt) => opt.length <= 3);

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final isCompactHeight = availableHeight < 620;
            final monitorHeight = isCompactHeight ? 165.h : 195.h;

            return Column(
              children: [
                SizedBox(height: isCompactHeight ? 68.h : 82.h),

                // Studio Monitor Stage with DragTarget Drop Zone
                Expanded(
                  flex: 6,
                  child: Center(
                    child: DragTarget<String>(
                      onWillAcceptWithDetails: (details) => !isAnswered,
                      onAcceptWithDetails: (details) {
                        if (isAnswered) return;
                        _submitAnswer(context, state, details.data);
                      },
                      builder: (context, candidateData, rejectedData) {
                        final isHovering = candidateData.isNotEmpty;
                        return _StudioMonitor(
                          state: state,
                          quest: quest,
                          monitorHeight: monitorHeight,
                          isHovering: isHovering,
                          animController: _animController,
                          onReplayAudio: () => _speakInstruction(quest),
                        );
                      },
                    ),
                  ),
                ),

                SizedBox(height: isCompactHeight ? 8.h : 14.h),

                // Interactive Instruction Prompt
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: KidsFittedText(
                    isAnswered
                        ? (state.answerStatus == AnswerStatus.correct
                            ? context.tr('games.kids_phonics_correct', fallback: 'Great job! You found the right sound.')
                            : context.tr('games.kids_phonics_incorrect', fallback: 'Listen carefully and try again.'))
                        : context.tr(
                            'games.kids_phonics_drag',
                            fallback: 'Choose the matching sound, or drag it to the speaker.',
                          ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.8),
                    ),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                ),

                SizedBox(height: isCompactHeight ? 8.h : 12.h),

                // Studio Mixing Desk & Vinyl Records
                Flexible(
                  flex: 5,
                  child: _StudioDeskArea(
                    options: options,
                    quest: quest,
                    state: state,
                    isAllShort: isAllShort,
                    animController: _animController,
                    isCompactHeight: isCompactHeight,
                    onOptionSelected: (option) => _submitAnswer(context, state, option),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The Studio Monitor Screen with Equalizer, Clue Target, and DragTarget
class _StudioMonitor extends StatelessWidget {
  final KidsLoaded state;
  final KidsQuest quest;
  final double monitorHeight;
  final AnimationController animController;
  final bool isHovering;
  final VoidCallback onReplayAudio;

  const _StudioMonitor({
    required this.state,
    required this.quest,
    required this.monitorHeight,
    required this.isHovering,
    required this.animController,
    required this.onReplayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final blankWord = _PhonicsClueHelper.extractBlankWord(quest.instruction);
    final targetWord = _PhonicsClueHelper.extractTargetWord(quest.instruction);
    final phoneme = _PhonicsClueHelper.extractPhoneme(quest.instruction);

    return Semantics(
      label: 'Speaker area. Tap Listen to hear the clue, or select a sound below.',
      child: Container(
          width: 290.w,
          height: monitorHeight,
            decoration: BoxDecoration(
              color: _LocalPalette.color09090b,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isHovering
                    ? _LocalPalette.color818cf8
                    : (isCorrect
                        ? _LocalPalette.color22c55e
                        : _LocalPalette.color52525b),
                width: isHovering ? 3.r : 2.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? _LocalPalette.color818cf8.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.35),
                  blurRadius: isHovering ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Animated Soundwave Equalizer Background
                  Positioned(
                    bottom: 0,
                    left: 8.w,
                    right: 8.w,
                    height: 90.h,
                    child: _EqualizerVisualizer(
                      animController: animController,
                      isHovering: isHovering,
                      isCorrect: isCorrect,
                    ),
                  ),

                  // Top Status Header
                  Positioned(
                    top: 10.h,
                    left: 12.w,
                    child: Row(
                      children: [
                        Container(
                          width: 8.r,
                          height: 8.r,
                          decoration: BoxDecoration(
                            color: isCorrect
                                ? _LocalPalette.color22c55e
                                : (isHovering
                                    ? _LocalPalette.color818cf8
                                    : const Color(0xFF38BDF8)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          isCorrect
                              ? context.tr('games.matched', fallback: 'Matched!')
                              : context.tr('games.listen_and_match', fallback: 'Listen & Match'),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Audio Replay Button at Bottom Right (Clean and Unobstructed)
                  Positioned(
                    bottom: 10.h,
                    right: 12.w,
                    child: ScaleButton(
                      onTap: onReplayAudio,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              color: Colors.amberAccent,
                              size: 15.r,
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              context.tr('games.listen', fallback: 'Listen'),
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Center Content Display
                  Padding(
                    padding: EdgeInsets.only(top: 24.h, bottom: 8.h, left: 12.w, right: 12.w),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        // Emoji with clean halo (NO clashing text overlay!)
                        if (quest.emoji != null && quest.emoji!.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCorrect
                                  ? _LocalPalette.color22c55e.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                            child: Text(
                              quest.emoji!,
                              style: TextStyle(fontSize: 48.sp),
                            ),
                          ),
                          SizedBox(height: 6.h),
                        ],

                        // Target Clue Display (Blank Word, Quoted Word, or Phoneme)
                        if (blankWord != null)
                          _buildBlankWordBadge(blankWord, isCorrect)
                        else if (targetWord != null)
                          _buildTargetWordBadge(targetWord, phoneme, isCorrect)
                        else if (phoneme != null)
                          _buildPhonemeBadge(phoneme, isCorrect)
                        else if (quest.question != null && quest.question != '?')
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10.w),
                            child: KidsFittedText(
                              quest.question!,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                          )
                        else
                          // Subtle sound target prompt
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.graphic_eq_rounded,
                                  color: _LocalPalette.color818cf8,
                                  size: 16.r,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  isCorrect ? (quest.correctAnswer ?? 'Matched!') : 'Match the sound',
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isCorrect ? _LocalPalette.color22c55e : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      ),
                    ),
                  ),

                  // Turntable Vinyl Spin Overlay on Correct Answer
                  if (isCorrect)
                    Positioned(
                      bottom: 8.h,
                      left: 12.w,
                      child: AnimatedBuilder(
                        animation: animController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: animController.value * 2 * math.pi,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 32.r,
                          height: 32.r,
                          decoration: BoxDecoration(
                            color: _LocalPalette.color18181b,
                            shape: BoxShape.circle,
                            border: Border.all(color: _LocalPalette.color22c55e, width: 2),
                          ),
                          child: Center(
                            child: Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

  Widget _buildBlankWordBadge(String blankWord, bool isCorrect) {
    // If answered correctly, replace blanks with the correct answer
    final displayWord = isCorrect
        ? blankWord.replaceAll(RegExp(r'_{1,4}'), quest.correctAnswer ?? '')
        : blankWord;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: isCorrect
            ? _LocalPalette.color22c55e.withValues(alpha: 0.25)
            : Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCorrect ? _LocalPalette.color22c55e : _LocalPalette.color818cf8,
          width: 1.5,
        ),
      ),
      child: Text(
        displayWord,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 22.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
          color: isCorrect ? _LocalPalette.color22c55e : Colors.white,
        ),
      ),
    );
  }

  Widget _buildTargetWordBadge(String targetWord, String? phoneme, bool isCorrect) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isCorrect ? _LocalPalette.color22c55e : Colors.white24,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '“$targetWord”',
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: isCorrect ? _LocalPalette.color22c55e : Colors.white,
            ),
          ),
          if (phoneme != null) ...[
            SizedBox(width: 6.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: _LocalPalette.color818cf8.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                '/$phoneme/',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.amberAccent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPhonemeBadge(String phoneme, bool isCorrect) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: _LocalPalette.color818cf8.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Text(
        'Sound: /$phoneme/',
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: Colors.amberAccent,
        ),
      ),
    );
  }
}

/// Dynamic Animated Equalizer Bars
class _EqualizerVisualizer extends StatelessWidget {
  final AnimationController animController;
  final bool isHovering;
  final bool isCorrect;

  const _EqualizerVisualizer({
    required this.animController,
    required this.isHovering,
    required this.isCorrect,
  });

  static const List<double> _baseHeights = [
    18.0, 42.0, 26.0, 68.0, 34.0, 52.0, 80.0, 58.0, 36.0, 72.0, 44.0, 24.0, 50.0, 20.0, 35.0,
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (context, child) {
        final animVal = animController.value;
        final barColor = isCorrect
            ? _LocalPalette.color22c55e.withValues(alpha: 0.45)
            : (isHovering
                ? _LocalPalette.color818cf8.withValues(alpha: 0.5)
                : const Color(0xFF22C55E).withValues(alpha: 0.25));

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(_baseHeights.length, (index) {
            final baseH = _baseHeights[index];
            // Sine-wave dynamic pulsing factor per bar
            final offset = (index / _baseHeights.length) * 2 * math.pi;
            final dynamicFactor = 0.6 + 0.4 * math.sin(animVal * 2 * math.pi + offset);
            final currentHeight = (baseH * dynamicFactor).clamp(10.0, 85.0);

            return Container(
              width: 7.w,
              height: currentHeight.h,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(3.r),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Studio Mixing Desk with Vinyl Records & Audio Preview
class _StudioDeskArea extends StatelessWidget {
  final List<String> options;
  final KidsQuest quest;
  final KidsLoaded state;
  final bool isAllShort;
  final AnimationController animController;
  final bool isCompactHeight;
  final ValueChanged<String> onOptionSelected;

  const _StudioDeskArea({
    required this.options,
    required this.quest,
    required this.state,
    required this.isAllShort,
    required this.animController,
    required this.isCompactHeight,
    required this.onOptionSelected,
  });

  static const List<Color> _labelColors = [
    AppColors.red500,
    IllustrationColors.brightBlue,
    AppColors.amber500,
    IllustrationColors.vibrantPink,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Studio Desk Surface
        Container(
          height: isCompactHeight ? 34.h : 42.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _LocalPalette.studioDeck,
            borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
            border: Border(
              top: BorderSide(color: _LocalPalette.studioDeckBorder, width: 2.h),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
        ),

        // Vinyl Records Row on Desk
        Padding(
          padding: EdgeInsets.only(
            bottom: isCompactHeight ? 8.h : 14.h,
            left: 12.w,
            right: 12.w,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(options.length, (index) {
              final option = options[index];
              final labelColor = _labelColors[index % _labelColors.length];
              final isCorrectAnswer = (quest.correctAnswer == option);

              // 50/50 Lifeline removal: if hint is used and this is a distractor, dissolve it
              bool isHintEliminated = false;
              if (state.hintUsed && !isCorrectAnswer && options.length > 2) {
                final distractors = options
                    .where((o) => o != quest.correctAnswer)
                    .toList();
                if (distractors.isNotEmpty && option == distractors.first) {
                  isHintEliminated = true;
                }
              }

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _VinylOptionItem(
                    text: option,
                    labelColor: labelColor,
                    isShort: isAllShort || option.length <= 3,
                    isCorrect: isCorrectAnswer,
                    isHintEliminated: isHintEliminated,
                    state: state,
                    animController: animController,
                    onTap: () => onOptionSelected(option),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// Individual Vinyl Record or Studio Track Card Item
class _VinylOptionItem extends StatelessWidget {
  final String text;
  final Color labelColor;
  final bool isShort;
  final bool isCorrect;
  final bool isHintEliminated;
  final KidsLoaded state;
  final AnimationController animController;
  final VoidCallback onTap;

  const _VinylOptionItem({
    required this.text,
    required this.labelColor,
    required this.isShort,
    required this.isCorrect,
    this.isHintEliminated = false,
    required this.state,
    required this.animController,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = state.answerStatus.isAnswered;
    final isOptionSelectedCorrectly =
        isAnswered && isCorrect && (state.answerStatus == AnswerStatus.correct);

    // Build the visual disc/card widget
    final Widget cardWidget = isShort
        ? _buildCircularVinylDisc(isOptionSelectedCorrectly)
        : _buildExtendedTrackCard(isOptionSelectedCorrectly);

    // 50/50 Lifeline elimination: smoothly dissolve the eliminated distractor
    if (isHintEliminated) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: 0.0,
        curve: Curves.easeOutCubic,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 400),
          scale: 0.5,
          curve: Curves.easeOutCubic,
          child: IgnorePointer(child: cardWidget),
        ),
      );
    }

    if (isAnswered) {
      // Locked state: no dragging or tapping
      return Opacity(
        opacity: isOptionSelectedCorrectly ? 1.0 : 0.45,
        child: cardWidget,
      );
    }

    // Unanswered: Dual-mode interaction (Draggable + Tap to Select)
    return Semantics(
      button: true,
      label: 'Sound option $text. Tap to select or drag up.',
      child: Draggable<String>(
        data: text,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.08,
            child: Opacity(opacity: 0.92, child: cardWidget),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.25, child: cardWidget),
        child: ScaleButton(
          onTap: onTap,
          child: cardWidget,
        ),
      ),
    );
  }

  /// Classic Circular Vinyl Record Disc (For 1-3 character phonemes)
  Widget _buildCircularVinylDisc(bool isSpinning) {
    final disc = Container(
      height: 88.r,
      width: 84.w,
      decoration: BoxDecoration(
        color: _LocalPalette.color18181b,
        shape: BoxShape.circle,
        border: Border.all(
          color: isCorrect && state.answerStatus == AnswerStatus.correct
              ? _LocalPalette.color22c55e
              : _LocalPalette.color3f3f46,
          width: isCorrect && state.answerStatus == AnswerStatus.correct ? 2.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Concentric Grooves
          Container(
            width: 68.r,
            height: 68.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _LocalPalette.color27272a, width: 1.5),
            ),
          ),
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _LocalPalette.color27272a, width: 1),
            ),
          ),

          // Center Record Label
          Container(
            width: 38.r,
            height: 38.r,
            decoration: BoxDecoration(
              color: labelColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: labelColor.withValues(alpha: 0.35),
                  blurRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 6.r,
                height: 6.r,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),

          // High-Contrast Floating Phoneme Label Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: labelColor, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate900,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );

    if (isSpinning) {
      return AnimatedBuilder(
        animation: animController,
        builder: (context, child) {
          return Transform.rotate(
            angle: animController.value * 2 * math.pi,
            child: child,
          );
        },
        child: disc,
      );
    }
    return disc;
  }

  /// Extended Studio Track Card (For multi-letter words and phrases)
  Widget _buildExtendedTrackCard(bool isCelebrating) {
    return Container(
      constraints: BoxConstraints(minHeight: 70.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _LocalPalette.color18181b,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isCelebrating
              ? _LocalPalette.color22c55e
              : (labelColor.withValues(alpha: 0.8)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mini vinyl groove icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14.r,
                height: 14.r,
                decoration: BoxDecoration(
                  color: labelColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 4.r,
                    height: 4.r,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 4.w),
              Icon(
                Icons.music_note_rounded,
                color: labelColor,
                size: 13.r,
              ),
            ],
          ),
          SizedBox(height: 6.h),

          // Word / Phrase Text Badge
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate900,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
