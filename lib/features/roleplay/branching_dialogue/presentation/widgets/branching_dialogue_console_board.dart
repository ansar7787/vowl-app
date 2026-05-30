import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_path_painter.dart';

class BranchingDialogueConsoleBoard extends StatelessWidget {
  final List<String> options;
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

  const BranchingDialogueConsoleBoard({
    super.key,
    required this.options,
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
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw,
      height: 400.h,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF07070F) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double width = constraints.maxWidth;
          final double height = constraints.maxHeight;

          // Bottom launcher dock center
          final Offset launchCenter = Offset(width / 2, height - 70.h);

          // Calculate horizontal positioning of 3 terminal nodes evenly spaced along a curved arc
          final double leftPadding = 45.w;
          final List<Offset> terminalCenters = List.generate(options.length, (i) {
            double x = leftPadding + i * (width - 2 * leftPadding) / (options.length - 1);
            
            // Dip in vertical height at centers to create a beautiful sweeping arc curve
            double arcOffset = 25.h * math.sin((i / (options.length - 1)) * math.pi);
            double y = 80.h - arcOffset;
            return Offset(x, y);
          });

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Custom paint grid connector lanes
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
                return _buildPathTerminalNode(i, options[i], termPos);
              }),

              // Launch pad base
              Positioned(
                left: launchCenter.dx - 45.r,
                top: launchCenter.dy - 45.r,
                child: Container(
                  width: 90.r,
                  height: 90.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
                    color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.01),
                  ),
                ),
              ),

              // Interactive Decision Probe
              if (!isAnswered)
                Positioned(
                  left: launchCenter.dx + probeOffset.dx - 36.r,
                  top: launchCenter.dy + probeOffset.dy - 36.r,
                  child: GestureDetector(
                    onPanStart: onProbeDragStart,
                    onPanUpdate: (details) => onProbeDragUpdate(details, launchCenter, terminalCenters),
                    onPanEnd: (_) => onProbeDragEnd(correctIndex),
                    child: Container(
                      width: 72.r,
                      height: 72.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.white,
                        size: 32.r,
                      ),
                    ).animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    ).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 800.ms,
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
  ) {
    final bool isHovered = hoveredIndex == index;
    final bool isSelected = selectedIndex == index;
    final bool hideOther = isAnswered && !isSelected;

    Color termColor = color;
    if (isAnswered && isSelected) {
      termColor = (index == correctIndex) ? Colors.greenAccent : Colors.redAccent;
    }

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 250),
      left: position.dx - 48.w,
      top: position.dy - 60.h,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: hideOther ? 0.0 : 1.0,
        child: Column(
          children: [
            Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHovered ? color : (isDark ? const Color(0xFF0F0F1B) : Colors.white),
                border: Border.all(
                  color: isSelected ? termColor : color.withValues(alpha: 0.5),
                  width: isSelected || isHovered ? 3.0 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? termColor : color).withValues(alpha: isHovered || isSelected ? 0.35 : 0.1),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(
                isAnswered && isSelected
                    ? (index == correctIndex ? Icons.verified_rounded : Icons.cancel_outlined)
                    : Icons.alt_route_rounded,
                color: isHovered || (isAnswered && isSelected)
                    ? Colors.white
                    : color,
                size: 28.r,
              ),
            ),
            SizedBox(height: 8.h),
            SizedBox(
              width: 90.w,
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  color: isHovered
                      ? color
                      : (isDark ? Colors.white70 : Colors.black87),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
