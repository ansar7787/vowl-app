import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

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
            SizedBox(height: 80.h),
            // The Fruit Stand Awning
            Expanded(
              flex: 5,
              child: Center(child: _buildAwningFrame(context, state, quest)),
            ),
            SizedBox(height: 32.h),
            KidsFittedText(
              context.tr(
                'games.kids_fruits_drag',
                fallback: 'Drag the correct fruit to the stand! 🧺',
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
            SizedBox(height: 32.h),
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
        if (!isCorrect) {
          di.sl<KidsTTSService>().speak(text);
        }
        context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return InkWell(
          onTap: state.answerStatus.isAnswered
              ? null
              : () {
                  if (InstructionHelper.getInstruction(quest).isNotEmpty) {
                    di.sl<KidsTTSService>().speak(InstructionHelper.getInstruction(quest));
                  }
                },
          child: Stack(
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
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (quest.emoji != null &&
                                (quest.question == "?" ||
                                    quest.question == null))
                              state.answerStatus == AnswerStatus.correct
                                  ? Text(
                                      quest.emoji!,
                                      style: TextStyle(fontSize: 100.sp),
                                    )
                                  : ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color(
                                          0xFF78350F,
                                        ).withValues(alpha: 0.15),
                                        BlendMode.srcIn,
                                      ),
                                      child: Text(
                                        quest.emoji!,
                                        style: TextStyle(fontSize: 100.sp),
                                      ),
                                    ),
                            if (state.answerStatus != AnswerStatus.correct ||
                                (quest.question != "?" &&
                                    quest.question != null))
                              KidsFittedText(
                                quest.question ?? "?",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize:
                                      (quest.question == "?" ||
                                          quest.question == null)
                                      ? 70.sp
                                      : 24.sp,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF78350F).withValues(
                                    alpha:
                                        (quest.question == "?" ||
                                            quest.question == null)
                                        ? 0.7
                                        : 1.0,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 6,
                              ),
                          ],
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
          ),
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
          top: -24.h,
          child: Container(
            constraints: BoxConstraints(
              minWidth: 60.w,
              maxWidth: 90.w,
              minHeight: 34.h,
            ),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6.r),
              border: Border.all(color: const Color(0xFF92400E), width: 1.5),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                text.trim(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w800,
                  height:
                      1.2, // Fixes descenders like p, g from touching bottom
                  color: const Color(0xFF451A03),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
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
