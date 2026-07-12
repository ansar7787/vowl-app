import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Jungle Safari Theme for Animals Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsAnimalsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsAnimalsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'animals',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Stack(
          children: [
            // Lush jungle framing the screen edges
            Positioned(
              top: 100.h,
              left: -20.w,
              child: _buildLeaf(const Color(0xFF166534), 80.r, 0.5),
            ),
            Positioned(
              top: 180.h,
              right: -10.w,
              child: _buildLeaf(const Color(0xFF14532D), 100.r, -0.8),
            ),
            Positioned(
              bottom: 200.h,
              left: -30.w,
              child: _buildLeaf(const Color(0xFF15803D), 120.r, 0.3),
            ),

            Column(
              children: [
                SizedBox(height: 120.h),
                // The Binoculars / Safari Frame
                Expanded(
                  flex: 5,
                  child: Center(child: _buildSafariFrame(quest)),
                ),
                // Wooden Signposts for Options
                Flexible(
                  flex: 5,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (
                        index,
                      ) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildWoodenSignpost(
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

  Widget _buildLeaf(Color color, double size, double rotation) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size),
            bottomRight: Radius.circular(size),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(4, 4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSafariFrame(dynamic quest) {
    return Container(
      width: 300.w,
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7), // Safari Khaki
        borderRadius: BorderRadius.circular(100.r), // Pill shape for binoculars
        border: Border.all(
          color: const Color(0xFF78350F),
          width: 8.r,
        ), // Dark leather
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Middle split of binoculars
          Container(
            width: 12.w,
            height: double.infinity,
            color: const Color(0xFF78350F),
          ),
          Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (quest.emoji != null)
                    Text(quest.emoji!, style: TextStyle(fontSize: 48.sp)),
                  Text(
                    quest.question ?? "?",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 32.sp,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (quest.funFact != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      quest.funFact!,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF047857), // Jungle green
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWoodenSignpost(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final baseColor = const Color(0xFFD97706); // Wood
    final shadowColor = const Color(0xFF92400E); // Dark Wood

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The wooden board
          Container(
            height: 70.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: baseColor,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: shadowColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF451A03), // Very dark wood text
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          // The stick holding it up
          Container(
            height: 40.h,
            width: 16.w,
            decoration: BoxDecoration(
              color: shadowColor,
              border: Border.all(color: const Color(0xFF78350F), width: 1),
            ),
          ),
        ],
      ),
    );
  }
}
