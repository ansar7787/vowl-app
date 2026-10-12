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
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Production-grade Dollhouse Layout for the Kids Home game.
///
/// Features:
/// - Fully responsive layout adapting from 320dp small phones to large tablets.
/// - Dual interaction: Intuitive drag-and-drop AND accessible tap-to-answer.
/// - Unspoiled question state: No pre-answer silhouette spoiling the answer emoji.
/// - Audio scaffolding: Pronounce options on demand and replay instruction audio.
/// - Legible typography: Full non-truncated, multi-line wrapped option text.
/// - Tactile visual feedback: Rich cottage aesthetic, drop target glow, card highlights.
/// - Never overflows: Responsive vertical scaling with safety scroll for large fonts.
///
/// Algorithmic Complexity:
/// - Time Complexity: O(N) where N is the number of options (3..4)
/// - Space Complexity: O(1) auxiliary space
class KidsHomeLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsHomeLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsHomeLayout> createState() => _KidsHomeLayoutState();
}

class _KidsHomeLayoutState extends State<KidsHomeLayout> {
  String? _selectedOption;
  int _lastAnsweredQuestIndex = -1;

  void _handleOptionSubmit(
    BuildContext context,
    KidsLoaded state,
    String option,
  ) {
    if (state.answerStatus.isAnswered) return;

    setState(() {
      _selectedOption = option;
      _lastAnsweredQuestIndex = state.currentIndex;
    });

    final quest = state.currentQuest;
    final isCorrect = (option == quest.correctAnswer);

    if (!isCorrect) {
      di.sl<KidsTTSService>().speak(option);
      di.sl<HapticService>().error();
    } else {
      di.sl<HapticService>().success();
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    di.sl<KidsTTSService>().speak(text, force: true);
    di.sl<HapticService>().selection();
  }

  void _replayQuestionAudio(dynamic quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      di.sl<KidsTTSService>().speak(instruction, force: true);
      di.sl<HapticService>().selection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: 'home',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        // Reset selected option on new question
        if (state.currentIndex != _lastAnsweredQuestIndex &&
            state.answerStatus == AnswerStatus.unanswered) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final isCompactHeight = maxHeight < 580;
            final topSpacing = isCompactHeight ? 80.0.h : 100.0.h;
            final dollhouseHeight = isCompactHeight ? 140.0.h : 170.0.h;
            final dollhouseWidth = math.min(constraints.maxWidth * 0.78, 290.0.w);

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
                      // Top spacing clearance for the mascot speech bubble
                      SizedBox(height: topSpacing),

                      // Interactive Dollhouse (Drop Zone & Question Target)
                      _DollhouseTarget(
                        width: dollhouseWidth,
                        height: dollhouseHeight,
                        state: state,
                        quest: quest,
                        onReplayAudio: () => _replayQuestionAudio(quest),
                        onAcceptOption: (option) =>
                            _handleOptionSubmit(context, state, option),
                      ),

                      SizedBox(height: 12.h),

                      // Instruction subtitle
                      _InstructionSubtitle(
                        isAnswered: state.answerStatus.isAnswered,
                      ),

                      SizedBox(height: 10.h),

                      // Wooden Floor & Concept Options Area
                      _OptionsFloorArea(
                        options: quest.options ?? const [],
                        correctAnswer: quest.correctAnswer,
                        selectedOption: state.answerStatus.isAnswered ? _selectedOption : null,
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
            );
          },
        );
      },
    );
  }
}

/// A delightful, architectural dollhouse drop-zone and question beacon.
class _DollhouseTarget extends StatelessWidget {
  final double width;
  final double height;
  final KidsLoaded state;
  final dynamic quest;
  final VoidCallback onReplayAudio;
  final ValueChanged<String> onAcceptOption;

  const _DollhouseTarget({
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
              ? 'Home completed with answer: ${quest.correctAnswer}'
              : 'Dollhouse drop zone. Double tap to hear clue or drag an answer here.',
          button: true,
          child: GestureDetector(
            onTap: isAnswered ? null : onReplayAudio,
            child: AnimatedScale(
              scale: isHovering ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: SizedBox(
                width: width,
                height: height,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topCenter,
                  children: [
                    // Dollhouse Body Container
                    Positioned(
                      top: height * 0.26,
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isHovering
                              ? const Color(0xFFFEF3C7) // Amber 100
                              : isCorrect
                                  ? const Color(0xFFECFDF5) // Emerald 50
                                  : isIncorrect
                                      ? const Color(0xFFFFF1F2) // Rose 50
                                      : const Color(0xFFFFFBEB), // Cream amber 50
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isHovering
                                ? const Color(0xFFF59E0B) // Amber 500
                                : isCorrect
                                    ? AppColors.emerald500
                                    : isIncorrect
                                        ? AppColors.rose500
                                        : const Color(0xFFB45309), // Amber 700
                            width: isHovering ? 4.r : 3.r,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isHovering
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.35)
                                  : Colors.black.withValues(alpha: 0.14),
                              blurRadius: isHovering ? 20 : 12,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: _DollhouseInterior(
                          isHovering: isHovering,
                          isAnswered: isAnswered,
                          isCorrect: isCorrect,
                          quest: quest,
                        ),
                      ),
                    ),

                    // Chimney with Puff of Smoke
                    Positioned(
                      top: 0,
                      right: width * 0.16,
                      child: _ChimneyWidget(isCelebration: isCorrect),
                    ),

                    // Pitched Roof with Attic Gable
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: height * 0.32,
                      child: _RoofWidget(
                        isHovering: isHovering,
                        isCorrect: isCorrect,
                        onAudioTap: isAnswered ? null : onReplayAudio,
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

/// The charming pitched roof with attic window and audio replay cue.
class _RoofWidget extends StatelessWidget {
  final bool isHovering;
  final bool isCorrect;
  final VoidCallback? onAudioTap;

  const _RoofWidget({
    required this.isHovering,
    required this.isCorrect,
    this.onAudioTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Roof Triangular Shape
        CustomPaint(
          size: Size.infinite,
          painter: _PitchedRoofPainter(
            roofColor: isHovering
                ? const Color(0xFFEA580C) // Vibrant orange-red
                : isCorrect
                    ? AppColors.emerald600
                    : AppColors.red500,
            eavesColor: const Color(0xFF991B1B), // Deep crimson eaves
          ),
        ),

        // Attic Circular Window / Audio Button
        Positioned(
          top: 12.h,
          child: Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFB45309),
                width: 2.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.volume_up_rounded,
              color: const Color(0xFFB45309),
              size: 18.r,
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for a warm pitched cottage roof with overhang eaves.
class _PitchedRoofPainter extends CustomPainter {
  final Color roofColor;
  final Color eavesColor;

  const _PitchedRoofPainter({
    required this.roofColor,
    required this.eavesColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final roofPaint = Paint()
      ..color = roofColor
      ..style = PaintingStyle.fill;

    final eavesPaint = Paint()
      ..color = eavesColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Apex
    path.lineTo(size.width, size.height); // Bottom right
    path.lineTo(0, size.height); // Bottom left
    path.close();

    canvas.drawPath(path, roofPaint);

    // Outline eaves
    final eavesPath = Path();
    eavesPath.moveTo(0, size.height);
    eavesPath.lineTo(size.width / 2, 0);
    eavesPath.lineTo(size.width, size.height);
    canvas.drawPath(eavesPath, eavesPaint);
  }

  @override
  bool shouldRepaint(covariant _PitchedRoofPainter oldDelegate) {
    return oldDelegate.roofColor != roofColor ||
        oldDelegate.eavesColor != eavesColor;
  }
}

/// Chimney with cute cloud puffs for visual charm.
class _ChimneyWidget extends StatelessWidget {
  final bool isCelebration;

  const _ChimneyWidget({required this.isCelebration});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24.w,
      height: 38.h,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Chimney Brick Column
          Positioned(
            bottom: 0,
            child: Container(
              width: 16.w,
              height: 28.h,
              decoration: BoxDecoration(
                color: const Color(0xFFB91C1C),
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: const Color(0xFF7F1D1D), width: 1.5),
              ),
            ),
          ),
          // Smoke puff
          Positioned(
            top: 0,
            child: Icon(
              Icons.cloud_rounded,
              size: isCelebration ? 18.r : 14.r,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// The inside room of the dollhouse displaying drop cues or celebrated answers.
class _DollhouseInterior extends StatelessWidget {
  final bool isHovering;
  final bool isAnswered;
  final bool isCorrect;
  final dynamic quest;

  const _DollhouseInterior({
    required this.isHovering,
    required this.isAnswered,
    required this.isCorrect,
    required this.quest,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: isCorrect
              ? _buildCorrectCelebration(context)
              : isHovering
                  ? _buildHoverPrompt(context)
                  : _buildAwaitingState(context),
        ),
      ),
    );
  }

  Widget _buildCorrectCelebration(BuildContext context) {
    final emoji = quest.emoji ?? '🏡';
    final answerText = quest.correctAnswer ?? '';

    return Row(
      key: const ValueKey('correct_celebration'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 36.sp),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: AppColors.emerald500,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 16.r),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    answerText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHoverPrompt(BuildContext context) {
    return Row(
      key: const ValueKey('hover_prompt'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.arrow_downward_rounded,
          size: 22.r,
          color: const Color(0xFFD97706),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            context.tr('games.kids_home_drop_here', fallback: 'Drop here'),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF92400E),
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ],
    );
  }

  Widget _buildAwaitingState(BuildContext context) {
    return Row(
      key: const ValueKey('awaiting_state'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFDE68A).withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.home_rounded,
            size: 22.r,
            color: const Color(0xFFB45309),
          ),
        ),
        SizedBox(width: 8.w),
        Flexible(
          child: Text(
            context.tr(
              'games.kids_home_tap_or_drag',
              fallback: 'Drop answer here',
            ),
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF78350F),
            ),
            textAlign: TextAlign.center,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}

/// Clear, standard instruction subtitle without buzzwords.
class _InstructionSubtitle extends StatelessWidget {
  final bool isAnswered;

  const _InstructionSubtitle({required this.isAnswered});

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
            size: 16.r,
            color: isDark ? Colors.amber.shade300 : const Color(0xFFB45309),
          ),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              context.tr(
                'games.kids_home_action_hint',
                fallback: 'Choose an answer or drag it to the house.',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

/// Area presenting the concept cards with comfortable standard spacing.
class _OptionsFloorArea extends StatelessWidget {
  final List<String> options;
  final String? correctAnswer;
  final String? selectedOption;
  final KidsLoaded state;
  final ValueChanged<String> onOptionSelected;
  final ValueChanged<String> onOptionPlayAudio;

  const _OptionsFloorArea({
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
          padding: EdgeInsets.only(bottom: index == options.length - 1 ? 0 : 8.h),
          child: _HomeOptionCard(
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

/// A standard, professional, accessible option card.
class _HomeOptionCard extends StatelessWidget {
  final String optionText;
  final int index;
  final bool isCorrect;
  final bool isSelected;
  final KidsLoaded state;
  final VoidCallback onTap;
  final VoidCallback onPlayAudio;

  const _HomeOptionCard({
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

    // Harmonious, standard mobile palette with clean contrast
    final colorThemes = [
      const _CardPalette(
        bg: Color(0xFFF8FAFC), // Slate 50
        border: Color(0xFF38BDF8), // Sky 400
        text: Color(0xFF0F172A), // Slate 900
        badgeBg: Color(0xFFE0F2FE), // Sky 100
      ),
      const _CardPalette(
        bg: Color(0xFFFFFBEB), // Amber 50
        border: Color(0xFFFBBF24), // Amber 400
        text: Color(0xFF0F172A), // Slate 900
        badgeBg: Color(0xFFFEF3C7), // Amber 100
      ),
      const _CardPalette(
        bg: Color(0xFFFAF5FF), // Purple 50
        border: Color(0xFFA78BFA), // Violet 400
        text: Color(0xFF0F172A), // Slate 900
        badgeBg: Color(0xFFEDE9FE), // Violet 100
      ),
      const _CardPalette(
        bg: Color(0xFFF0FDF4), // Green 50
        border: Color(0xFF4ADE80), // Green 400
        text: Color(0xFF0F172A), // Slate 900
        badgeBg: Color(0xFFDCFCE7), // Green 100
      ),
    ];

    final theme = colorThemes[index % colorThemes.length];

    // Card styling based on game status
    Color cardBg = theme.bg;
    Color cardBorder = theme.border;
    Color textColor = theme.text;
    Widget? statusBadge;

    if (isAnswered) {
      if (isCorrect) {
        cardBg = const Color(0xFFECFDF5);
        cardBorder = AppColors.emerald500;
        textColor = const Color(0xFF064E3B);
        statusBadge = Icon(
          Icons.check_circle_rounded,
          color: AppColors.emerald600,
          size: 22.r,
        );
      } else if (isSelected && !isCorrectStatus) {
        cardBg = const Color(0xFFFFF1F2);
        cardBorder = AppColors.rose500;
        textColor = const Color(0xFF881337);
        statusBadge = Icon(
          Icons.cancel_rounded,
          color: AppColors.rose500,
          size: 22.r,
        );
      }
    }

    final cardContent = Container(
      constraints: BoxConstraints(minHeight: 56.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: cardBorder, width: 1.8.r),
        boxShadow: [
          BoxShadow(
            color: cardBorder.withValues(alpha: 0.16),
            offset: Offset(0, 2.h),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          // Index Badge (Standard clean weight)
          Container(
            width: 28.r,
            height: 28.r,
            decoration: BoxDecoration(
              color: theme.badgeBg,
              shape: BoxShape.circle,
              border: Border.all(color: cardBorder, width: 1.2.r),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ),

          SizedBox(width: 12.w),

          // Standard, non-truncated English text without ellipses
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.3,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),

          SizedBox(width: 8.w),

          // Status indicator or audio listen button
          if (statusBadge != null)
            statusBadge
          else
            GestureDetector(
              onTap: onPlayAudio,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 32.r,
                height: 32.r,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: cardBorder.withValues(alpha: 0.6), width: 1.2.r),
                ),
                child: Center(
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: cardBorder,
                    size: 17.r,
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

    return Draggable<String>(
      data: optionText,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.85,
          child: Transform.scale(
            scale: 0.96,
            child: Opacity(opacity: 0.95, child: cardContent),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: cardContent),
      child: ScaleButton(
        onTap: onTap,
        child: Semantics(
          label: '$optionText. Tap to choose or drag to the house.',
          button: true,
          child: cardContent,
        ),
      ),
    );
  }
}

class _CardPalette {
  final Color bg;
  final Color border;
  final Color text;
  final Color badgeBg;

  const _CardPalette({
    required this.bg,
    required this.border,
    required this.text,
    required this.badgeBg,
  });
}
