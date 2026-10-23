import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color92400e = Color(0xFF92400E);
  static const Color color9f1239 = Color(0xFF9F1239);
  static const Color colorbe123c = Color(0xFFBE123C);
  static const Color colorfde047 = Color(0xFFFDE047);
  static const Color color7dd3fc = Color(0xFF7DD3FC);
  static const Color colorca8a04 = Color(0xFFCA8A04);
  static const Color color0284c7 = Color(0xFF0284C7);
}

/// Puppet theater pedagogical layout for the Kids Emotions recognition game.
class KidsEmotionsLayout extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The title of the game.
  final String title;

  /// The primary theme accent color.
  final Color primaryColor;

  /// Creates a [KidsEmotionsLayout] widget.
  const KidsEmotionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsEmotionsLayout> createState() => _KidsEmotionsLayoutState();
}

class _KidsEmotionsLayoutState extends State<KidsEmotionsLayout> {
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
        'Submitting emotions option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsEmotionsLayout',
      );
    }

    if (!isCorrect) {
      final parts = option.trim().split(' ');
      if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
        parts.removeLast();
      }
      final textToSpeak = parts.join(' ');
      if (di.sl.isRegistered<KidsTTSService>()) {
        di.sl<KidsTTSService>().speak(textToSpeak);
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
    final parts = text.trim().split(' ');
    if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
      parts.removeLast();
    }
    final textToSpeak = parts.join(' ');
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl<AppLogger>().debug(
        'Pronouncing emotion option "$textToSpeak"',
        tag: 'KidsEmotionsLayout',
      );
    }
    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl<KidsTTSService>().speak(textToSpeak, force: true);
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
          tag: 'KidsEmotionsLayout',
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
      gameType: 'emotions',
      level: widget.level,
      primaryColor: widget.primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;
        final options = quest.options?.map((e) => e.toString()).toList() ?? [];

        if (state.currentIndex != _lastAnsweredQuestIndex) {
          _selectedOption = null;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final isNarrow = availableWidth < 360;

            final stageWidth = (availableWidth * 0.90).clamp(240.0, 340.0).w;
            final stageHeight = 185.h;

            return Center(
              child: SizedBox(
                width: availableWidth,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: KidsGameBaseScreen.mascotClearanceHeight + 6.h,
                      ),

                      // The Puppet Theater Stage
                      Center(
                        child: _buildTheaterStage(
                          context,
                          state,
                          quest,
                          width: stageWidth,
                          height: stageHeight,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      // Prompt banner with dual interaction hint
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.theater_comedy_rounded,
                              size: 16.r,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.white70
                                  : _LocalPalette.color92400e,
                            ),
                            SizedBox(width: 6.w),
                            Flexible(
                              child: KidsFittedText(
                                state.answerStatus == AnswerStatus.correct
                                    ? context.tr(
                                        'games.kids_emotions_done',
                                        fallback: 'Bravo! Correct emotion!',
                                      )
                                    : context.tr(
                                        'games.kids_emotions_drag',
                                        fallback:
                                            'Tap or drag the feeling mask onto the stage!',
                                      ),
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: isNarrow ? 12.5.sp : 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.white.withValues(alpha: 0.85)
                                      : Colors.black.withValues(alpha: 0.75),
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 16.h),

                      // The Theater Masks (Options) with Wooden Stage Floor
                      _buildStageOptionsFloor(context, state, quest, options),

                      SizedBox(height: 20.h),
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

  Widget _buildTheaterStage(
    BuildContext context,
    KidsLoaded state,
    dynamic quest, {
    required double width,
    required double height,
  }) {
    return DragTarget<String>(
      key: const Key('kids_emotions_theater_stage_target'),
      onAcceptWithDetails: (details) {
        _handleOptionSubmit(context, state, details.data);
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16.r),
            onTap: state.answerStatus.isAnswered
                ? null
                : () => _replayQuestionAudio(quest),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Backstage Container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isHovering ? AppColors.slate700 : AppColors.slate800,
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color:
                          isHovering ? AppColors.amber500 : AppColors.amber900,
                      width: isHovering ? 6.r : 4.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isHovering ? 0.5 : 0.3,
                        ),
                        blurRadius: isHovering ? 25 : 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 40.w),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (quest.emoji != null &&
                              state.answerStatus == AnswerStatus.correct)
                            Text(
                              quest.emoji!,
                              style: TextStyle(fontSize: 52.sp),
                            )
                          else
                            KidsFittedText(
                              quest.question ?? '?',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 32.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Left Red Velvet Curtain
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 36.w,
                    decoration: BoxDecoration(
                      color: _LocalPalette.color9f1239,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(14.r),
                      ),
                      border: Border(
                        right: BorderSide(
                          color: AppColors.rose700,
                          width: 4.w,
                        ),
                      ),
                    ),
                  ),
                ),

                // Right Red Velvet Curtain
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 36.w,
                    decoration: BoxDecoration(
                      color: _LocalPalette.color9f1239,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(14.r),
                      ),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.rose700,
                          width: 4.w,
                        ),
                      ),
                    ),
                  ),
                ),

                // Top Curtain Valance
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 28.h,
                    decoration: BoxDecoration(
                      color: _LocalPalette.colorbe123c,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(14.r),
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          offset: Offset(0, 3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),

                // Audio Replay Button
                Positioned(
                  top: 8.h,
                  right: 8.w,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      key: const Key('kids_emotions_replay_audio_button'),
                      onTap: () => _replayQuestionAudio(quest),
                      borderRadius: BorderRadius.circular(16.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: KidsColors.warmAmber,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.volume_up_rounded,
                          color: Colors.white,
                          size: 18.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStageOptionsFloor(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    List<String> options,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: _LocalPalette.color92400e,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: KidsColors.warmAmber,
          width: 4.h,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(options.length, (index) {
          final option = options[index];
          final isCorrect = (option == quest.correctAnswer);
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildTheaterMaskOption(
                context,
                state,
                option,
                isCorrect,
                index,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTheaterMaskOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final isComedy = index % 2 == 0;
    final color =
        isComedy ? _LocalPalette.colorfde047 : _LocalPalette.color7dd3fc;
    final shadowColor =
        isComedy ? _LocalPalette.colorca8a04 : _LocalPalette.color0284c7;

    final parts = text.trim().split(' ');
    String wordPart = text;
    String emojiPart = '';
    if (parts.length > 1 && parts.last.runes.any((r) => r > 127)) {
      emojiPart = parts.removeLast();
      wordPart = parts.join(' ');
    }

    final isSelected = (_selectedOption == text);

    final maskWidget = Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('kids_emotions_option_$index'),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(36.r),
          bottomRight: Radius.circular(36.r),
        ),
        onTap: state.answerStatus.isAnswered
            ? null
            : () => _handleOptionSubmit(context, state, text),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(minHeight: 92.h),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
              bottomLeft: Radius.circular(36.r),
              bottomRight: Radius.circular(36.r),
            ),
            border: Border.all(
              color: isSelected ? KidsColors.warmAmber : Colors.white,
              width: isSelected ? 3.5 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, isSelected ? 3 : 5),
                blurRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Speaker icon for audio pronunciation
              Positioned(
                top: 4.h,
                right: 4.w,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    key: Key('kids_emotions_pronounce_$index'),
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => _playOptionAudio(text),
                    child: Padding(
                      padding: EdgeInsets.all(2.r),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 15.r,
                        color: AppColors.slate700.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),

              // Mask Body with text & emoji
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 8.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      KidsFittedText(
                        wordPart,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                      if (emojiPart.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(top: 2.h),
                          child: Text(
                            emojiPart,
                            style: TextStyle(fontSize: 20.sp),
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

    if (state.answerStatus.isAnswered) {
      return maskWidget;
    }

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 75.w,
          child: Transform.scale(
            scale: 1.05,
            child: Opacity(opacity: 0.9, child: maskWidget),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: maskWidget),
      child: maskWidget,
    );
  }
}
