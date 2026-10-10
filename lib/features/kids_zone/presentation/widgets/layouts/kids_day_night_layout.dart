import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
class _LocalPalette {
  _LocalPalette._();
  static const Color color38bdf8 = Color(0xFF38BDF8);
  static const Color color0ea5e9 = Color(0xFF0EA5E9);
  static const Color color7dd3fc = Color(0xFF7DD3FC);
  static const Color color0284c7 = Color(0xFF0284C7);
  static const Color colorfef08a = Color(0xFFFEF08A);
}

/// Sky Observatory Theme for Day & Night Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsDayNightLayout extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: "day_night",
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Stack(
          children: [
            // Ambient Floating Clouds in Background
            Positioned(top: 80.h, left: 10.w, child: _buildCloud(40.w)),
            Positioned(top: 150.h, right: 20.w, child: _buildCloud(60.w)),
            Positioned(top: 250.h, left: -20.w, child: _buildCloud(80.w)),

            Column(
              children: [
                SizedBox(height: 120.h),
                // The Observatory Telescope View
                Flexible(
                  flex: 5,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: _buildSkyView(context, state, quest),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Text(
                    context.tr(
                      'games.kids_day_night_drag',
                      fallback: 'Select the correct option',
                    ),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.9)
                          : Colors.black.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 16.h),
                // Celestial Cards (Options)
                Flexible(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 16.h,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: List.generate(quest.options?.length ?? 0, (
                        index,
                      ) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: _buildCelestialCard(
                              context,
                              state,
                              option,
                              quest,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCloud(double size) {
    return Builder(
      builder: (context) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        Widget cloud = Icon(
          Icons.cloud_rounded,
          color: Colors.white.withValues(alpha: 0.2),
          size: size,
        );
        if (!reduceMotion) {
          cloud = cloud
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveX(
                begin: -10.w,
                end: 10.w,
                duration: 6.seconds,
                curve: Curves.easeInOutSine,
              );
        }
        return cloud;
      },
    );
  }

  Widget _buildSkyView(BuildContext context, KidsLoaded state, dynamic quest) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return InkWell(
          onTap: state.answerStatus.isAnswered
              ? null
              : () {
                  if (InstructionHelper.getInstruction(quest).isNotEmpty) {
                    di.sl<KidsTTSService>().speak(
                      InstructionHelper.getInstruction(quest),
                    );
                  }
                },
          borderRadius: BorderRadius.circular(24.r),
          child: Container(
            width: 300.w,
            height: 240.h,
            decoration: BoxDecoration(
              color: isHovering ? AppColors.slate800 : AppColors.slate900,
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: isHovering
                    ? _LocalPalette.color38bdf8
                    : AppColors.slate600,
                width: isHovering ? 4.r : 2.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                if (isHovering)
                  BoxShadow(
                    color: _LocalPalette.color0ea5e9.withValues(
                      alpha: 0.2,
                    ),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: Stack(
              children: [
                // Twinkling stars in the background
                Positioned(top: 20.h, left: 30.w, child: _buildTwinklingStar()),
                Positioned(
                  bottom: 40.h,
                  right: 40.w,
                  child: _buildTwinklingStar(),
                ),
                Positioned(
                  top: 60.h,
                  right: 30.w,
                  child: _buildTwinklingStar(),
                ),

                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 16.h,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (quest.emoji != null)
                          state.answerStatus == AnswerStatus.correct
                              ? Text(
                                  quest.emoji!,
                                  style: TextStyle(fontSize: 48.sp),
                                )
                              : ColorFiltered(
                                  colorFilter: ColorFilter.mode(
                                    const Color(
                                      0xFF38BDF8,
                                    ).withValues(alpha: 0.3),
                                    BlendMode.srcIn,
                                  ),
                                  child: Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 48.sp),
                                  ),
                                ),
                        SizedBox(height: 12.h),
                        if (state.answerStatus == AnswerStatus.correct)
                          Text(
                            quest.correctAnswer ?? "",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 20.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else if (quest.question != null &&
                            quest.question != "?")
                          Text(
                            quest.question!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          )
                        else
                          Text(
                            "?",
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 40.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                      ],
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

  Widget _buildTwinklingStar() {
    return Builder(
      builder: (context) {
        final reduceMotion = MediaQuery.disableAnimationsOf(context);
        Widget star = Icon(
          Icons.star_rounded,
          color: Colors.white.withValues(alpha: 0.8),
          size: 16.r,
        );
        if (!reduceMotion) {
          star = star
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(begin: 0.2, end: 1.0, duration: 1500.ms)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 1500.ms,
              );
        }
        return star;
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
      final questText = '${quest.instruction ?? ''} ${quest.explanation ?? ''}'
          .toLowerCase();
      int dayScore = dayWords.where((w) => questText.contains(w)).length;
      int nightScore = nightWords.where((w) => questText.contains(w)).length;

      if (dayScore != nightScore) {
        if (isCorrect) {
          return dayScore > nightScore;
        } else {
          return nightScore > dayScore;
        }
      }

      // Ultimate fallback: assign based on index to ensure visual variety
      return options.indexOf(text) == 0;
    }

    return true;
  }

  Widget _buildCelestialCard(
    BuildContext context,
    KidsLoaded state,
    String text,
    dynamic quest,
  ) {
    final isDay = _isDaytime(text, quest);
    final isCorrect = text == quest.correctAnswer;

    // Day = Sunny Sky colors, Night = Deep Space colors
    final color = isDay ? _LocalPalette.color38bdf8 : AppColors.slate800;
    final borderColor = isDay ? _LocalPalette.color7dd3fc : AppColors.slate700;
    final shadowColor = isDay ? _LocalPalette.color0284c7 : AppColors.slate900;

    final cardWidget = GestureDetector(
      onTap: state.answerStatus.isAnswered
          ? null
          : () {
              if (!isCorrect) {
                di.sl<KidsTTSService>().speak(text);
              }
              context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
            },
      child: Container(
        constraints: BoxConstraints(minHeight: 100.h),
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: borderColor, width: 2.r),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bouncing icon (Sun or Moon)
            Builder(
              builder: (context) {
                final reduceMotion = MediaQuery.disableAnimationsOf(context);
                Widget icon = Icon(
                  isDay ? Icons.wb_sunny_rounded : Icons.mode_night_rounded,
                  color: isDay ? _LocalPalette.colorfef08a : AppColors.slate200,
                  size: 32.sp,
                );
                if (!reduceMotion && !state.answerStatus.isAnswered) {
                  icon = icon
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .moveY(
                        begin: -2.h,
                        end: 2.h,
                        duration: 2.seconds,
                        curve: Curves.easeInOutSine,
                      );
                }
                return icon;
              },
            ),
            SizedBox(height: 12.h),
            Flexible(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  height: 1.3,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

    return Draggable<String>(
      data: text,
      maxSimultaneousDrags: state.answerStatus.isAnswered ? 0 : 1,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(
            opacity: 0.9,
            child: SizedBox(
              width:
                  MediaQuery.of(context).size.width *
                  0.4, // Responsive feedback width
              child: cardWidget,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardWidget),
      child: cardWidget,
    );
  }
}
