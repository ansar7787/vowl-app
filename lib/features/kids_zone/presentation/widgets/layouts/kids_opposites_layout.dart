import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

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
            Expanded(
              flex: 5,
              child: Center(child: _buildSplitWorld(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr(
                'games.kids_opposites_drag',
                fallback: 'Drag the matching plaque! ✨',
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
            SizedBox(height: 16.h),
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

  Widget _buildSplitWorld(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
  ) {
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFF6366F1)
                  : const Color(0xFF1E293B),
              width: isHovering ? 10.r : 8.r,
            ), // Dark frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.4 : 0.2),
                blurRadius: isHovering ? 25 : 15,
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
                  child: Container(
                    color: isHovering
                        ? const Color(0xFFFECACA)
                        : const Color(0xFFFCA5A5),
                  ), // Light red
                ),
                // Right Half (Ice / Cold)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  width: 140.w,
                  child: Container(
                    color: isHovering
                        ? const Color(0xFFBFDBFE)
                        : const Color(0xFF93C5FD),
                  ), // Light blue
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
                    width: 220.w,
                    height: 160.h,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
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
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            child: AutoSizeText(
                              quest.instruction ??
                                  "?", // Use instruction, hide emoji/question to prevent cheat
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 22.sp,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              minFontSize: 12,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSplitPlaqueOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final plaqueWidget = Container(
      height: 70.h,
      width: 80.w,
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
                  border: Border.all(color: const Color(0xFF1E293B), width: 1),
                ),
                child: AutoSizeText(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 8,
                ),
              ),
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
          child: Opacity(opacity: 0.9, child: plaqueWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: plaqueWidget),
      child: plaqueWidget,
    );
  }
}
