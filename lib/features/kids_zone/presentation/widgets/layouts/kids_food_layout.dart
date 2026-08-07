import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Chef's Kitchen Theme for Food Game
/// Space Complexity: O(1)
/// Time Complexity: O(N) where N is the number of options (max 4)
class KidsFoodLayout extends StatelessWidget {
  final int level;
  final String title;
  final Color primaryColor;

  const KidsFoodLayout({
    super.key,
    required this.level,
    required this.title,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return KidsGameBaseScreen(
      title: title,
      gameType: 'food',
      level: level,
      primaryColor: primaryColor,
      backgroundColors: const [],
      buildGameUI: (context, state, onHintTap) {
        final quest = state.currentQuest;

        return Column(
          children: [
            SizedBox(height: 120.h),
            // The Chef's Hat / Board
            Expanded(flex: 5, child: Center(child: _buildKitchenBoard(context, state, quest))),
            // Serving Platters (Options)
            Flexible(
              flex: 5,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Checkered Tablecloth
                  Container(
                    height: 40.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(8.r),
                      ),
                    ),
                    child: CustomPaint(painter: _CheckeredPainter()),
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
                            child: _buildServingPlatterOption(
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

  Widget _buildKitchenBoard(BuildContext context, KidsLoaded state, dynamic quest) {
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
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            // The White Kitchen Tile Board
            Container(
              width: 280.w,
              height: 200.h,
              decoration: BoxDecoration(
                color: isHovering ? const Color(0xFFFEF2F2) : Colors.white, // Light red tint on hover
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isHovering ? const Color(0xFFE11D48) : const Color(0xFFD4D4D8),
                  width: isHovering ? 6.r : 4.r,
                ), // Light grey tile border
                boxShadow: [
                  BoxShadow(
                    color: isHovering 
                        ? const Color(0xFFE11D48).withValues(alpha: 0.3) 
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: isHovering ? 20 : 10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (quest.emoji != null)
                      Text(quest.emoji!, style: TextStyle(fontSize: 64.sp)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: AutoSizeText(
                        quest.instruction ?? "?", // Use instruction as clue, hide question
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFE11D48), // Tasty red text
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        minFontSize: 12,
                      ),
                    ),
                    if (quest.funFact != null) ...[
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: AutoSizeText(
                          quest.funFact!,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF71717A), // Gray fact text
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          minFontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // A cute chef hat resting on top
            Positioned(
              top: -30.h,
              child: Container(
                width: 80.w,
                height: 40.h,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
                  border: Border.all(color: const Color(0xFFE4E4E7), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 2.w,
                      height: 20.h,
                      color: const Color(0xFFE4E4E7),
                    ),
                    Container(
                      width: 2.w,
                      height: 25.h,
                      color: const Color(0xFFE4E4E7),
                    ),
                    Container(
                      width: 2.w,
                      height: 20.h,
                      color: const Color(0xFFE4E4E7),
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

  Widget _buildServingPlatterOption(
    BuildContext context,
    KidsLoaded state,
    String text,
    bool isCorrect,
  ) {
    final platterWidget = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // The Cloche (Silver Dome)
          Container(
            height: 50.h,
            decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0), // Silver
              borderRadius: BorderRadius.vertical(top: Radius.circular(40.r)),
              border: Border.all(color: const Color(0xFF94A3B8), width: 2),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFCBD5E1)],
              ),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: EdgeInsets.only(top: 4.h),
                width: 15.w,
                height: 8.h,
                decoration: BoxDecoration(
                  color: const Color(0xFF94A3B8), // Dome handle
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
            ),
          ),
          // The Platter Base
          Container(
            height: 35.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9), // Light silver plate
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(16.r),
              ),
              border: Border.all(color: const Color(0xFF94A3B8), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                child: AutoSizeText(
                  text,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  minFontSize: 8,
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
          child: Opacity(
            opacity: 0.9,
            child: platterWidget,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: platterWidget,
      ),
      child: platterWidget,
    );
  }
}

class _CheckeredPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final squareSize = 20.0;

    for (double y = 0; y < size.height; y += squareSize) {
      for (double x = 0; x < size.width; x += squareSize) {
        if (((x / squareSize).floor() + (y / squareSize).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, squareSize, squareSize), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
