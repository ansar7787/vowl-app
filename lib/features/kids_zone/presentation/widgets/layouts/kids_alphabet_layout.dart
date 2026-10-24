import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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

/// Design system color palette for the Alphabet Explorer Game.
class _AlphabetPalette {
  _AlphabetPalette._();

  // Classroom Blackboard Colors
  static const Color slateDark = Color(0xFF143026); // Deep forest blackboard
  static const Color slateLight = Color(0xFF1E4537); // Mid chalkboard
  static const Color chalkDustGreen = Color(0xFF2D6A4F); // Chalk green border

  // Wooden Frame
  static const Color woodFrameDark = Color(0xFF5C3A21); // Rich timber
  static const Color woodFrameMedium = Color(0xFF8B5A2B); // Warm teak
  static const Color woodFrameBorder = Color(0xFF3E2312); // Deep wood border

  // Chalk Typography
  static const Color chalkWhite = Color(0xFFF8FAFC); // Crisp chalk white
  static const Color chalkYellow = Color(0xFFFDE68A); // Warm chalk yellow
  static const Color chalkMint = Color(0xFFA7F3D0); // Mint chalk accent
  static const Color chalkHighlight = Color(0xFFFCD34D); // Highlight yellow

  // Wooden Alphabet Blocks (Options)
  static const Color woodBlockBg = Color(0xFFFFFBEB); // Smooth pale maple
  static const Color woodBlockBorder = Color(0xFFF59E0B); // Amber 500 edge
  static const Color woodBlockShadow = Color(0xFFB45309); // Amber 700 3D shadow
  static const Color woodBlockText = Color(0xFF78350F); // Deep engraved wood text

  // Interactive Target States
  static const Color hoverGlow = Color(0xFFFBBF24); // Amber 400 target glow

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color successText = Color(0xFF15803D); // Green 700
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
  static const Color errorText = Color(0xFFBE123C); // Rose 700
}

/// Production-grade Alphabet & Letter Recognition Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop of wooden letter blocks to the Chalkboard,
///   AND accessible tap-to-answer for younger learners or motor-impaired children.
/// - Unspoiled classroom chalkboard: Displays clear, unoccluded letter riddles and instructions
///   with high-contrast chalk styling.
/// - Dynamic Chalkboard target: Features rich wooden timber trim, soft chalk dust borders,
///   and an interactive drop target with hover glow that transforms into a celebratory
///   phonetic letter reveal upon correct completion.
/// - Audio scaffolding: Pronounces target alphabet letters and example words on demand
///   and upon submission, with dedicated speaker buttons on the chalkboard and wooden blocks.
/// - Adaptive card layout: Automatically renders tactile 3D wooden alphabet blocks for
///   individual letters or short words, and wide horizontal wooden banners for longer words
///   or skipped-sequence problems (Batches 1-20 safe).
/// - Lifeline integration: Automatically dims a distractor block when `hintUsed` is active.
/// - Visual hierarchy & 2026 polish: Rich wood textures, tactile cartoon shadows, vibrant
///   feedback states, and full screen-reader Semantics support.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees zero
///   RenderFlex overflows across 320dp to tablet dimensions.
class KidsAlphabetLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsAlphabetLayout] widget.
  const KidsAlphabetLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsAlphabetLayout> createState() => _KidsAlphabetLayoutState();
}

class _KidsAlphabetLayoutState extends State<KidsAlphabetLayout> {
  String? _selectedOption;
  String? _lastQuestId;

  void _syncStateWithQuest(KidsQuest currentQuest) {
    if (_lastQuestId != currentQuest.id) {
      _lastQuestId = currentQuest.id;
      _selectedOption = null;
    }
  }

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String optionText,
  ) {
    if (state.answerStatus.isAnswered) return;

    final quest = state.currentQuest;
    final isCorrect = (optionText.trim() == quest.correctAnswer?.trim());

    setState(() {
      _selectedOption = optionText;
    });

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Alphabet option selected: "$optionText" (Correct: $isCorrect)',
        tag: 'KidsAlphabet',
      );
    }

    try {
      if (isCorrect) {
        di.sl<HapticService>().success();
      } else {
        di.sl<HapticService>().error();
      }
    } catch (_) {}

    try {
      di.sl<KidsTTSService>().speak(optionText, force: true);
    } catch (_) {}

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Playing phonetic audio for option: "$text"',
        tag: 'KidsAlphabet',
      );
    }
    try {
      di.sl<KidsTTSService>().speak(text, force: true);
      di.sl<HapticService>().selection();
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'Failed to pronounce letter "$text": $e',
          tag: 'KidsAlphabet',
        );
      }
    }
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final textToSpeak = instruction.isNotEmpty
        ? (question.isNotEmpty && question != '?'
            ? '$instruction $question'
            : instruction)
        : question;

    if (textToSpeak.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying instruction audio for quest "${quest.id}"',
          tag: 'KidsAlphabet',
        );
      }
      try {
        di.sl<KidsTTSService>().speak(textToSpeak, force: true);
        di.sl<HapticService>().selection();
      } catch (e) {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().warning(
            'Failed to replay audio for quest "${quest.id}": $e',
            tag: 'KidsAlphabet',
          );
        }
      }
    }
  }
  @override
  void dispose() {
    try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'alphabet',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        _syncStateWithQuest(quest);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final isTablet = constraints.maxWidth > 550;
            final contentWidth = isTablet
                ? 520.0
                : (constraints.maxWidth - 24.w);

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: 24.h,
                    left: 4.w,
                    right: 4.w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: KidsGameBaseScreen.mascotClearanceHeight + 12.h,
                      ),

                      // Blackboard Target Zone
                      _buildChalkboardTarget(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 14.h),

                      // Action Instruction Header
                      _buildInteractionPrompt(context, state),

                      SizedBox(height: 12.h),

                      // Alphabet Wooden Block Options
                      _buildOptionsSection(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
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

  /// Interactive Classroom Blackboard (Target Zone)
  Widget _buildChalkboardTarget(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final instruction = InstructionHelper.getInstruction(quest);

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !isAnswered,
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Semantics(
          label: isCorrect
              ? 'Correct letter: ${quest.correctAnswer}'
              : 'Classroom blackboard. Instruction: $instruction. Tap an answer below or drag it here.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _AlphabetPalette.woodFrameMedium,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: isHovering
                    ? _AlphabetPalette.hoverGlow
                    : (isCorrect
                        ? _AlphabetPalette.successBorder
                        : _AlphabetPalette.woodFrameBorder),
                width: isHovering ? 4.5.w : 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? _AlphabetPalette.hoverGlow.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.22),
                  blurRadius: isHovering ? 18 : 10,
                  offset: const Offset(0, 6),
                  spreadRadius: isHovering ? 2 : 0,
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Frame Header with Slate Label & Audio Button
                _buildFrameHeader(quest, isHovering: isHovering),

                // Main Slate Board Area
                Container(
                  margin: EdgeInsets.all(8.r),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12.w : 16.w,
                    vertical: 14.h,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _AlphabetPalette.slateDark,
                        _AlphabetPalette.slateLight,
                      ],
                    ),
                    border: Border.all(
                      color: _AlphabetPalette.chalkDustGreen.withValues(alpha: 0.5),
                      width: 1.5.w,
                    ),
                  ),
                  child: isCorrect
                      ? _buildCelebratoryReveal(quest)
                      : _buildChalkboardContent(
                          quest,
                          isHovering,
                          isNarrow: isNarrow,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Decorative Timber Frame Top Header
  Widget _buildFrameHeader(KidsQuest quest, {required bool isHovering}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _AlphabetPalette.woodFrameDark,
        border: Border(
          bottom: BorderSide(
            color: _AlphabetPalette.woodFrameBorder,
            width: 1.5.w,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_rounded,
                size: 16.r,
                color: _AlphabetPalette.chalkYellow,
              ),
              SizedBox(width: 6.w),
              Text(
                'ALPHABET BOARD',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _AlphabetPalette.chalkYellow,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          // Speaker button to replay instruction & question
          ScaleButton(
            key: const ValueKey('alphabet_audio_replay_btn'),
            onTap: () => _replayQuestionAudio(quest),
            child: Container(
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: _AlphabetPalette.woodFrameMedium,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _AlphabetPalette.chalkYellow.withValues(alpha: 0.5),
                  width: 1.2.w,
                ),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 16.r,
                color: _AlphabetPalette.chalkYellow,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chalkboard Question/Riddle Content when unanswered
  Widget _buildChalkboardContent(
    KidsQuest quest,
    bool isHovering, {
    required bool isNarrow,
  }) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final hasBoth = instruction.isNotEmpty &&
        question.isNotEmpty &&
        question != '?' &&
        instruction != question;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (hasBoth) ...[
          Text(
            instruction,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 14.sp : 15.sp,
              fontWeight: FontWeight.w500,
              color: _AlphabetPalette.chalkMint,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
        ],

        // Main Letter Riddle / Question
        Text(
          hasBoth
              ? question
              : (question.isNotEmpty && question != '?'
                  ? question
                  : instruction),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isNarrow ? 17.sp : 19.sp,
            fontWeight: FontWeight.w700,
            color: _AlphabetPalette.chalkWhite,
            height: 1.35,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),

        SizedBox(height: 12.h),

        // Drop zone indicator plaque
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _AlphabetPalette.hoverGlow.withValues(alpha: 0.20)
                : Colors.black.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isHovering
                  ? _AlphabetPalette.hoverGlow
                  : _AlphabetPalette.chalkMint.withValues(alpha: 0.45),
              width: 1.5.w,
              strokeAlign: BorderSide.strokeAlignCenter,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pan_tool_alt_rounded,
                size: 15.r,
                color: isHovering
                    ? _AlphabetPalette.hoverGlow
                    : _AlphabetPalette.chalkMint,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  isHovering ? 'Drop letter here!' : 'Place your block here',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering
                        ? _AlphabetPalette.hoverGlow
                        : _AlphabetPalette.chalkMint,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Celebratory Reveal upon correct answer
  Widget _buildCelebratoryReveal(KidsQuest quest) {
    final emoji = (quest.wordEmoji ?? quest.emoji) ?? '⭐';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _AlphabetPalette.slateLight,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _AlphabetPalette.successBorder,
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebratory Emoji with animated scale
          Text(
            emoji,
            style: TextStyle(fontSize: 44.sp),
          )
              .animate()
              .scale(
                duration: 400.ms,
                curve: Curves.elasticOut,
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
              )
              .fadeIn(duration: 250.ms),

          SizedBox(height: 6.h),

          // Correct Answer Letter Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20.r,
                color: _AlphabetPalette.chalkMint,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  quest.correctAnswer ?? '',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: _AlphabetPalette.chalkYellow,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),

          // Example word with highlighted letter if present
          if (quest.wordExample != null && quest.wordExample!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text.rich(
                  TextSpan(
                    children: _buildHighlightedWordSpans(
                      quest.wordExample!,
                      quest.correctAnswer,
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
                SizedBox(width: 8.w),
                ScaleButton(
                  onTap: () => _playOptionAudio(quest.wordExample!),
                  child: Container(
                    padding: EdgeInsets.all(4.r),
                    decoration: BoxDecoration(
                      color: _AlphabetPalette.chalkYellow.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 16.r,
                      color: _AlphabetPalette.chalkYellow,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Phonetic pronunciation guide if present
          if (quest.phonetic != null && quest.phonetic!.isNotEmpty) ...[
            SizedBox(height: 4.h),
            Text(
              '/${quest.phonetic}/',
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: _AlphabetPalette.chalkMint,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }

  /// Helper to highlight the target letter in the word to teach phonetics
  List<TextSpan> _buildHighlightedWordSpans(
    String word,
    String? correctAnswer,
  ) {
    if (correctAnswer == null || correctAnswer.isEmpty) {
      return [
        TextSpan(
          text: word,
          style: const TextStyle(color: _AlphabetPalette.chalkMint),
        ),
      ];
    }

    final lowerWord = word.toLowerCase();
    final lowerTarget = correctAnswer.toLowerCase();
    final index = lowerWord.indexOf(lowerTarget);

    if (index != -1) {
      final before = word.substring(0, index);
      final match = word.substring(index, index + correctAnswer.length);
      final after = word.substring(index + correctAnswer.length);

      return [
        if (before.isNotEmpty)
          TextSpan(
            text: before,
            style: const TextStyle(color: _AlphabetPalette.chalkMint),
          ),
        TextSpan(
          text: match,
          style: const TextStyle(
            color: _AlphabetPalette.chalkHighlight,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (after.isNotEmpty)
          TextSpan(
            text: after,
            style: const TextStyle(color: _AlphabetPalette.chalkMint),
          ),
      ];
    }

    return [
      TextSpan(
        text: word,
        style: const TextStyle(color: _AlphabetPalette.chalkMint),
      ),
    ];
  }

  /// Interaction instruction prompt
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _AlphabetPalette.woodBlockBorder.withValues(alpha: 0.5),
          width: 1.2.w,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 15.r,
            color: _AlphabetPalette.woodBlockText,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              context.tr(
                'games.kids_alphabet_drag',
                fallback: 'Drag the block to the chalkboard or tap to answer!',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _AlphabetPalette.woodBlockText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Options section supporting both short letters & wide sequence cards
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Determine if options are short single letters or full words / sequences
    final bool areAllOptionsShort =
        options.every((opt) => opt.trim().length <= 6);

    // Identify distractor block to dim if hint is active
    String? hintDimOption;
    if (state.hintUsed && !state.answerStatus.isAnswered) {
      hintDimOption = options.firstWhere(
        (opt) => opt != quest.correctAnswer,
        orElse: () => '',
      );
      if (hintDimOption.isEmpty) hintDimOption = null;
    }

    if (areAllOptionsShort) {
      // 3D Wooden Toy Letter Blocks in a responsive Wrap
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: isNarrow ? 12.w : 16.w,
        runSpacing: isNarrow ? 12.h : 16.h,
        children: options.map((option) {
          final isDimmedByHint = (option == hintDimOption);
          return _buildWoodenToyBlock(
            context,
            state,
            quest,
            option,
            isDimmedByHint: isDimmedByHint,
            isNarrow: isNarrow,
          );
        }).toList(),
      );
    } else {
      // Wide Horizontal Wooden Banner Plaques for word/skip sequence options
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options.map((option) {
          final isDimmedByHint = (option == hintDimOption);
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildWideWoodenBanner(
              context,
              state,
              quest,
              option,
              isDimmedByHint: isDimmedByHint,
            ),
          );
        }).toList(),
      );
    }
  }

  /// Tactile 3D Wooden Toy Alphabet Block (for short letters & words)
  Widget _buildWoodenToyBlock(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required bool isDimmedByHint,
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    Color bgColor = _AlphabetPalette.woodBlockBg;
    Color borderColor = _AlphabetPalette.woodBlockBorder;
    Color textColor = _AlphabetPalette.woodBlockText;
    Color shadowColor = _AlphabetPalette.woodBlockShadow;

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          bgColor = _AlphabetPalette.successBg;
          borderColor = _AlphabetPalette.successBorder;
          textColor = _AlphabetPalette.successText;
          shadowColor = _AlphabetPalette.successBorder;
        } else {
          bgColor = _AlphabetPalette.errorBg;
          borderColor = _AlphabetPalette.errorBorder;
          textColor = _AlphabetPalette.errorText;
          shadowColor = _AlphabetPalette.errorBorder;
        }
      } else if (isCorrectOption) {
        bgColor = _AlphabetPalette.successBg;
        borderColor = _AlphabetPalette.successBorder;
        textColor = _AlphabetPalette.successText;
        shadowColor = _AlphabetPalette.successBorder;
      }
    }

    final double blockSize = isNarrow ? 82.w : 92.w;

    Widget blockVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Container(
        width: blockSize,
        height: blockSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(color: borderColor, width: 2.2.w),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.5),
              offset: Offset(0, 6.h),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center Letter / Word
            Padding(
              padding: EdgeInsets.all(6.r),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: text.length <= 2 ? 38.sp : 22.sp,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // Phonetic sound button in corner
            Positioned(
              top: 4.r,
              right: 4.r,
              child: Semantics(
                label: 'Hear $text pronounced',
                button: true,
                child: ScaleButton(
                  key: ValueKey('speaker_block_$text'),
                  onTap: () => _playOptionAudio(text),
                  child: Padding(
                    padding: EdgeInsets.all(4.r),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 14.r,
                      color: textColor.withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final feedbackWidget = Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.12,
        child: Opacity(
          opacity: 0.95,
          child: blockVisual,
        ),
      ),
    );

    final interactiveCard = ScaleButton(
      onTap: isAnswered || isDimmedByHint
          ? null
          : () => _handleOptionSubmit(context, state, text),
      child: blockVisual,
    );

    return Semantics(
      label: 'Letter $text. Tap to choose, or drag to the chalkboard.',
      button: true,
      enabled: !isAnswered && !isDimmedByHint,
      child: isAnswered || isDimmedByHint
          ? blockVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: blockVisual),
              child: interactiveCard,
            ),
    );
  }

  /// Wide Horizontal Wooden Banner (for long words & sequence options)
  Widget _buildWideWoodenBanner(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required bool isDimmedByHint,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    Color bgColor = _AlphabetPalette.woodBlockBg;
    Color borderColor = _AlphabetPalette.woodBlockBorder;
    Color textColor = _AlphabetPalette.woodBlockText;
    Color shadowColor = _AlphabetPalette.woodBlockShadow;

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          bgColor = _AlphabetPalette.successBg;
          borderColor = _AlphabetPalette.successBorder;
          textColor = _AlphabetPalette.successText;
          shadowColor = _AlphabetPalette.successBorder;
        } else {
          bgColor = _AlphabetPalette.errorBg;
          borderColor = _AlphabetPalette.errorBorder;
          textColor = _AlphabetPalette.errorText;
          shadowColor = _AlphabetPalette.errorBorder;
        }
      } else if (isCorrectOption) {
        bgColor = _AlphabetPalette.successBg;
        borderColor = _AlphabetPalette.successBorder;
        textColor = _AlphabetPalette.successText;
        shadowColor = _AlphabetPalette.successBorder;
      }
    }

    Widget bannerVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: shadowColor.withValues(alpha: 0.4),
              offset: Offset(0, 4.h),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Letter / Word Text
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.25,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Pronunciation Speaker Icon
            ScaleButton(
              key: ValueKey('speaker_banner_$text'),
              onTap: () => _playOptionAudio(text),
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 18.r,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final feedbackWidget = Material(
      color: Colors.transparent,
      child: Transform.scale(
        scale: 1.04,
        child: Opacity(
          opacity: 0.95,
          child: bannerVisual,
        ),
      ),
    );

    final interactiveCard = ScaleButton(
      onTap: isAnswered || isDimmedByHint
          ? null
          : () => _handleOptionSubmit(context, state, text),
      child: bannerVisual,
    );

    return Semantics(
      label: '$text. Tap to choose, or drag to the chalkboard.',
      button: true,
      enabled: !isAnswered && !isDimmedByHint,
      child: isAnswered || isDimmedByHint
          ? bannerVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: bannerVisual),
              child: interactiveCard,
            ),
    );
  }
}
