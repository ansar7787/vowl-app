import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Split World Theme for Opposites Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsOppositesLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsOppositesLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'opposites',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Split Mirror / Split World
            Expanded(flex: 5, child: Center(child: _buildSplitWorld(quest))),
            // The Split Plaques (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Base shelf
                  Container(
                    height: 10.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B), // Slate shelf
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 10.h,
                      left: 16.w,
                      right: 16.w,
                    ),
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
                            child: _buildSplitPlaqueOption(
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

  Widget _buildSplitWorld(dynamic quest) {
    return Container(
      width: 280.w,
      height: 220.h,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: const Color(0xFF1E293B),
          width: 8.r,
        ), // Dark frame
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Stack(
          children: [
            // Left Half (Fire / Warm)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 140.w, // Half width approx
              child: Container(color: const Color(0xFFFCA5A5)), // Light red
            ),
            // Right Half (Ice / Cold)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 140.w,
              child: Container(color: const Color(0xFF93C5FD)), // Light blue
            ),
            // Center Divider Line
            Center(
              child: Container(
                width: 4.w,
                height: double.infinity,
                color: const Color(0xFF1E293B),
              ),
            ),
            // Main Text in a central circle
            Center(
              child: Container(
                width: 200.w,
                height: 140.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: const Color(0xFF1E293B),
                    width: 4.r,
                  ),
                ),
                child: Center(
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
                          color: const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (quest.funFact != null) ...[
                        SizedBox(height: 4.h),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: Text(
                            quest.funFact!,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569), // Slate grey
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitPlaqueOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    return ScaleButton(
      onTap: () {
        di.sl<KidsTTSService>().speak(text);
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      child: Container(
        height: 70.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: const Color(0xFF1E293B), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.r),
          child: Stack(
            children: [
              // Top half
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 35.h,
                child: Container(color: const Color(0xFFFDE047)), // Yellow
              ),
              // Bottom half
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 35.h,
                child: Container(color: const Color(0xFFC4B5FD)), // Purple
              ),
              // Divider
              Center(
                child: Container(
                  height: 2.h,
                  width: double.infinity,
                  color: const Color(0xFF1E293B),
                ),
              ),
              // Text Box in the middle
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4.r),
                    border: Border.all(
                      color: const Color(0xFF1E293B),
                      width: 1,
                    ),
                  ),
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
            ],
          ),
        ),
      ),
    );
  }
}
