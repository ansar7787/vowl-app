import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/widgets/prefix_suffix_laser_painter.dart';

/// Laser Seam Slicer Widget for Prefix & Suffix Mastery Phase ("Morpheme Precision Slicer").
class PrefixSuffixPrecisionSlicer extends StatefulWidget {
  final String word;
  final int correctCutIndex;
  final ValueChanged<int> onSlice;
  final bool isSliced;
  final bool isWrongCut;
  final bool isAnswered;

  const PrefixSuffixPrecisionSlicer({
    super.key,
    required this.word,
    required this.correctCutIndex,
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
  Offset? _dragStart;
  Offset? _dragCurrent;
  final GlobalKey _wordContainerKey = GlobalKey();

  late final AnimationController _splitController;
  late final Animation<double> _splitAnimation;

  @override
  void initState() {
    super.initState();
    _splitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _splitAnimation = CurvedAnimation(
      parent: _splitController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void didUpdateWidget(covariant PrefixSuffixPrecisionSlicer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSliced && !oldWidget.isSliced) {
      _splitController.forward(from: 0.0);
    } else if (!widget.isSliced && oldWidget.isSliced) {
      _splitController.reset();
    }
  }

  @override
  void dispose() {
    _splitController.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.isAnswered) {
      setState(() {
        _dragStart = details.localPosition;
        _dragCurrent = details.localPosition;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.isAnswered) {
      setState(() => _dragCurrent = details.localPosition);
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.isAnswered && _dragStart != null && _dragCurrent != null) {
      final dy = _dragCurrent!.dy - _dragStart!.dy;
      if (dy.abs() >= 24) {
        _detectAndExecuteCut((_dragStart!.dx + _dragCurrent!.dx) / 2.0);
      }
    }
    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _detectAndExecuteCut(double localX) {
    final box =
        _wordContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && widget.word.length >= 2) {
      final seam = (localX / (box.size.width / widget.word.length)).round();
      HapticFeedback.mediumImpact();
      widget.onSlice(seam.clamp(1, widget.word.length - 1));
    }
  }

  Widget _buildLetterTile(String letter, {required bool isHighlighted}) {
    final borderColor = isHighlighted
        ? AppColors.indigo400
        : AppColors.slate700;
    final bgColor = isHighlighted
        ? AppColors.indigo500.withValues(alpha: 0.18)
        : AppColors.slate800;
    return Container(
      width: 32.w,
      height: 48.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isHighlighted
            ? [
                BoxShadow(
                  color: AppColors.indigo500.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 20.sp,
          fontWeight: FontWeight.w900,
          color: isHighlighted ? AppColors.indigo400 : AppColors.slate50,
        ),
      ),
    );
  }

  Widget _buildLetterGroup(List<String> items, double shift, double angle) {
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
                child: _buildLetterTile(l, isHighlighted: widget.isSliced),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.word.split('');
    final cutSeam = widget.correctCutIndex.clamp(1, letters.length - 1);

    return AnimatedBuilder(
      animation: _splitAnimation,
      builder: (context, child) {
        final splitShift = _splitAnimation.value * 14.w;
        final tiltAngle = _splitAnimation.value * 0.04;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gesture Table with Laser Trail Overlay
            GestureDetector(
              onPanStart: _onPanStart,
              onPanUpdate: _onPanUpdate,
              onPanEnd: _onPanEnd,
              behavior: HitTestBehavior.opaque,
              child: CustomPaint(
                foregroundPainter: PrefixSuffixLaserPainter(
                  start: _dragStart,
                  current: _dragCurrent,
                  isWrong: widget.isWrongCut,
                ),
                child: Container(
                  key: _wordContainerKey,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 16.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.slate900.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: widget.isSliced
                          ? AppColors.emerald500
                          : (widget.isWrongCut
                                ? AppColors.red500
                                : AppColors.slate700),
                      width: 2.0,
                    ),
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
                                Icons.swipe_vertical_rounded,
                                size: 13.sp,
                                color: AppColors.slate400,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'SWIPE DOWN ACROSS A SEAM TO SLICE',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildLetterGroup(
                              letters.sublist(0, cutSeam),
                              -splitShift,
                              -tiltAngle,
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

            // WCAG Accessible Scissor Buttons
            Wrap(
              spacing: 6.w,
              runSpacing: 6.h,
              alignment: WrapAlignment.center,
              children: [
                for (int seam = 1; seam < letters.length; seam++)
                  OutlinedButton.icon(
                    onPressed: widget.isAnswered
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            widget.onSlice(seam);
                          },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      minimumSize: Size(44.w, 36.h),
                      side: BorderSide(
                        color: widget.isSliced && seam == widget.correctCutIndex
                            ? AppColors.emerald500
                            : AppColors.slate700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    icon: Icon(
                      Icons.content_cut_rounded,
                      size: 14.sp,
                      color: widget.isSliced && seam == widget.correctCutIndex
                          ? AppColors.emerald500
                          : AppColors.slate400,
                    ),
                    label: Text(
                      '${letters.sublist(0, seam).join()}|${letters.sublist(seam).join()}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.slate50,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            _buildShieldButton(),
          ],
        );
      },
    );
  }

  Widget _buildShieldButton() {
    final isCorrect = widget.isSliced && widget.correctCutIndex == 0;
    final isWrong = widget.isWrongCut && widget.correctCutIndex == 0;
    final bg = isCorrect
        ? AppColors.emerald500.withValues(alpha: 0.15)
        : (isWrong
              ? AppColors.red500.withValues(alpha: 0.15)
              : AppColors.slate800);
    final border = isCorrect ? AppColors.emerald500 : AppColors.slate700;
    final text = isCorrect ? AppColors.emerald500 : AppColors.slate300;

    return OutlinedButton.icon(
      onPressed: widget.isAnswered
          ? null
          : () {
              HapticFeedback.mediumImpact();
              widget.onSlice(0);
            },
      style: OutlinedButton.styleFrom(
        backgroundColor: bg,
        side: BorderSide(color: border, width: 1.5),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
      icon: Icon(Icons.shield_outlined, size: 14.sp, color: text),
      label: Text(
        'UNBREAKABLE ROOT (NO AFFIX)',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: text,
        ),
      ),
    );
  }
}
