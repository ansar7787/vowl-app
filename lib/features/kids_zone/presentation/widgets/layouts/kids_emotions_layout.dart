import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Puppet Theater Theme for Emotions Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsEmotionsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsEmotionsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'emotions',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Theater Stage
            Expanded(
              flex: 5,
              child: Center(child: _buildTheaterStage(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            AutoSizeText(
              context.tr(
                'games.kids_emotions_drag',
                fallback: 'Drag the feeling to the stage! ✨',
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
              minFontSize: 10,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            // The Theater Masks (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Wooden Stage Floor
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF92400E), // Wooden stage
                      border: Border(
                        top: BorderSide(
                          color: const Color(0xFFB45309),
                          width: 6.h,
                        ),
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
                            child: _buildTheaterMaskOption(
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

  Widget _buildTheaterStage(
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
            // The Stage background
            Container(
              width: 280.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFF334155)
                    : const Color(0xFF1E293B), // Dark backstage
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFFD97706)
                      : const Color(0xFF78350F),
                  width: 8.r,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isHovering ? 0.5 : 0.3,
                    ),
                    blurRadius: isHovering ? 25 : 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        offset: Offset(0, 4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (quest.emoji != null)
                        Text(
                          quest.emoji!,
                          style: TextStyle(fontSize: 80.sp),
                        ), // Enlarge emoji, hide question string
                    ],
                  ),
                ),
              ),
            ),
            // Red Velvet Curtains (Left)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF9F1239), // Velvet red
                  borderRadius: BorderRadius.horizontal(
                    left: Radius.circular(4.r),
                  ),
                  border: Border(
                    right: BorderSide(
                      color: const Color(0xFFE11D48),
                      width: 4.w,
                    ), // Curtain fold highlight
                  ),
                ),
              ),
            ),
            // Red Velvet Curtains (Right)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFF9F1239),
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(4.r),
                  ),
                  border: Border(
                    left: BorderSide(
                      color: const Color(0xFFE11D48),
                      width: 4.w,
                    ),
                  ),
                ),
              ),
            ),
            // Stage Valance (Top curtain)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 30.h,
                decoration: BoxDecoration(
                  color: const Color(0xFFBE123C),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(4.r),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      offset: Offset(0, 4),
                      blurRadius: 4,
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

  Widget _buildTheaterMaskOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    // Alternate between "comedy" (yellow) and "tragedy" (blue) base colors for flair
    final isComedy = index % 2 == 0;
    final color = isComedy ? const Color(0xFFFDE047) : const Color(0xFF7DD3FC);
    final shadowColor = isComedy
        ? const Color(0xFFCA8A04)
        : const Color(0xFF0284C7);

    final maskWidget = Container(
      height: 85.h,
      width: 80.w,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
          bottomLeft: Radius.circular(40.r),
          bottomRight: Radius.circular(40.r),
        ), // Mask shape
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: shadowColor, offset: const Offset(0, 6))],
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
                color: const Color(0xFF1E293B),
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
          child: Opacity(opacity: 0.9, child: maskWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: maskWidget),
      child: maskWidget,
    );
  }
}
