import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/kids_zone/theme/kids_colors.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_game_base_screen.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/kids_fitted_text.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colorfef9c3 = Color(0xFFFEF9C3);
  static const Color colorfef3c7 = Color(0xFFFEF3C7);
  static const Color color92400e = Color(0xFF92400E);
  static const Color color451a03 = Color(0xFF451A03);
}

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
            SizedBox(height: KidsGameBaseScreen.mascotClearanceHeight),
            // The Fruit Stand Awning
            Expanded(
              flex: 7,
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double boardHeight = (constraints.maxHeight * 0.9).clamp(120.0, 240.0);
                    return _buildAwningFrame(context, state, quest, boardHeight);
                  },
                ),
              ),
            ),
            SizedBox(height: 4.h),
            KidsFittedText(
              context.tr(
                'games.kids_fruits_drag',
                fallback: 'Tap or drag the correct fruit.',
              ),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.7),
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
            SizedBox(height: 8.h),
          ],
        );
      },
    );
  }

  Widget _buildAwningFrame(
    BuildContext context,
    KidsLoaded state,
    dynamic quest,
    double boardHeight,
  ) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => !state.answerStatus.isAnswered,
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
                    di.sl<KidsTTSService>().speak(
                      InstructionHelper.getInstruction(quest),
                    );
                  }
                },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Main wooden board
              Container(
                width: 280.w,
                height: boardHeight,
                decoration: BoxDecoration(
                  color: isHovering
                      ? _LocalPalette.colorfef9c3
                      : _LocalPalette.colorfef3c7, // Light wood
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isHovering
                        ? KidsColors.warmAmber
                        : _LocalPalette.color92400e,
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
                                      style: TextStyle(fontSize: 80.sp),
                                    ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack)
                                  : ColorFiltered(
                                      colorFilter: ColorFilter.mode(
                                        const Color(
                                          0xFF78350F,
                                        ).withValues(alpha: 0.15),
                                        BlendMode.srcIn,
                                      ),
                                      child: Text(
                                        quest.emoji!,
                                        style: TextStyle(fontSize: 80.sp),
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
                                          ? 60.sp
                                          : 22.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amber900.withValues(
                                    alpha:
                                        (quest.question == "?" ||
                                                quest.question == null)
                                            ? 0.7
                                            : 1.0,
                                  ),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final basketColor = AppColors.amber600; // Wicker yellow/brown
        final bool isAnswered = state.answerStatus.isAnswered;
        final double opacity = (isAnswered && !isCorrect) ? 0.4 : 1.0;
        final double basketWidth = constraints.maxWidth;

        Widget basketWidget = Stack(
          alignment: Alignment.bottomCenter,
          clipBehavior: Clip.none,
          children: [
            // The label sticking out
            Positioned(
              top: -24.h,
              left: 0,
              right: 0,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 36.h,
                ),
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: _LocalPalette.color92400e, width: 1.5),
                ),
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 2.h), // Micro-adjustment for font baseline
                    child: Text(
                      text.trim(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: _LocalPalette.color451a03,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
            // The basket
            Container(
              height: 75.h,
              width: basketWidth,
              decoration: BoxDecoration(
                color: basketColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20.r),
                  bottomRight: Radius.circular(20.r),
                ),
                border: Border.all(
                  color: (isAnswered && isCorrect) ? Colors.green.shade600 : AppColors.amber900, 
                  width: (isAnswered && isCorrect) ? 4 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: Offset(0, 4.h),
                  ),
                ],
              ),
              child: const CustomPaint(painter: _WickerPainter()),
            ),
          ],
        );

        if (isAnswered && isCorrect) {
          basketWidget = basketWidget.animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.05, duration: 600.ms, curve: Curves.easeInOut);
        }

        basketWidget = Opacity(
          opacity: opacity,
          child: basketWidget,
        );

        return Semantics(
          label: 'Basket for $text',
          button: true,
          enabled: !isAnswered,
          child: GestureDetector(
            onTap: isAnswered
                ? null
                : () {
                    if (!isCorrect) {
                      di.sl<KidsTTSService>().speak(text);
                    }
                    context.read<KidsBloc>().add(SubmitKidsAnswer(isCorrect));
                  },
            child: Draggable<String>(
              data: text,
              maxSimultaneousDrags: isAnswered ? 0 : 1,
              onDragStarted: () => di.sl<KidsTTSService>().speak(text),
              feedback: Material(
                color: Colors.transparent,
                child: Transform.scale(
                  scale: 1.05,
                  child: Opacity(opacity: 0.9, child: basketWidget),
                ),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: basketWidget),
              child: basketWidget,
            ),
          ),
        );
      },
    );
  }
}

class _WickerPainter extends CustomPainter {
  const _WickerPainter();

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
