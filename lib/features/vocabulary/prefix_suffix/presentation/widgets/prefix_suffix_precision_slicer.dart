import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Laser Seam Slicer Widget for Prefix & Suffix Mastery Phase ("Morpheme Precision Slicer").
///
/// Features:
/// - Displays the target word as individual typographic letter tiles.
/// - Neon downward laser blade swipe gesture detection across letter seam boundaries.
/// - Letter separation animation upon successful morpheme severing.
/// - Scissor icon tap-targets beneath each seam for WCAG accessibility.
class PrefixSuffixPrecisionSlicer extends StatefulWidget {
  /// The word being sliced (e.g. "PREVIEW").
  final String word;

  /// The index of the correct seam cut (e.g. 3 for PRE|VIEW).
  final int correctCutIndex;

  /// Callback when a seam is severed, passing the severed cut index.
  final ValueChanged<int> onSlice;

  /// Whether the word has been successfully sliced.
  final bool isSliced;

  /// Whether an erroneous slice attempt occurred.
  final bool isWrongCut;

  /// Whether the current quest has been answered.
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
    if (widget.isAnswered) return;
    setState(() {
      _dragStart = details.localPosition;
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (widget.isAnswered) return;
    setState(() {
      _dragCurrent = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (widget.isAnswered || _dragStart == null || _dragCurrent == null) {
      setState(() {
        _dragStart = null;
        _dragCurrent = null;
      });
      return;
    }

    final dy = _dragCurrent!.dy - _dragStart!.dy;
    // Require downward slash gesture with minimum vertical displacement
    if (dy.abs() >= 24) {
      final averageX = (_dragStart!.dx + _dragCurrent!.dx) / 2.0;
      _detectAndExecuteCut(averageX);
    }

    setState(() {
      _dragStart = null;
      _dragCurrent = null;
    });
  }

  void _detectAndExecuteCut(double localX) {
    final renderBox =
        _wordContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final wordWidth = renderBox.size.width;
    final letterCount = widget.word.length;
    if (letterCount < 2) return;

    final letterWidth = wordWidth / letterCount;
    // Find closest seam boundary index between 1 and letterCount - 1
    int closestSeam = (localX / letterWidth).round();
    closestSeam = closestSeam.clamp(1, letterCount - 1);

    HapticFeedback.mediumImpact();
    widget.onSlice(closestSeam);
  }

  Widget _buildLetterTile(String letter, {required bool isHighlighted}) {
    return Container(
      width: 32.w,
      height: 48.h,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.indigo500.withValues(alpha: 0.18)
            : AppColors.slate800,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isHighlighted ? AppColors.indigo400 : AppColors.slate700,
          width: 1.5,
        ),
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

  @override
  Widget build(BuildContext context) {
    final letters = widget.word.split('');
    final cutSeam = widget.correctCutIndex.clamp(1, letters.length - 1);

    return AnimatedBuilder(
      animation: _splitAnimation,
      builder: (context, child) {
        final splitShift = _splitAnimation.value * 12.w;

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
                foregroundPainter: _LaserPainter(
                  start: _dragStart,
                  current: _dragCurrent,
                  isWrong: widget.isWrongCut,
                ),
                child: Container(
                  key: _wordContainerKey,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 20.h,
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
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Prefix letters (Shift Left on slice)
                        Transform.translate(
                          offset: Offset(-splitShift, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = 0; i < cutSeam; i++)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                  ),
                                  child: _buildLetterTile(
                                    letters[i],
                                    isHighlighted: widget.isSliced,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Severed Gap Indicator when sliced
                        if (widget.isSliced) ...[
                          SizedBox(width: 6.w),
                          Icon(
                            Icons.content_cut_rounded,
                            size: 16.sp,
                            color: AppColors.emerald500,
                          ),
                          SizedBox(width: 6.w),
                        ],

                        // Root / Suffix letters (Shift Right on slice)
                        Transform.translate(
                          offset: Offset(splitShift, 0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (int i = cutSeam; i < letters.length; i++)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 2.w,
                                  ),
                                  child: _buildLetterTile(
                                    letters[i],
                                    isHighlighted: widget.isSliced,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
          ],
        );
      },
    );
  }
}

/// Custom painter for real-time laser swipe trail.
class _LaserPainter extends CustomPainter {
  final Offset? start;
  final Offset? current;
  final bool isWrong;

  _LaserPainter({this.start, this.current, this.isWrong = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;

    final bladeColor = isWrong ? AppColors.red500 : AppColors.violet500;

    final glowPaint = Paint()
      ..color = bladeColor.withValues(alpha: 0.5)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final corePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawLine(start!, current!, glowPaint);
    canvas.drawLine(start!, current!, corePaint);
  }

  @override
  bool shouldRepaint(covariant _LaserPainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.current != current ||
        oldDelegate.isWrong != isWrong;
  }
}
