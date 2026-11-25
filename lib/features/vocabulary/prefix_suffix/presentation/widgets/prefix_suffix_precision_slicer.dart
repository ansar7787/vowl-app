import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_laser_painter.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_scissor_pad.dart';

/// Laser Seam Slicer Widget for Prefix & Suffix Mastery Phase ("Morpheme Precision Slicer").
class PrefixSuffixPrecisionSlicer extends StatefulWidget {
  final String word;
  final int correctCutIndex;
  final int? secondaryCutIndex;
  final ValueChanged<int> onSlice;
  final bool isSliced;
  final bool isWrongCut;
  final bool isAnswered;

  const PrefixSuffixPrecisionSlicer({
    super.key,
    required this.word,
    required this.correctCutIndex,
    this.secondaryCutIndex,
    required this.onSlice,
    this.isSliced = false,
    this.isWrongCut = false,
    this.isAnswered = false,
  });

  @override
  State<PrefixSuffixPrecisionSlicer> createState() =>
      _PrefixSuffixPrecisionSlicerState();
}

class _PrefixSuffixPrecisionSlicerState
    extends State<PrefixSuffixPrecisionSlicer>
    with SingleTickerProviderStateMixin {
  Offset? _dragStartGlobal;
  Offset? _dragCurrentGlobal;
  final ValueNotifier<List<Offset?>?> _dragNotifier = ValueNotifier(null);
  int? _lastCut;
  final GlobalKey _wordContainerKey = GlobalKey();
  final GlobalKey _lettersKey = GlobalKey();

  late final AnimationController _splitController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _splitAnimation = CurvedAnimation(
    parent: _splitController,
    curve: Curves.easeOutBack,
  );

  @override
  void didUpdateWidget(covariant PrefixSuffixPrecisionSlicer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word ||
        (!widget.isSliced && !widget.isWrongCut)) {
      _lastCut = null;
    }
    if (widget.isSliced && !oldWidget.isSliced) {
      _splitController.forward(from: 0.0);
    } else if (!widget.isSliced && oldWidget.isSliced) {
      _splitController.reset();
    }
  }

  @override
  void dispose() {
    _splitController.dispose();
    _dragNotifier.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails d) {
    if (!widget.isAnswered) {
      _dragStartGlobal = _dragCurrentGlobal = d.globalPosition;
      _dragNotifier.value = [d.localPosition, d.localPosition];
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!widget.isAnswered && _dragNotifier.value != null) {
      _dragCurrentGlobal = d.globalPosition;
      _dragNotifier.value = [_dragNotifier.value![0], d.localPosition];
    }
  }

  void _onPanEnd(DragEndDetails d) {
    final start = _dragNotifier.value?[0];
    final current = _dragNotifier.value?[1];
    if (!widget.isAnswered &&
        start != null &&
        current != null &&
        (current.dy - start.dy).abs() >= 18) {
      final midGlobal = (_dragStartGlobal != null && _dragCurrentGlobal != null)
          ? (_dragStartGlobal! + _dragCurrentGlobal!) / 2.0
          : null;
      _detectAndExecuteCut(
        midGlobal: midGlobal,
        fallbackLocalX: (start.dx + current.dx) / 2.0,
      );
    }
    _dragNotifier.value = null;
    _dragStartGlobal = null;
    _dragCurrentGlobal = null;
  }

  void _onTapUp(TapUpDetails d) {
    if (!widget.isAnswered) {
      _detectAndExecuteCut(
        midGlobal: d.globalPosition,
        fallbackLocalX: d.localPosition.dx,
      );
    }
  }

  void _detectAndExecuteCut({
    required Offset? midGlobal,
    required double fallbackLocalX,
  }) {
    if (widget.word.length < 2) return;
    double? localX;
    double? totalWidth;
    final lettersBox =
        _lettersKey.currentContext?.findRenderObject() as RenderBox?;
    if (lettersBox != null && midGlobal != null) {
      localX = lettersBox.globalToLocal(midGlobal).dx;
      totalWidth = lettersBox.size.width;
    } else {
      final box =
          _wordContainerKey.currentContext?.findRenderObject() as RenderBox?;
      if (box != null) {
        localX = fallbackLocalX;
        totalWidth = box.size.width;
      }
    }
    if (localX == null || totalWidth == null) return;

    final letterWidth = totalWidth / widget.word.length;
    int targetSeam = (localX / letterWidth).round();
    if (widget.correctCutIndex > 0 &&
        (localX - widget.correctCutIndex * letterWidth).abs() <=
            letterWidth * 0.42) {
      targetSeam = widget.correctCutIndex;
    } else if (widget.secondaryCutIndex != null &&
        widget.secondaryCutIndex! > 0 &&
        (localX - widget.secondaryCutIndex! * letterWidth).abs() <=
            letterWidth * 0.42) {
      targetSeam = widget.secondaryCutIndex!;
    }

    final clamped = targetSeam.clamp(1, widget.word.length - 1);
    HapticFeedback.mediumImpact();
    setState(() => _lastCut = clamped);
    widget.onSlice(clamped);
  }

  Widget _buildLetterTile(
    String letter, {
    required bool isHighlighted,
    required bool isDark,
  }) {
    final border = isHighlighted
        ? (isDark ? AppColors.indigo400 : AppColors.indigo500)
        : (isDark ? AppColors.slate700 : AppColors.slate300);
    final bg = isHighlighted
        ? (isDark
              ? AppColors.indigo500.withValues(alpha: 0.18)
              : AppColors.indigo50.withValues(alpha: 0.8))
        : (isDark ? AppColors.slate800 : const Color(0xFFF1F5F9));
    final fg = isHighlighted
        ? (isDark ? AppColors.indigo400 : AppColors.indigo600)
        : (isDark ? AppColors.slate50 : AppColors.slate900);
    final shadow = isHighlighted
        ? [BoxShadow(color: AppColors.indigo500.withValues(alpha: isDark ? 0.3 : 0.2), blurRadius: 8)]
        : null;

    return Container(
      width: 32.w,
      height: 48.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: border, width: 1.5),
        boxShadow: shadow,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildLetterGroup(
    List<String> items,
    double shift,
    double angle, {
    required bool isDark,
  }) {
    return Transform.translate(
      offset: Offset(shift, 0),
      child: Transform.rotate(
        angle: angle,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final l in items)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: _buildLetterTile(
                  l,
                  isHighlighted: widget.isSliced,
                  isDark: isDark,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letters = widget.word.split('');
    final targetSeam =
        (_lastCut != null &&
            widget.secondaryCutIndex != null &&
            _lastCut == widget.secondaryCutIndex)
        ? widget.secondaryCutIndex!
        : widget.correctCutIndex;
    final cutSeam = letters.length < 2
        ? 0
        : targetSeam.clamp(1, letters.length - 1);
    final boardBorder = widget.isSliced
        ? AppColors.emerald500
        : (widget.isWrongCut
              ? AppColors.red500
              : (isDark ? AppColors.slate700 : AppColors.slate200));

    return AnimatedBuilder(
      animation: _splitAnimation,
      builder: (context, child) {
        final splitShift = _splitAnimation.value * 14.w;
        final tiltAngle = _splitAnimation.value * 0.04;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTapUp: _onTapUp,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              behavior: HitTestBehavior.opaque,
              child: ValueListenableBuilder<List<Offset?>?>(
                valueListenable: _dragNotifier,
                builder: (context, drag, child) {
                  return RepaintBoundary(
                    child: CustomPaint(
                      foregroundPainter: PrefixSuffixLaserPainter(
                        start: drag?[0],
                        current: drag?[1],
                        isWrong: widget.isWrongCut,
                      ),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  key: _wordContainerKey,
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.slate900.withValues(alpha: 0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: boardBorder, width: 2.0),
                    boxShadow: isDark
                        ? null
                        : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.touch_app_rounded,
                                size: 13.sp,
                                color: isDark
                                    ? AppColors.slate400
                                    : AppColors.slate500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Swipe down or tap between letters to slice',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: isDark
                                      ? AppColors.slate400
                                      : AppColors.slate600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          key: _lettersKey,
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLetterGroup(
                              letters.sublist(0, cutSeam),
                              -splitShift,
                              -tiltAngle,
                              isDark: isDark,
                            ),
                            if (widget.isSliced) ...[
                              SizedBox(width: 6.w),
                              Icon(
                                Icons.content_cut_rounded,
                                size: 16.sp,
                                color: AppColors.emerald500,
                              ),
                              SizedBox(width: 6.w),
                            ],
                            _buildLetterGroup(
                              letters.sublist(cutSeam),
                              splitShift,
                              tiltAngle,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            PrefixSuffixScissorPad(
              letters: letters,
              correctCutIndex: widget.correctCutIndex,
              secondaryCutIndex: widget.secondaryCutIndex,
              lastCut: _lastCut,
              isSliced: widget.isSliced,
              isWrongCut: widget.isWrongCut,
              isAnswered: widget.isAnswered,
              onSlice: (seam) {
                setState(() => _lastCut = seam);
                widget.onSlice(seam);
              },
            ),
          ],
        );
      },
    );
  }
}
