import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

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
                Expanded(
                  flex: 5,
                  child: Center(child: _buildSkyView(context, state, quest)),
                ),
                // Celestial Cards (Options)
                Flexible(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 20.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(quest.options?.length ?? 0, (
                        index,
                      ) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: _buildCelestialCard(
                              context,
                              state,
                              option,
                              quest.correctAnswer == option,
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
    return Icon(
          Icons.cloud_rounded,
          color: Colors.white.withValues(alpha: 0.2),
          size: size,
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveX(
          begin: -10.w,
          end: 10.w,
          duration: 6.seconds,
          curve: Curves.easeInOutSine,
        );
  }

  Widget _buildSkyView(BuildContext context, KidsLoaded state, dynamic quest) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 280.w,
          height: 220.h,
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(
              40.r,
            ), // Chunky rounded rectangle
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF64748B),
              width: isHovering ? 12.r : 8.r,
            ), // Thick observatory metal frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.5 : 0.3),
                blurRadius: isHovering ? 30 : 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: const Color(0xFF0EA5E9).withValues(
                  alpha: isHovering ? 0.3 : 0.1,
                ), // Slight atmospheric glow
                blurRadius: isHovering ? 60 : 40,
                spreadRadius: isHovering ? 10 : 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Twinkling stars in the observatory view
              Positioned(top: 20.h, left: 30.w, child: _buildTwinklingStar()),
              Positioned(
                bottom: 40.h,
                right: 40.w,
                child: _buildTwinklingStar(),
              ),
              Positioned(top: 60.h, right: 30.w, child: _buildTwinklingStar()),

              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AutoSizeText(
                        quest.instruction ?? "?",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                        minFontSize: 12,
                      ),
                    ),
                    if (quest.funFact != null) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: AutoSizeText(
                          quest.funFact!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7DD3FC), // Light sky blue
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTwinklingStar() {
    return Icon(
          Icons.star_rounded,
          color: Colors.white.withValues(alpha: 0.8),
          size: 12.r,
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(begin: 0.2, end: 1.0, duration: 1500.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.2, 1.2),
          duration: 1500.ms,
        );
  }

  Widget _buildCelestialCard(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final isDay =
        text.toLowerCase().contains("day") ||
        text.toLowerCase().contains("sun") ||
        text.toLowerCase().contains("morning");

    // Day = Sunny Sky colors, Night = Deep Space colors
    final color = isDay ? const Color(0xFF38BDF8) : const Color(0xFF1E293B);
    final borderColor = isDay
        ? const Color(0xFF7DD3FC)
        : const Color(0xFF334155);
    final shadowColor = isDay
        ? const Color(0xFF0284C7)
        : const Color(0xFF0F172A);

    final cardWidget = Container(
      height: 120.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 4.r),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 8))],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouncing icon (Sun or Moon)
            Icon(
                  isDay ? Icons.wb_sunny_rounded : Icons.mode_night_rounded,
                  color: isDay
                      ? const Color(0xFFFEF08A)
                      : const Color(0xFFE2E8F0),
                  size: 42.sp,
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(
                  begin: -2.h,
                  end: 2.h,
                  duration: 2.seconds,
                  curve: Curves.easeInOutSine,
                ),

            SizedBox(height: 12.h),

            AutoSizeText(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              minFontSize: 8,
            ),
          ],
        ),
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: cardWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: cardWidget),
      child: cardWidget,
    );
  }
}
