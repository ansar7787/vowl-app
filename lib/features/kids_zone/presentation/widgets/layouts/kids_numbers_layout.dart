import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

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
            SizedBox(height: 12.h),

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
                        ),
                      ),
                    );
                  }),
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
    bool isRevealed = false; // Progressive disclosure state

    return StatefulBuilder(
      key: ValueKey(quest), // CRITICAL: Reset state when quest changes
      builder: (context, setState) {
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
                    color: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: isHovering ? 0.6 : 0.3),
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
                        // Reveal the visual clues if not already revealed
                        if (!isRevealed) {
                          setState(() => isRevealed = true);
                        }
                      },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Little stars in the background
                    Positioned(top: 40.r, left: 50.r, child: _buildStar(10)),
                    Positioned(
                      bottom: 60.r,
                      right: 40.r,
                      child: _buildStar(14),
                    ),
                    Positioned(top: 80.r, right: 60.r, child: _buildStar(8)),

                    // Interactive mystery button / number
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: isRevealed
                          ? Column(
                              key: const ValueKey('revealed_question'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (quest.emoji != null &&
                                    quest.question != quest.emoji)
                                  Text(
                                    quest.emoji!,
                                    style: TextStyle(fontSize: 48.sp),
                                  ),
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: AutoSizeText(
                                    quest.question ?? "?",
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 60.sp,
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
                                    minFontSize: 20,
                                  ),
                                ),
                                if (quest.funFact != null) ...[
                                  SizedBox(height: 4.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24.w,
                                    ),
                                    child: AutoSizeText(
                                      quest.funFact!,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(
                                          0xFF94A3B8,
                                        ), // Silver
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      minFontSize: 8,
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Column(
                              key: const ValueKey('mystery'),
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: EdgeInsets.all(16.r),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFFFDE68A,
                                    ).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFFDE68A),
                                      width: 3.w,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    size: 40.sp,
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                SizedBox(height: 12.h),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDE68A),
                                    borderRadius: BorderRadius.circular(20.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.1,
                                        ),
                                        offset: Offset(0, 4.h),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    context.tr(
                                      'games.kids_tap_me',
                                      fallback: 'TAP ME!',
                                    ),
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF78350F),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
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
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: AutoSizeText(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 36.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            maxLines: 1,
            minFontSize: 12,
          ),
        ),
      ),
    );

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
      child: planetWidget,
    );
  }
}
