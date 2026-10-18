import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color92400e = Color(0xFF92400E);
  static const Color colorfde047 = Color(0xFFFDE047);
  static const Color coloreab308 = Color(0xFFEAB308);
  static const Color colord4d4d8 = Color(0xFFD4D4D8);
  static const Color color9ca3af = Color(0xFF9CA3AF);
  static const Color colore4e4e7 = Color(0xFFE4E4E7);
  static const Color color3f3f46 = Color(0xFF3F3F46);
  static const Color color52525b = Color(0xFF52525B);
  static const Color color000080 = Color(0xFF000080);
  static const Color color006400 = Color(0xFF006400);
  static const Color color800000 = Color(0xFF800000);
  static const Color colorfa8072 = Color(0xFFFA8072);
  static const Color colorfffacd = Color(0xFFFFFACD);
  static const Color color4b0082 = Color(0xFF4B0082);
  static const Color colore6e6fa = Color(0xFFE6E6FA);
  static const Color color3e2723 = Color(0xFF3E2723);
  static const Color colord2b48c = Color(0xFFD2B48C);
  static const Color color424242 = Color(0xFF424242);
  static const Color colorbdbdbd = Color(0xFFBDBDBD);
  static const Color colorffdab9 = Color(0xFFFFDAB9);
  static const Color color32cd32 = Color(0xFF32CD32);
  static const Color colorb22222 = Color(0xFFB22222);
  static const Color color50c878 = Color(0xFF50C878);
  static const Color color0f52ba = Color(0xFF0F52BA);
  static const Color color9966cc = Color(0xFF9966CC);
  static const Color colorffc87c = Color(0xFFFFC87C);

  // Status colors
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successBorder = Color(0xFF16A34A);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFDC2626);
}

/// Art Studio Theme for Kids Colors Game
/// Supports DUAL INTERACTION (tap-to-answer + drag-and-drop),
/// TTS audio replay, zero 320dp small-screen overflow, and tactile haptics.
class KidsColorsLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsColorsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsColorsLayout> createState() => _KidsColorsLayoutState();
}

class _KidsColorsLayoutState extends State<KidsColorsLayout> {
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
    final isCorrect = (option.trim() == quest.correctAnswer?.trim());

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Submitting option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsColorsLayout',
      );
    }

    if (!isCorrect) {
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(option);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().error();
      }
    } else {
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().success();
      }
    }

    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
  }

  void _playOptionAudio(String text) {
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Pronouncing color option "$text"',
        tag: 'KidsColorsLayout',
      );
    }
    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl<KidsTTSService>().speak(text, force: true);
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl<HapticService>().selection();
    }
  }

  void _replayQuestionAudio(dynamic quest) {
    final instruction = InstructionHelper.getInstruction(quest);
    if (instruction.isNotEmpty) {
      if (di.sl.isRegistered<AppLogger>()) {
        di.sl<AppLogger>().debug(
          'Replaying instruction audio for quest "${quest.id}"',
          tag: 'KidsColorsLayout',
        );
      }
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(instruction, force: true);
      }
      if (di.sl.isRegistered<HapticService>()) {
        di.sl<HapticService>().selection();
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
      gameType: 'colors',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final options = quest.options?.map((e) => e.toString()).toList() ?? [];
        final isColorQuest = options.every(_isColorOption);

        if (state.currentIndex != _lastAnsweredQuestIndex) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isNarrow = availableWidth < 360;

            final easelWidth = (availableWidth * 0.86).clamp(220.0, 310.0).w;
            final easelHeight = 170.h;

            return Center(
              child: SizedBox(
                width: availableWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: KidsGameBaseScreen.mascotClearanceHeight + 6.h,
                      ),

                      // The Artist Easel
                      Center(
                        child: _buildEasel(
                          context,
                          state,
                          quest,
                          width: easelWidth,
                          height: easelHeight,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Prompt banner with visual dual-interaction hint
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app_rounded,
                              size: 15.r,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : _LocalPalette.color92400e,
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: KidsFittedText(
                                isColorQuest
                                    ? context.tr(
                                        'games.kids_colors_drag',
                                        fallback:
                                            'Tap or drag the correct color to the canvas!',
                                      )
                                    : context.tr(
                                        'games.kids_colors_drag_object',
                                        fallback:
                                            'Tap or drag the correct item to the easel!',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isNarrow ? 12.5.sp : 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Colors.black.withValues(alpha: 0.75),
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Options Container (adaptive single row or multi-tier)
                      _buildOptionsArea(
                        context,
                        state,
                        quest,
                        options,
                        isColorQuest: isColorQuest,
                        isNarrow: isNarrow,
                        availableWidth: availableWidth,
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

  Widget _buildOptionsArea(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    List<String> options, {
    required bool isColorQuest,
    required bool isNarrow,
    required double availableWidth,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    // If 4 options on narrow screen, split into 2 rows of 2
    if (options.length == 4 && isNarrow) {
      final row1 = options.sublist(0, 2);
      final row2 = options.sublist(2, 4);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: row1
                .map(
                  (opt) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 3.h,
                      ),
                      child: _buildOptionItem(
                        context,
                        state,
                        quest,
                        opt,
                        isColorQuest: isColorQuest,
                        maxWidth: (availableWidth - 36.w) / 2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          Row(
            children: row2
                .map(
                  (opt) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 3.h,
                      ),
                      child: _buildOptionItem(
                        context,
                        state,
                        quest,
                        opt,
                        isColorQuest: isColorQuest,
                        maxWidth: (availableWidth - 36.w) / 2,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      );
    }

    // Default single row
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(options.length, (index) {
        final option = options[index];
        final itemWidth =
            (availableWidth - 28.w - (options.length * 6.w)) / options.length;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 3.w),
            child: _buildOptionItem(
              context,
              state,
              quest,
              option,
              isColorQuest: isColorQuest,
              maxWidth: itemWidth,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest,
    String option, {
    required bool isColorQuest,
    required double maxWidth,
  }) {
    final isCorrect = (quest.correctAnswer?.trim() == option.trim());

    return isColorQuest
        ? _buildPaintTube(
            context,
            state,
            option,
            isCorrect,
            maxWidth,
          )
        : _buildObjectCard(
            context,
            state,
            option,
            isCorrect,
            maxWidth,
          );
  }

  Widget _buildEasel(
    BuildContext context,
    KidsLoaded state,
    KidsQuest quest, {
    required double width,
    required double height,
  }) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        final isAnswered = state.answerStatus.isAnswered;
        final isCorrectAnswer = (_selectedOption == quest.correctAnswer) ||
            (state.answerStatus == AnswerStatus.correct);

        Color canvasBg = Colors.white;
        Color borderColor = _LocalPalette.colord4d4d8;
        if (isHovering) {
          canvasBg = _LocalPalette.colorfde047;
          borderColor = _LocalPalette.coloreab308;
        } else if (isAnswered) {
          if (isCorrectAnswer) {
            canvasBg = _LocalPalette.successBg;
            borderColor = _LocalPalette.successBorder;
          } else {
            canvasBg = _LocalPalette.errorBg;
            borderColor = _LocalPalette.errorBorder;
          }
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Wooden back legs of the easel
            Positioned(
              top: -14.h,
              child: Container(
                width: 120.w,
                height: height + 40.h,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: _LocalPalette.color92400e,
                      width: 10.w,
                    ),
                    right: BorderSide(
                      color: _LocalPalette.color92400e,
                      width: 10.w,
                    ),
                  ),
                ),
              ),
            ),

            // The Canvas
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: canvasBg,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: borderColor,
                  width: isHovering || isAnswered ? 3.w : 2.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isHovering ? 0.25 : 0.1,
                    ),
                    blurRadius: isHovering ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Audio Replay Button (Top Right)
                  Positioned(
                    top: 6.r,
                    right: 6.r,
                    child: Semantics(
                      label: 'Listen to instruction',
                      button: true,
                      child: InkWell(
                        key: const ValueKey('colors_audio_replay_btn'),
                        onTap: () => _replayQuestionAudio(quest),
                        borderRadius: BorderRadius.circular(16.r),
                        child: Container(
                          padding: EdgeInsets.all(5.r),
                          decoration: BoxDecoration(
                            color: _LocalPalette.color92400e
                                .withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.volume_up_rounded,
                            size: 18.r,
                            color: _LocalPalette.color92400e,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center Content (Question + Visuals)
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 6.h,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (quest.question != null &&
                              quest.question != '?' &&
                              quest.question!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(bottom: 4.h),
                              child: KidsFittedText(
                                quest.question!,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: _LocalPalette.color3f3f46,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          if (quest.emoji != null && quest.emoji!.isNotEmpty)
                            isAnswered && isCorrectAnswer
                                ? Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 60.sp),
                                  )
                                : ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      _LocalPalette.color9ca3af,
                                      BlendMode.srcIn,
                                    ),
                                    child: Text(
                                      quest.emoji!,
                                      style: TextStyle(fontSize: 60.sp),
                                    ),
                                  ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Wooden tray at the bottom of the canvas
            Positioned(
              bottom: 0,
              child: Container(
                width: width + 20.w,
                height: 14.h,
                decoration: BoxDecoration(
                  color: KidsColors.warmAmber,
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, offset: Offset(0, 3)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOptionText(String text) {
    final hasSpace = text.trim().contains(' ');
    final textStyle = TextStyle(
      fontFamily: 'Outfit',
      fontSize: 14.sp,
      fontWeight: FontWeight.w700,
      color: _LocalPalette.color3f3f46,
    );

    if (!hasSpace) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: textStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      );
    } else {
      return KidsFittedText(
        text,
        style: textStyle,
        textAlign: TextAlign.center,
        maxLines: 2,
      );
    }
  }

  Widget _buildPaintTube(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    double maxWidth,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    Color tubeColor = _getColorFromName(text, widget.primaryColor);

    Color cardBg = Colors.white;
    Color borderColor = _LocalPalette.colore4e4e7;
    if (isAnswered) {
      if (isSelected) {
        if (isCorrect) {
          cardBg = _LocalPalette.successBg;
          borderColor = _LocalPalette.successBorder;
        } else {
          cardBg = _LocalPalette.errorBg;
          borderColor = _LocalPalette.errorBorder;
        }
      } else if (isCorrect) {
        cardBg = _LocalPalette.successBg;
        borderColor = _LocalPalette.successBorder;
      }
    }

    final tubeWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.water_drop_rounded, color: tubeColor, size: 22.r),
        Container(
          height: 80.h,
          width: maxWidth,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(8.r),
              topRight: Radius.circular(8.r),
              bottomLeft: Radius.circular(16.r),
              bottomRight: Radius.circular(16.r),
            ),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.5.w : 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                offset: Offset(0, 4.h),
                blurRadius: 4,
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 24.h,
                    width: double.infinity,
                    color: tubeColor,
                  ),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: _buildOptionText(text),
                      ),
                    ),
                  ),
                ],
              ),

              // Small speaker button in top corner
              Positioned(
                top: 2.r,
                right: 2.r,
                child: Semantics(
                  label: 'Pronounce $text',
                  button: true,
                  child: InkWell(
                    key: ValueKey('colors_speaker_$text'),
                    onTap: () => _playOptionAudio(text),
                    child: Container(
                      padding: EdgeInsets.all(2.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 12.r,
                        color: _LocalPalette.color3f3f46,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 9.h,
          width: maxWidth * 0.45,
          decoration: BoxDecoration(
            color: _LocalPalette.color52525b,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.r)),
          ),
        ),
      ],
    );

    // Interactive card wrapping tap-to-answer
    final interactiveCard = Semantics(
      label: 'Color option $text',
      button: true,
      enabled: !isAnswered,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('colors_option_$text'),
          borderRadius: BorderRadius.circular(16.r),
          onTap: isAnswered
              ? null
              : () => _handleOptionSubmit(context, state, text),
          child: tubeWidget,
        ),
      ),
    );

    return Draggable<String>(
      data: text,
      maxSimultaneousDrags: isAnswered ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: maxWidth,
          child: Transform.scale(
            scale: 1.05,
            child: Opacity(opacity: 0.9, child: tubeWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: tubeWidget),
      child: interactiveCard,
    );
  }

  Widget _buildObjectCard(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    double maxWidth,
  ) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);

    Color cardBg = Colors.white;
    Color borderColor = _LocalPalette.colord4d4d8;
    if (isAnswered) {
      if (isSelected) {
        if (isCorrect) {
          cardBg = _LocalPalette.successBg;
          borderColor = _LocalPalette.successBorder;
        } else {
          cardBg = _LocalPalette.errorBg;
          borderColor = _LocalPalette.errorBorder;
        }
      } else if (isCorrect) {
        cardBg = _LocalPalette.successBg;
        borderColor = _LocalPalette.successBorder;
      }
    }

    final cardWidget = Container(
      width: maxWidth,
      height: 90.h,
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.5.w : 2.w,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: Offset(0, 4.h),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w),
              child: _buildOptionText(text),
            ),
          ),
          // Small speaker button in top corner
          Positioned(
            top: 4.r,
            right: 4.r,
            child: Semantics(
              label: 'Pronounce $text',
              button: true,
              child: InkWell(
                key: ValueKey('colors_speaker_$text'),
                onTap: () => _playOptionAudio(text),
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 13.r,
                    color: _LocalPalette.color3f3f46,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final interactiveCard = Semantics(
      label: 'Object option $text',
      button: true,
      enabled: !isAnswered,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('colors_option_$text'),
          borderRadius: BorderRadius.circular(12.r),
          onTap: isAnswered
              ? null
              : () => _handleOptionSubmit(context, state, text),
          child: cardWidget,
        ),
      ),
    );

    return Draggable<String>(
      data: text,
      maxSimultaneousDrags: isAnswered ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: maxWidth,
          child: Transform.scale(
            scale: 1.05,
            child: Opacity(opacity: 0.9, child: cardWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.25, child: cardWidget),
      child: interactiveCard,
    );
  }

  bool _isColorOption(String name) {
    final lower = name.toLowerCase();
    return lower.contains('red') ||
        lower.contains('blue') ||
        lower.contains('green') ||
        lower.contains('yellow') ||
        lower.contains('orange') ||
        lower.contains('purple') ||
        lower.contains('pink') ||
        lower.contains('black') ||
        lower.contains('white') ||
        lower.contains('brown') ||
        lower.contains('gray') ||
        lower.contains('grey') ||
        lower.contains('teal') ||
        lower.contains('cyan') ||
        lower.contains('indigo') ||
        lower.contains('gold') ||
        lower.contains('silver');
  }

  Color _getColorFromName(String name, Color fallback) {
    final lower = name.toLowerCase();

    // Advanced Shades (must check before base colors)
    if (lower.contains('light blue') ||
        lower.contains('baby blue') ||
        lower.contains('sky blue')) {
      return Colors.lightBlue;
    }
    if (lower.contains('dark blue') || lower.contains('navy')) {
      return _LocalPalette.color000080;
    }
    if (lower.contains('light green') ||
        lower.contains('mint') ||
        lower.contains('sage')) {
      return Colors.lightGreen;
    }
    if (lower.contains('dark green') ||
        lower.contains('forest') ||
        lower.contains('olive')) {
      return _LocalPalette.color006400;
    }
    if (lower.contains('dark red') ||
        lower.contains('maroon') ||
        lower.contains('burgundy')) {
      return _LocalPalette.color800000;
    }
    if (lower.contains('light red') || lower.contains('salmon')) {
      return _LocalPalette.colorfa8072;
    }
    if (lower.contains('light yellow') || lower.contains('pastel yellow')) {
      return _LocalPalette.colorfffacd;
    }
    if (lower.contains('dark purple') ||
        lower.contains('plum') ||
        lower.contains('eggplant')) {
      return _LocalPalette.color4b0082;
    }
    if (lower.contains('light purple') ||
        lower.contains('lavender') ||
        lower.contains('lilac')) {
      return _LocalPalette.colore6e6fa;
    }
    if (lower.contains('dark brown') ||
        lower.contains('chocolate') ||
        lower.contains('espresso')) {
      return _LocalPalette.color3e2723;
    }
    if (lower.contains('light brown') ||
        lower.contains('tan') ||
        lower.contains('khaki') ||
        lower.contains('beige') ||
        lower.contains('cream') ||
        lower.contains('oatmeal')) {
      return _LocalPalette.colord2b48c;
    }
    if (lower.contains('dark gray') ||
        lower.contains('dark grey') ||
        lower.contains('charcoal')) {
      return _LocalPalette.color424242;
    }
    if (lower.contains('light gray') ||
        lower.contains('light grey') ||
        lower.contains('silver')) {
      return _LocalPalette.colorbdbdbd;
    }
    if (lower.contains('hot pink') ||
        lower.contains('neon pink') ||
        lower.contains('fuchsia') ||
        lower.contains('magenta')) {
      return Colors.pinkAccent;
    }

    // Mixed & Tertiary Colors
    if (lower.contains('teal')) {
      return Colors.teal;
    }
    if (lower.contains('cyan') ||
        lower.contains('aqua') ||
        lower.contains('turquoise')) {
      return Colors.cyan;
    }
    if (lower.contains('peach') ||
        lower.contains('coral') ||
        lower.contains('apricot')) {
      return _LocalPalette.colorffdab9;
    }
    if (lower.contains('gold')) {
      return IllustrationColors.premiumGold;
    }
    if (lower.contains('lime') || lower.contains('chartreuse')) {
      return _LocalPalette.color32cd32;
    }
    if (lower.contains('indigo')) {
      return Colors.indigo;
    }

    // Gemstones & Minerals
    if (lower.contains('ruby') ||
        lower.contains('garnet') ||
        lower.contains('scarlet') ||
        lower.contains('brick')) {
      return _LocalPalette.colorb22222;
    }
    if (lower.contains('emerald') || lower.contains('jade')) {
      return _LocalPalette.color50c878;
    }
    if (lower.contains('sapphire')) {
      return _LocalPalette.color0f52ba;
    }
    if (lower.contains('amethyst')) {
      return _LocalPalette.color9966cc;
    }
    if (lower.contains('topaz') || lower.contains('citrine')) {
      return _LocalPalette.colorffc87c;
    }
    if (lower.contains('onyx') || lower.contains('coal')) {
      return Colors.black87;
    }

    // Base Colors
    if (lower.contains('red')) {
      return Colors.red;
    }
    if (lower.contains('blue')) {
      return Colors.blue;
    }
    if (lower.contains('green')) {
      return Colors.green;
    }
    if (lower.contains('yellow')) {
      return Colors.yellow;
    }
    if (lower.contains('orange')) {
      return Colors.orange;
    }
    if (lower.contains('purple')) {
      return Colors.purple;
    }
    if (lower.contains('pink')) {
      return Colors.pink;
    }
    if (lower.contains('black')) {
      return Colors.black;
    }
    if (lower.contains('white') ||
        lower.contains('snow') ||
        lower.contains('pearl')) {
      return _LocalPalette.colore4e4e7;
    }
    if (lower.contains('brown')) {
      return Colors.brown;
    }
    if (lower.contains('gray') || lower.contains('grey')) {
      return Colors.grey;
    }

    return fallback;
  }
}
