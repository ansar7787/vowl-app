import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_painter.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color color07070f = Color(0xFF07070F);
}

/// Interactive starry constellation board for chaining words into conversation sparks.
class SocialSparkGalaxyBoard extends StatelessWidget {
  /// Available words or phrases placed as stars in the galaxy.
  final List<String> words;

  /// Primary theme accent color.
  final Color color;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Ordered indices of currently linked stars.
  final List<int> selectedIndices;

  /// Whether an answer has been submitted for this stage.
  final bool isAnswered;

  /// Whether the submitted sequence was evaluated as correct.
  final bool? isCorrect;

  /// Pulse animation value for twinkling stars.
  final double pulseValue;

  /// Callback fired when a star node is tapped.
  final Function(int) onStarTap;

  /// Creates a [SocialSparkGalaxyBoard] widget.
  const SocialSparkGalaxyBoard({
    super.key,
    required this.words,
    required this.color,
    required this.isDark,
    required this.selectedIndices,
    required this.isAnswered,
    required this.isCorrect,
    required this.pulseValue,
    required this.onStarTap,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        final int cols = width > 520 ? 4 : (width > 340 ? 3 : 2);
        final double hMargin = 12.w;
        final double availableWidth = width - (hMargin * 2);
        final double hSpacing = 10.w;
        final double nodeWidth =
            ((availableWidth - ((cols - 1) * hSpacing)) / cols)
                .floorToDouble()
                .clamp(80.w, 140.w);
        final double nodeHeight = 56.h;
        final double vSpacing = 14.h;

        final int rows = words.isEmpty ? 0 : (words.length / cols).ceil();
        final double topPadding = 18.h;
        final double calculatedHeight =
            (topPadding * 2) +
            (rows * nodeHeight) +
            (math.max(0, rows - 1) * vSpacing);
        final double containerHeight = math.max(180.h, calculatedHeight);

        // Responsive centered layout with guaranteed bounds
        final List<Offset> starOffsets = [];

        for (int i = 0; i < words.length; i++) {
          int row = i ~/ cols;
          int col = i % cols;

          int itemsInThisRow = math.min(cols, words.length - row * cols);
          double rowWidth =
              (itemsInThisRow * nodeWidth) + ((itemsInThisRow - 1) * hSpacing);
          double startX = (width - rowWidth) / 2;

          double cx = startX + (col * (nodeWidth + hSpacing)) + (nodeWidth / 2);
          double cy =
              topPadding +
              (row * (nodeHeight + vSpacing)) +
              (nodeHeight / 2);

          starOffsets.add(Offset(cx, cy));
        }

        return Container(
          key: const Key('social_spark_galaxy_board'),
          width: width,
          height: containerHeight,
          decoration: BoxDecoration(
            color: isDark
                ? _LocalPalette.color07070f
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.05),
              width: 1.0,
            ),
          ),
          child: Stack(
            children: [
              // Radial soft glow
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        color.withValues(alpha: 0.05),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Interactive connector paths
              Positioned.fill(
                child: CustomPaint(
                  painter: ConstellationPainter(
                    selectedIndices: selectedIndices,
                    starOffsets: starOffsets,
                    themeColor: color,
                    isAnswered: isAnswered,
                    isCorrect: isCorrect,
                    pulseValue: pulseValue,
                  ),
                ),
              ),

              // Responsive verbal word nodes
              ...List.generate(words.length, (i) {
                final Offset pos = starOffsets[i];
                return _buildStarNode(
                  i,
                  words[i],
                  pos,
                  nodeWidth,
                  nodeHeight,
                  color,
                  isDark,
                  reduceMotion,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarNode(
    int index,
    String text,
    Offset pos,
    double nodeWidth,
    double nodeHeight,
    Color color,
    bool isDark,
    bool reduceMotion,
  ) {
    final bool isSelected = selectedIndices.contains(index);
    final int selectOrderIndex = selectedIndices.indexOf(index) + 1;

    Color nodeColor = color;
    if (isAnswered && isSelected) {
      nodeColor = (isCorrect ?? false)
          ? AppColors.gameCorrect
          : AppColors.gameIncorrect;
    }

    final nodeWidget = Semantics(
      button: true,
      label:
          'Word $text, ${isSelected ? "selected order $selectOrderIndex" : "unselected"}',
      child: ScaleButton(
        key: Key('social_spark_star_$index'),
        onTap: () => onStarTap(index),
        child: Container(
          width: nodeWidth,
          height: nodeHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            color: isSelected
                ? nodeColor
                : (isDark ? AppColors.deepDark : Colors.white),
            border: Border.all(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.9)
                  : color.withValues(alpha: 0.3),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? nodeColor : color).withValues(
                  alpha: isSelected ? 0.35 : 0.08,
                ),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Clean connection order badge
              if (isSelected)
                Positioned(
                  top: 5.h,
                  left: 7.w,
                  child: Container(
                    width: 18.r,
                    height: 18.r,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      "$selectOrderIndex",
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),

              // Sparkle indicator
              Positioned(
                right: 7.w,
                top: 5.h,
                child: Icon(
                  Icons.star_rounded,
                  size: 12.r,
                  color: isSelected
                      ? Colors.white
                      : color.withValues(alpha: 0.3),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 4.h,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : AppColors.slate900),
                        height: 1.2,
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

    return Positioned(
      left: pos.dx - (nodeWidth / 2),
      top: pos.dy - (nodeHeight / 2),
      width: nodeWidth,
      height: nodeHeight,
      child: reduceMotion
          ? nodeWidget
          : nodeWidget
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.02, 1.02),
                duration: (2.0 + (index % 3) * 0.4).seconds,
                curve: Curves.easeInOut,
              ),
    );
  }
}
