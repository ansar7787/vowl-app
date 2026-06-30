import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

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
              child: Center(
                child: _buildRocketWindow(quest.question ?? "?", quest.emoji),
              ),
            ),
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

  Widget _buildRocketWindow(String text, String? emoji) {
    return Container(
      width: 220.r,
      height: 220.r,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Deep Space Blue
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF94A3B8), width: 16.r), // Silver metallic frame
        boxShadow: [
          // Outer glow for the window
          BoxShadow(
            color: const Color(0xFF0EA5E9).withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
          // Inner shadow for depth
          const BoxShadow(
            color: Colors.black54,
            blurRadius: 10,
            offset: Offset(0, 5), // Simulating inner shadow via generic blur isn't native, so we just use standard shadow.
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Little stars in the background
          Positioned(top: 40.r, left: 50.r, child: _buildStar(10)),
          Positioned(bottom: 60.r, right: 40.r, child: _buildStar(14)),
          Positioned(top: 80.r, right: 60.r, child: _buildStar(8)),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (emoji != null)
                Text(
                  emoji,
                  style: TextStyle(fontSize: 48.sp),
                ),
              Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 80.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: const [
                    Shadow(color: Color(0xFF38BDF8), blurRadius: 15),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStar(double size) {
    return Icon(Icons.star_rounded, color: Colors.white.withValues(alpha: 0.5), size: size.r);
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

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 100.h,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              offset: Offset(0, 8.h),
            ),
            // Glowing atmosphere
            BoxShadow(
              color: baseColor.withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 36.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
