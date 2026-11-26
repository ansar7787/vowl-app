import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';
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
  int? _lastCut;
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
    super.dispose();
  }

  void _executeCut(int seam) {
    if (widget.isAnswered) return;
    HapticFeedback.mediumImpact();
    setState(() => _lastCut = seam);
    widget.onSlice(seam);
  }

  Widget _buildLetterTile(
    String letter,
    int index, {
    required int lettersLength,
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

    return GestureDetector(
      onTap: () {
        final targetSeam = index + 1;
        if (targetSeam < lettersLength) _executeCut(targetSeam);
      },
      child: Container(
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
      ),
    );
  }

  Widget _buildSeamCutter(int seam, {required bool isDark}) {
    final isThisSeamCorrect =
        seam == widget.correctCutIndex ||
        (widget.secondaryCutIndex != null && seam == widget.secondaryCutIndex);
    final isUserPicked = widget.isWrongCut && _lastCut == seam;
    final isRevealedCorrect = widget.isWrongCut && isThisSeamCorrect;
    final isCut = widget.isSliced && (isThisSeamCorrect || seam == _lastCut);

    Color color;
    Widget? indicator;
    if (isCut || isRevealedCorrect) {
      color = AppColors.emerald500;
      indicator = Icon(
        Icons.content_cut_rounded,
        size: 14.sp,
        color: AppColors.emerald500,
      );
    } else if (isUserPicked) {
      color = AppColors.red500;
      indicator = Icon(
        Icons.close_rounded,
        size: 14.sp,
        color: AppColors.red500,
      );
    } else {
      color = isDark ? AppColors.slate600 : AppColors.slate300;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _executeCut(seam),
      child: Container(
        width: (isUserPicked || isRevealedCorrect) ? 22.w : 18.w,
        height: 52.h,
        alignment: Alignment.center,
        child:
            indicator ??
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 2.5,
              height: 26.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
      ),
    );
  }

  Widget _buildLetterGroup(
    List<String> items,
    int startIndex,
    double shift,
    double angle, {
    required int lettersLength,
    required bool isDark,
  }) => Transform.translate(
    offset: Offset(shift, 0),
    child: Transform.rotate(
      angle: angle,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildLetterTile(
              items[i],
              startIndex + i,
              lettersLength: lettersLength,
              isHighlighted: widget.isSliced,
              isWrong: widget.isWrongCut,
              isDark: isDark,
            ),
            if (i < items.length - 1)
              _buildSeamCutter(startIndex + i + 1, isDark: isDark),
          ],
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
              'Tap between letters or pick an option to slice',
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

        Widget boardContent;
        if (widget.isSliced && cutSeam > 0) {
          boardContent = Row(
            key: _lettersKey,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLetterGroup(
                letters.sublist(0, cutSeam),
                0,
                -splitShift,
                -tiltAngle,
                lettersLength: letters.length,
                isDark: isDark,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Icon(
                  Icons.content_cut_rounded,
                  size: 18.sp,
                  color: AppColors.emerald500,
                ),
              ),
              _buildLetterGroup(
                letters.sublist(cutSeam),
                cutSeam,
                splitShift,
                tiltAngle,
                lettersLength: letters.length,
                isDark: isDark,
              ),
            ],
          );
        } else {
          boardContent = Row(
            key: _lettersKey,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i < letters.length; i++) ...[
                _buildLetterTile(
                  letters[i],
                  i,
                  lettersLength: letters.length,
                  isHighlighted: widget.isSliced,
                  isWrong: widget.isWrongCut,
                  isDark: isDark,
                ),
                if (i < letters.length - 1)
                  _buildSeamCutter(i + 1, isDark: isDark),
              ],
            ],
          );
        }

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
              onSlice: _executeCut,
            ),
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
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
                  FittedBox(fit: BoxFit.scaleDown, child: boardContent),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
