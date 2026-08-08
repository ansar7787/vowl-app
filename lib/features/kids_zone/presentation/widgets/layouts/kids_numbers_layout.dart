import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Space / Rocket Theme for Numbers Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsNumbersLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsNumbersLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'numbers',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Rocket Window for the Question
            Expanded(
              flex: 5,
              child: Center(child: _buildRocketWindow(context, state, quest)),
            ),

            SizedBox(height: 24.h), // Increased space so it doesn't touch the circle
            Text(
              context.tr(
                'games.kids_numbers_drag',
                fallback: 'Drag the planet to the rocket! 🚀',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 16.h), // Increased space below the text as well

            // The Planets/Asteroids for Options
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: _buildPlanetOption(
                          context,
                          state,
                          option,
                          quest.correctAnswer == option,
                          index,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Small AAA Design Card for Fun Facts
            if (quest.funFact != null)
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 24.h, left: 32.w, right: 32.w),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.3),
                      width: 2.w,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_circle_rounded,
                        color: primaryColor,
                        size: 28.r,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: AutoSizeText(
                          quest.funFact!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.8),
                          ),
                          maxLines: 2,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildRocketWindow(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
    return DragTarget<String>(
      onAcceptWithDetails: (details) {
        if (state.lastAnswerCorrect != null) return;
        final text = details.data;
        final isCorrect = (text == quest.correctAnswer);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          width: 260.r,
          height: 260.r,
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFF1E293B)
                : const Color(0xFF0F172A), // Deep Space Blue
            shape: BoxShape.circle,
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF94A3B8),
              width: 16.r,
            ), // Silver metallic frame
            boxShadow: [
              // Outer glow for the window
              BoxShadow(
                color: const Color(0xFF0EA5E9).withValues(
                  alpha: isHovering ? 0.6 : 0.3,
                ),
                blurRadius: isHovering ? 40 : 30,
                spreadRadius: isHovering ? 10 : 5,
              ),
              // Inner shadow for depth
              const BoxShadow(
                color: Colors.black54,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: state.lastAnswerCorrect != null
                ? null
                : () {
                    // Play the instruction sound
                    if (quest.instruction != null) {
                      di.sl<KidsTTSService>().speak(quest.instruction!);
                    }
                  },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Little stars in the background
                Positioned(top: 40.r, left: 50.r, child: _buildStar(10)),
                Positioned(bottom: 60.r, right: 40.r, child: _buildStar(14)),
                Positioned(top: 80.r, right: 60.r, child: _buildStar(8)),

                // The Question ALWAYS visible (No progressive disclosure loophole)
                Padding(
                  padding: EdgeInsets.all(24.r),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AutoSizeText(
                      quest.question ?? "?",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 80.sp, // Made larger since it's the only thing in the window
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: const [
                          Shadow(
                            color: Color(0xFF38BDF8),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
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

  Widget _buildStar(double size) {
    return Icon(
      Icons.star_rounded,
      color: Colors.white.withValues(alpha: 0.5),
      size: size.r,
    );
  }

  Widget _buildPlanetOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // A vibrant gas giant planet style
    final baseColor = const Color(0xFFF59E0B); // Amber planet
    final shadowColor = const Color(0xFFB45309);

    final planetWidget = Container(
      height: 100.h,
      decoration: BoxDecoration(
        color: baseColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(color: shadowColor, offset: Offset(0, 8.h)),
          // Glowing atmosphere
          BoxShadow(
            color: baseColor.withValues(alpha: 0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: AutoSizeText(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 36.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );

    if (state.lastAnswerCorrect != null) {
      return planetWidget;
    }

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: planetWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: planetWidget),
      child: planetWidget
          .animate(
            onPlay: (controller) => controller.repeat(reverse: true),
            delay: Duration(milliseconds: 300 * index), // Staggered start
          )
          .moveY(begin: -5, end: 5, duration: 2.seconds, curve: Curves.easeInOut),
    );
  }
}
