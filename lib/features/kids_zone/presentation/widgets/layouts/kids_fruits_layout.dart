import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// Farmer's Market Theme for Fruits Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFruitsLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFruitsLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'fruits',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Fruit Stand Awning
            Expanded(
              flex: 5,
              child: Center(child: _buildAwningFrame(context, state, quest)),
            ),
            SizedBox(height: 24.h),
            Text(
              context.tr(
                'games.kids_fruits_drag',
                fallback: 'Drag the fruit to the stand! ✨',
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
            // Wicker Baskets for Options
            Flexible(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(quest.options?.length ?? 0, (index) {
                    final option = quest.options![index];
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6.w),
                        child: _buildBasketOption(
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

  Widget _buildAwningFrame(
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
        return Stack(
          alignment: Alignment.center,
          children: [
            // Main wooden board
            Container(
              width: 280.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: isHovering
                    ? const Color(0xFFFEF9C3)
                    : const Color(0xFFFEF3C7), // Light wood
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isHovering
                      ? const Color(0xFFB45309)
                      : const Color(0xFF92400E),
                  width: isHovering ? 8.r : 6.r,
                ), // Dark wood frame
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isHovering ? 0.3 : 0.15,
                    ),
                    blurRadius: isHovering ? 20 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AutoSizeText(
                        quest.instruction ??
                            "?", // Use instruction, hide emoji/question to prevent cheat
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF78350F),
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
            // Red and White striped awning on top
            Positioned(
              top: -15.h,
              child: Container(
                width: 280.w,
                height: 40.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.r),
                  child: Row(
                    children: List.generate(
                      8,
                      (index) => Expanded(
                        child: Container(
                          color: index % 2 == 0
                              ? Colors.red[600]
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBasketOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final basketColor = const Color(0xFFD97706); // Wicker yellow/brown

    final basketWidget = Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // The label sticking out
        Positioned(
          top: -20.h,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4.r),
              border: Border.all(color: const Color(0xFF92400E), width: 1),
            ),
            child: AutoSizeText(
              text,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF451A03),
              ),
              maxLines: 1,
              minFontSize: 8,
            ),
          ),
        ),
        // The basket
        Container(
          height: 80.h,
          width: 80.w,
          decoration: BoxDecoration(
            color: basketColor,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20.r),
              bottomRight: Radius.circular(20.r),
            ),
            border: Border.all(color: const Color(0xFF78350F), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                offset: Offset(0, 4.h),
              ),
            ],
          ),
          child: CustomPaint(painter: _WickerPainter()),
        ),
      ],
    );

    return Draggable<String>(
      data: text,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(opacity: 0.9, child: basketWidget),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: basketWidget),
      child: basketWidget,
    );
  }
}

class _WickerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (double y = 10; y < size.height; y += 15) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 10; x < size.width; x += 15) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
