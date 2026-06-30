import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'dart:math' as math;

/// Magic Show Theme for Prepositions Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsPrepositionsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsPrepositionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'prepositions',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Magical Floating Stage
            Expanded(
              flex: 5,
              child: Center(
                child: _buildMagicStage(quest.question ?? "?", quest.emoji),
              ),
            ),
            // The Magician Top Hats (Options)
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: _buildTopHatOption(
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

  Widget _buildMagicStage(String text, String? emoji) {
    return Container(
      width: 240.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: const Color(0xFF2E1065), // Deep magical purple
        borderRadius: BorderRadius.circular(100.r), // Magical orb shape
        border: Border.all(color: const Color(0xFFC084FC), width: 4.r), // Glowing border
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9333EA).withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Magic sparkles
          Positioned(top: 30.h, left: 40.w, child: _buildSparkle(15)),
          Positioned(bottom: 40.h, right: 30.w, child: _buildSparkle(20)),
          Positioned(top: 80.h, right: 20.w, child: _buildSparkle(10)),
          
          Center(
            child: Column(
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
                    fontSize: 48.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    shadows: const [
                      Shadow(color: Color(0xFFD8B4FE), blurRadius: 10),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .moveY(begin: -5.h, end: 5.h, duration: 2.seconds, curve: Curves.easeInOutSine);
  }

  Widget _buildSparkle(double size) {
    return Icon(Icons.star_rounded, color: Colors.yellow, size: size.r)
      .animate(onPlay: (c) => c.repeat(reverse: true))
      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 1.seconds);
  }

  Widget _buildTopHatOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Little bunny ears popping out of the hat for fun
          Positioned(
            top: -15.h,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Transform.rotate(
                  angle: -math.pi / 8,
                  child: Container(width: 8.w, height: 25.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.pink[200]!))),
                ),
                SizedBox(width: 5.w),
                Transform.rotate(
                  angle: math.pi / 8,
                  child: Container(width: 8.w, height: 25.h, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r), border: Border.all(color: Colors.pink[200]!))),
                ),
              ],
            ),
          ),
          
          // Main Top Hat body
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hat cylinder
              Container(
                height: 70.h,
                width: 60.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B), // Black/dark grey hat
                  borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                  border: Border.all(color: Colors.white24, width: 1),
                ),
                child: Column(
                  children: [
                    const Spacer(),
                    // Red ribbon band
                    Container(
                      height: 12.h,
                      width: double.infinity,
                      color: const Color(0xFFE11D48),
                    ),
                  ],
                ),
              ),
              // Hat brim
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 4)),
                  ],
                ),
              ),
            ],
          ),
          // Option Text Plaque resting on the hat brim
          Positioned(
            bottom: 20.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4.r),
                border: Border.all(color: const Color(0xFF9333EA), width: 1),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF4C1D95),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
