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

/// Design system color palette for the Body Parts Game.
class _ClinicPalette {
  _ClinicPalette._();

  // Clinic Lightbox & X-Ray Display
  static const Color xrayBgDark = Color(0xFF0F172A); // Slate 900
  static const Color xrayBgMid = Color(0xFF1E293B); // Slate 800
  static const Color xrayBorder = Color(0xFF334155); // Slate 700
  static const Color xrayGlow = Color(0xFF38BDF8); // Sky 400 luminous glow

  // Typography & Accents
  static const Color textWhite = Color(0xFFF8FAFC); // Slate 50
  static const Color textCyan = Color(0xFF38BDF8); // Sky 400
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400

  // Band-aid Option Colors
  static const Color bandaidTan = Color(0xFFFDE68A); // Warm beige bandaid
  static const Color bandaidPink = Color(0xFFFCA5A5); // Soft peach bandaid
  static const Color bandaidMint = Color(0xFF6EE7B7); // Mint green bandaid
  static const Color bandaidBlue = Color(0xFF93C5FD); // Sky blue bandaid
  static const Color bandaidPad = Colors.white; // Sterile gauze pad

  // Interactive Target States
  static const Color hoverGlow = Color(0xFF38BDF8); // Luminous cyan target glow

  // Feedback States
  static const Color successBg = Color(0xFFDCFCE7); // Green 100
  static const Color successBorder = Color(0xFF16A34A); // Green 600
  static const Color errorBg = Color(0xFFFFE4E6); // Rose 100
  static const Color errorBorder = Color(0xFFE11D48); // Rose 600
}

/// Production-grade Body Parts & Anatomy Discovery Layout for Kids Zone.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop of colorful band-aids to the
///   X-Ray Lightbox, AND accessible tap-to-answer for younger or motor-impaired children.
/// - Unspoiled X-Ray Riddle: Clearly presents humanized anatomy and sensory riddles
///   with high readability on a medical scanner lightbox.
/// - Dynamic Optical Lightbox: Medical X-Ray screen with cyan glow, scanner grid,
///   and interactive drop target with hover glow that transforms into a celebratory
///   anatomy reveal upon correct completion.
/// - Audio scaffolding: Pronounces target body parts and instructions on demand
///   and upon submission, with dedicated speaker buttons on the X-Ray scanner and band-aids.
/// - Adaptive band-aid layout: Renders cute pediatric pill band-aids for concise
///   vocabulary, and wide horizontal bandage strips for multi-word sensory chains
///   (e.g., "Ears → brain → skin 🎵") with zero text truncation.
/// - Lifeline integration: Automatically dims a distractor band-aid when `hintUsed` is active.
/// - Visual hierarchy & 2026 polish: Rich medical clinic aesthetics, tactile shadows,
///   vibrant feedback states, and full screen-reader Semantics support.
/// - Responsive & scroll-safe: LayoutBuilder + SingleChildScrollView guarantees zero
///   RenderFlex overflows across 320dp to tablet dimensions.
class KidsBodyPartsLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsBodyPartsLayout] widget.
  const KidsBodyPartsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsBodyPartsLayout> createState() => _KidsBodyPartsLayoutState();
}

class _KidsBodyPartsLayoutState extends State<KidsBodyPartsLayout> {
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
        'Body part option selected: "$optionText" (Correct: $isCorrect)',
        tag: 'KidsBodyParts',
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
      final cleanText = _cleanOptionText(optionText);
      di.sl<KidsTTSService>().speak(cleanText, force: true);
    } catch (_) {}

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  String _cleanOptionText(String raw) {
    final lastSpace = raw.lastIndexOf(' ');
    if (lastSpace != -1) {
      final wordOnly = raw.substring(0, lastSpace).trim();
      if (wordOnly.isNotEmpty) return wordOnly;
    }
    return raw.trim();
  }

  void _playOptionAudio(String text) {
    final cleanText = _cleanOptionText(text);
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Playing audio for body part: "$cleanText"',
        tag: 'KidsBodyParts',
      );
    }
    try {
      di.sl<KidsTTSService>().speak(cleanText, force: true);
      di.sl<HapticService>().selection();
    } catch (e) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().warning(
          'Failed to pronounce body part "$cleanText": $e',
          tag: 'KidsBodyParts',
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
          tag: 'KidsBodyParts',
        );
      }
      try {
        di.sl<KidsTTSService>().speak(textToSpeak, force: true);
        di.sl<HapticService>().selection();
      } catch (e) {
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().warning(
            'Failed to replay audio for quest "${quest.id}": $e',
            tag: 'KidsBodyParts',
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
      gameType: 'body_parts',
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

                      // X-Ray Lightbox Target Zone
                      _buildXRayTarget(
                        context,
                        state,
                        quest,
                        isNarrow: isNarrow,
                      ),

                      SizedBox(height: 14.h),

                      // Interaction Instruction Header
                      _buildInteractionPrompt(context, state),

                      SizedBox(height: 12.h),

                      // Band-aid Options
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

  /// Interactive Medical X-Ray Lightbox (Target Zone)
  Widget _buildXRayTarget(
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
              ? 'Correct body part: ${quest.correctAnswer}'
              : 'X-Ray scanner lightbox. Riddle: $instruction. Tap a band-aid below or drag it here.',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: _ClinicPalette.xrayBgMid,
              borderRadius: BorderRadius.circular(22.r),
              border: Border.all(
                color: isHovering
                    ? _ClinicPalette.hoverGlow
                    : (isCorrect
                        ? _ClinicPalette.successBorder
                        : _ClinicPalette.xrayBorder),
                width: isHovering ? 4.5.w : 3.5.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: isHovering
                      ? _ClinicPalette.hoverGlow.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.25),
                  blurRadius: isHovering ? 20 : 12,
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
                // Lightbox Scanner Top Header
                _buildLightboxHeader(quest, isHovering: isHovering),

                // Main X-Ray Screen Pane Area
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
                        _ClinicPalette.xrayBgDark,
                        _ClinicPalette.xrayBgMid,
                      ],
                    ),
                    border: Border.all(
                      color: _ClinicPalette.xrayGlow.withValues(alpha: 0.45),
                      width: 1.5.w,
                    ),
                  ),
                  child: isCorrect
                      ? _buildCelebratoryReveal(quest)
                      : _buildXRayContent(
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

  /// Lightbox Scanner Top Header with Status & Audio Button
  Widget _buildLightboxHeader(KidsQuest quest, {required bool isHovering}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _ClinicPalette.xrayBgDark,
        border: Border(
          bottom: BorderSide(
            color: _ClinicPalette.xrayBorder,
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
                Icons.medical_services_rounded,
                size: 16.r,
                color: _ClinicPalette.textCyan,
              ),
              SizedBox(width: 6.w),
              Text(
                'X-RAY SCANNER',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: _ClinicPalette.textCyan,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          // Audio Replay Button
          ScaleButton(
            key: const ValueKey('body_parts_audio_replay_btn'),
            onTap: () => _replayQuestionAudio(quest),
            child: Container(
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: _ClinicPalette.xrayBgMid,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ClinicPalette.textCyan.withValues(alpha: 0.5),
                  width: 1.2.w,
                ),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 16.r,
                color: _ClinicPalette.textCyan,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Unspoiled X-Ray Riddle content inside the lightbox
  Widget _buildXRayContent(
    KidsQuest quest,
    bool isHovering, {
    required bool isNarrow,
  }) {
    final instruction = InstructionHelper.getInstruction(quest);
    final question = quest.question ?? '';
    final hasDistinctQuestion = question.isNotEmpty &&
        question != '?' &&
        question != instruction;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Sensory/Anatomy clue badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: _ClinicPalette.xrayGlow.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.psychology_rounded,
                size: 14.r,
                color: _ClinicPalette.textCyan,
              ),
              SizedBox(width: 5.w),
              Text(
                'BODY CLUE',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: _ClinicPalette.textCyan,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: 10.h),

        // Main Clue / Riddle text
        Text(
          instruction,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isNarrow ? 15.sp : 16.5.sp,
            fontWeight: FontWeight.w600,
            color: _ClinicPalette.textWhite,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),

        if (hasDistinctQuestion) ...[
          SizedBox(height: 8.h),
          Text(
            question,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isNarrow ? 16.sp : 18.sp,
              fontWeight: FontWeight.w700,
              color: _ClinicPalette.textCyan,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],

        SizedBox(height: 12.h),

        // Drop zone indicator
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _ClinicPalette.hoverGlow.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: isHovering
                  ? _ClinicPalette.hoverGlow
                  : _ClinicPalette.xrayGlow.withValues(alpha: 0.4),
              width: 1.5.w,
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
                    ? _ClinicPalette.hoverGlow
                    : _ClinicPalette.textCyan,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  isHovering ? 'Drop band-aid here!' : 'Place band-aid on the X-Ray',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.5.sp,
                    fontWeight: FontWeight.w600,
                    color: isHovering
                        ? _ClinicPalette.hoverGlow
                        : _ClinicPalette.textCyan,
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
    final emoji = quest.emoji ?? '✨';
    final correctAnswer = quest.correctAnswer ?? 'Correct';

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: _ClinicPalette.xrayBgDark,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _ClinicPalette.successBorder,
          width: 2.w,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji pop
          Text(
            emoji,
            style: TextStyle(fontSize: 46.sp),
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

          // Correct Answer Badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_rounded,
                size: 20.r,
                color: _ClinicPalette.successBorder,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  correctAnswer,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w800,
                    color: _ClinicPalette.successBorder,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),

          if (quest.explanation != null && quest.explanation!.isNotEmpty) ...[
            SizedBox(height: 6.h),
            Text(
              quest.explanation!,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w500,
                color: _ClinicPalette.textMuted,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  /// Interaction instruction banner between target and choices
  Widget _buildInteractionPrompt(BuildContext context, KidsLoaded state) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: _ClinicPalette.xrayGlow.withValues(alpha: 0.4),
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
            color: _ClinicPalette.xrayBgDark,
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              context.tr(
                'games.kids_body_parts_drag',
                fallback: 'Drag the band-aid to the X-Ray or tap to choose!',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _ClinicPalette.xrayBgDark,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Band-aid Options Section (handles both short words & wide sensory chain strips)
  Widget _buildOptionsSection(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required bool isNarrow,
  }) {
    final options = quest.options ?? [];
    if (options.isEmpty) return const SizedBox.shrink();

    // Check if options are short single words or longer sensory chains
    final bool areAllOptionsShort =
        options.every((opt) => opt.trim().length <= 14);

    // Identify distractor band-aid to dim if hint is active
    String? hintDimOption;
    if (state.hintUsed && !state.answerStatus.isAnswered) {
      hintDimOption = options.firstWhere(
        (opt) => opt != quest.correctAnswer,
        orElse: () => '',
      );
      if (hintDimOption.isEmpty) hintDimOption = null;
    }

    if (areAllOptionsShort) {
      // Pill-shaped Band-aids in a responsive Wrap
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: isNarrow ? 10.w : 14.w,
        runSpacing: isNarrow ? 10.h : 14.h,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isDimmedByHint = (option == hintDimOption);
          return _buildBandaidPill(
            context,
            state,
            quest,
            option,
            index: index,
            isDimmedByHint: isDimmedByHint,
            isNarrow: isNarrow,
          );
        }),
      );
    } else {
      // Wide Horizontal Bandage Strips for sensory chains / longer text
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isDimmedByHint = (option == hintDimOption);
          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _buildWideBandageStrip(
              context,
              state,
              quest,
              option,
              index: index,
              isDimmedByHint: isDimmedByHint,
            ),
          );
        }),
      );
    }
  }

  /// Compact Pill-shaped Band-aid (for short body parts)
  Widget _buildBandaidPill(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required int index,
    required bool isDimmedByHint,
    required bool isNarrow,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    const colors = [
      _ClinicPalette.bandaidTan,
      _ClinicPalette.bandaidPink,
      _ClinicPalette.bandaidMint,
      _ClinicPalette.bandaidBlue,
    ];

    Color bgColor = colors[index % colors.length];
    Color borderColor = Colors.black.withValues(alpha: 0.15);
    Color shadowColor = Colors.black.withValues(alpha: 0.2);

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          bgColor = _ClinicPalette.successBg;
          borderColor = _ClinicPalette.successBorder;
          shadowColor = _ClinicPalette.successBorder.withValues(alpha: 0.5);
        } else {
          bgColor = _ClinicPalette.errorBg;
          borderColor = _ClinicPalette.errorBorder;
          shadowColor = _ClinicPalette.errorBorder.withValues(alpha: 0.5);
        }
      } else if (isCorrectOption) {
        bgColor = _ClinicPalette.successBg;
        borderColor = _ClinicPalette.successBorder;
        shadowColor = _ClinicPalette.successBorder.withValues(alpha: 0.5);
      }
    }

    final double bandaidWidth = isNarrow ? 94.w : 108.w;
    final double bandaidHeight = isNarrow ? 68.h : 74.h;

    Widget bandaidVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Container(
        width: bandaidWidth,
        height: bandaidHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(bandaidHeight / 2),
          border: Border.all(color: borderColor, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, 4.h),
              blurRadius: 4,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Band-aid ventilation dots
            Positioned(
              left: 10.w,
              top: 14.h,
              child: const _BandaidDot(),
            ),
            Positioned(
              left: 10.w,
              bottom: 14.h,
              child: const _BandaidDot(),
            ),
            Positioned(
              right: 10.w,
              top: 14.h,
              child: const _BandaidDot(),
            ),
            Positioned(
              right: 10.w,
              bottom: 14.h,
              child: const _BandaidDot(),
            ),

            // Center Sterile Gauze Pad
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: _ClinicPalette.bandaidPad.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ),

            // Speaker button for pronunciation
            Positioned(
              top: 3.r,
              right: 3.r,
              child: Semantics(
                label: 'Hear $text pronounced',
                button: true,
                child: ScaleButton(
                  key: ValueKey('speaker_bandaid_$text'),
                  onTap: () => _playOptionAudio(text),
                  child: Padding(
                    padding: EdgeInsets.all(3.r),
                    child: Icon(
                      Icons.volume_up_rounded,
                      size: 13.r,
                      color: Colors.black.withValues(alpha: 0.6),
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
        scale: 1.10,
        child: Opacity(
          opacity: 0.95,
          child: bandaidVisual,
        ),
      ),
    );

    final interactiveCard = ScaleButton(
      onTap: isAnswered || isDimmedByHint
          ? null
          : () => _handleOptionSubmit(context, state, text),
      child: bandaidVisual,
    );

    return Semantics(
      label: 'Band-aid $text. Tap to choose, or drag to the X-Ray.',
      button: true,
      enabled: !isAnswered && !isDimmedByHint,
      child: isAnswered || isDimmedByHint
          ? bandaidVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: bandaidVisual),
              child: interactiveCard,
            ),
    );
  }

  /// Wide Horizontal Bandage Strip (for sensory chains / longer option texts)
  Widget _buildWideBandageStrip(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String text, {
    required int index,
    required bool isDimmedByHint,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrectOption = (text == quest.correctAnswer);

    const colors = [
      _ClinicPalette.bandaidTan,
      _ClinicPalette.bandaidPink,
      _ClinicPalette.bandaidMint,
      _ClinicPalette.bandaidBlue,
    ];

    Color bgColor = colors[index % colors.length];
    Color borderColor = Colors.black.withValues(alpha: 0.15);
    Color shadowColor = Colors.black.withValues(alpha: 0.2);

    if (isAnswered) {
      if (isSelected) {
        if (isCorrectOption) {
          bgColor = _ClinicPalette.successBg;
          borderColor = _ClinicPalette.successBorder;
          shadowColor = _ClinicPalette.successBorder.withValues(alpha: 0.5);
        } else {
          bgColor = _ClinicPalette.errorBg;
          borderColor = _ClinicPalette.errorBorder;
          shadowColor = _ClinicPalette.errorBorder.withValues(alpha: 0.5);
        }
      } else if (isCorrectOption) {
        bgColor = _ClinicPalette.successBg;
        borderColor = _ClinicPalette.successBorder;
        shadowColor = _ClinicPalette.successBorder.withValues(alpha: 0.5);
      }
    }

    Widget stripVisual = Opacity(
      opacity: isDimmedByHint ? 0.35 : 1.0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 2.w),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, 4.h),
              blurRadius: 4,
            ),
          ],
        ),
        child: Row(
          children: [
            // Center Pad Area with clean readable typography
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: _ClinicPalette.bandaidPad.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.5.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    height: 1.25,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Speaker Icon
            ScaleButton(
              key: ValueKey('speaker_bandaid_$text'),
              onTap: () => _playOptionAudio(text),
              child: Padding(
                padding: EdgeInsets.all(4.r),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 18.r,
                  color: Colors.black.withValues(alpha: 0.65),
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
          child: stripVisual,
        ),
      ),
    );

    final interactiveCard = ScaleButton(
      onTap: isAnswered || isDimmedByHint
          ? null
          : () => _handleOptionSubmit(context, state, text),
      child: stripVisual,
    );

    return Semantics(
      label: '$text. Tap to choose, or drag to the X-Ray.',
      button: true,
      enabled: !isAnswered && !isDimmedByHint,
      child: isAnswered || isDimmedByHint
          ? stripVisual
          : Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              feedback: feedbackWidget,
              childWhenDragging: Opacity(opacity: 0.25, child: stripVisual),
              child: interactiveCard,
            ),
    );
  }
}

/// Small ventilation dot for band-aid visual authenticity
class _BandaidDot extends StatelessWidget {
  const _BandaidDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 4.r,
      height: 4.r,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
    );
  }
}
