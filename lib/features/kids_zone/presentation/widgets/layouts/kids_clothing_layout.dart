import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

/// Fashion Wardrobe Theme for Clothing Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsClothingLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsClothingLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'clothing',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Open Closet
            Expanded(
              flex: 5,
              child: Center(child: _buildClosetBoard(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            KidsFittedText(
              context.tr(
                'games.kids_clothing_drag',
                fallback: 'Drag the clothing tag to the closet! ✨',
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
            // The Clothing Hangers (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // The metal closet rod
                  Positioned(
                    top: 15.h,
                    left: 16.w,
                    right: 16.w,
                    child: Container(
                      height: 8.h,
                      decoration: BoxDecoration(
                        color: const Color(0xFF94A3B8), // Silver rod
                        borderRadius: BorderRadius.circular(4.r),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          ),
                        ],
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
                            child: _buildHangerOption(
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

  Widget _buildClosetBoard(
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
                ? const Color(0xFFFDE68A)
                : const Color(0xFFFEF3C7), // Light wood inside closet
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHovering
                  ? const Color(0xFFD97706)
                  : const Color(0xFFB45309),
              width: 12.r,
            ), // Dark wood frame
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHovering ? 0.4 : 0.2),
                blurRadius: isHovering ? 25 : 15,
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
                  ), // Enlarge emoji, hidden question string
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHangerOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
    int index,
  ) {
    final colors = [
      const Color(0xFFFCA5A5), // Light Red
      const Color(0xFF93C5FD), // Light Blue
      const Color(0xFF6EE7B7), // Mint
      const Color(0xFFC4B5FD), // Light Purple
    ];
    final tagColor = colors[index % colors.length];

    final hangerWidget = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Metal Hanger Hook
        Container(
          width: 20.w,
          height: 15.h,
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: const Color(0xFF94A3B8), width: 3.r),
              left: BorderSide(color: const Color(0xFF94A3B8), width: 3.r),
              right: BorderSide(color: const Color(0xFF94A3B8), width: 3.r),
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(10.r)),
          ),
        ),
        // Wooden Hanger Base
        Container(
          height: 10.h,
          width: 80.w,
          decoration: BoxDecoration(
            color: const Color(0xFFD97706),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
        // Clothing Tag hanging from it
        Container(
          height: 60.h,
          margin: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: tagColor,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
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
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: hangerWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: hangerWidget),
      child: hangerWidget,
    );
  }
}
