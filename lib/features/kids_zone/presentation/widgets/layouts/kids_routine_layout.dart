import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// Cozy Bedroom Theme for Routine Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsRoutineLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsRoutineLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'routine',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Bedroom Window
            Expanded(
              flex: 5,
              child: Center(child: _buildBedroomWindow(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_routine_drag',
                fallback: 'Drag the pillow to the window! ✨',
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
            // The Bed with Pillows
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // The Bed Blanket
                  Container(
                    height: 80.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1), // Indigo blanket
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24.r),
                      ),
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          offset: const Offset(0, -4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 20.h,
                      left: 24.w,
                      right: 24.w,
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
                            child: _buildPillowOption(
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
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBedroomWindow(
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
        return Stack(
          alignment: Alignment.center,
          children: [
            // The Window pane
            Container(
              width: 240.w,
              height: 180.h,
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFF0284C7)
                    : const Color(0xFF38BDF8), // Light blue daytime sky
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: Colors.white,
                  width: 8.r,
                ), // White window frame
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isHovering ? 0.3 : 0.1,
                    ),
                    blurRadius: isHovering ? 20 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Window mullions (cross pattern)
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 4.h,
                      color: Colors.white,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: 4.w,
                      height: double.infinity,
                      color: Colors.white,
                    ),
                  ),
                  // The text
                  Center(
                    child: Container(
                      width: 180.w,
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (quest.emoji != null)
                            Text(
                              quest.emoji!,
                              style: TextStyle(fontSize: 80.sp),
                            ), // Enlarge emoji, hidden question string
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Curtains
            Positioned(
              left: 10.w,
              top: 0,
              bottom: 0,
              child: Container(
                width: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E), // Rose red curtains
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(8.r),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10.w,
              top: 0,
              bottom: 0,
              child: Container(
                width: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF43F5E), // Rose red curtains
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(8.r),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPillowOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final pillowWidget = Container(
      height: 70.h,
      width: 80.w,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
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
          child: Opacity(opacity: 0.9, child: pillowWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: pillowWidget),
      child: pillowWidget,
    );
  }
}
