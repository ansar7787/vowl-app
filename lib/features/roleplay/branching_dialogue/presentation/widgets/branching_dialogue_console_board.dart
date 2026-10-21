import 'package:vowl/core/theme/app_colors.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_path_painter.dart';

class BranchingDialogueConsoleBoard extends StatelessWidget {
  final List<String> options;
  final List<String> consequencePreviews;
  final int correctIndex;
  final Color color;
  final bool isDark;
  final Offset probeOffset;
  final int? hoveredIndex;
  final int? selectedIndex;
  final bool isAnswered;
  final Function(DragStartDetails) onProbeDragStart;
  final Function(DragUpdateDetails, Offset, List<Offset>) onProbeDragUpdate;
  final Function(int) onProbeDragEnd;
  final Function(int) onOptionTapped;

  const BranchingDialogueConsoleBoard({
    super.key,
    required this.options,
    this.consequencePreviews = const [],
    required this.correctIndex,
    required this.color,
    required this.isDark,
    required this.probeOffset,
    required this.hoveredIndex,
    required this.selectedIndex,
    required this.isAnswered,
    required this.onProbeDragStart,
    required this.onProbeDragUpdate,
    required this.onProbeDragEnd,
    required this.onOptionTapped,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.deepDark : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: color.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Bottom launcher dock center
          final Offset launchCenter = Offset(width / 2, height - 65.h);

          // Standard horizontal padding inside the board mechanism card so nodes never touch the borders
          final double horizontalPadding = 16.w;
          final double usableWidth =
              math.max(0.0, width - (2 * horizontalPadding));

          // Calculate horizontal positioning of terminal nodes evenly spaced with standard breathing padding
          final List<Offset> terminalCenters =
              List.generate(options.length, (i) {
                if (options.length <= 1) return Offset(width / 2, 75.h);

                final double colWidth = usableWidth / options.length;
                final double x =
                    horizontalPadding + (i * colWidth) + (colWidth / 2);

                // Gentle sweeping arc curve
                final double arcOffset =
                    18.h * math.sin((i / (options.length - 1)) * math.pi);
                final double y = 78.h - arcOffset;
                return Offset(x, y);
              });

          Widget probeWidget = Container(
            width: 60.r,
            height: 60.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.gps_fixed_rounded,
              color: Colors.white,
              size: 26.r,
            ),
          );

          if (!reduceMotion) {
            probeWidget = probeWidget
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.08, 1.08),
                  duration: 800.ms,
                );
          }

          final double colWidth = options.isNotEmpty
              ? usableWidth / options.length
              : usableWidth;
          final double nodeWidth = math.max(64.w, colWidth - 8.w);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Custom paint connector lanes
              Positioned.fill(
                child: CustomPaint(
                  painter: BranchingPathPainter(
                    probeOffset: probeOffset,
                    launchCenter: launchCenter,
                    terminalCenters: terminalCenters,
                    hoveredIndex: hoveredIndex,
                    themeColor: color,
                    isAnswered: isAnswered,
                    selectedIndex: selectedIndex,
                    correctIndex: correctIndex,
                  ),
                ),
              ),

              // Orbiting path nodes (Dialogue Terminal options)
              ...List.generate(options.length, (i) {
                final Offset termPos = terminalCenters[i];
                return _buildPathTerminalNode(
                  i,
                  options[i],
                  termPos,
                  nodeWidth,
                  reduceMotion,
                );
              }),

              // Launch pad base
              Positioned(
                left: launchCenter.dx - 38.r,
                top: launchCenter.dy - 38.r,
                child: Container(
                  width: 76.r,
                  height: 76.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    color: color.withValues(alpha: 0.04),
                  ),
                ),
              ),

              // Interactive Decision Probe
              if (!isAnswered)
                Positioned(
                  left: launchCenter.dx + probeOffset.dx - 30.r,
                  top: launchCenter.dy + probeOffset.dy - 30.r,
                  child: Semantics(
                    label: 'Decision probe. Drag to a reply path',
                    button: true,
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: const Key('branching_dialogue_probe'),
                      behavior: HitTestBehavior.opaque,
                      onPanStart: onProbeDragStart,
                      onPanUpdate: (details) => onProbeDragUpdate(
                        details,
                        launchCenter,
                        terminalCenters,
                      ),
                      onPanEnd: (_) => onProbeDragEnd(correctIndex),
                      child: probeWidget,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPathTerminalNode(
    int index,
    String text,
    Offset position,
    double nodeWidth,
    bool reduceMotion,
  ) {
    final bool isHovered = hoveredIndex == index;
    final bool isSelected = selectedIndex == index;
    final bool hideOther = isAnswered && !isSelected;

    Color termColor = color;
    if (isAnswered && isSelected) {
      termColor = (index == correctIndex)
          ? AppColors.gameCorrect
          : AppColors.gameIncorrect;
    }

    Widget? previewWidget;
    if (consequencePreviews.length > index && (isHovered || isSelected)) {
      Widget previewInner = Container(
        key: Key('branching_dialogue_consequence_preview_$index'),
        width: nodeWidth,
        padding: EdgeInsets.symmetric(
          horizontal: 6.w,
          vertical: 3.h,
        ),
        decoration: BoxDecoration(
          color: (isSelected && isAnswered)
              ? (index == correctIndex
                    ? AppColors.gameCorrect.withValues(alpha: 0.15)
                    : AppColors.gameIncorrect.withValues(alpha: 0.15))
              : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: (isSelected && isAnswered)
                ? (index == correctIndex
                      ? AppColors.gameCorrect.withValues(alpha: 0.3)
                      : AppColors.gameIncorrect.withValues(alpha: 0.3))
                : color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          consequencePreviews[index],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 10.sp,
            fontWeight: FontWeight.w600,
            color: (isSelected && isAnswered)
                ? (index == correctIndex
                      ? AppColors.gameCorrect
                      : AppColors.gameIncorrect)
                : color,
            height: 1.2,
          ),
        ),
      );
      if (!reduceMotion) {
        previewInner = previewInner.animate().fadeIn(duration: 200.ms);
      }
      previewWidget = Padding(
        padding: EdgeInsets.only(top: 6.h),
        child: previewInner,
      );
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      left: position.dx - (nodeWidth / 2),
      top: position.dy - 55.h,
      child: Semantics(
        label: 'Option ${index + 1}: $text',
        button: true,
        excludeSemantics: true,
        child: GestureDetector(
          key: Key('branching_dialogue_option_$index'),
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!isAnswered) {
              onOptionTapped(index);
            }
          },
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: hideOther ? 0.0 : 1.0,
            child: SizedBox(
              width: nodeWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62.r,
                    height: 62.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHovered
                          ? color
                          : (isDark ? AppColors.deepDark : Colors.white),
                      border: Border.all(
                        color: isSelected
                            ? termColor
                            : color.withValues(alpha: 0.5),
                        width: isSelected || isHovered ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isSelected ? termColor : color).withValues(
                            alpha: isHovered || isSelected ? 0.3 : 0.08,
                          ),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      isAnswered && isSelected
                          ? (index == correctIndex
                                ? Icons.verified_rounded
                                : Icons.cancel_outlined)
                          : Icons.alt_route_rounded,
                      color: isHovered || (isAnswered && isSelected)
                          ? Colors.white
                          : color,
                      size: 26.r,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    text,
                    key: Key('branching_dialogue_option_text_$index'),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: isHovered
                          ? color
                          : (isDark
                                ? Colors.white.withValues(alpha: 0.88)
                                : Colors.black87),
                      height: 1.3,
                    ),
                  ),
                  ?previewWidget,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
