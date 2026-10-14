import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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

class _LocalPalette {
  _LocalPalette._();
  static const Color color38bdf8 = Color(0xFF38BDF8);
  static const Color color0ea5e9 = Color(0xFF0EA5E9);
  static const Color color7dd3fc = Color(0xFF7DD3FC);
  static const Color color0284c7 = Color(0xFF0284C7);
  static const Color colorfef08a = Color(0xFFFEF08A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color successBorder = Color(0xFF16A34A);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color errorBorder = Color(0xFFDC2626);
}

/// Sky Observatory Theme for Kids Day & Night Game
/// Supports DUAL INTERACTION (tap-to-answer + drag-and-drop),
/// TTS audio replay, zero 320dp small-screen overflow, and tactile haptics.
class KidsDayNightLayout extends StatefulWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsDayNightLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  State<KidsDayNightLayout> createState() => _KidsDayNightLayoutState();
}

class _KidsDayNightLayoutState extends State<KidsDayNightLayout> {
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
        'Submitting day/night option "$option" for quest "${quest.id}" (correct: $isCorrect)',
        tag: 'KidsDayNightLayout',
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
        'Pronouncing celestial option "$text"',
        tag: 'KidsDayNightLayout',
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
          tag: 'KidsDayNightLayout',
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
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: widget.title,
      gameType: "day_night",
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

            final observatoryWidth =
                (availableWidth * 0.88).clamp(240.0, 340.0).w;
            final observatoryHeight = 175.h;

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

                      // The Observatory Telescope View
                      Center(
                        child: _buildSkyView(
                          context,
                          state,
                          quest,
                          width: observatoryWidth,
                          height: observatoryHeight,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      // Prompt banner with dual-interaction hint
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
                                  : _LocalPalette.color0284c7,
                            ),
                            SizedBox(width: 5.w),
                            Flexible(
                              child: KidsFittedText(
                                context.tr(
                                  'games.kids_day_night_drag',
                                  fallback:
                                      'Tap or drag the correct sky card to the observatory!',
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

                      // Celestial Cards (Options)
                      _buildOptionsArea(
                        context,
                        state,
                        quest,
                        options,
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
    required bool isNarrow,
    required double availableWidth,
  }) {
    if (options.isEmpty) return const SizedBox.shrink();

    // If 2 options (Daytime vs Nighttime), place side by side
    if (options.length == 2) {
      final cardWidth = (availableWidth - 36.w) / 2;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: options.map((option) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: _buildCelestialCard(
                context,
                state,
                option,
                quest,
                maxWidth: cardWidth,
              ),
            ),
          );
        }).toList(),
      );
    }

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
                        horizontal: 4.w,
                        vertical: 3.h,
                      ),
                      child: _buildCelestialCard(
                        context,
                        state,
                        opt,
                        quest,
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
                        horizontal: 4.w,
                        vertical: 3.h,
                      ),
                      child: _buildCelestialCard(
                        context,
                        state,
                        opt,
                        quest,
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

    // Default column of options for action phrases
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(options.length, (index) {
        final option = options[index];
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.h),
          child: _buildCelestialCard(
            context,
            state,
            option,
            quest,
            maxWidth: availableWidth - 24.w,
          ),
        );
      }),
    );
  }

  Widget _buildSkyView(
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

        Color canvasBg = isHovering ? AppColors.slate800 : AppColors.slate900;
        Color borderColor =
            isHovering ? _LocalPalette.color38bdf8 : AppColors.slate600;

        if (isAnswered) {
          if (isCorrectAnswer) {
            canvasBg = const Color(0xFF064E3B); // Deep forest green
            borderColor = _LocalPalette.successBorder;
          } else {
            canvasBg = const Color(0xFF7F1D1D); // Deep crimson red
            borderColor = _LocalPalette.errorBorder;
          }
        }

        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: canvasBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: borderColor,
              width: isHovering || isAnswered ? 3.w : 2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: isHovering ? 18 : 10,
                offset: const Offset(0, 5),
              ),
              if (isHovering)
                BoxShadow(
                  color: _LocalPalette.color0ea5e9.withValues(alpha: 0.3),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative stars in observatory view
              Positioned(
                top: 14.h,
                left: 18.w,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white.withValues(alpha: 0.6),
                  size: 14.r,
                ),
              ),
              Positioned(
                bottom: 20.h,
                right: 22.w,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 12.r,
                ),
              ),
              Positioned(
                top: 38.h,
                right: 26.w,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 10.r,
                ),
              ),

              // Audio Replay Button (Top Right)
              Positioned(
                top: 6.r,
                right: 6.r,
                child: Semantics(
                  label: 'Listen to instruction',
                  button: true,
                  child: InkWell(
                    key: const ValueKey('day_night_audio_replay_btn'),
                    onTap: () => _replayQuestionAudio(quest),
                    borderRadius: BorderRadius.circular(16.r),
                    child: Container(
                      padding: EdgeInsets.all(5.r),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.volume_up_rounded,
                        size: 18.r,
                        color: _LocalPalette.color7dd3fc,
                      ),
                    ),
                  ),
                ),
              ),

              // Center Content (Question + Visuals)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quest.emoji != null && quest.emoji!.isNotEmpty)
                        isAnswered && isCorrectAnswer
                            ? Text(
                                quest.emoji!,
                                style: TextStyle(fontSize: 54.sp),
                              )
                            : ColorFiltered(
                                colorFilter: ColorFilter.mode(
                                  _LocalPalette.color38bdf8
                                      .withValues(alpha: 0.4),
                                  BlendMode.srcIn,
                                ),
                                child: Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 54.sp),
                                ),
                              ),
                      SizedBox(height: 8.h),
                      if (isAnswered && isCorrectAnswer)
                        Text(
                          quest.correctAnswer ?? "",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        )
                      else if (quest.question != null &&
                          quest.question != "?" &&
                          quest.question!.isNotEmpty)
                        KidsFittedText(
                          quest.question!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        )
                      else
                        Text(
                          "?",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 32.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isDaytime(String text, dynamic quest) {
    final options = quest.options as List<dynamic>? ?? [];
    if (options.length == 2) {
      final lowerOpt = text.toLowerCase();
      final otherOpt = options
          .firstWhere((o) => o != text, orElse: () => '')
          .toString()
          .toLowerCase();

      final dayWords = [
        'day',
        'sun',
        'morning',
        'wake',
        'breakfast',
        'school',
        'recess',
        'lunch',
        'bright',
        'light',
      ];
      final nightWords = [
        'night',
        'moon',
        'star',
        'sleep',
        'bed',
        'dark',
        'lamp',
        'pajama',
        'evening',
      ];

      bool hasDay(String s) => dayWords.any((w) => s.contains(w));
      bool hasNight(String s) => nightWords.any((w) => s.contains(w));

      if (hasDay(lowerOpt)) return true;
      if (hasNight(lowerOpt)) return false;

      // Check the other option
      if (hasDay(otherOpt)) return false;
      if (hasNight(otherOpt)) return true;

      // Fallback to quest text analysis
      bool isCorrect = text == quest.correctAnswer;
      final questText =
          '${quest.instruction ?? ''} ${quest.explanation ?? ''}'.toLowerCase();
      int dayScore = dayWords.where((w) => questText.contains(w)).length;
      int nightScore = nightWords.where((w) => questText.contains(w)).length;

      if (dayScore != nightScore) {
        if (isCorrect) {
          return dayScore > nightScore;
        } else {
          return nightScore > dayScore;
        }
      }

      return options.indexOf(text) == 0;
    }

    return true;
  }

  Widget _buildCelestialCard(
    BuildContext context,
    KidsLoaded state,
    String text,
    dynamic quest, {
    required double maxWidth,
  }) {
    final isAnswered = state.answerStatus.isAnswered;
    final isSelected = (_selectedOption == text);
    final isCorrect = (text.trim() == quest.correctAnswer?.trim());
    final isDay = _isDaytime(text, quest);

    // Day = Sunny Sky colors, Night = Deep Space colors
    Color color = isDay ? _LocalPalette.color38bdf8 : AppColors.slate800;
    Color borderColor =
        isDay ? _LocalPalette.color7dd3fc : AppColors.slate700;
    Color shadowColor =
        isDay ? _LocalPalette.color0284c7 : AppColors.slate900;

    if (isAnswered) {
      if (isSelected) {
        if (isCorrect) {
          color = _LocalPalette.successBg;
          borderColor = _LocalPalette.successBorder;
          shadowColor = _LocalPalette.successBorder;
        } else {
          color = _LocalPalette.errorBg;
          borderColor = _LocalPalette.errorBorder;
          shadowColor = _LocalPalette.errorBorder;
        }
      } else if (isCorrect) {
        color = _LocalPalette.successBg;
        borderColor = _LocalPalette.successBorder;
        shadowColor = _LocalPalette.successBorder;
      }
    }

    final cardWidget = Container(
      constraints: BoxConstraints(minHeight: 72.h),
      width: maxWidth,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 2.5.w : 2.r,
        ),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withValues(alpha: 0.3),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDay ? Icons.wb_sunny_rounded : Icons.mode_night_rounded,
                  color: isAnswered
                      ? (isCorrect
                          ? _LocalPalette.successBorder
                          : _LocalPalette.errorBorder)
                      : (isDay
                          ? _LocalPalette.colorfef08a
                          : AppColors.slate200),
                  size: 26.r,
                ),
                SizedBox(height: 6.h),
                KidsFittedText(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.5.sp,
                    fontWeight: FontWeight.w700,
                    color: isAnswered
                        ? (isCorrect
                            ? _LocalPalette.successBorder
                            : _LocalPalette.errorBorder)
                        : Colors.white,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),

          // Small speaker button in top corner
          Positioned(
            top: 2.r,
            right: 2.r,
            child: Semantics(
              label: 'Pronounce $text',
              button: true,
              child: InkWell(
                key: ValueKey('day_night_speaker_$text'),
                onTap: () => _playOptionAudio(text),
                child: Container(
                  padding: EdgeInsets.all(2.r),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.volume_up_rounded,
                    size: 13.r,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    final interactiveCard = Semantics(
      label: 'Celestial option $text',
      button: true,
      enabled: !isAnswered,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey('day_night_option_$text'),
          borderRadius: BorderRadius.circular(16.r),
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
}
