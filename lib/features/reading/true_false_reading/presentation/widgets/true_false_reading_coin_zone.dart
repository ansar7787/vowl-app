import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/pulsing_arrows.dart';

class TrueFalseReadingCoinZone extends StatefulWidget {
  final Function(bool) onAnswerSelected;
  final bool isDark;
  final bool isDisabled;
  final bool? pendingAnswer;
  final double horizontalPadding;

  const TrueFalseReadingCoinZone({
    super.key,
    required this.onAnswerSelected,
    required this.isDark,
    this.isDisabled = false,
    this.pendingAnswer,
    this.horizontalPadding = 0.0,
  });

  @override
  State<TrueFalseReadingCoinZone> createState() =>
      _TrueFalseReadingCoinZoneState();
}

class _TrueFalseReadingCoinZoneState extends State<TrueFalseReadingCoinZone> {
  final _hapticService = di.sl<HapticService>();
  double _coinX = 0.0;
  double _coinY = 0.0;
  double _coinRotation = 0.0;
  bool _isDragging = false;
  double _lastTargetOffset = 120.0;

  @override
  void didUpdateWidget(TrueFalseReadingCoinZone oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pendingAnswer != oldWidget.pendingAnswer) {
      if (widget.pendingAnswer == null) {
        setState(() {
          _coinX = 0.0;
          _coinY = 0.0;
          _coinRotation = 0.0;
        });
      } else {
        setState(() {
          _coinX = widget.pendingAnswer! ? _lastTargetOffset : -_lastTargetOffset;
          _coinY = 0.0;
        });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details, double targetOffset) {
    if (widget.isDisabled) return;
    setState(() {
      _isDragging = true;
      _coinX = (_coinX + details.delta.dx)
          .clamp(-targetOffset * 1.15, targetOffset * 1.15);
      _coinY = (_coinY + details.delta.dy).clamp(-24.h, 24.h);
      _coinRotation += (details.delta.dx + details.delta.dy) / 100;
    });
  }

  void _onPanEnd(DragEndDetails details, double targetOffset) {
    if (widget.isDisabled) return;
    setState(() {
      _isDragging = false;
    });

    final velocity = details.velocity.pixelsPerSecond.dx;
    final isFlickRight = velocity > 800;
    final isFlickLeft = velocity < -800;
    final threshold = (targetOffset * 0.45).clamp(40.w, 75.w);

    if (_coinX.abs() > threshold || isFlickRight || isFlickLeft) {
      final isTrue = isFlickRight
          ? true
          : isFlickLeft
          ? false
          : _coinX > 0;
      _hapticService.selection();
      setState(() {
        _coinX = isTrue ? targetOffset : -targetOffset;
        _coinY = 0.0;
      });
      widget.onAnswerSelected(isTrue);
    } else {
      // Spring back
      setState(() {
        _coinX = 0.0;
        _coinY = 0.0;
        _coinRotation = 0.0;
      });
    }
  }

  void _onSlotTap(bool isTrue, double targetOffset) {
    if (widget.isDisabled) return;
    _hapticService.selection();
    setState(() {
      _coinX = isTrue ? targetOffset : -targetOffset;
      _coinY = 0.0;
    });
    widget.onAnswerSelected(isTrue);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bool showHint =
        !_isDragging && _coinX == 0.0 && widget.pendingAnswer == null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final horizontalPadding = widget.horizontalPadding;
        final slotWidth = 70.w;
        final slotHeight = 110.h;
        final coinSize = 84.r;
        final zoneHeight = 175.h;

        final leftSlotCenter = horizontalPadding + (slotWidth / 2);
        final centerX = totalWidth / 2;
        final targetOffset = centerX - leftSlotCenter;
        _lastTargetOffset = targetOffset;

        if (widget.pendingAnswer != null &&
            !_isDragging &&
            _coinX.abs() < targetOffset * 0.5) {
          _coinX = widget.pendingAnswer! ? targetOffset : -targetOffset;
        }

        final coinLeft = (centerX - (coinSize / 2)) + _coinX;
        final coinTop = ((zoneHeight - 25.h - coinSize) / 2) + _coinY;
        final slotTop = (zoneHeight - 25.h - slotHeight) / 2;

        final leftSlotRightEdge = horizontalPadding + slotWidth;
        final coinLeftEdgeAtCenter = centerX - (coinSize / 2);
        final leftArrowX =
            (leftSlotRightEdge + coinLeftEdgeAtCenter) / 2 - 22.w;

        final coinRightEdgeAtCenter = centerX + (coinSize / 2);
        final rightSlotLeftEdge = totalWidth - horizontalPadding - slotWidth;
        final rightArrowX =
            (coinRightEdgeAtCenter + rightSlotLeftEdge) / 2 - 22.w;
        final arrowTop = (zoneHeight - 25.h - 22.r) / 2;

        return SizedBox(
          height: zoneHeight,
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // FALSE Slot (Left)
              Positioned(
                left: horizontalPadding,
                top: slotTop,
                child: _buildSlot(
                  label: "FALSE",
                  color: tokens.gameIncorrect,
                  isDark: widget.isDark,
                  width: slotWidth,
                  height: slotHeight,
                  targetOffset: targetOffset,
                ),
              ),

              // TRUE Slot (Right)
              Positioned(
                right: horizontalPadding,
                top: slotTop,
                child: _buildSlot(
                  label: "TRUE",
                  color: tokens.gameCorrect,
                  isDark: widget.isDark,
                  width: slotWidth,
                  height: slotHeight,
                  targetOffset: targetOffset,
                ),
              ),

              // Hint Arrows
              if (showHint)
                Positioned(
                  left: leftArrowX,
                  top: arrowTop,
                  child: PulsingArrows(
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                    isLeft: true,
                  ),
                ),
              if (showHint)
                Positioned(
                  left: rightArrowX,
                  top: arrowTop,
                  child: PulsingArrows(
                    color: widget.isDark ? Colors.white54 : Colors.black45,
                    isLeft: false,
                  ),
                ),

              // The Coin
              AnimatedPositioned(
                duration: _isDragging
                    ? Duration.zero
                    : const Duration(milliseconds: 350),
                curve: Curves.easeOutCubic,
                left: coinLeft,
                top: coinTop,
                child: Transform.rotate(
                  angle: _coinRotation,
                  child: GestureDetector(
                    onPanUpdate: (d) => _onPanUpdate(d, targetOffset),
                    onPanEnd: (d) => _onPanEnd(d, targetOffset),
                    onPanCancel: () {
                      if (widget.isDisabled) return;
                      setState(() {
                        _isDragging = false;
                        _coinX = 0.0;
                        _coinY = 0.0;
                        _coinRotation = 0.0;
                      });
                    },
                    child: Container(
                      key: const ValueKey('truth_coin'),
                      width: coinSize,
                      height: coinSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFDF00), Color(0xFFF09819)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isDark
                                ? Colors.black54
                                : Colors.black.withValues(alpha: 0.22),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.35),
                            blurRadius: 0,
                            spreadRadius: 2,
                            offset: const Offset(0, -2),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.95),
                          width: 3.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          _coinX > 30.w || widget.pendingAnswer == true
                              ? Icons.check_rounded
                              : _coinX < -30.w || widget.pendingAnswer == false
                              ? Icons.close_rounded
                              : Icons.swap_horiz_rounded,
                          color: Colors.white,
                          size: 42.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom guidance label
              Positioned(
                bottom: 0,
                child: AnimatedOpacity(
                  opacity: (widget.pendingAnswer == null && !widget.isDisabled)
                      ? 0.75
                      : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Swipe coin or tap True / False',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      color: widget.isDark
                          ? Colors.white70
                          : const Color(0xFF6B7280),
                      letterSpacing: 0.3,
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

  Widget _buildSlot({
    required String label,
    required Color color,
    required bool isDark,
    required double width,
    required double height,
    required double targetOffset,
  }) {
    final bool isTrue = label == "TRUE";
    final bool isTargeted =
        (_coinX > 20.w && isTrue) || (_coinX < -20.w && !isTrue);
    final bool isSelected =
        widget.pendingAnswer == isTrue ||
        (_coinX.abs() >= targetOffset * 0.85 &&
            ((_coinX > 0 && isTrue) || (_coinX < 0 && !isTrue)));

    return GestureDetector(
      key: ValueKey('slot_$label'),
      onTap: () => _onSlotTap(isTrue, targetOffset),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: color.withValues(
            alpha: isSelected
                ? (isDark ? 0.25 : 0.18)
                : isTargeted
                ? (isDark ? 0.20 : 0.14)
                : (isDark ? 0.10 : 0.06),
          ),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: isSelected || isTargeted
                ? color
                : color.withValues(alpha: isDark ? 0.4 : 0.25),
            width: isSelected || isTargeted ? 2.5 : 1.5,
          ),
          boxShadow: isSelected || isTargeted
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: isDark ? 0.3 : 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(
                  alpha: isSelected ? 0.25 : 0.12,
                ),
              ),
              child: Icon(
                isTrue ? Icons.check_rounded : Icons.close_rounded,
                color: color,
                size: 20.r,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
