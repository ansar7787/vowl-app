import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';

/// Friendly Clinic Theme for Body Parts Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsBodyPartsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsBodyPartsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'body_parts',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The X-Ray Board
            Expanded(
              flex: 5,
              child: Center(
                child: _buildXRayBoard(quest.question ?? "?", quest.emoji),
              ),
            ),
            // The Band-aids (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Clinic Desk (Clean white/blue)
                  Container(
                    height: 30.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
                      border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h, left: 16.w, right: 16.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(quest.options?.length ?? 0, (index) {
                        final option = quest.options![index];
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildBandaidOption(
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
        );
      },
    );
  }

  Widget _buildXRayBoard(String text, String? emoji) {
    return Container(
      width: 240.w,
      height: 160.h,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark X-Ray background
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 12.r), // Medical white frame
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.3), // Blue glowing backlight
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Center(
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
                fontSize: 42.sp,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFE0F2FE), // Glowing light blue text
                shadows: const [
                  Shadow(color: Color(0xFF38BDF8), blurRadius: 10),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBandaidOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final colors = [
      const Color(0xFFFDE68A), // Light tan
      const Color(0xFFFCA5A5), // Pinkish
      const Color(0xFF6EE7B7), // Mint green (fun kid bandaid)
      const Color(0xFF93C5FD), // Light blue
    ];
    final bandaidColor = colors[index % colors.length];

    return ScaleButton(
      onTap: () {
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 70.h,
        decoration: BoxDecoration(
          color: bandaidColor,
          borderRadius: BorderRadius.circular(30.r), // Pill shape for bandaid
          border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Band-aid dots texture
            Positioned(left: 10.w, top: 20.h, child: _buildDot()),
            Positioned(left: 10.w, bottom: 20.h, child: _buildDot()),
            Positioned(right: 10.w, top: 20.h, child: _buildDot()),
            Positioned(right: 10.w, bottom: 20.h, child: _buildDot()),
            
            // White pad in the middle
            Center(
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 20.w),
                padding: EdgeInsets.symmetric(vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
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
          ],
        ),
      ),
    );
  }

  Widget _buildDot() {
    return Container(
      width: 4.r,
      height: 4.r,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
    );
  }
}
