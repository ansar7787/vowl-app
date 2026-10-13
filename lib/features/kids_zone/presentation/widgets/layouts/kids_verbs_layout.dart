import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

/// Design system color palette for the Verbs Sports Arena & Stadium.
class _VerbsPalette {
  _VerbsPalette._();

  // Stadium Architecture
  static const Color stadiumDark = Color(0xFF0F172A); // Slate 900
  static const Color stadiumFrame = Color(0xFF1E293B); // Slate 800
  static const Color stadiumBorder = Color(0xFF334155); // Slate 700
  static const Color scoreboardGlow = Color(0xFFFBBF24); // Amber 400
  static const Color ledAmber = Color(0xFFF59E0B); // Amber 500
  static const Color stadiumFloodlight = Color(0xFF38BDF8); // Sky 400

  // Pitch / Turf Field
  static const Color turfLight = Color(0xFF22C55E); // Green 500
  static const Color turfDark = Color(0xFF16A34A); // Green 600

  // Ball Colors
  static const Color soccerWhite = Colors.white;
  static const Color soccerBlack = Color(0xFF1E293B);
  static const Color basketballOrange = Color(0xFFEA580C);
  static const Color basketballLine = Color(0xFF1E1B4B);
  static const Color tennisLime = Color(0xFFA3E635);
  static const Color tennisSeam = Colors.white;
  static const Color baseballWhite = Color(0xFFF8FAFC);
  static const Color baseballStitch = Color(0xFFDC2626);

  // Interactive Target States
  static const Color hoverTargetGlow = Color(0xFFFBBF24); // Amber 400
  static const Color goalGlowGreen = Color(0xFF10B981); // Emerald 500

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
}

/// Parsed metadata for an option card in the Verbs game.
/// Isolates the action verb string from the trailing emoji icon while
/// keeping the original raw text for exact answer verification.
class VerbOptionData {
  final String raw;
  final String verbText;
  final String? emoji;

  const VerbOptionData({
    required this.raw,
    required this.verbText,
    this.emoji,
  });

  factory VerbOptionData.parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return VerbOptionData(raw: text, verbText: text);
    }

    final generalEmojiRegExp = RegExp(
      r'[\u{1F000}-\u{1FAFF}\u{2000}-\u{3300}\u{FE00}-\u{FE0F}\u{200D}\u{2600}-\u{27BF}]+',
      unicode: true,
    );
    final trailingEmojiRegExp = RegExp(
      r'[\u{1F000}-\u{1FAFF}\u{2000}-\u{3300}\u{FE00}-\u{FE0F}\u{200D}\u{2600}-\u{27BF}]+$',
      unicode: true,
    );

    final match = trailingEmojiRegExp.firstMatch(trimmed);
    if (match != null && match.start > 0) {
      final titleStr = trimmed.substring(0, match.start).trim();
      final emojiStr = trimmed.substring(match.start).trim();
      final cleanTitle = titleStr.replaceAll(generalEmojiRegExp, '').trim();
      return VerbOptionData(
        raw: text,
        verbText: cleanTitle.isNotEmpty ? cleanTitle : text,
        emoji: emojiStr.isNotEmpty ? emojiStr : null,
      );
    }

    final allMatches = generalEmojiRegExp.allMatches(trimmed).toList();
    if (allMatches.isNotEmpty) {
      final emojiChars = allMatches.map((m) => m.group(0)).join();
      final cleanTitle = trimmed.replaceAll(generalEmojiRegExp, '').trim();
      return VerbOptionData(
        raw: text,
        verbText: cleanTitle.isNotEmpty ? cleanTitle : text,
        emoji: emojiChars.isNotEmpty ? emojiChars : null,
      );
    }

    return VerbOptionData(raw: text, verbText: trimmed);
  }
}

/// Production-grade Sports Stadium Theme for Kids Zone Verbs (Action Words) Game.
///
/// Features standard, professional typography and natural ESL copywriting:
/// - Clear, calm, human instruction text without robotic buzzwords or AI markers.
/// - Balanced proportions and standard font weights (w500 for prose, w600 for labels, w700 for titles).
/// - Fast ESL verb recognition & association through rich real-world action scenarios.
/// - Auditory reinforcement: on-demand pronunciation buttons on scenario clue and all sports balls.
/// - Dual-input accessibility: seamless Drag-and-Drop to the Stadium Jumbotron AND direct Tap-to-Score.
/// - Anti-spoiler design: zero pre-answer emoji leaks.
/// - Responsive & overflow-proof across all screen sizes (320dp to tablets).
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is options count (typically 3..4).
/// - Space Complexity: O(1) auxiliary space.
class KidsVerbsLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsVerbsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsVerbsLayout> createState() => _KidsVerbsLayoutState();
}

class _KidsVerbsLayoutState extends State<KidsVerbsLayout> {
  String? _selectedOption;
  String? _lastQuestId;

  void _syncStateWithQuest(KidsQuest currentQuest) {
    if (_lastQuestId != currentQuest.id) {
      _lastQuestId = currentQuest.id;
      _selectedOption = null;
    }
  }

  bool _isMatch(String option, String? target) {
    if (target == null) return false;
    if (option.trim() == target.trim()) return true;
    final optVerb = VerbOptionData.parse(option).verbText.trim().toLowerCase();
    final tgtVerb = VerbOptionData.parse(target).verbText.trim().toLowerCase();
    if (optVerb.isNotEmpty && tgtVerb.isNotEmpty && optVerb == tgtVerb) {
      return true;
    }
    return false;
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
    final isCorrect = _isMatch(option, quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsVerbsLayout: Submitting verb "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsZone',
      );
    }

    // Audio scaffolding: Pronounce the verb clearly to reinforce ESL acquisition
    final parsed = VerbOptionData.parse(option);
    di.sl<KidsTTSService>().speak(parsed.verbText, force: true);

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    final parsed = VerbOptionData.parse(text);
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsVerbsLayout: Pronouncing option "$text" ("${parsed.verbText}")',
        tag: 'KidsZone',
      );
    }
    di.sl<KidsTTSService>().speak(parsed.verbText, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsVerbsLayout: Replaying clue audio for quest "${quest.id}"',
          tag: 'KidsZone',
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
      gameType: 'verbs',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        _syncStateWithQuest(quest);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            final isShortHeight = constraints.maxHeight < 620;
            final isTablet = constraints.maxWidth > 550;
            final contentWidth = isTablet
                ? 520.0
                : (constraints.maxWidth - 20.w);

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    bottom: 20.h,
                    left: 4.w,
                    right: 4.w,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: isShortHeight
                            ? 50.h
                            : KidsGameBaseScreen.mascotClearanceHeight,
                      ),

                      // Stadium Jumbotron Scoreboard Target
                      _buildJumbotronScoreboard(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                        isShortHeight: isShortHeight,
                      ),

                      SizedBox(height: isShortHeight ? 10.h : 14.h),

                      // Natural Pedagogical Prompt Banner
                      _buildActionPrompt(context, state),

                      SizedBox(height: isShortHeight ? 8.h : 12.h),

                      // Stadium Grass Pitch with Interactive Sports Balls
                      _buildPitchAndSportsBalls(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                        isShortHeight: isShortHeight,
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

  /// Stadium Jumbotron Scoreboard Drop Zone and Action Display
  Widget _buildJumbotronScoreboard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
    required bool isShortHeight,
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
              ? 'Goal scored. The correct verb is ${quest.correctAnswer}'
              : 'Action clue: $instruction. Tap a sports ball, or drag it into the goal.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _VerbsPalette.stadiumDark,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isHovering
                    ? _VerbsPalette.hoverTargetGlow
                    : (isCorrect
                        ? _VerbsPalette.goalGlowGreen
                        : _VerbsPalette.stadiumBorder),
                width: isHovering ? 4.w : 2.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isHovering
                          ? _VerbsPalette.hoverTargetGlow
                          : (isCorrect
                              ? _VerbsPalette.goalGlowGreen
                              : Colors.black))
                      .withValues(alpha: isHovering ? 0.35 : 0.2),
                  blurRadius: isHovering ? 18 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Jumbotron Header Bar
                _buildJumbotronTopBar(context, quest, isHovering: isHovering),

                // Main Scoreboard Clue Screen
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: isShortHeight ? 10.h : 14.h,
                  ),
                  child: isCorrect
                      ? _buildSolvedGoalDisplay(context, quest, isNarrow: isNarrow)
                      : _buildPromptClueDisplay(
                          quest,
                          instruction,
                          isHovering: isHovering,
                          isNarrow: isNarrow,
                          isShortHeight: isShortHeight,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Top Jumbotron Header Bar with Status Beacon and Replay Audio
  Widget _buildJumbotronTopBar(
    BuildContext context,
    KidsQuest quest, {
    required bool isHovering,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _VerbsPalette.stadiumFrame,
        border: Border(
          bottom: BorderSide(
            color: isHovering
                ? _VerbsPalette.hoverTargetGlow.withValues(alpha: 0.4)
                : _VerbsPalette.stadiumBorder,
            width: 1.h,
          ),
        ),
      ),
      child: Row(
        children: [
          // Left Floodlight Beacon
          Container(
            width: 7.r,
            height: 7.r,
            decoration: BoxDecoration(
              color: isHovering
                  ? _VerbsPalette.hoverTargetGlow
                  : _VerbsPalette.stadiumFloodlight,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),

          // Clean, Professional Section Label
          Expanded(
            child: Text(
              context.tr('games.kids_verbs_story', fallback: 'Action Story'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppColors.slate300,
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ),
          SizedBox(width: 8.w),

          // Audio Replay Button for the Scenario
          Semantics(
            label: 'Listen to the story',
            button: true,
            child: ScaleButton(
              onTap: () => _replayQuestionAudio(quest),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.slate700,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.slate600,
                    width: 1.w,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      size: 15.r,
                      color: _VerbsPalette.scoreboardGlow,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      context.tr('common.listen', fallback: 'Listen'),
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
        ],
      ),
    );
  }

  /// Scoreboard in unsolved state: displays rich scenario clue and drop target
  Widget _buildPromptClueDisplay(
    KidsQuest quest,
    String instruction, {
    required bool isHovering,
    required bool isNarrow,
    required bool isShortHeight,
  }) {
    final displayText = (quest.question != null &&
            quest.question!.trim() != '?' &&
            quest.question!.trim().isNotEmpty)
        ? quest.question!
        : instruction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Action Scenario Clue Text
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: isShortHeight ? 10.h : 14.h,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.slate700,
              width: 1.w,
            ),
          ),
          child: Text(
            displayText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isShortHeight ? 15.sp : (isNarrow ? 15.sp : 17.sp),
              fontWeight: FontWeight.w600,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ),

        SizedBox(height: isShortHeight ? 10.h : 12.h),

        // Drop Zone / Goal Target Ring with Natural, Friendly Copy
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: isShortHeight ? 7.h : 9.h,
          ),
          decoration: BoxDecoration(
            color: isHovering
                ? _VerbsPalette.hoverTargetGlow.withValues(alpha: 0.18)
                : AppColors.slate800,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isHovering
                  ? _VerbsPalette.hoverTargetGlow
                  : AppColors.slate600,
              width: isHovering ? 2.w : 1.2.w,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isHovering
                    ? Icons.sports_score_rounded
                    : Icons.touch_app_rounded,
                size: 16.r,
                color: isHovering
                    ? _VerbsPalette.hoverTargetGlow
                    : _VerbsPalette.scoreboardGlow,
              ),
              SizedBox(width: 7.w),
              Flexible(
                child: Text(
                  isHovering
                      ? context.tr('games.kids_verbs_drop_hover', fallback: 'Drop here to score!')
                      : context.tr('games.kids_verbs_drop_target', fallback: 'Tap a ball, or drag it into the goal'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: isHovering ? FontWeight.w600 : FontWeight.w500,
                    color: isHovering
                        ? _VerbsPalette.hoverTargetGlow
                        : AppColors.slate300,
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

  /// Scoreboard in solved state: celebrates goal with target verb and hero emoji
  Widget _buildSolvedGoalDisplay(
    BuildContext context,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final parsed = VerbOptionData.parse(quest.correctAnswer ?? '');
    final heroEmoji = parsed.emoji ?? quest.emoji ?? '⚽';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Clean Celebratory Badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _VerbsPalette.goalGlowGreen,
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: _VerbsPalette.goalGlowGreen.withValues(alpha: 0.4),
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 15.r,
                color: Colors.white,
              ),
              SizedBox(width: 6.w),
              Text(
                context.tr('games.kids_verbs_goal', fallback: 'Goal!'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 350.ms, curve: Curves.elasticOut),

        SizedBox(height: 10.h),

        // Celebratory Hero Emoji & Word
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              heroEmoji,
              style: TextStyle(fontSize: 42.sp),
            ).animate().scale(duration: 400.ms, curve: Curves.elasticOut),
            SizedBox(width: 12.w),
            Flexible(
              child: Text(
                parsed.verbText.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isNarrow ? 22.sp : 24.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: _VerbsPalette.scoreboardGlow,
                  shadows: const [
                    Shadow(
                      color: _VerbsPalette.ledAmber,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Action Prompt Header under the scoreboard
  Widget _buildActionPrompt(BuildContext context, KidsLoaded state) {
    return KidsFittedText(
      context.tr(
        'games.kids_verbs_drag',
        fallback: 'Tap the matching ball or drag it to the scoreboard',
      ),
      style: TextStyle(
        fontFamily: 'Outfit',
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.75),
      ),
      maxLines: 2,
      textAlign: TextAlign.center,
    );
  }

  /// Stadium Pitch and Sports Ball Action Cards
  Widget _buildPitchAndSportsBalls(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
    required bool isShortHeight,
  }) {
    final options = quest.options ?? const [];

    return Container(
      decoration: BoxDecoration(
        color: _VerbsPalette.turfDark,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 2.5.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Field Pitch Striped Turf & Chalk Lines
          Positioned.fill(
            child: CustomPaint(
              painter: _StadiumPitchPainter(),
            ),
          ),

          // Options Row
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical: isShortHeight ? 12.h : 15.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: () {
                // Dim exactly one distractor when lifeline hint is active
                final firstDistractor = options.firstWhere(
                  (opt) => !_isMatch(opt, quest.correctAnswer),
                  orElse: () => '',
                );

                return List.generate(options.length, (index) {
                  final option = options[index];
                  final isSelected = _selectedOption == option;
                  final isDimmedByHint = state.hintUsed &&
                      firstDistractor.isNotEmpty &&
                      option == firstDistractor;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: _buildSportsBallCard(
                        context,
                        state,
                        quest,
                        option: option,
                        index: index,
                        isSelected: isSelected,
                        isDimmedByHint: isDimmedByHint,
                        isNarrow: isNarrow,
                        isShortHeight: isShortHeight,
                      ),
                    ),
                  );
                });
              }(),
            ),
          ),
        ],
      ),
    );
  }

  /// Individual Sports Ball Card with Authentic Textures and Dual Interaction
  Widget _buildSportsBallCard(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required String option,
    required int index,
    required bool isSelected,
    required bool isDimmedByHint,
    required bool isNarrow,
    required bool isShortHeight,
  }) {
    final parsed = VerbOptionData.parse(option);
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = quest.correctAnswer == option;

    // Determine Sports Ball Type: 0 = Soccer, 1 = Basketball, 2 = Tennis, 3 = Baseball
    final ballTypes = ['soccer', 'basketball', 'tennis', 'baseball'];
    final ballType = ballTypes[index % ballTypes.length];

    // Card background & feedback styling
    Color cardBorderColor = Colors.white.withValues(alpha: 0.35);
    Color cardBgColor = Colors.white.withValues(alpha: 0.94);

    if (isAnswered && isSelected) {
      if (isCorrect) {
        cardBorderColor = _VerbsPalette.successBorder;
        cardBgColor = _VerbsPalette.successBg;
      } else {
        cardBorderColor = _VerbsPalette.errorBorder;
        cardBgColor = _VerbsPalette.errorBg;
      }
    } else if (isAnswered && isCorrect) {
      cardBorderColor = _VerbsPalette.successBorder;
      cardBgColor = _VerbsPalette.successBg;
    }

    final double ballDiameter = isShortHeight ? 50.r : (isNarrow ? 52.r : 58.r);

    Widget ballCardWidget = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Semantics(
        label: 'Action verb option: ${parsed.verbText}. Tap to score, or drag to goal.',
        button: true,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 4.w,
            vertical: isShortHeight ? 6.h : 8.h,
          ),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: cardBorderColor,
              width: isSelected ? 2.5.w : 1.5.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle Pronunciation Speaker Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Semantics(
                    label: 'Pronounce ${parsed.verbText}',
                    button: true,
                    child: ScaleButton(
                      onTap: () => _playOptionAudio(option),
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          size: 13.r,
                          color: AppColors.slate700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 2.h),

              // Authentic Vector Sports Ball
              SizedBox(
                width: ballDiameter,
                height: ballDiameter,
                child: CustomPaint(
                  painter: _getBallPainter(ballType),
                ),
              ),

              SizedBox(height: isShortHeight ? 5.h : 7.h),

              // Action Verb Text with Emoji
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        parsed.verbText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: isShortHeight ? 13.sp : 15.sp,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate900,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                    if (parsed.emoji != null) ...[
                      SizedBox(width: 4.w),
                      Text(
                        parsed.emoji!,
                        style: TextStyle(
                          fontSize: isShortHeight ? 13.sp : 15.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // If game is not answered, enable dual interaction (tap or drag)
    if (!isAnswered && !isDimmedByHint) {
      ballCardWidget = Draggable<String>(
        data: option,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.06,
            child: SizedBox(
              width: 100.w,
              child: Opacity(opacity: 0.95, child: ballCardWidget),
            ),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: ballCardWidget,
        ),
        child: ScaleButton(
          onTap: () => _handleOptionSubmit(context, state, option),
          child: ballCardWidget,
        ),
      );
    }

    return ballCardWidget;
  }

  CustomPainter _getBallPainter(String ballType) {
    switch (ballType) {
      case 'soccer':
        return const _SoccerBallPainter();
      case 'basketball':
        return const _BasketballPainter();
      case 'tennis':
        return const _TennisBallPainter();
      case 'baseball':
      default:
        return const _BaseballPainter();
    }
  }
}

/// Stadium Pitch Turf Painter drawing field stripes and chalk lines
class _StadiumPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final stripePaint = Paint()
      ..color = _VerbsPalette.turfLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    const stripeCount = 6;
    final stripeWidth = size.width / stripeCount;
    for (int i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(i * stripeWidth, 0, stripeWidth, size.height),
        stripePaint,
      );
    }

    // Top chalk line
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(0, 1),
      Offset(size.width, 1),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Authentic Vector Soccer Ball with geometric pentagon patterns
class _SoccerBallPainter extends CustomPainter {
  const _SoccerBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ball Base
    final basePaint = Paint()
      ..color = _VerbsPalette.soccerWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // Ball Shadow / 3D shading
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.22),
        ],
        stops: const [0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);

    // Center Pentagon
    final patchPaint = Paint()
      ..color = _VerbsPalette.soccerBlack
      ..style = PaintingStyle.fill;

    final centerPentagon = Path();
    final pentagonRadius = radius * 0.38;
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * math.pi / 180;
      final x = center.dx + pentagonRadius * math.cos(angle);
      final y = center.dy + pentagonRadius * math.sin(angle);
      if (i == 0) {
        centerPentagon.moveTo(x, y);
      } else {
        centerPentagon.lineTo(x, y);
      }
    }
    centerPentagon.close();
    canvas.drawPath(centerPentagon, patchPaint);

    // Outer Seams radiating outward
    final seamPaint = Paint()
      ..color = AppColors.slate700
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * math.pi / 180;
      final startX = center.dx + pentagonRadius * math.cos(angle);
      final startY = center.dy + pentagonRadius * math.sin(angle);
      final endX = center.dx + radius * 0.95 * math.cos(angle);
      final endY = center.dy + radius * 0.95 * math.sin(angle);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), seamPaint);
    }

    // Border
    final borderPaint = Paint()
      ..color = AppColors.slate400
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 0.75, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Authentic Vector Basketball with curved rib lines
class _BasketballPainter extends CustomPainter {
  const _BasketballPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ball Base
    final basePaint = Paint()
      ..color = _VerbsPalette.basketballOrange
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // 3D Rim Shading
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.28),
        ],
        stops: const [0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);

    // Black Rib Lines
    final ribPaint = Paint()
      ..color = _VerbsPalette.basketballLine
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      ribPaint,
    );

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      ribPaint,
    );

    // Left curved arc
    final leftArcPath = Path();
    leftArcPath.moveTo(center.dx, center.dy - radius * 0.9);
    leftArcPath.quadraticBezierTo(
      center.dx - radius * 0.75,
      center.dy,
      center.dx,
      center.dy + radius * 0.9,
    );
    canvas.drawPath(leftArcPath, ribPaint);

    // Right curved arc
    final rightArcPath = Path();
    rightArcPath.moveTo(center.dx, center.dy - radius * 0.9);
    rightArcPath.quadraticBezierTo(
      center.dx + radius * 0.75,
      center.dy,
      center.dx,
      center.dy + radius * 0.9,
    );
    canvas.drawPath(rightArcPath, ribPaint);

    // Border
    final borderPaint = Paint()
      ..color = _VerbsPalette.basketballLine
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 0.9, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Authentic Vector Tennis Ball with parabolic optic seams
class _TennisBallPainter extends CustomPainter {
  const _TennisBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Optic Lime Base
    final basePaint = Paint()
      ..color = _VerbsPalette.tennisLime
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // 3D Shading
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.22),
        ],
        stops: const [0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);

    // White Curved Seams
    final seamPaint = Paint()
      ..color = _VerbsPalette.tennisSeam
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;

    // Left Seam Arc
    final leftSeam = Path();
    leftSeam.moveTo(center.dx - radius * 0.55, center.dy - radius * 0.8);
    leftSeam.quadraticBezierTo(
      center.dx - radius * 0.05,
      center.dy,
      center.dx - radius * 0.55,
      center.dy + radius * 0.8,
    );
    canvas.drawPath(leftSeam, seamPaint);

    // Right Seam Arc
    final rightSeam = Path();
    rightSeam.moveTo(center.dx + radius * 0.55, center.dy - radius * 0.8);
    rightSeam.quadraticBezierTo(
      center.dx + radius * 0.05,
      center.dy,
      center.dx + radius * 0.55,
      center.dy + radius * 0.8,
    );
    canvas.drawPath(rightSeam, seamPaint);

    // Subtle Border
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 0.75, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Authentic Vector Baseball with classic horseshoe red stitching
class _BaseballPainter extends CustomPainter {
  const _BaseballPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Ball Base
    final basePaint = Paint()
      ..color = _VerbsPalette.baseballWhite
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, basePaint);

    // Shading
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.2),
        ],
        stops: const [0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, shadowPaint);

    // Seam Paths
    final stitchLinePaint = Paint()
      ..color = _VerbsPalette.baseballStitch.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final tickPaint = Paint()
      ..color = _VerbsPalette.baseballStitch
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    // Left curved seam with chevron ticks
    final leftSeam = Path();
    leftSeam.moveTo(center.dx - radius * 0.65, center.dy - radius * 0.75);
    leftSeam.quadraticBezierTo(
      center.dx - radius * 0.2,
      center.dy,
      center.dx - radius * 0.65,
      center.dy + radius * 0.75,
    );
    canvas.drawPath(leftSeam, stitchLinePaint);

    // Right curved seam with chevron ticks
    final rightSeam = Path();
    rightSeam.moveTo(center.dx + radius * 0.65, center.dy - radius * 0.75);
    rightSeam.quadraticBezierTo(
      center.dx + radius * 0.2,
      center.dy,
      center.dx + radius * 0.65,
      center.dy + radius * 0.75,
    );
    canvas.drawPath(rightSeam, stitchLinePaint);

    // Draw V-stitch tick marks along left & right arcs
    for (int i = 1; i <= 6; i++) {
      final t = i / 7.0;
      final y = center.dy - radius * 0.65 + t * (radius * 1.3);

      // Left ticks
      final leftX = center.dx - radius * 0.65 + (1 - (2 * (t - 0.5)).abs()) * radius * 0.45;
      canvas.drawLine(
        Offset(leftX - 3.5, y - 2),
        Offset(leftX + 3.5, y + 2),
        tickPaint,
      );

      // Right ticks
      final rightX = center.dx + radius * 0.65 - (1 - (2 * (t - 0.5)).abs()) * radius * 0.45;
      canvas.drawLine(
        Offset(rightX - 3.5, y + 2),
        Offset(rightX + 3.5, y - 2),
        tickPaint,
      );
    }

    // Border
    final borderPaint = Paint()
      ..color = AppColors.slate300
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius - 0.75, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
