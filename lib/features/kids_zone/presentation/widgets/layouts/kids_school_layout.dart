import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// School Bus Theme for School Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsSchoolLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsSchoolLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'school',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Bus Window
            Expanded(
              flex: 5,
              child: Center(child: _buildBusWindow(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_school_drag',
                fallback: 'Drag the backpack to the bus window! ✨',
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
            // Backpacks on Seats
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Bus Seats
                  Container(
                    height: 50.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B), // Dark seat color
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(16.r),
                      ),
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
                            child: _buildBackpackOption(
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

  Widget _buildBusWindow(
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
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 280.w,
          height: 200.h,
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFFBAE6FD)
                : const Color(0xFFE0F2FE), // Sky blue outside window
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFFFDE047)
                  : const Color(0xFFFACC15),
              width: 16.r,
            ), // School bus yellow frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quest.emoji != null)
                  Text(
                    quest.emoji!,
                    style: TextStyle(fontSize: 80.sp),
                  ), // Enlarge emoji since question is hidden
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackpackOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final colors = [
      const Color(0xFFEF4444), // Red
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
    ];
    final color = colors[index % colors.length];

    final backpackWidget = SizedBox(
      width: 80.w,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Backpack Handle
          Container(
            width: 30.w,
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                color: color.withValues(alpha: 0.8),
                width: 4.r,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
            ),
          ),
          // Main Backpack Body
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Container(
              height: 90.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.1),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Front Pocket Line
                  Container(
                    margin: EdgeInsets.only(top: 30.h),
                    height: 2.h,
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: Center(
                      child: KidsFittedText(
                        text,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
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
          child: Opacity(opacity: 0.9, child: backpackWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: backpackWidget),
      child: backpackWidget,
    );
  }
}
