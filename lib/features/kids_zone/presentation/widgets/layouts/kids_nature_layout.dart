import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';

class _NaturePalette {
  _NaturePalette._();
  static const Color darkMoss = Color(0xFF14532D); // Green 900
  static const Color forestGreen = Color(0xFF15803D); // Green 700
  static const Color brightSprout = Color(0xFF22C55E); // Green 500
  static const Color woodDark = Color(0xFF451A03); // Amber 950
  static const Color woodMedium = Color(0xFF78350F); // Amber 900
  static const Color woodPlank = Color(0xFF92400E); // Amber 800
  static const Color parchment = Color(0xFFFEF3C7); // Amber 100
  static const Color fireflyGlow = Color(0xFFFEF08A); // Yellow 200
  static const Color fireflyAmber = Color(0xFFEAB308); // Yellow 500
  static const Color stoneBg = Color(0xFFF8FAFC); // Slate 50
  static const Color stoneBorder = Color(0xFFCBD5E1); // Slate 300
}

/// Production-grade Nature Discovery Sanctuary Layout for Kids Zone.
///
/// Features:
/// - Fully responsive layout adapting from 320dp small phones to large tablets.
/// - Dual interaction: Intuitive drag-and-drop AND accessible tap-to-answer.
/// - Unspoiled question state: No pre-answer silhouette spoiling the answer emoji.
/// - Adaptive options: Renders organic river stones for short vocabulary, and
///   multi-line wrapping stepping-stone cards for longer sentences/phrases.
/// - Audio scaffolding: Pronounce options on demand and replay instruction audio.
/// - Standard typography: Balanced sizes, clean weights, zero artificial truncation.
/// - Living forest atmosphere: Ambient pulsing fireflies with battery-efficient loop.
/// - Zero overflow guarantee: Uses constrained layout with smooth scroll physics.
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is the number of options (3..4)
/// - Space Complexity: O(1) auxiliary space
class KidsNatureLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsNatureLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsNatureLayout> createState() => _KidsNatureLayoutState();
}

class _KidsNatureLayoutState extends State<KidsNatureLayout>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fireflyController;
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _fireflyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _fireflyController.dispose();
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

    // Audio reinforcement: Pronounce target vocabulary clearly
    di.sl<KidsTTSService>().speak(option, force: true);

    if (isCorrect) {
      di.sl<HapticService>().success();
    } else {
      di.sl<HapticService>().error();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    di.sl<KidsTTSService>().speak(text, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(KidsQuest quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
    }
  }

  /// Determines whether options should display as adaptive stepping stone cards
  /// rather than horizontal river stones, ensuring zero text truncation.
  bool _shouldUseSteppingStones(List<String> options) {
    if (options.length > 3) return true;
    for (final opt in options) {
      if (opt.length > 14 || opt.trim().split(' ').length > 2) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'nature',
      level: widget.level,
      primaryColor: widget.primaryColor,
      painterName: 'ForestFriend',
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final options = quest.options ?? const [];
        final useSteppingStones = _shouldUseSteppingStones(options);

        // Reset selected option whenever question is unanswered (new question or retry)
        if (state.answerStatus == AnswerStatus.unanswered) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isCompactHeight = maxHeight < 620;
            final topSpacing = isCompactHeight
                ? 52.0.h
                : KidsGameBaseScreen.mascotClearanceHeight;
            final signHeight = isCompactHeight ? 140.0.h : 175.0.h;
            final signWidth = math.min(constraints.maxWidth * 0.84, 300.0.w);

            return Stack(
              children: [
                // Living Forest Ambient Fireflies
                _FirefliesOverlay(animation: _fireflyController),

                // Main Game Content with Smooth Scroll Physics
                SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
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
                          // Top clearance for the mascot speech bubble
                          SizedBox(height: topSpacing),

                          // Ancient Tree Sign (Target & Mystery Scroll)
                          _AncientTreeSignTarget(
                            width: signWidth,
                            height: signHeight,
                            state: state,
                            quest: quest,
                            onReplayAudio: () => _replayQuestionAudio(quest),
                            onAcceptOption: (option) =>
                                _handleOptionSubmit(context, state, option),
                          ),

                          SizedBox(height: 12.h),

                          // Clear, Standard Subtitle
                          _NatureInstructionSubtitle(
                            isAnswered: state.answerStatus.isAnswered,
                          ),

                          SizedBox(height: 10.h),

                          // Options Area (Adaptive River Stones vs. Stepping Stone Cards)
                          if (useSteppingStones)
                            _SteppingStonesArea(
                              options: options,
                              correctAnswer: quest.correctAnswer,
                              selectedOption: state.answerStatus.isAnswered
                                  ? _selectedOption
                                  : null,
                              state: state,
                              onOptionSelected: (option) =>
                                  _handleOptionSubmit(context, state, option),
                              onOptionPlayAudio: _playOptionAudio,
                            )
                          else
                            _RiverStonesArea(
                              options: options,
                              correctAnswer: quest.correctAnswer,
                              selectedOption: state.answerStatus.isAnswered
                                  ? _selectedOption
                                  : null,
                              state: state,
                              onOptionSelected: (option) =>
                                  _handleOptionSubmit(context, state, option),
                              onOptionPlayAudio: _playOptionAudio,
                            ),

                          SizedBox(height: 16.h),
                        ],
                      ),
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
}

/// Ambient fireflies softly pulsing and floating across the screen.
class _FirefliesOverlay extends StatelessWidget {
  final Animation<double> animation;

  const _FirefliesOverlay({required this.animation});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final scale1 = 0.8 + 0.4 * t;
          final scale2 = 1.1 - 0.3 * t;
          final scale3 = 0.7 + 0.5 * math.sin(t * math.pi);
          final opacity1 = (0.35 + 0.55 * t).clamp(0.0, 1.0);
          final opacity2 = (0.75 - 0.45 * t).clamp(0.0, 1.0);

          return Stack(
            children: [
              Positioned(
                top: 85.h,
                left: 24.w + 10.w * t,
                child: _buildFireflyDot(scale1, opacity1),
              ),
              Positioned(
                top: 170.h,
                right: 32.w - 8.w * t,
                child: _buildFireflyDot(scale2, opacity2),
              ),
              Positioned(
                top: 240.h,
                left: 45.w + 6.w * t,
                child: _buildFireflyDot(scale3, opacity1),
              ),
              Positioned(
                bottom: 120.h,
                right: 40.w - 12.w * t,
                child: _buildFireflyDot(scale1, opacity2),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFireflyDot(double scale, double opacity) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 8.r,
          height: 8.r,
          decoration: BoxDecoration(
            color: _NaturePalette.fireflyGlow,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _NaturePalette.fireflyAmber.withValues(alpha: 0.75),
                blurRadius: 8,
                spreadRadius: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Ancient Tree Sign acting as both a drop zone and question focal point.
class _AncientTreeSignTarget extends StatelessWidget {
  final double width;
  final double height;
  final KidsLoaded state;
  final KidsQuest quest;
  final VoidCallback onReplayAudio;
  final ValueChanged<String> onAcceptOption;

  const _AncientTreeSignTarget({
    required this.width,
    required this.height,
    required this.state,
    required this.quest,
    required this.onReplayAudio,
    required this.onAcceptOption,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrect = state.answerStatus == AnswerStatus.correct;
    final isIncorrect = state.answerStatus == AnswerStatus.incorrect;

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !isAnswered,
      onAcceptWithDetails: (details) {
        if (!isAnswered) {
          onAcceptOption(details.data);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Semantics(
          label: isCorrect
              ? 'Nature item found: ${quest.correctAnswer}'
              : 'Sign drop zone. Double tap to hear clue or drag an answer here.',
          button: true,
          child: GestureDetector(
            onTap: isAnswered ? null : onReplayAudio,
            child: AnimatedScale(
              scale: isHovering ? 1.03 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Main Wooden Oak Sign Board
                    Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isHovering
                              ? [
                                  _NaturePalette.woodPlank,
                                  _NaturePalette.woodMedium,
                                ]
                              : isCorrect
                                  ? [
                                      const Color(0xFF065F46), // Emerald 800
                                      _NaturePalette.darkMoss,
                                    ]
                                  : isIncorrect
                                      ? [
                                          const Color(0xFF991B1B), // Red 800
                                          _NaturePalette.woodDark,
                                        ]
                                      : [
                                          _NaturePalette.woodMedium,
                                          _NaturePalette.woodDark,
                                        ],
                        ),
                        borderRadius: BorderRadius.circular(18.r),
                        border: Border.all(
                          color: isHovering
                              ? _NaturePalette.brightSprout
                              : isCorrect
                                  ? KidsColors.safeGreen
                                  : isIncorrect
                                      ? AppColors.rose500
                                      : _NaturePalette.woodPlank,
                          width: isHovering ? 3.0.r : 2.5.r,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isHovering
                                ? _NaturePalette.brightSprout.withValues(
                                    alpha: 0.35,
                                  )
                                : Colors.black.withValues(alpha: 0.22),
                            blurRadius: isHovering ? 18 : 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Subtle Wood Grain Texture Line
                          Positioned(
                            top: height * 0.5,
                            left: 12.w,
                            right: 12.w,
                            child: Container(
                              height: 1.0.h,
                              color: Colors.black.withValues(alpha: 0.2),
                            ),
                          ),

                          // Sign Inner Content
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              child: _SignInterior(
                                isHovering: isHovering,
                                isAnswered: isAnswered,
                                isCorrect: isCorrect,
                                quest: quest,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Top Hanging Leaf Foliage
                    Positioned(
                      top: -14.h,
                      left: -8.w,
                      child: Icon(
                        Icons.eco_rounded,
                        color: _NaturePalette.brightSprout,
                        size: 42.r,
                      ),
                    ),

                    // Bottom Right Vine Cluster
                    Positioned(
                      bottom: -10.h,
                      right: -6.w,
                      child: Icon(
                        Icons.eco_rounded,
                        color: _NaturePalette.forestGreen,
                        size: 38.r,
                      ),
                    ),

                    // Listen Clue Audio Badge (Bottom Right of Sign)
                    if (!isAnswered)
                      Positioned(
                        bottom: 8.h,
                        right: 12.w,
                        child: ScaleButton(
                          onTap: onReplayAudio,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 9.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: _NaturePalette.parchment,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: _NaturePalette.woodPlank,
                                width: 1.4.r,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.volume_up_rounded,
                                  size: 14.r,
                                  color: _NaturePalette.woodDark,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  context.tr(
                                    'games.kids_clue',
                                    fallback: 'Clue',
                                  ),
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: _NaturePalette.woodDark,
                                  ),
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
          ),
        );
      },
    );
  }
}

/// Sign Interior managing clean clue state vs celebratory discovery.
class _SignInterior extends StatelessWidget {
  final bool isHovering;
  final bool isAnswered;
  final bool isCorrect;
  final KidsQuest quest;

  const _SignInterior({
    required this.isHovering,
    required this.isAnswered,
    required this.isCorrect,
    required this.quest,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) {
      if (isCorrect) {
        // Discovered Nature Item Badge
        final answerText = quest.correctAnswer ?? quest.emoji ?? '';
        final discoveryEmoji = quest.emoji != null && quest.emoji != '?'
            ? quest.emoji!
            : '🌿';

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFF059669),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _NaturePalette.brightSprout,
                        width: 1.8.r,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        discoveryEmoji,
                        style: TextStyle(fontSize: 20.sp),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: const Color(0xFF059669),
                      size: 15.r,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 5.h),
              Text(
                answerText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: _NaturePalette.parchment,
                  height: 1.25,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
              ),
            ],
          ),
        );
      } else {
        // Incorrect State: Standard Encouragement
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.refresh_rounded,
                color: Colors.amber.shade200,
                size: 26.r,
              ),
              SizedBox(height: 5.h),
              Text(
                context.tr('games.try_again', fallback: 'Try Again'),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                  color: _NaturePalette.parchment,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }
    }

    if (isHovering) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.arrow_downward_rounded,
              color: _NaturePalette.fireflyGlow,
              size: 28.r,
            ),
            SizedBox(height: 4.h),
            Text(
              context.tr('games.kids_drop_here', fallback: 'DROP HERE!'),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w600,
                color: _NaturePalette.parchment,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Default Unspoiled State: Clean Emblem & Prompt
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.r,
            height: 40.r,
            decoration: BoxDecoration(
              color: _NaturePalette.woodDark.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: _NaturePalette.fireflyGlow.withValues(alpha: 0.4),
                width: 1.5.r,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.park_rounded,
                color: _NaturePalette.brightSprout,
                size: 22.r,
              ),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            context.tr(
              'games.kids_drop_prompt',
              fallback: 'Drop answer here',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.5.sp,
              fontWeight: FontWeight.w600,
              color: _NaturePalette.parchment,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

/// Standard, clean subtitle without buzzwords.
class _NatureInstructionSubtitle extends StatelessWidget {
  final bool isAnswered;

  const _NatureInstructionSubtitle({required this.isAnswered});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            size: 15.r,
            color: isDark ? Colors.amber.shade300 : const Color(0xFF15803D),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: KidsFittedText(
              context.tr(
                'games.kids_nature_action_hint',
                fallback: 'Choose an answer or drag it to the sign',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF334155),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stepping stones card layout for multi-word phrases and longer sentences.
/// Guarantees 100% full text readability with zero truncation or font squishing.
class _SteppingStonesArea extends StatelessWidget {
  final List<String> options;
  final String? correctAnswer;
  final String? selectedOption;
  final KidsLoaded state;
  final ValueChanged<String> onOptionSelected;
  final ValueChanged<String> onOptionPlayAudio;

  const _SteppingStonesArea({
    required this.options,
    required this.correctAnswer,
    required this.selectedOption,
    required this.state,
    required this.onOptionSelected,
    required this.onOptionPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final isCorrect = (option == correctAnswer);
        final isSelected = (option == selectedOption);

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == options.length - 1 ? 0 : 8.h,
          ),
          child: _NatureSteppingStoneCard(
            optionText: option,
            index: index,
            isCorrect: isCorrect,
            isSelected: isSelected,
            state: state,
            onTap: () => onOptionSelected(option),
            onPlayAudio: () => onOptionPlayAudio(option),
          ),
        );
      }),
    );
  }
}

/// A standard, accessible stepping stone card for sentence-length options.
class _NatureSteppingStoneCard extends StatelessWidget {
  final String optionText;
  final int index;
  final bool isCorrect;
  final bool isSelected;
  final KidsLoaded state;
  final VoidCallback onTap;
  final VoidCallback onPlayAudio;

  const _NatureSteppingStoneCard({
    required this.optionText,
    required this.index,
    required this.isCorrect,
    required this.isSelected,
    required this.state,
    required this.onTap,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrectStatus = state.answerStatus == AnswerStatus.correct;

    Color cardBg = Colors.white;
    Color cardBorder = const Color(0xFFE2E8F0);
    Color textColor = AppColors.slate900;
    Widget? statusBadge;

    if (isAnswered) {
      if (isCorrect) {
        cardBg = const Color(0xFFECFDF5);
        cardBorder = AppColors.emerald500;
        textColor = const Color(0xFF064E3B);
        statusBadge = Icon(
          Icons.check_circle_rounded,
          color: AppColors.emerald600,
          size: 20.r,
        );
      } else if (isSelected && !isCorrectStatus) {
        cardBg = const Color(0xFFFFF1F2);
        cardBorder = AppColors.rose500;
        textColor = const Color(0xFF881337);
        statusBadge = Icon(
          Icons.cancel_rounded,
          color: AppColors.rose500,
          size: 20.r,
        );
      }
    }

    final cardContent = Container(
      constraints: BoxConstraints(minHeight: 56.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder, width: 1.5.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: Offset(0, 2.h),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Index Stepping Pebble
          Container(
            width: 26.r,
            height: 26.r,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0.r),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.5.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate700,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),

          // Full Wrapped Readable Text (Never truncated)
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.3,
              ),
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),

          SizedBox(width: 8.w),

          // Status Badge or Sound Speaker Button
          if (statusBadge != null)
            statusBadge
          else
            ScaleButton(
              onTap: onPlayAudio,
              child: Container(
                padding: EdgeInsets.all(5.r),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.volume_up_rounded,
                  size: 16.r,
                  color: AppColors.slate600,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      label: 'Option ${index + 1}: $optionText. Double tap to select.',
      button: true,
      child: isAnswered
          ? cardContent
          : Draggable<String>(
              data: optionText,
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 48.w,
                  child: Opacity(opacity: 0.92, child: cardContent),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.28, child: cardContent),
              child: ScaleButton(
                onTap: onTap,
                child: cardContent,
              ),
            ),
    );
  }
}

/// Horizontal River Stones floor area for short vocabulary words.
class _RiverStonesArea extends StatelessWidget {
  final List<String> options;
  final String? correctAnswer;
  final String? selectedOption;
  final KidsLoaded state;
  final ValueChanged<String> onOptionSelected;
  final ValueChanged<String> onOptionPlayAudio;

  const _RiverStonesArea({
    required this.options,
    required this.correctAnswer,
    required this.selectedOption,
    required this.state,
    required this.onOptionSelected,
    required this.onOptionPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        // Forest Floor (Moss Bed)
        Container(
          height: 38.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _NaturePalette.darkMoss,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, -2),
              ),
            ],
          ),
        ),

        // River Stones
        Padding(
          padding: EdgeInsets.only(bottom: 14.h, left: 4.w, right: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(options.length, (index) {
              final option = options[index];
              final isCorrect = (option == correctAnswer);
              final isSelected = (option == selectedOption);

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: _GlowingRiverStone(
                    text: option,
                    index: index,
                    isCorrect: isCorrect,
                    isSelected: isSelected,
                    state: state,
                    onTap: () => onOptionSelected(option),
                    onPlayAudio: () => onOptionPlayAudio(option),
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

/// Organic tactile river stone supporting both drag and tap.
class _GlowingRiverStone extends StatelessWidget {
  final String text;
  final int index;
  final bool isCorrect;
  final bool isSelected;
  final KidsLoaded state;
  final VoidCallback onTap;
  final VoidCallback onPlayAudio;

  const _GlowingRiverStone({
    required this.text,
    required this.index,
    required this.isCorrect,
    required this.isSelected,
    required this.state,
    required this.onTap,
    required this.onPlayAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = state.answerStatus.isAnswered;
    final isCorrectStatus = state.answerStatus == AnswerStatus.correct;

    // Organic pebble shapes with balanced radii
    final cornerVariations = [
      BorderRadius.only(
        topLeft: Radius.circular(28.r),
        topRight: Radius.circular(20.r),
        bottomLeft: Radius.circular(22.r),
        bottomRight: Radius.circular(32.r),
      ),
      BorderRadius.only(
        topLeft: Radius.circular(22.r),
        topRight: Radius.circular(30.r),
        bottomLeft: Radius.circular(28.r),
        bottomRight: Radius.circular(18.r),
      ),
      BorderRadius.only(
        topLeft: Radius.circular(26.r),
        topRight: Radius.circular(22.r),
        bottomLeft: Radius.circular(20.r),
        bottomRight: Radius.circular(30.r),
      ),
      BorderRadius.only(
        topLeft: Radius.circular(24.r),
        topRight: Radius.circular(26.r),
        bottomLeft: Radius.circular(30.r),
        bottomRight: Radius.circular(22.r),
      ),
    ];

    final stoneRadii = cornerVariations[index % cornerVariations.length];

    Color stoneColor = _NaturePalette.stoneBg;
    Color borderColor = _NaturePalette.stoneBorder;
    Color textColor = AppColors.slate900;
    List<BoxShadow> shadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.16),
        offset: const Offset(0, 4),
        blurRadius: 6,
      ),
    ];

    if (isAnswered) {
      if (isCorrect) {
        stoneColor = const Color(0xFFECFDF5);
        borderColor = AppColors.emerald500;
        textColor = const Color(0xFF064E3B);
        shadows = [
          BoxShadow(
            color: AppColors.emerald500.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ];
      } else if (isSelected && !isCorrectStatus) {
        stoneColor = const Color(0xFFFFF1F2);
        borderColor = AppColors.rose500;
        textColor = const Color(0xFF881337);
        shadows = [
          BoxShadow(
            color: AppColors.rose500.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ];
      }
    }

    final stoneWidget = Container(
      constraints: BoxConstraints(minHeight: 74.h),
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: stoneColor,
        borderRadius: stoneRadii,
        border: Border.all(color: borderColor, width: 1.6.r),
        boxShadow: shadows,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Audio Speaker Button on Top
          if (!isAnswered)
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onPlayAudio,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 14.r,
                    color: AppColors.slate500,
                  ),
                ),
              ),
            ),

          // Option Text
          Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.5.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.25,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      label: 'Stone option: $text. Double tap to select or drag to sign.',
      button: true,
      child: isAnswered
          ? stoneWidget
          : Draggable<String>(
              data: text,
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.05,
                  child: SizedBox(
                    width: 95.w,
                    child: Opacity(opacity: 0.92, child: stoneWidget),
                  ),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.28, child: stoneWidget),
              child: ScaleButton(
                onTap: onTap,
                child: stoneWidget,
              ),
            ),
    );
  }
}
