import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
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

/// Design tokens for the Mystical Magic Show Theme.
class _PrepositionsPalette {
  _PrepositionsPalette._();

  // Magical Stage
  static const Color stageBg = Color(0xFF2E1065); // Deep magical purple
  static const Color stageHoverBg = Color(0xFF4C1D95); // Deep hover violet
  static const Color stageBorder = Color(0xFFC084FC); // Glowing border
  static const Color stageHoverBorder = Color(0xFFE9D5FF); // Hover border
  static const Color stageGlow = Color(0xFF9333EA); // Aura shadow

  // Magical Starlight & Accents
  static const Color starGold = Color(0xFFFBBF24); // Warm amber
  static const Color starGlow = Color(0xFFFEF08A); // Star glow
  static const Color mysticText = Color(0xFFF5F3FF); // Bright parchment white

  // Magician Top Hat
  static const Color hatCylinder = AppColors.slate800; // Obsidian felt
  static const Color hatBrim = AppColors.slate900; // Obsidian brim
  static const Color hatRibbon = AppColors.rose700; // Velvet crimson band
  static const Color hatRibbonHighlight = Color(0xFFFB7185); // Ribbon sheen
  static const Color bunnyEar = Colors.white; // Soft white fur
  static const Color bunnyInnerEar = Color(0xFFFBCFE8); // Pink 200

  // Plaque & Cards
  static const Color plaqueGoldStart = Color(0xFFFCD34D); // Amber 300
  static const Color plaqueGoldEnd = Color(0xFFF59E0B); // Amber 500
  static const Color plaqueBorder = Color(0xFFD97706); // Amber 600
  static const Color plaqueText = Color(
    0xFF1E1B4B,
  ); // Deep slate indigo 950 for high contrast

  // Feedback Colors
  static const Color successBg = Color(0xFF065F46); // Emerald 800
  static const Color successBorder = Color(0xFF34D399); // Emerald 400
  static const Color successGlow = Color(0xFF10B981); // Emerald 500
  static const Color successText = Color(0xFFECFDF5); // Emerald 50

  static const Color errorBg = Color(0xFF881337); // Rose 900
  static const Color errorBorder = Color(0xFFFB7185); // Rose 400
  static const Color errorGlow = Color(0xFFE11D48); // Rose 600
  static const Color errorText = Color(0xFFFFF1F2); // Rose 50
}

/// Parsed metadata for gap-fill quests.
class PrepositionsGapInfo {
  final String prefix;
  final String suffix;
  final String prompt;
  final String fullSentence;

  const PrepositionsGapInfo({
    required this.prefix,
    required this.suffix,
    required this.prompt,
    required this.fullSentence,
  });

  /// Constructs the full completed sentence with the chosen word.
  String completedSentence(String word) {
    final cleanWord = word.trim();
    if (prefix.isEmpty) {
      // Capitalize if it's the first word of the sentence
      final capitalized = cleanWord.isNotEmpty
          ? '${cleanWord[0].toUpperCase()}${cleanWord.substring(1)}'
          : cleanWord;
      return '$capitalized$suffix'.trim();
    }
    return '$prefix$cleanWord$suffix'.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

/// Helper for extracting sentence structures, blanks, and prompts from curriculum quests.
class PrepositionsQuestHelper {
  PrepositionsQuestHelper._();

  static final RegExp _blankRegExp = RegExp(r'_{2,}');
  static final RegExp _promptSplitRegExp = RegExp(
    r"""(?<=[.!?]['"]?)\s+(?=(?:Which|Choose|Pick|Select|What)\b)""",
    caseSensitive: false,
  );

  /// Returns true if the quest represents a sentence gap-fill item.
  static bool hasBlank(KidsQuest quest) {
    return _blankRegExp.hasMatch(quest.instruction);
  }

  /// Parses gap quest components cleanly without modifying curriculum.
  static PrepositionsGapInfo parseGapQuest(KidsQuest quest) {
    final text = quest.instruction.trim();
    final match = _blankRegExp.firstMatch(text);

    if (match == null) {
      return PrepositionsGapInfo(
        prefix: text,
        suffix: '',
        prompt: 'Choose the sentence that fits.',
        fullSentence: text,
      );
    }

    final prefix = text.substring(0, match.start);
    final remainder = text.substring(match.end);

    final splits = remainder.split(_promptSplitRegExp);
    final suffix = splits.isNotEmpty ? splits[0] : '';
    final prompt = splits.length > 1 && splits[1].trim().isNotEmpty
        ? splits[1].trim()
        : 'Choose the word that fits.';

    final sentence = '${prefix}___$suffix'.trim();

    return PrepositionsGapInfo(
      prefix: prefix,
      suffix: suffix,
      prompt: prompt,
      fullSentence: sentence,
    );
  }

  /// Checks if any option exceeds standard single-word pill bounds.
  static bool hasLongOptions(KidsQuest quest) {
    final options = quest.options ?? [];
    return options.any((opt) => opt.trim().length > 18);
  }
}

/// Production-Grade Magic Show Layout for Kids Zone Prepositions Game.
///
/// Features:
/// - Prominent Target Sentence on Central Magic Stage: Directly displays the ESL context
///   sentence with an illuminated magical slot `[ ___ ]`.
/// - Dual Accessible Interaction: Complete support for BOTH Tap-to-Place AND Drag-and-Drop.
/// - Dynamic Archetype Adaptation: Seamlessly handles gap-fill quests (Magic Top Hats)
///   and full-sentence scenario choice quests (Magic Scroll Parchments).
/// - Comprehensive Audio Reinforcement: Voicing of full completed sentences on correct
///   submissions, option pronunciation buttons, and question replay.
/// - Lifeline 50/50 Support: Intelligently dims out a wrong distractor when hints are used.
/// - Text Safety & Zero-Clipping: Fully responsive typography with auto-wrapping, zero ellipsis.
/// - Performance & Lifecycle: Managed single-ticker controller with motion-reduction checks.
/// - Full Semantic Labels: Accessible for screen-readers and assistive navigation.
///
/// Complexity:
/// - Time Complexity: O(N) where N is the number of options (3)
/// - Space Complexity: O(1) auxiliary space
class KidsPrepositionsLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsPrepositionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsPrepositionsLayout> createState() => _KidsPrepositionsLayoutState();
}

class _KidsPrepositionsLayoutState extends State<KidsPrepositionsLayout> {
  final ValueNotifier<bool> _isHoveringTarget = ValueNotifier<bool>(false);
  String? _selectedOption;
  String? _lastQuestId;

  @override
  void dispose() {
    _isHoveringTarget.dispose();
    super.dispose();
  }

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String option,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = option;
    });

    final quest = state.currentQuest;
    final isCorrect =
        (option.trim().toLowerCase() ==
        (quest.correctAnswer ?? '').trim().toLowerCase());

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsPrepositionsLayout: Submitted option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsPrepositions',
      );
    }

    if (isCorrect) {
      di.sl<HapticService>().success();
      // Speak the completed, grammatically whole sentence for ESL reinforcement
      final gapInfo = PrepositionsQuestHelper.parseGapQuest(quest);
      final sentenceToSpeak = PrepositionsQuestHelper.hasBlank(quest)
          ? gapInfo.completedSentence(option)
          : option;
      di.sl<KidsTTSService>().speak(sentenceToSpeak, force: true);
    } else {
      di.sl<HapticService>().error();
      // Speak the chosen word
      di.sl<KidsTTSService>().speak(option, force: true);
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsPrepositionsLayout: Pronouncing option "$text"',
        tag: 'KidsPrepositions',
      );
    }
    di.sl<KidsTTSService>().speak(text, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsPrepositionsLayout: Replaying audio "$instruction" for quest "${quest.id}"',
          tag: 'KidsPrepositions',
        );
      }
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'prepositions',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        // Reset local selection state on quest transition or retry
        if (_lastQuestId != quest.id || !state.answerStatus.isAnswered) {
          _lastQuestId = quest.id;
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 680;
            final isNarrow = constraints.maxWidth < 360;
            final isSentenceChoice =
                !PrepositionsQuestHelper.hasBlank(quest) ||
                PrepositionsQuestHelper.hasLongOptions(quest);

            return Column(
              children: [
                SizedBox(
                  height: isCompactHeight
                      ? 50.h
                      : KidsGameBaseScreen.mascotClearanceHeight,
                ),

                // Main Interactive Magic Stage
                Expanded(
                  flex: isSentenceChoice
                      ? (isCompactHeight ? 4 : 4)
                      : (isCompactHeight ? 5 : 5),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    child: Center(
                      child: _buildMagicStage(
                        context,
                        state,
                        quest,
                        isCompactHeight,
                        isNarrow,
                        isSentenceChoice,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: isCompactHeight ? 6.h : 12.h),

                // Interactive Guidance Pill
                _buildActionPrompt(context, state, quest, isSentenceChoice),

                SizedBox(height: isCompactHeight ? 6.h : 10.h),

                // Magician Options Shelf (Hats or Sentence Scrolls)
                Flexible(
                  flex: isSentenceChoice
                      ? (isCompactHeight ? 6 : 6)
                      : (isCompactHeight ? 5 : 5),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: isCompactHeight ? 10.h : 20.h,
                      left: 12.w,
                      right: 12.w,
                    ),
                    child: isSentenceChoice
                        ? _buildSentenceScrollsList(
                            context,
                            state,
                            quest,
                            isCompactHeight,
                          )
                        : _buildTopHatsShelf(
                            context,
                            state,
                            quest,
                            isCompactHeight,
                            isNarrow,
                          ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // CENTRAL MAGIC STAGE
  // ---------------------------------------------------------------------------

  Widget _buildMagicStage(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isCompactHeight,
    bool isNarrow,
    bool isSentenceChoice,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final isIncorrect = state.answerStatus == AnswerStatus.incorrect;
    final gapInfo = PrepositionsQuestHelper.parseGapQuest(quest);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        if (isAnswered) return false;
        _isHoveringTarget.value = true;
        di.sl<HapticService>().selection();
        return true;
      },
      onLeave: (_) {
        _isHoveringTarget.value = false;
      },
      onAcceptWithDetails: (details) {
        _isHoveringTarget.value = false;
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        return ValueListenableBuilder<bool>(
          valueListenable: _isHoveringTarget,
          builder: (context, isHovering, _) {
            Color borderCol = _PrepositionsPalette.stageBorder;
            Color bgCol = isHovering
                ? _PrepositionsPalette.stageHoverBg
                : _PrepositionsPalette.stageBg;

            if (isAnswered) {
              if (isCorrect) {
                borderCol = _PrepositionsPalette.successBorder;
                bgCol = _PrepositionsPalette.successBg;
              } else if (isIncorrect) {
                borderCol = _PrepositionsPalette.errorBorder;
                bgCol = _PrepositionsPalette.errorBg;
              }
            } else if (isHovering) {
              borderCol = _PrepositionsPalette.stageHoverBorder;
            }

            return Semantics(
              label: isSentenceChoice
                  ? 'Sentence question: ${quest.instruction}'
                  : 'Sentence: ${gapInfo.fullSentence}. ${gapInfo.prompt}',
              hint: isAnswered
                  ? 'Question answered.'
                  : 'Double tap to hear instruction, or place a word here.',
              button: true,
              child: InkWell(
                onTap: isAnswered ? null : () => _replayQuestionAudio(quest),
                borderRadius: BorderRadius.circular(24.r),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxHeight: isCompactHeight ? 230.h : 280.h,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: isCompactHeight ? 10.h : 14.h,
                  ),
                  decoration: BoxDecoration(
                    color: bgCol,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: borderCol,
                      width: isHovering || isAnswered ? 3.5.r : 2.5.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isAnswered && isCorrect)
                            ? _PrepositionsPalette.successGlow.withValues(
                                alpha: 0.4,
                              )
                            : (isAnswered && isIncorrect)
                            ? _PrepositionsPalette.errorGlow.withValues(
                                alpha: 0.35,
                              )
                            : _PrepositionsPalette.stageGlow.withValues(
                                alpha: isHovering ? 0.6 : 0.35,
                              ),
                        blurRadius: isHovering || isAnswered ? 24 : 16,
                        spreadRadius: isHovering ? 6 : 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ambient Stars in Background
                      Positioned(
                        top: 8.h,
                        left: 12.w,
                        child: _buildSparkle(12, 0.ms),
                      ),
                      Positioned(
                        bottom: 8.h,
                        left: 16.w,
                        child: _buildSparkle(10, 600.ms),
                      ),
                      Positioned(
                        bottom: 12.h,
                        right: 12.w,
                        child: _buildSparkle(12, 900.ms),
                      ),

                      // Replay Audio Pill in Top Corner
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Semantics(
                          label: 'Listen to instruction',
                          button: true,
                          child: ScaleButton(
                            onTap: () => _replayQuestionAudio(quest),
                            child: Container(
                              padding: EdgeInsets.all(6.r),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.volume_up_rounded,
                                color: Colors.white,
                                size: 16.r,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Stage Content (FittedBox ensures zero overflow on any viewport)
                      Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 340.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Subject Emoji with Magical Halo
                                _buildStageEmoji(
                                  quest.emoji ?? '✨',
                                  isAnswered,
                                  isCorrect,
                                  isCompactHeight,
                                ),

                                SizedBox(height: isCompactHeight ? 6.h : 10.h),

                                // Sentence & Blank Display
                                if (isSentenceChoice)
                                  _buildSentenceChoiceStagePrompt(
                                    quest,
                                    isCompactHeight,
                                  )
                                else
                                  _buildGapSentenceBanner(
                                    context,
                                    gapInfo,
                                    state,
                                    isHovering,
                                    isCompactHeight,
                                    isNarrow,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStageEmoji(
    String emoji,
    bool isAnswered,
    bool isCorrect,
    bool isCompactHeight,
  ) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final double size = isCompactHeight ? 48.sp : 56.sp;

    Widget emojiWidget = Container(
      padding: EdgeInsets.all(isCompactHeight ? 6.r : 8.r),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.25),
        border: Border.all(
          color: (isAnswered && isCorrect)
              ? _PrepositionsPalette.starGold
              : _PrepositionsPalette.stageBorder.withValues(alpha: 0.6),
          width: 2.r,
        ),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size)),
    );

    if (!reduceMotion) {
      if (isAnswered && isCorrect) {
        emojiWidget = emojiWidget.animate().scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.15, 1.15),
          duration: 400.ms,
          curve: Curves.elasticOut,
        );
      } else {
        emojiWidget = emojiWidget
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -3.h,
              end: 3.h,
              duration: 2.seconds,
              curve: Curves.easeInOutSine,
            );
      }
    }

    return emojiWidget;
  }

  /// Sentence display banner for fill-in-the-blank quests.
  Widget _buildGapSentenceBanner(
    BuildContext context,
    PrepositionsGapInfo gapInfo,
    KidsLoaded state,
    bool isHovering,
    bool isCompactHeight,
    bool isNarrow,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final isIncorrect = state.answerStatus == AnswerStatus.incorrect;

    final String slotText = isAnswered
        ? (_selectedOption ?? state.currentQuest.correctAnswer ?? '?')
        : '___';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: isCompactHeight ? 6.h : 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCompactHeight ? 15.sp : (isNarrow ? 14.5.sp : 16.sp),
            fontWeight: FontWeight.w600,
            color: _PrepositionsPalette.mysticText,
            height: 1.4,
          ),
          children: [
            if (gapInfo.prefix.isNotEmpty) TextSpan(text: gapInfo.prefix),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: _buildMagicBlankSlot(
                slotText: slotText,
                isAnswered: isAnswered,
                isCorrect: isCorrect,
                isIncorrect: isIncorrect,
                isHovering: isHovering,
                isCompactHeight: isCompactHeight,
              ),
            ),
            if (gapInfo.suffix.isNotEmpty) TextSpan(text: gapInfo.suffix),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMagicBlankSlot({
    required String slotText,
    required bool isAnswered,
    required bool isCorrect,
    required bool isIncorrect,
    required bool isHovering,
    required bool isCompactHeight,
  }) {
    Color slotBg = _PrepositionsPalette.stageBg;
    Color slotBorder = _PrepositionsPalette.stageBorder;
    Color textColor = _PrepositionsPalette.starGold;

    if (isAnswered) {
      if (isCorrect) {
        slotBg = _PrepositionsPalette.successBg;
        slotBorder = _PrepositionsPalette.successBorder;
        textColor = _PrepositionsPalette.successText;
      } else if (isIncorrect) {
        slotBg = _PrepositionsPalette.errorBg;
        slotBorder = _PrepositionsPalette.errorBorder;
        textColor = _PrepositionsPalette.errorText;
      }
    } else if (isHovering) {
      slotBg = _PrepositionsPalette.stageHoverBg;
      slotBorder = _PrepositionsPalette.starGold;
      textColor = _PrepositionsPalette.starGlow;
    }

    Widget slotWidget = Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.symmetric(
        horizontal: 10.w,
        vertical: isCompactHeight ? 3.h : 4.h,
      ),
      decoration: BoxDecoration(
        color: slotBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: slotBorder, width: 2.r),
        boxShadow: [
          BoxShadow(
            color: slotBorder.withValues(alpha: 0.35),
            blurRadius: isHovering ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        slotText,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompactHeight ? 14.sp : 15.sp,
          fontWeight: FontWeight.w700,
          color: textColor,
          letterSpacing: 0.3,
        ),
      ),
    );

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!reduceMotion && isAnswered && isIncorrect) {
      slotWidget = slotWidget.animate().shake(
        duration: 400.ms,
        hz: 4,
        curve: Curves.easeInOut,
      );
    } else if (!reduceMotion && isAnswered && isCorrect) {
      slotWidget = slotWidget.animate().scale(
        begin: const Offset(0.95, 0.95),
        end: const Offset(1.05, 1.05),
        duration: 300.ms,
        curve: Curves.elasticOut,
      );
    }

    return slotWidget;
  }

  /// Story prompt display for full-sentence choice quests.
  Widget _buildSentenceChoiceStagePrompt(
    KidsQuest quest,
    bool isCompactHeight,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: isCompactHeight ? 6.h : 8.h,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Text(
        quest.instruction,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompactHeight ? 15.sp : 16.sp,
          fontWeight: FontWeight.w600,
          color: _PrepositionsPalette.mysticText,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildSparkle(double size, Duration delay) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    Widget sparkle = Icon(
      Icons.star_rounded,
      color: _PrepositionsPalette.starGold,
      size: size.r,
    );

    if (!reduceMotion) {
      sparkle = sparkle
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scale(
            begin: const Offset(0.6, 0.6),
            end: const Offset(1.3, 1.3),
            duration: 1200.ms,
            delay: delay,
            curve: Curves.easeInOut,
          )
          .fade(begin: 0.3, end: 1.0, duration: 1200.ms, delay: delay);
    }

    return sparkle;
  }

  // ---------------------------------------------------------------------------
  // INTERACTIVE GUIDANCE PROMPT
  // ---------------------------------------------------------------------------

  Widget _buildActionPrompt(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isSentenceChoice,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final isIncorrect = state.answerStatus == AnswerStatus.incorrect;

    String text;
    IconData icon;
    Color color;

    if (isAnswered) {
      if (isCorrect) {
        text = context.tr('games.correct', fallback: 'Correct! Well done.');
        icon = Icons.check_circle_rounded;
        color = _PrepositionsPalette.successBorder;
      } else if (isIncorrect) {
        text = context.tr('games.try_again', fallback: 'Not quite. Try again.');
        icon = Icons.refresh_rounded;
        color = _PrepositionsPalette.errorBorder;
      } else {
        text = '';
        icon = Icons.touch_app_rounded;
        color = Colors.white;
      }
    } else if (isSentenceChoice) {
      text = context.tr(
        'games.kids_prepositions_choose_sentence',
        fallback: 'Choose the sentence that fits.',
      );
      icon = Icons.touch_app_rounded;
      color = Colors.white.withValues(alpha: 0.9);
    } else {
      text = context.tr(
        'games.kids_prepositions_drag',
        fallback: 'Choose the word that fits.',
      );
      icon = Icons.touch_app_rounded;
      color = Colors.white.withValues(alpha: 0.9);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16.r, color: color),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ARCHETYPE A: MAGICIAN TOP HATS SHELF (WORD / PHRASE OPTIONS)
  // ---------------------------------------------------------------------------

  Widget _buildTopHatsShelf(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isCompactHeight,
    bool isNarrow,
  ) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // 50/50 Lifeline check: determine distractor index to dim if hint is active
    int? dimmedDistractorIndex;
    if (state.hintUsed && options.length > 2) {
      for (int i = 0; i < options.length; i++) {
        if (options[i].trim().toLowerCase() !=
            (quest.correctAnswer ?? '').trim().toLowerCase()) {
          dimmedDistractorIndex = i;
          break;
        }
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isSelected = (_selectedOption == option);
        final isDimmedByHint = (dimmedDistractorIndex == index);

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: isNarrow ? 3.w : 5.w),
            child: _buildTopHatItem(
              context,
              state,
              quest,
              option,
              isSelected,
              isDimmedByHint,
              isCompactHeight,
              isNarrow,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildTopHatItem(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text,
    bool isSelected,
    bool isDimmedByHint,
    bool isCompactHeight,
    bool isNarrow,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrectOption =
        (text.trim().toLowerCase() ==
        (quest.correctAnswer ?? '').trim().toLowerCase());

    final hatWidget = Opacity(
      opacity: isDimmedByHint ? 0.25 : 1.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3D Top Hat Graphic
          _buildHatGraphic(
            isCompactHeight,
            isNarrow,
            isSelected,
            isAnswered,
            isCorrectOption,
          ),

          SizedBox(height: isCompactHeight ? 4.h : 6.h),

          // Option Word Plaque with Audio Speaker
          _buildHatPlaque(
            context,
            text,
            isSelected,
            isAnswered,
            isCorrectOption,
            isCompactHeight,
            isNarrow,
          ),
        ],
      ),
    );

    if (isAnswered || isDimmedByHint) {
      return hatWidget;
    }

    return Semantics(
      label: 'Preposition option $text',
      hint: 'Double tap to select, or drag to the blank.',
      button: true,
      child: Draggable<String>(
        data: text,
        maxSimultaneousDrags: 1,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: isNarrow ? 85.w : 95.w,
            child: Transform.scale(
              scale: 1.08,
              child: Opacity(opacity: 0.9, child: hatWidget),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: hatWidget),
        child: ScaleButton(
          onTap: () => _handleOptionSubmit(context, state, text),
          child: hatWidget,
        ),
      ),
    );
  }

  Widget _buildHatGraphic(
    bool isCompactHeight,
    bool isNarrow,
    bool isSelected,
    bool isAnswered,
    bool isCorrectOption,
  ) {
    final double cylinderHeight = isCompactHeight ? 38.h : 46.h;
    final double cylinderWidth = isCompactHeight ? 50.w : 58.w;
    final double brimWidth = isCompactHeight ? 68.w : 78.w;
    final double brimHeight = isCompactHeight ? 7.h : 9.h;

    return SizedBox(
      width: brimWidth + 8.w,
      height: isCompactHeight ? 70.h : 84.h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Bunny Ears peeking out from inside hat
          Positioned(
            top: 2.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -math.pi / 10,
                  child: Container(
                    width: isCompactHeight ? 6.w : 8.w,
                    height: isCompactHeight ? 18.h : 22.h,
                    decoration: BoxDecoration(
                      color: _PrepositionsPalette.bunnyEar,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: _PrepositionsPalette.bunnyInnerEar,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Transform.rotate(
                  angle: math.pi / 10,
                  child: Container(
                    width: isCompactHeight ? 6.w : 8.w,
                    height: isCompactHeight ? 18.h : 22.h,
                    decoration: BoxDecoration(
                      color: _PrepositionsPalette.bunnyEar,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: _PrepositionsPalette.bunnyInnerEar,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Top Hat Cylinder & Brim
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cylinder
                Container(
                  height: cylinderHeight,
                  width: cylinderWidth,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        _PrepositionsPalette.hatCylinder,
                        AppColors.slate900,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(8.r),
                    ),
                    border: Border.all(
                      color: isSelected
                          ? _PrepositionsPalette.starGold
                          : Colors.white24,
                      width: isSelected ? 2.r : 1.r,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      // Crimson Velvet Ribbon Band
                      Container(
                        height: isCompactHeight ? 9.h : 11.h,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _PrepositionsPalette.hatRibbonHighlight,
                              _PrepositionsPalette.hatRibbon,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Brim
                Container(
                  height: brimHeight,
                  width: brimWidth,
                  decoration: BoxDecoration(
                    color: _PrepositionsPalette.hatBrim,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected
                          ? _PrepositionsPalette.starGold
                          : Colors.white12,
                      width: 1.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        offset: const Offset(0, 3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHatPlaque(
    BuildContext context,
    String text,
    bool isSelected,
    bool isAnswered,
    bool isCorrectOption,
    bool isCompactHeight,
    bool isNarrow,
  ) {
    List<Color> plaqueColors = [
      _PrepositionsPalette.plaqueGoldStart,
      _PrepositionsPalette.plaqueGoldEnd,
    ];
    Color borderColor = _PrepositionsPalette.plaqueBorder;
    Color textColor = _PrepositionsPalette.plaqueText;

    if (isAnswered) {
      if (isCorrectOption) {
        plaqueColors = [
          _PrepositionsPalette.successBorder,
          _PrepositionsPalette.successGlow,
        ];
        borderColor = _PrepositionsPalette.successText;
        textColor = Colors.white;
      } else if (isSelected) {
        plaqueColors = [
          _PrepositionsPalette.errorBorder,
          _PrepositionsPalette.errorGlow,
        ];
        borderColor = _PrepositionsPalette.errorText;
        textColor = Colors.white;
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 4.w,
        vertical: isCompactHeight ? 6.h : 8.h,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: plaqueColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor, width: isSelected ? 2.5 : 2.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: 14.w,
              right: 24.w,
            ),
            child: KidsFittedText(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompactHeight
                    ? 13.5.sp
                    : (isNarrow ? 13.5.sp : 14.5.sp),
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
          ),

          // Mini Audio Pronunciation Button on Plaque
          Positioned(
            right: 0,
            child: Semantics(
              label: 'Hear pronunciation for $text',
              button: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _playOptionAudio(text),
                child: Padding(
                  padding: EdgeInsets.all(5.r),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 15.r,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // ARCHETYPE B: FULL SENTENCE CHOICE SCROLLS LIST
  // ---------------------------------------------------------------------------

  Widget _buildSentenceScrollsList(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    bool isCompactHeight,
  ) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      itemCount: options.length,
      separatorBuilder: (_, _) => SizedBox(height: isCompactHeight ? 6.h : 8.h),
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = (_selectedOption == option);
        final isAnswered = state.answerStatus.isAnswered;
        final isCorrect =
            (option.trim().toLowerCase() ==
            (quest.correctAnswer ?? '').trim().toLowerCase());

        return _buildSentenceScrollCard(
          context,
          state,
          option,
          index,
          isSelected,
          isAnswered,
          isCorrect,
          isCompactHeight,
        );
      },
    );
  }

  Widget _buildSentenceScrollCard(
    BuildContext context,
    KidsLoaded state,
    String option,
    int index,
    bool isSelected,
    bool isAnswered,
    bool isCorrect,
    bool isCompactHeight,
  ) {
    Color cardBg = Colors.white;
    Color borderCol = const Color(0xFFCBD5E1);
    Color textColor = AppColors.slate900;

    if (isAnswered) {
      if (isCorrect) {
        cardBg = _PrepositionsPalette.successBg;
        borderCol = _PrepositionsPalette.successBorder;
        textColor = Colors.white;
      } else if (isSelected) {
        cardBg = _PrepositionsPalette.errorBg;
        borderCol = _PrepositionsPalette.errorBorder;
        textColor = Colors.white;
      }
    } else if (isSelected) {
      cardBg = _PrepositionsPalette.plaqueGoldStart.withValues(alpha: 0.2);
      borderCol = _PrepositionsPalette.starGold;
    }

    final cardContent = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: isCompactHeight ? 10.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderCol,
          width: isSelected || isAnswered ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, 3),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Option Badge ("A", "B", "C")
          Container(
            width: isCompactHeight ? 26.r : 30.r,
            height: isCompactHeight ? 26.r : 30.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAnswered && isCorrect
                  ? _PrepositionsPalette.successBorder
                  : (isAnswered && isSelected
                        ? _PrepositionsPalette.errorBorder
                        : _PrepositionsPalette.stageBg),
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index), // 'A', 'B', 'C'
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompactHeight ? 13.sp : 14.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Full sentence text (wraps naturally, zero clipping, zero ellipsis)
          Expanded(
            child: Text(
              option,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompactHeight ? 14.sp : 15.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.35,
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Pronounce Sentence Audio Button
          Semantics(
            label: 'Listen to sentence: $option',
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _playOptionAudio(option),
              child: Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 18.r,
                  color: textColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (isAnswered) {
      return cardContent;
    }

    return Semantics(
      label: 'Option ${String.fromCharCode(65 + index)}: $option',
      hint: 'Double tap to select this sentence.',
      button: true,
      child: ScaleButton(
        onTap: () => _handleOptionSubmit(context, state, option),
        child: cardContent,
      ),
    );
  }
}
