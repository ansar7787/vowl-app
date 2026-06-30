import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';


/// Magical Forest Theme for Nature Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsNatureLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsNatureLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'nature',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Stack(
          children: [
            // Floating Fireflies in background
            Positioned(top: 100.h, left: 20.w, child: _buildFirefly()),
            Positioned(top: 180.h, right: 30.w, child: _buildFirefly()),
            Positioned(top: 250.h, left: 50.w, child: _buildFirefly()),
            
            Column(
              children: [
                SizedBox(height: 120.h),
                // The Wooden Tree Sign
                Expanded(
                  flex: 5,
                  child: Center(
                    child: _buildTreeSign(quest.question ?? "?"),
                  ),
                ),
                // Glowing River Stones (Options)
                Flexible(
                  flex: 5,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // Forest Floor (Moss)
                      Container(
                        height: 40.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF14532D), // Dark green moss
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 20.h, left: 16.w, right: 16.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(quest.options?.length ?? 0, (index) {
                            final option = quest.options![index];
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4.w),
                                child: _buildGlowingStoneOption(
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
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildFirefly() {
    return Container(
      width: 10.r,
      height: 10.r,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF08A),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEAB308),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.5, 1.5), duration: 2.seconds)
     .fade(begin: 0.2, end: 1.0, duration: 1.seconds);
  }

  Widget _buildTreeSign(String text) {
    return Container(
      width: 240.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: const Color(0xFF78350F), // Dark wood
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFF451A03), width: 6.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Leaves on the sign
          Positioned(
            top: -20.h,
            left: -10.w,
            child: Icon(Icons.eco_rounded, color: const Color(0xFF16A34A), size: 60.r),
          ),
          Positioned(
            bottom: -15.h,
            right: -10.w,
            child: Icon(Icons.eco_rounded, color: const Color(0xFF15803D), size: 50.r),
          ),
          
          Center(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 42.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFEF3C7), // Light wood text
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlowingStoneOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // Subtle rotation for organic stone look
    final rotations = [-0.1, 0.05, -0.05, 0.1];
    final rotation = rotations[index % rotations.length];

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Transform.rotate(
        angle: rotation,
        child: Container(
          height: 80.r,
          decoration: BoxDecoration(
            color: const Color(0xFF94A3B8), // Slate grey stone
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(20.r),
              bottomLeft: Radius.circular(25.r),
              bottomRight: Radius.circular(35.r),
            ),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
            boxShadow: [
              // Shadow below
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                offset: const Offset(0, 8),
              ),
              // Magic glow inside
              BoxShadow(
                color: const Color(0xFF6EE7B7).withValues(alpha: 0.3), // Mint green glow
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
