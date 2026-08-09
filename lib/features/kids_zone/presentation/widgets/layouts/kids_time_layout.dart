import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// Giant Clock Tower Theme for Time Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsTimeLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsTimeLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'time',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Giant Clock Face
            Expanded(
              flex: 5,
              child: Center(child: _buildClockFace(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_time_drag',
                fallback: 'Drag the pocket watch to the clock tower! ✨',
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
            // The Pocket Watches (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Wooden Shelf inside tower
                  Container(
                    height: 20.h,
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF451A03), // Dark wood
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: 20.h,
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
                            child: _buildPocketWatchOption(
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

  Widget _buildClockFace(
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
          width: 260.r,
          height: 260.r,
          decoration: BoxDecoration(
            color: isHovering
                ? const Color(0xFFFEF9C3)
                : const Color(0xFFFEF3C7), // Antique clock face
            shape: BoxShape.circle,
            border: Border.all(
              color: isHovering
                  ? const Color(0xFFD97706)
                  : const Color(0xFFB45309),
              width: isHovering ? 16.r : 12.r,
            ), // Brass frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.5 : 0.3),
                blurRadius: isHovering ? 25 : 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Clock numbers (visual decoration)
              Positioned(
                top: 10.r,
                child: Text("12", style: _clockNumStyle()),
              ),
              Positioned(
                bottom: 10.r,
                child: Text("6", style: _clockNumStyle()),
              ),
              Positioned(
                left: 15.r,
                child: Text("9", style: _clockNumStyle()),
              ),
              Positioned(
                right: 15.r,
                child: Text("3", style: _clockNumStyle()),
              ),

              // Background gears
              _buildGear(40, -40, 60, true),
              _buildGear(-40, 30, 80, false),

              // Main Instruction text in the center (Hide question/emoji)
              Center(
                child: Container(
                  width: 200.w,
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: const Color(0xFFD97706),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      KidsFittedText(
                        quest.question ?? "?", // Use instruction
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 20.sp,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  TextStyle _clockNumStyle() {
    return TextStyle(
      fontFamily: 'Outfit',
      fontSize: 24.sp,
      fontWeight: FontWeight.w700,
      color: const Color(0xFF78350F).withValues(alpha: 0.3),
    );
  }

  Widget _buildGear(double x, double y, double size, bool clockwise) {
    // Static gears for now, rotation isn't strictly necessary since flutter_animate was removed.
    return Positioned(
      left: 110.r + x - (size / 2),
      top: 110.r + y - (size / 2),
      child: Icon(
        Icons.settings_rounded,
        color: const Color(0xFFD97706).withValues(alpha: 0.2),
        size: size,
      ),
    );
  }

  Widget _buildPocketWatchOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final watchWidget = SizedBox(
      width: 80.w,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The chain
          Container(
            height: 15.h,
            width: 4.w,
            color: const Color(0xFFFBBF24), // Gold chain
          ),
          // The Watch body
          Container(
            height: 75.r,
            width: 75.r,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFBBF24),
                width: 6.r,
              ), // Gold rim
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 4),
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
                      color: const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
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
          child: Opacity(opacity: 0.9, child: watchWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: watchWidget),
      child: watchWidget,
    );
  }
}
