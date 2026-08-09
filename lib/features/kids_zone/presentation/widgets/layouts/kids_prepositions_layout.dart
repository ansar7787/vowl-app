import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'dart:math' as math;
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

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
              child: Center(child: _buildMagicStage(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_prepositions_drag',
                fallback: 'Drag the magic hat to the stage! ✨',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.8)
                    : Colors.black.withValues(alpha: 0.6),
              ),
              maxLines: 2,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
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

  Widget _buildMagicStage(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
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
            return Container(
              width: 280.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFF4C1D95)
                    : const Color(0xFF2E1065), // Deep magical purple
                borderRadius: BorderRadius.circular(100.r), // Magical orb shape
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFFE9D5FF)
                      : const Color(0xFFC084FC),
                  width: 4.r,
                ), // Glowing border
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9333EA).withValues(alpha: 0.5),
                    blurRadius: isHovering ? 30 : 20,
                    spreadRadius: isHovering ? 10 : 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Magic sparkles
                  Positioned(top: 30.h, left: 40.w, child: _buildSparkle(15)),
                  Positioned(
                    bottom: 40.h,
                    right: 30.w,
                    child: _buildSparkle(20),
                  ),
                  Positioned(top: 80.h, right: 20.w, child: _buildSparkle(10)),

                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (quest.emoji != null)
                          Text(
                            quest.emoji!,
                            style: TextStyle(fontSize: 80.sp),
                          ), // Enlarged emoji, hidden question
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: -5.h,
          end: 5.h,
          duration: 2.seconds,
          curve: Curves.easeInOutSine,
        );
  }

  Widget _buildSparkle(double size) {
    return Icon(Icons.star_rounded, color: Colors.yellow, size: size.r)
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.5, 1.5),
          duration: 1.seconds,
        );
  }

  Widget _buildTopHatOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final hatWidget = SizedBox(
      width: 80.w,
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
                  child: Container(
                    width: 8.w,
                    height: 25.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.pink[200]!),
                    ),
                  ),
                ),
                SizedBox(width: 5.w),
                Transform.rotate(
                  angle: math.pi / 8,
                  child: Container(
                    width: 8.w,
                    height: 25.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.pink[200]!),
                    ),
                  ),
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
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(8.r),
                  ),
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
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      offset: const Offset(0, 4),
                    ),
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
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF4C1D95),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: hatWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: hatWidget),
      child: hatWidget,
    );
  }
}
