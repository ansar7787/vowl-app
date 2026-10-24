import 'dart:math' as math;
import 'package:flutter/material.dart';
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

/// Isolated color palette specifically for the Cosmic Space / Numbers theme.
class _CosmicPalette {
  _CosmicPalette._();

  static const Color voidDark = Color(0xFF030712); // Gray 950
  static const Color spaceSlate = Color(0xFF0F172A); // Slate 900
  static const Color cockpitPanel = Color(0xFF1E293B); // Slate 800
  static const Color metallicRim = Color(0xFF475569); // Slate 600
  static const Color cyanThruster = Color(0xFF38BDF8); // Sky 400
  static const Color cyanGlow = Color(0xFF0EA5E9); // Sky 500
  static const Color deepCyanGlow = Color(0x330EA5E9);

  // Four Distinct Planetary Bodies
  static const Color planetAzure = Color(0xFF0284C7); // Sky 600
  static const Color planetAzureLight = Color(0xFF38BDF8); // Sky 400
  static const Color planetAzureShadow = Color(0xFF0369A1); // Sky 700

  static const Color planetGold = Color(0xFFD97706); // Amber 600
  static const Color planetGoldLight = Color(0xFFFBBF24); // Amber 400
  static const Color planetGoldShadow = Color(0xFFB45309); // Amber 700

  static const Color planetCrimson = Color(0xFFE11D48); // Rose 600
  static const Color planetCrimsonLight = Color(0xFFFB7185); // Rose 400
  static const Color planetCrimsonShadow = Color(0xFFBE123C); // Rose 700

  static const Color planetAmethyst = Color(0xFF7C3AED); // Violet 600
  static const Color planetAmethystLight = Color(0xFFA78BFA); // Violet 400
  static const Color planetAmethystShadow = Color(0xFF6D28D9); // Violet 700
}

/// Planetary visual theme definition for option differentiation.
class _PlanetTheme {
  final Color primary;
  final Color highlight;
  final Color shadow;
  final String label;

  const _PlanetTheme({
    required this.primary,
    required this.highlight,
    required this.shadow,
    required this.label,
  });
}

const List<_PlanetTheme> _planetThemes = [
  _PlanetTheme(
    primary: _CosmicPalette.planetAzure,
    highlight: _CosmicPalette.planetAzureLight,
    shadow: _CosmicPalette.planetAzureShadow,
    label: 'Blue planet',
  ),
  _PlanetTheme(
    primary: _CosmicPalette.planetGold,
    highlight: _CosmicPalette.planetGoldLight,
    shadow: _CosmicPalette.planetGoldShadow,
    label: 'Golden planet',
  ),
  _PlanetTheme(
    primary: _CosmicPalette.planetCrimson,
    highlight: _CosmicPalette.planetCrimsonLight,
    shadow: _CosmicPalette.planetCrimsonShadow,
    label: 'Red planet',
  ),
  _PlanetTheme(
    primary: _CosmicPalette.planetAmethyst,
    highlight: _CosmicPalette.planetAmethystLight,
    shadow: _CosmicPalette.planetAmethystShadow,
    label: 'Purple planet',
  ),
];

/// Production-grade Cosmic Rocket & Planetary Launchpad Layout for Numbers.
///
/// Features:
/// - Dual interaction: Intuitive Drag-and-Drop AND accessible Tap-to-Answer.
/// - Adaptive target viewport: Circular porthole for short items/emojis;
///   futuristic stardate console for multi-line story problems.
/// - Adaptive options: Distinct celestial planets for numbers/emojis,
///   and sleek cosmic capsule pods for multi-word phrases.
/// - Clean content hierarchy: Mascot speech bubble presents instruction;
///   action cue provides dual-mode guidance and one-tap audio replay.
/// - Audio scaffolding on options for ESL learners.
/// - Zero overflow guarantee with responsive constraints & compact scroll fallback.
/// - Battery-efficient single animation controller with reduced motion support.
///
/// Complexity:
/// - Time Complexity: O(N) where N is options count (3..4)
/// - Space Complexity: O(1) auxiliary space
class KidsNumbersLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsNumbersLayout] widget.
  const KidsNumbersLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsNumbersLayout> createState() => _KidsNumbersLayoutState();
}

class _KidsNumbersLayoutState extends State<KidsNumbersLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _orbitController;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
        try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
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
    final isCorrect = (option == quest.correctAnswer);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsNumbersLayout: Submitted option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsNumbers',
      );
    }

    // Audio pronunciation for ESL reinforcement
    di.sl<KidsTTSService>().speak(option, force: true);

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'KidsNumbersLayout: Pronouncing option "$text"',
        tag: 'KidsNumbers',
      );
    }
    di.sl<KidsTTSService>().speak(text, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    final questionText = quest.question ?? '';
    final textToSpeak = questionText.isNotEmpty && questionText != '?'
        ? '$instruction. $questionText'
        : instruction;

    if (textToSpeak.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'KidsNumbersLayout: Replaying audio "$textToSpeak" for quest "${quest.id}"',
          tag: 'KidsNumbers',
        );
      }
      di.sl<KidsTTSService>().speak(textToSpeak, force: true);
      di.sl<HapticService>().selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'numbers',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        // Reset local selection when question is unanswered (new question or try-again)
        if (state.answerStatus == AnswerStatus.unanswered && _selectedOption != null) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isCompactHeight = maxHeight < 620;
            final topSpacing = isCompactHeight
                ? 48.0.h
                : KidsGameBaseScreen.mascotClearanceHeight;

            final options = quest.options ?? const [];
            final bool hasLongOptions = options.any(
              (opt) => opt.trim().length > 6 || opt.contains(' '),
            );

            final String questionText = quest.question?.trim() ?? '?';
            final int alphaWordCount =
                RegExp(r'[a-zA-Z]{2,}').allMatches(questionText).length;
            final bool isStoryQuestion = questionText.length > 30 ||
                questionText.contains('\n') ||
                alphaWordCount >= 3;

            return SingleChildScrollView(
              physics: isCompactHeight
                  ? const ClampingScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: maxHeight,
                  maxWidth: constraints.maxWidth,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: topSpacing),

                      // Central Rocket Target (Adaptive Porthole or Console)
                      _RocketQuestionTarget(
                        quest: quest,
                        state: state,
                        isStoryQuestion: isStoryQuestion,
                        isCompactHeight: isCompactHeight,
                        maxWidth: constraints.maxWidth,
                        onAcceptOption: (option) =>
                            _handleOptionSubmit(context, state, option),
                        onReplayAudio: () => _replayQuestionAudio(quest),
                      ),

                      SizedBox(height: isCompactHeight ? 10.h : 16.h),

                      // Dynamic Action Hint Subtitle with Audio Replay Button
                      _ActionHintText(
                        isAnswered: state.answerStatus.isAnswered,
                        onReplayAudio: () => _replayQuestionAudio(quest),
                      ),

                      SizedBox(height: isCompactHeight ? 10.h : 16.h),

                      // Planetary Options Area (Spherical Orbs or Capsule Pods)
                      _OptionsLaunchpad(
                        options: options,
                        state: state,
                        selectedOption: _selectedOption,
                        hasLongOptions: hasLongOptions,
                        isCompactHeight: isCompactHeight,
                        orbitAnimation: _orbitController,
                        onOptionSelected: (opt) =>
                            _handleOptionSubmit(context, state, opt),
                        onPlayAudio: _playOptionAudio,
                      ),

                      // Bottom clearance padding for the feedback modal
                      SizedBox(height: isCompactHeight ? 16.h : 24.h),
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
}

/// The central DragTarget. Adapts into a porthole or a navigation console.
class _RocketQuestionTarget extends StatelessWidget {
  final KidsQuest quest;
  final KidsLoaded state;
  final bool isStoryQuestion;
  final bool isCompactHeight;
  final double maxWidth;
  final ValueChanged<String> onAcceptOption;
  final VoidCallback onReplayAudio;

  const _RocketQuestionTarget({
    required this.quest,
    required this.state,
    required this.isStoryQuestion,
    required this.isCompactHeight,
    required this.maxWidth,
    required this.onAcceptOption,
    required this.onReplayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !state.answerStatus.isAnswered,
      onAcceptWithDetails: (details) {
        if (state.answerStatus.isAnswered) return;
        if (di.sl.isRegistered<AppLogger>()) {
          di.sl<AppLogger>().debug(
            'KidsNumbersLayout: Rocket target accepted dropped option: "${details.data}"',
            tag: 'KidsNumbers',
          );
        }
        onAcceptOption(details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        if (isStoryQuestion) {
          return _buildConsoleTarget(context, isHovering);
        } else {
          return _buildPortholeTarget(context, isHovering);
        }
      },
    );
  }

  /// Cylindrical/Porthole Rocket Window for short numerals, counting dots & emojis.
  Widget _buildPortholeTarget(BuildContext context, bool isHovering) {
    final portholeSize = isCompactHeight
        ? math.min(maxWidth * 0.48, 175.0.r)
        : math.min(maxWidth * 0.55, 205.0.r);

    return Semantics(
      label: 'Rocket window. Drop your answer here or tap a planet below.',
      child: ScaleButton(
        onTap: state.answerStatus.isAnswered ? null : onReplayAudio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: portholeSize,
          height: portholeSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isHovering
                ? _CosmicPalette.cockpitPanel
                : _CosmicPalette.voidDark,
            border: Border.all(
              color: isHovering
                  ? _CosmicPalette.cyanThruster
                  : _CosmicPalette.metallicRim,
              width: isHovering ? 8.r : 6.r,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovering
                    ? _CosmicPalette.cyanGlow.withValues(alpha: 0.6)
                    : _CosmicPalette.cyanGlow.withValues(alpha: 0.3),
                blurRadius: isHovering ? 32 : 20,
                spreadRadius: isHovering ? 5 : 2,
              ),
              const BoxShadow(
                color: Colors.black87,
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Cosmic starry atmosphere inside cockpit porthole
              Positioned(top: 22.r, left: 28.r, child: _StarGlyph(size: 9.r)),
              Positioned(bottom: 26.r, right: 26.r, child: _StarGlyph(size: 12.r)),
              Positioned(top: 36.r, right: 32.r, child: _StarGlyph(size: 8.r)),
              Positioned(bottom: 36.r, left: 26.r, child: _StarGlyph(size: 8.r)),

              // Question content
              Padding(
                padding: EdgeInsets.all(18.r),
                child: Center(
                  child: KidsFittedText(
                    quest.question ?? '?',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.25,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 4,
                  ),
                ),
              ),

              // Audio indicator badge in the corner
              Positioned(
                bottom: 8.r,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 3.h),
                  decoration: BoxDecoration(
                    color: _CosmicPalette.spaceSlate.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: _CosmicPalette.cyanThruster.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hearing_rounded,
                        size: 14.r,
                        color: _CosmicPalette.cyanThruster,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'Listen',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Clean question card console for multi-line story problems.
  Widget _buildConsoleTarget(BuildContext context, bool isHovering) {
    return Semantics(
      label: 'Question card. Drop your answer here or tap an option below.',
      child: ScaleButton(
        onTap: state.answerStatus.isAnswered ? null : onReplayAudio,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: isCompactHeight ? 120.h : 140.h,
            maxHeight: 200.h,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: isHovering
                ? _CosmicPalette.cockpitPanel
                : _CosmicPalette.spaceSlate.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: isHovering
                  ? _CosmicPalette.cyanThruster
                  : _CosmicPalette.metallicRim,
              width: isHovering ? 2.5 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isHovering
                    ? _CosmicPalette.cyanGlow.withValues(alpha: 0.5)
                    : _CosmicPalette.deepCyanGlow,
                blurRadius: isHovering ? 26 : 16,
                spreadRadius: isHovering ? 3 : 1,
              ),
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Console status bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8.r,
                        height: 8.r,
                        decoration: const BoxDecoration(
                          color: AppColors.emerald400,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Question',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w700,
                          color: _CosmicPalette.cyanThruster,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.volume_up_rounded,
                    size: 16.r,
                    color: _CosmicPalette.cyanThruster,
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Flexible(
                child: Text(
                  quest.question ?? '?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 5,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StarGlyph extends StatelessWidget {
  final double size;
  const _StarGlyph({required this.size});

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.star_rounded,
      color: Colors.white.withValues(alpha: 0.45),
      size: size,
    );
  }
}

/// Dynamic user cue indicating both tap and drag capability with audio replay.
class _ActionHintText extends StatelessWidget {
  final bool isAnswered;
  final VoidCallback onReplayAudio;

  const _ActionHintText({
    required this.isAnswered,
    required this.onReplayAudio,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    final localizedText = context.tr(
      'games.kids_numbers_drag',
      fallback: 'Tap a planet or drag it to the rocket!',
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: _CosmicPalette.spaceSlate.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _CosmicPalette.cyanThruster.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              localizedText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
          SizedBox(width: 8.w),
          ScaleButton(
            onTap: onReplayAudio,
            child: Container(
              padding: EdgeInsets.all(5.r),
              decoration: BoxDecoration(
                color: _CosmicPalette.cockpitPanel,
                shape: BoxShape.circle,
                border: Border.all(
                  color: _CosmicPalette.cyanThruster.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 15.r,
                color: _CosmicPalette.cyanThruster,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Planetary and pod options launchpad.
class _OptionsLaunchpad extends StatelessWidget {
  final List<String> options;
  final KidsLoaded state;
  final String? selectedOption;
  final bool hasLongOptions;
  final bool isCompactHeight;
  final AnimationController orbitAnimation;
  final ValueChanged<String> onOptionSelected;
  final ValueChanged<String> onPlayAudio;

  const _OptionsLaunchpad({
    required this.options,
    required this.state,
    required this.selectedOption,
    required this.hasLongOptions,
    required this.isCompactHeight,
    required this.orbitAnimation,
    required this.onOptionSelected,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAnswered = state.answerStatus.isAnswered;

    if (hasLongOptions) {
      // Multi-word / sentence options: Render as Capsule Pods
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final theme = _planetThemes[index % _planetThemes.length];
          final isSelected = selectedOption == option;

          return Padding(
            padding: EdgeInsets.only(bottom: 10.h),
            child: _CapsulePodOption(
              option: option,
              theme: theme,
              index: index,
              isSelected: isSelected,
              isAnswered: isAnswered,
              onTap: () => onOptionSelected(option),
              onPlayAudio: () => onPlayAudio(option),
            ),
          );
        }),
      );
    }

    // Short numerals, counting items, emojis: Render as Distinct Planets
    return AnimatedBuilder(
      animation: orbitAnimation,
      builder: (context, _) {
        final double motionOffset =
            MediaQuery.disableAnimationsOf(context)
                ? 0.0
                : math.sin(orbitAnimation.value * math.pi) * 6.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(options.length, (index) {
            final option = options[index];
            final theme = _planetThemes[index % _planetThemes.length];
            final isSelected = selectedOption == option;

            // Staggered motion phase
            final double itemMotion = (index % 2 == 0)
                ? motionOffset
                : -motionOffset;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Transform.translate(
                  offset: Offset(0, itemMotion),
                  child: _SphericalPlanetOption(
                    option: option,
                    theme: theme,
                    isSelected: isSelected,
                    isAnswered: isAnswered,
                    isCompactHeight: isCompactHeight,
                    onTap: () => onOptionSelected(option),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Spherical Celestial Planet option with rings and planetary glow.
class _SphericalPlanetOption extends StatelessWidget {
  final String option;
  final _PlanetTheme theme;
  final bool isSelected;
  final bool isAnswered;
  final bool isCompactHeight;
  final VoidCallback onTap;

  const _SphericalPlanetOption({
    required this.option,
    required this.theme,
    required this.isSelected,
    required this.isAnswered,
    required this.isCompactHeight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double planetSize = isCompactHeight ? 74.0.r : 84.0.r;

    final planetContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: planetSize,
      height: planetSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          radius: 0.9,
          colors: [
            theme.highlight,
            theme.primary,
            theme.shadow,
          ],
        ),
        border: Border.all(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.85),
          width: isSelected ? 3.0 : 2.0,
        ),
        boxShadow: [
          // 3D planet underside shadow
          BoxShadow(
            color: theme.shadow.withValues(alpha: 0.7),
            offset: Offset(0, 5.h),
            blurRadius: 10,
          ),
          // Atmospheric celestial glow
          BoxShadow(
            color: theme.primary.withValues(alpha: isSelected ? 0.7 : 0.4),
            blurRadius: isSelected ? 20 : 12,
            spreadRadius: isSelected ? 3 : 1,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8.r),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              option,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 24.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ),
      ),
    );

    if (isAnswered) {
      return planetContainer;
    }

    return Semantics(
      label: '${theme.label}: $option. Tap to answer or drag to the rocket.',
      button: true,
      child: Draggable<String>(
        data: option,
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.15,
            child: Opacity(opacity: 0.95, child: planetContainer),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: planetContainer),
        child: ScaleButton(
          onTap: onTap,
          child: planetContainer,
        ),
      ),
    );
  }
}

/// Cosmic Capsule Pod for longer multi-word phrases and sentences.
class _CapsulePodOption extends StatelessWidget {
  final String option;
  final _PlanetTheme theme;
  final int index;
  final bool isSelected;
  final bool isAnswered;
  final VoidCallback onTap;
  final VoidCallback onPlayAudio;

  const _CapsulePodOption({
    required this.option,
    required this.theme,
    required this.index,
    required this.isSelected,
    required this.isAnswered,
    required this.onTap,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final podContainer = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      constraints: BoxConstraints(minHeight: 56.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isSelected
            ? theme.primary.withValues(alpha: 0.25)
            : _CosmicPalette.spaceSlate.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isSelected ? theme.highlight : theme.primary.withValues(alpha: 0.5),
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: isSelected ? 0.4 : 0.2),
            blurRadius: isSelected ? 16 : 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Orbital identification badge
          Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [theme.highlight, theme.primary],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primary.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Center(
              child: Text(
                String.fromCharCode(65 + index), // 'A', 'B', 'C', 'D'
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // Option text
          Expanded(
            child: Text(
              option,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.visible,
            ),
          ),

          // Pronunciation speaker button
          ScaleButton(
            onTap: onPlayAudio,
            child: Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: _CosmicPalette.cockpitPanel,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.highlight.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.volume_up_rounded,
                size: 16.r,
                color: theme.highlight,
              ),
            ),
          ),
        ],
      ),
    );

    if (isAnswered) {
      return podContainer;
    }

    return Semantics(
      label: 'Option ${String.fromCharCode(65 + index)}: $option. Tap to choose or drag to the rocket.',
      button: true,
      child: Draggable<String>(
        data: option,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 320.w,
            child: Opacity(opacity: 0.95, child: podContainer),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.35, child: podContainer),
        child: ScaleButton(
          onTap: onTap,
          child: podContainer,
        ),
      ),
    );
  }
}
