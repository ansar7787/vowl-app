import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/shakeable_wrapper.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_grid_builder.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_grid_trace_detector.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_grid_trace_painter.dart';

/// Responsive 5x5 (or 6x5) connected word-search grid supporting continuous
/// drag-tracing, mid-drag backtracking undo, and accessible one-tap tracing.
class SynonymWordGridBoard extends StatelessWidget {
  final SynonymGridModel grid;
  final List<int> activePath;
  final bool isHintActive;
  final int shakeCount;
  final bool showSuccessFlash;
  final String? subtleStatusMessage;
  final Color primaryColor;
  final ValueChanged<int> onStartDrag;
  final ValueChanged<int> onExtendDrag;
  final VoidCallback onEndDrag;
  final ValueChanged<int> onTapCell;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const SynonymWordGridBoard({
    super.key,
    required this.grid,
    required this.activePath,
    required this.isHintActive,
    required this.shakeCount,
    required this.showSuccessFlash,
    required this.subtleStatusMessage,
    required this.primaryColor,
    required this.onStartDrag,
    required this.onExtendDrag,
    required this.onEndDrag,
    required this.onTapCell,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hintSpotlightIndices = isHintActive
        ? grid.targetPathIndices.take(2).toSet()
        : const <int>{};
    final activeSet = activePath.toSet();
    final spelled = grid.spellPath(activePath);

    return ShakeableWrapper(
      shakeCount: shakeCount,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subtleStatusMessage ??
                      (spelled.isNotEmpty
                          ? 'Tracing: $spelled'
                          : 'Drag or tap adjacent letters'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: subtleStatusMessage != null
                        ? (isDark ? AppColors.amber400 : AppColors.amber600)
                        : (spelled.isNotEmpty
                              ? (isDark ? AppColors.slate50 : primaryColor)
                              : (isDark
                                    ? AppColors.slate300
                                    : AppColors.slate600)),
                  ),
                ),
              ),
              SynonymGridControlPill(
                key: const Key('grid_undo_btn'),
                label: 'Undo',
                icon: Icons.backspace_outlined,
                enabled: activePath.isNotEmpty,
                isDark: isDark,
                onTap: onBackspace,
              ),
              SizedBox(width: 6.w),
              SynonymGridControlPill(
                key: const Key('grid_clear_btn'),
                label: 'Clear',
                icon: Icons.refresh_rounded,
                enabled: activePath.isNotEmpty,
                isDark: isDark,
                onTap: onClear,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          LayoutBuilder(
            builder: (context, constraints) {
              const double cardPad = 6.0;
              const double spacing = 5.0;
              final double availWidth = math.max(
                180.0,
                constraints.maxWidth - (cardPad * 2),
              );
              final double rawCellSize =
                  (availWidth - spacing * (grid.columns - 1)) / grid.columns;
              final double minCell = grid.columns <= 5 ? 48.0 : 42.0;
              final double cellSize = rawCellSize.clamp(minCell, 60.0);
              final double gridWidth =
                  cellSize * grid.columns + spacing * (grid.columns - 1);
              final double gridHeight =
                  cellSize * grid.rows + spacing * (grid.rows - 1);

              return Center(
                child: AnimatedContainer(
                  duration: VowlMotion.shouldReduceMotion(context)
                      ? Duration.zero
                      : VowlMotion.fast,
                  padding: const EdgeInsets.all(cardPad),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate900.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: showSuccessFlash
                          ? AppColors.emerald500
                          : (isDark ? AppColors.slate700 : AppColors.slate200),
                      width: showSuccessFlash ? 2.2 : 1.4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color:
                            (showSuccessFlash
                                    ? AppColors.emerald500
                                    : primaryColor)
                                .withValues(alpha: isDark ? 0.22 : 0.10),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SynonymGridTraceDetector(
                    onTapAt: (pos) {
                      final idx = _hitTestCell(
                        localPos: pos,
                        cellSize: cellSize,
                        spacing: spacing,
                        isDrag: false,
                      );
                      if (idx != null) onTapCell(idx);
                    },
                    onDragStartAt: (pos) {
                      final idx = _hitTestCell(
                        localPos: pos,
                        cellSize: cellSize,
                        spacing: spacing,
                        isDrag: false,
                      );
                      if (idx != null) onStartDrag(idx);
                    },
                    onDragUpdateAt: (pos) {
                      final idx = _hitTestCell(
                        localPos: pos,
                        cellSize: cellSize,
                        spacing: spacing,
                        isDrag: true,
                      );
                      if (idx != null) onExtendDrag(idx);
                    },
                    onDragEnd: onEndDrag,
                    child: SizedBox(
                      key: const Key('synonym_word_grid'),
                      width: gridWidth,
                      height: gridHeight,
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: CustomPaint(
                                painter: SynonymGridTracePainter(
                                  activePath: activePath,
                                  columns: grid.columns,
                                  cellSize: cellSize,
                                  spacing: spacing,
                                  traceColor: primaryColor,
                                  isSuccessFlash: showSuccessFlash,
                                ),
                              ),
                            ),
                          ),
                          for (int i = 0; i < grid.totalCells; i++)
                            _buildPositionedCell(
                              context: context,
                              index: i,
                              cellSize: cellSize,
                              spacing: spacing,
                              pathStep: activePath.indexOf(i),
                              isHead:
                                  activePath.isNotEmpty && activePath.last == i,
                              isAdjacentCandidate:
                                  activePath.isNotEmpty &&
                                  !activeSet.contains(i) &&
                                  grid.isAdjacent(activePath.last, i),
                              isHinted: hintSpotlightIndices.contains(i),
                              isDark: isDark,
                            ),
                          if (activePath.length >= 2)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: RepaintBoundary(
                                  child: CustomPaint(
                                    painter: SynonymGridTracePainter(
                                      activePath: activePath,
                                      columns: grid.columns,
                                      cellSize: cellSize,
                                      spacing: spacing,
                                      traceColor: primaryColor,
                                      isSuccessFlash: showSuccessFlash,
                                      isForegroundOverlay: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  int? _hitTestCell({
    required Offset localPos,
    required double cellSize,
    required double spacing,
    required bool isDrag,
  }) {
    final step = cellSize + spacing;
    if (localPos.dx < 0 || localPos.dy < 0) return null;

    final col = (localPos.dx / step).floor();
    final row = (localPos.dy / step).floor();
    if (col < 0 || col >= grid.columns || row < 0 || row >= grid.rows) {
      return null;
    }

    final dx = localPos.dx - col * step;
    final dy = localPos.dy - row * step;
    if (dx > cellSize || dy > cellSize) return null;

    if (isDrag) {
      final center = Offset(cellSize / 2, cellSize / 2);
      if ((Offset(dx, dy) - center).distance > cellSize * 0.48) {
        return null;
      }
    }
    return row * grid.columns + col;
  }

  Widget _buildPositionedCell({
    required BuildContext context,
    required int index,
    required double cellSize,
    required double spacing,
    required int pathStep,
    required bool isHead,
    required bool isAdjacentCandidate,
    required bool isHinted,
    required bool isDark,
  }) {
    final row = index ~/ grid.columns;
    final col = index % grid.columns;
    final step = cellSize + spacing;
    final isSelected = pathStep != -1;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    final Color bgColor;
    final Color borderColor;
    final Color letterColor;

    if (showSuccessFlash && isSelected) {
      bgColor = AppColors.emerald500;
      borderColor = AppColors.emerald400;
      letterColor = Colors.white;
    } else if (isSelected) {
      bgColor = primaryColor.withValues(alpha: isHead ? 0.96 : 0.80);
      borderColor = isHead ? Colors.white : primaryColor;
      letterColor = Colors.white;
    } else if (isHinted) {
      bgColor = AppColors.amber500.withValues(alpha: isDark ? 0.28 : 0.18);
      borderColor = AppColors.amber500;
      letterColor = isDark ? AppColors.amber200 : AppColors.amber900;
    } else if (isAdjacentCandidate) {
      bgColor = primaryColor.withValues(alpha: isDark ? 0.14 : 0.08);
      borderColor = primaryColor.withValues(alpha: 0.45);
      letterColor = isDark ? AppColors.slate50 : AppColors.slate900;
    } else {
      bgColor = isDark
          ? AppColors.slate800.withValues(alpha: 0.92)
          : AppColors.slate100;
      borderColor = isDark ? AppColors.slate700 : AppColors.slate200;
      letterColor = isDark ? AppColors.slate50 : AppColors.slate900;
    }

    return Positioned(
      left: col * step,
      top: row * step,
      width: cellSize,
      height: cellSize,
      child: Semantics(
        button: true,
        selected: isSelected,
        label:
            'Letter ${grid.letters[index]}, row ${row + 1} column ${col + 1}',
        child: AnimatedScale(
          scale: (!reduceMotion && isHead) ? 1.05 : 1.0,
          duration: reduceMotion ? Duration.zero : VowlMotion.fast,
          child: Container(
            key: Key('grid_cell_$index'),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: borderColor,
                width: (isSelected || isHinted)
                    ? 2.0
                    : (isAdjacentCandidate ? 1.4 : 1.0),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withValues(
                          alpha: isHead ? 0.36 : 0.22,
                        ),
                        blurRadius: isHead ? 9 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  grid.letters[index],
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: (cellSize * 0.42).clamp(16.0, 22.0),
                    fontWeight: FontWeight.w900,
                    color: letterColor,
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 3,
                    right: 4,
                    child: Text(
                      '${pathStep + 1}',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 9.sp,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withValues(alpha: 0.90),
                      ),
                    ),
                  )
                else if (isHinted)
                  Positioned(
                    top: 3,
                    right: 4,
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      size: 10.sp,
                      color: AppColors.amber500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
