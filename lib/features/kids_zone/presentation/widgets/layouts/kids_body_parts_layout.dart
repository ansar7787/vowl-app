import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

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
              child: Center(child: _buildXRayBoard(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_body_parts_drag',
                fallback: 'Drag the band-aid to the x-ray! ✨',
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
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                      border: Border.all(
                        color: const Color(0xFFCBD5E1),
                        width: 2,
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

  Widget _buildXRayBoard(
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
        return InkWell(
          onTap: state.lastAnswerCorrect != null
              ? null
              : () {
                  if (quest.instruction != null) {
                    di.sl<KidsTTSService>().speak(quest.instruction!);
                  }
                },
          child: Container(
            width: 280.w,
            height: 200.h,
            decoration: BoxDecoration(
              color: isHovering
                  ? const Color(0xFF1E293B)
                  : const Color(0xFF0F172A), // Dark X-Ray background
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
              color: isHovering
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFFE2E8F0),
              width: 12.r,
            ), // Medical white frame
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(
                  alpha: isHovering ? 0.6 : 0.3,
                ), // Blue glowing backlight
                blurRadius: isHovering ? 30 : 20,
                spreadRadius: isHovering ? 10 : 5,
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
                  ), // Enlarge emoji, hidden question
              ],
            ),
          ),
        ));
      },
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

    final bandaidWidget = Container(
      height: 70.h,
      width: 80.w,
      decoration: BoxDecoration(
        color: bandaidColor,
        borderRadius: BorderRadius.circular(30.r), // Pill shape for bandaid
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
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
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
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
          child: Opacity(opacity: 0.9, child: bandaidWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: bandaidWidget),
      child: bandaidWidget,
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
