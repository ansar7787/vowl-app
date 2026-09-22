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

  const TrueFalseReadingCoinZone({
    super.key,
    required this.onAnswerSelected,
    required this.isDark,
    this.isDisabled = false,
    this.pendingAnswer,
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
          _coinX = widget.pendingAnswer! ? 120.w : -120.w;
          _coinY = 0.0;
        });
      }
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isDisabled) return;
    setState(() {
      _isDragging = true;
      _coinX += details.delta.dx;
      _coinY += details.delta.dy;
      _coinRotation += (details.delta.dx + details.delta.dy) / 100;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isDisabled) return;
    setState(() {
      _isDragging = false;
    });

    final velocity = details.velocity.pixelsPerSecond.dx;
    final isFlickRight = velocity > 1000;
    final isFlickLeft = velocity < -1000;

    if (_coinX.abs() > 90.w || isFlickRight || isFlickLeft) {
      final isTrue = isFlickRight
          ? true
          : isFlickLeft
          ? false
          : _coinX > 0;
      _hapticService.selection();
      // Snap it visually immediately so it doesn't feel sluggish
      setState(() {
        _coinX = isTrue ? 120.w : -120.w;
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

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bool showHint =
        !_isDragging && _coinX == 0.0 && widget.pendingAnswer == null;

    return SizedBox(
      height: 250.h,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Slots
          Positioned(
            left: 20.w,
            child: _buildSlot("FALSE", tokens.gameIncorrect, widget.isDark),
          ),
          Positioned(
            right: 20.w,
            child: _buildSlot("TRUE", tokens.gameCorrect, widget.isDark),
          ),

          // Hint Arrows
          if (showHint)
            Positioned(
              left: 100.w,
              child: PulsingArrows(
                color: widget.isDark ? Colors.white54 : Colors.black45,
                isLeft: true,
              ),
            ),
          if (showHint)
            Positioned(
              right: 100.w,
              child: PulsingArrows(
                color: widget.isDark ? Colors.white54 : Colors.black45,
                isLeft: false,
              ),
            ),

          // The Coin
          AnimatedPositioned(
            duration: _isDragging
                ? Duration.zero
                : const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            left: (MediaQuery.of(context).size.width / 2) - 50.r + _coinX,
            top: 125.h - 50.r + _coinY,
            child: Transform.rotate(
              angle: _coinRotation,
              child: GestureDetector(
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
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
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFDF00), Color(0xFFF09819)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isDark ? Colors.black54 : Colors.black26,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 0,
                        spreadRadius: 2,
                        offset: const Offset(0, -2),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9),
                      width: 3.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 52.r,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(String label, Color color, bool isDark) {
    bool isTargeted =
        (_coinX > 0 && label == "TRUE") || (_coinX < 0 && label == "FALSE");
    return Opacity(
      opacity: isTargeted ? 1.0 : (isDark ? 0.3 : 0.15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isTargeted
                ? color
                : color.withValues(alpha: isDark ? 0.4 : 0.2),
            width: 2,
          ),
        ),
        child: RotatedBox(
          quarterTurns: 3,
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
