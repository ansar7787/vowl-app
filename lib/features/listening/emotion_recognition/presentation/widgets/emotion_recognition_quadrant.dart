import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class EmotionRecognitionQuadrant extends StatelessWidget {
  final List<String> options;
  final List<String> optionEmojis;
  final int correctAnswerIndex;
  final Color color;
  final bool isAnswered;
  final bool? isCorrectState;
  final int? selectedIndex;
  final ValueNotifier<Offset> coreOffset;
  final Function(Offset, BoxConstraints) onCoreMove;
  final Function(int) onSubmitAnswer;

  const EmotionRecognitionQuadrant({
    super.key,
    required this.options,
    required this.optionEmojis,
    required this.correctAnswerIndex,
    required this.color,
    required this.isAnswered,
    required this.isCorrectState,
    required this.selectedIndex,
    required this.coreOffset,
    required this.onCoreMove,
    required this.onSubmitAnswer,
  });

  String _formatOptionText(String raw) {
    if (raw.isEmpty) return raw;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return trimmed;
    return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>();
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ValueListenableBuilder<Offset>(
          valueListenable: coreOffset,
          builder: (context, offset, _) {
            final double xDist = 88.w;
            final double yDist = 95.h;

            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Subtle guide ring
                  CustomPaint(
                    size: Size(constraints.maxWidth, constraints.maxHeight),
                    painter: EmotionGuidePainter(color.withValues(alpha: 0.15)),
                  ),

                  // Option Cards (4 Quadrants)
                  ...List.generate(options.length, (index) {
                    final double x = (index % 2 == 0) ? -xDist : xDist;
                    final double y = (index < 2) ? -yDist : yDist;

                    return Transform.translate(
                      offset: Offset(x, y),
                      child: _buildOptionCard(
                        context: context,
                        index: index,
                        text: _formatOptionText(options[index]),
                        rawText: options[index],
                        emoji: index < optionEmojis.length
                            ? optionEmojis[index]
                            : '🎭',
                        correct: correctAnswerIndex,
                        color: color,
                        tokens: tokens,
                        reduceMotion: reduceMotion,
                        targetOffset: Offset(x, y),
                      ),
                    );
                  }),

                  // Central Draggable Emotion Selector
                  Transform.translate(
                    offset: offset,
                    child: Semantics(
                      label: 'Psychology Core',
                      button: true,
                      excludeSemantics: true,
                      child: GestureDetector(
                        key: const Key('emotion_recognition_core'),
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) =>
                            onCoreMove(details.delta, constraints),
                        onPanEnd: (_) {
                          int closestIndex = -1;
                          double closestDist = double.infinity;
                          for (int i = 0; i < options.length; i++) {
                            final double x = (i % 2 == 0) ? -xDist : xDist;
                            final double y = (i < 2) ? -yDist : yDist;
                            final double dist =
                                (coreOffset.value - Offset(x, y)).distance;
                            if (dist < 65.r && dist < closestDist) {
                              closestDist = dist;
                              closestIndex = i;
                            }
                          }
                          if (closestIndex != -1) {
                            onSubmitAnswer(closestIndex);
                            return;
                          }
                          coreOffset.value = Offset.zero;
                        },
                        child: Container(
                          width: 58.r,
                          height: 58.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.9),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.sentiment_satisfied_alt_rounded,
                            color: Colors.white,
                            size: 30.r,
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
      },
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required int index,
    required String text,
    required String rawText,
    required String emoji,
    required int correct,
    required Color color,
    required AppColorTokens? tokens,
    required bool reduceMotion,
    required Offset targetOffset,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = selectedIndex == index;
    final isCorrect = isAnswered && index == correct && isCorrectState == true;
    final isWrong = isAnswered && isSelected && isCorrectState == false;

    Color cardBgColor;
    Color borderColor;
    Color textColor;

    if (isCorrect) {
      final success = tokens?.gameCorrect ?? AppColors.gameCorrect;
      cardBgColor = success.withValues(alpha: isDark ? 0.22 : 0.12);
      borderColor = success;
      textColor = success;
    } else if (isWrong) {
      final failure = tokens?.gameIncorrect ?? AppColors.gameIncorrect;
      cardBgColor = failure.withValues(alpha: isDark ? 0.22 : 0.12);
      borderColor = failure;
      textColor = failure;
    } else if (isSelected) {
      cardBgColor = color.withValues(alpha: isDark ? 0.24 : 0.14);
      borderColor = color;
      textColor = color;
    } else {
      cardBgColor = isDark
          ? Theme.of(context).colorScheme.surface
          : Colors.white;
      borderColor = color.withValues(alpha: 0.2);
      textColor = Theme.of(context).colorScheme.onSurface;
    }

    return Semantics(
      label: rawText,
      button: true,
      excludeSemantics: true,
      child: GestureDetector(
        key: Key('emotion_recognition_reservoir_$index'),
        onTap: () {
          if (isAnswered) return;
          coreOffset.value = targetOffset;
          onSubmitAnswer(index);
        },
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : 250.ms,
          curve: Curves.easeOutCubic,
          width: 138.w,
          height: 76.h,
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: borderColor,
              width: (isCorrect || isWrong || isSelected) ? 2.2 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCorrect || isWrong || isSelected)
                    ? borderColor.withValues(alpha: 0.25)
                    : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                blurRadius: (isCorrect || isWrong || isSelected) ? 14 : 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              reduceMotion
                  ? Text(
                      emoji,
                      style: TextStyle(fontSize: 24.sp),
                    )
                  : Text(
                      emoji,
                      style: TextStyle(fontSize: 24.sp),
                    )
                      .animate(target: (isCorrect || isWrong) ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.15, 1.15),
                        curve: Curves.easeOutBack,
                      ),
              SizedBox(height: 4.h),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 120.w,
                    ),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14.sp,
                        fontWeight: (isCorrect || isWrong || isSelected)
                            ? FontWeight.w700
                            : FontWeight.w600,
                        color: textColor,
                        height: 1.25,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmotionGuidePainter extends CustomPainter {
  final Color color;
  EmotionGuidePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    // Subtle guide circle connecting quadrants
    canvas.drawCircle(Offset(centerX, centerY), 90.r, paint);
    canvas.drawCircle(
      Offset(centerX, centerY),
      40.r,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
