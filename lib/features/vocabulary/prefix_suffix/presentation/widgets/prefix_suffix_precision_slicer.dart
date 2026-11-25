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

  late final _splitController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final _splitAnimation = CurvedAnimation(
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
    if (widget.isSliced != oldWidget.isSliced) {
      widget.isSliced
          ? _splitController.forward(from: 0.0)
          : _splitController.reset();
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
    final s = _dragNotifier.value?[0];
    final c = _dragNotifier.value?[1];
    if (!widget.isAnswered && s != null && c != null) {
      final dy = (c.dy - s.dy).abs();
      final dx = (c.dx - s.dx).abs();
      if (dy >= 18 || (dy < 18 && dx < 18)) {
        _detectAndExecuteCut(
          _dragStartGlobal,
          _dragCurrentGlobal,
          (s.dx + c.dx) / 2.0,
        );
      }
    }
    _clearDrag();
  }

  void _onPanCancel() => _clearDrag();
  void _clearDrag() {
    _dragNotifier.value = null;
    _dragStartGlobal = _dragCurrentGlobal = null;
  }

  void _onTapUp(TapUpDetails d) {
    if (!widget.isAnswered) {
      _detectAndExecuteCut(
        d.globalPosition,
        d.globalPosition,
        d.localPosition.dx,
      );
    }
  }

  void _detectAndExecuteCut(Offset? sG, Offset? eG, double fallbackLocalX) {
    if (widget.word.length < 2) return;
    final lBox = _lettersKey.currentContext?.findRenderObject() as RenderBox?;
    final cBox =
        _wordContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (lBox == null && cBox == null) return;

    double localX = fallbackLocalX;
    if (lBox != null && sG != null) {
      final rect = lBox.localToGlobal(Offset.zero) & lBox.size;
      final sy = sG.dy;
      final ey = (eG ?? sG).dy;
      final dy = (ey - sy).abs();
      final tX = (dy > 4 && eG != null)
          ? sG.dx +
                ((rect.center.dy - sy) / (ey - sy)).clamp(0.0, 1.0) *
                    (eG.dx - sG.dx)
          : sG.dx;
      localX = lBox.globalToLocal(Offset(tX, rect.center.dy)).dx;
    }

    final letterWidth =
        (lBox?.size.width ?? cBox?.size.width ?? 1.0) / widget.word.length;
    int target = (localX / letterWidth).round();
    final isSec =
        widget.secondaryCutIndex != null && widget.secondaryCutIndex! > 0;
    if (widget.correctCutIndex > 0 &&
        (localX - widget.correctCutIndex * letterWidth).abs() <=
            letterWidth * 0.25) {
      target = widget.correctCutIndex;
    } else if (isSec &&
        (localX - widget.secondaryCutIndex! * letterWidth).abs() <=
            letterWidth * 0.25) {
      target = widget.secondaryCutIndex!;
    }

    final clamped = target.clamp(1, widget.word.length - 1);
    HapticFeedback.mediumImpact();
    setState(() => _lastCut = clamped);
    widget.onSlice(clamped);
  }

  Widget _buildLetterTile(
    String letter, {
    required bool isHighlighted,
    required bool isWrong,
    required bool isDark,
  }) {
    final border = isHighlighted
        ? AppColors.emerald500
        : (isWrong
              ? AppColors.red500
              : (isDark ? AppColors.slate700 : AppColors.slate300));
    final bg = isHighlighted
        ? (isDark
              ? AppColors.emerald500.withValues(alpha: 0.22)
              : AppColors.emerald50.withValues(alpha: 0.85))
        : (isWrong
              ? (isDark
                    ? AppColors.red500.withValues(alpha: 0.18)
                    : AppColors.red50.withValues(alpha: 0.85))
              : (isDark ? AppColors.slate800 : const Color(0xFFF1F5F9)));
    final fg = isHighlighted
        ? (isDark ? AppColors.emerald400 : AppColors.emerald600)
        : (isWrong
              ? (isDark ? AppColors.red500 : AppColors.red900)
              : (isDark ? AppColors.slate50 : AppColors.slate900));

    final shadow = (isHighlighted || isWrong)
        ? [
            BoxShadow(
              color: (isHighlighted ? AppColors.emerald500 : AppColors.red500)
                  .withValues(alpha: isDark ? 0.35 : 0.22),
              blurRadius: 8,
            ),
          ]
        : null;

    return Container(
      width: 32.w,
      height: 48.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: border,
          width: (isHighlighted || isWrong) ? 1.8 : 1.5,
        ),
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
  }) => Transform.translate(
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
                isWrong: widget.isWrongCut,
                isDark: isDark,
              ),
            ),
        ],
      ),
    ),
  );

  Widget _buildPrompt(bool isDark) {
    final c = isDark ? AppColors.slate400 : AppColors.slate600;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.touch_app_rounded, size: 13.sp, color: c),
            SizedBox(width: 4.w),
            Text(
              'Swipe up/down or tap between letters to slice',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: c,
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
    final isSec =
        _lastCut != null &&
        widget.secondaryCutIndex != null &&
        _lastCut == widget.secondaryCutIndex;
    final targetSeam = isSec
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
            SizedBox(height: 12.h),
            GestureDetector(
              onTapUp: _onTapUp,
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              onPanCancel: _onPanCancel,
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
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.slate900.withValues(alpha: 0.5)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: boardBorder, width: 2.0),
                    boxShadow: isDark
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPrompt(isDark),
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
                            if (widget.isSliced)
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6.w),
                                child: Icon(
                                  Icons.content_cut_rounded,
                                  size: 16.sp,
                                  color: AppColors.emerald500,
                                ),
                              ),
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
          ],
        );
      },
    );
  }
}
