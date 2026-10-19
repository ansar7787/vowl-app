import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrefixSuffixSynthesizer extends StatefulWidget {
  final String rootWord;
  final List<String> options;
  final String correctAnswer;
  final String? targetWord;
  final String? selectedAffix;
  final String? hintedAffix;
  final bool isFirstStagePassed;
  final Color primaryColor;
  final bool isDark;
  final Function(String, bool?) onAffixSelected;

  const PrefixSuffixSynthesizer({
    super.key,
    required this.rootWord,
    required this.options,
    required this.correctAnswer,
    this.targetWord,
    this.selectedAffix,
    this.hintedAffix,
    required this.isFirstStagePassed,
    required this.primaryColor,
    required this.isDark,
    required this.onAffixSelected,
  });

  @override
  State<PrefixSuffixSynthesizer> createState() =>
      _PrefixSuffixSynthesizerState();
}

class _PrefixSuffixSynthesizerState extends State<PrefixSuffixSynthesizer> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(height: 16.h),

        // Builder Slot (Center)
        Container(
          constraints: BoxConstraints(minHeight: 80.h, maxHeight: 110.h),
          width: double.infinity,
          alignment: Alignment.center,
          child: widget.isFirstStagePassed
              ? _buildFusedWord()
              : _buildMagneticTrack(),
        ),

        SizedBox(height: widget.isFirstStagePassed ? 16.h : 28.h),

        // Affix Options
        if (widget.isFirstStagePassed) ...[
          const SizedBox.shrink(),
        ] else ...[
          Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            children: widget.options.map((option) {
              return _buildDraggableChip(option);
            }).toList(),
          )
          .animate(target: widget.selectedAffix != null ? 0 : 1)
          .scale(
            begin: const Offset(0.9, 0.9),
            end: const Offset(1.0, 1.0),
            duration: 250.ms,
            curve: Curves.easeOut,
          )
          .fade(duration: 250.ms),
        ],
      ],
    );
  }

  Widget _buildMagneticTrack() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            _MagneticDropZone(
              isPrefixSlot: true,
              selectedAffix: widget.selectedAffix,
              primaryColor: widget.primaryColor,
              isDark: widget.isDark,
              onAffixSelected: widget.onAffixSelected,
            ),
            _buildRootBlock(),
            _MagneticDropZone(
              isPrefixSlot: false,
              selectedAffix: widget.selectedAffix,
              primaryColor: widget.primaryColor,
              isDark: widget.isDark,
              onAffixSelected: widget.onAffixSelected,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRootBlock() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          widget.rootWord.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : Colors.black87,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableChip(String affix) {
    final bool isHinted = widget.hintedAffix == affix;

    Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.slate800 : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isHinted
              ? widget.primaryColor
              : widget.primaryColor.withValues(alpha: 0.25),
          width: isHinted ? 2.5 : 1.5,
        ),
        boxShadow: isHinted
            ? [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Text(
        affix.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 17.sp,
          fontWeight: FontWeight.w700,
          color: widget.isDark ? Colors.white : Colors.black87,
          letterSpacing: 0.5,
        ),
      ),
    );

    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;

    if (isHinted && !reduceMotion) {
      chip = chip
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scale(
            begin: const Offset(1.0, 1.0),
            end: const Offset(1.05, 1.05),
            duration: 500.ms,
          );
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onAffixSelected(affix, null);
      },
      child: Draggable<String>(
        data: affix,
        dragAnchorStrategy: childDragAnchorStrategy,
        onDragStarted: () {
          HapticFeedback.selectionClick();
        },
        onDragEnd: (details) {
          // DragTarget automatically fires onLeave, so no need to clear local state manually.
        },
        feedback: Transform.scale(
          scale: 1.05,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.slate800 : Colors.white,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: widget.primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 16,
                    spreadRadius: 3,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                affix.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ),
        ),
        childWhenDragging: Opacity(opacity: 0.2, child: chip),
        child: chip,
      ),
    );
  }

  Widget _buildFusedWord() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context) ||
        VowlMotion.lowAnimationModeOverride.value;
    final displayWord = (widget.targetWord != null && widget.targetWord!.isNotEmpty)
        ? widget.targetWord!
        : widget.correctAnswer;

    final content = FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 16.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              widget.primaryColor,
              widget.primaryColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Text(
          displayWord.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 26.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 2.0,
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return content;
    }

    return content
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          curve: Curves.easeOutCubic,
          duration: 400.ms,
        )
        .shimmer(
          color: Colors.white.withValues(alpha: 0.5),
          duration: 800.ms,
          delay: 200.ms,
        );
  }
}

class _MagneticDropZone extends StatefulWidget {
  final bool isPrefixSlot;
  final String? selectedAffix;
  final Color primaryColor;
  final bool isDark;
  final Function(String, bool?) onAffixSelected;

  const _MagneticDropZone({
    required this.isPrefixSlot,
    required this.selectedAffix,
    required this.primaryColor,
    required this.isDark,
    required this.onAffixSelected,
  });

  @override
  State<_MagneticDropZone> createState() => _MagneticDropZoneState();
}

class _MagneticDropZoneState extends State<_MagneticDropZone> {
  final ValueNotifier<bool> _isHovering = ValueNotifier(false);

  @override
  void dispose() {
    _isHovering.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedAffix != null) {
      final isSelectedPrefix = widget.selectedAffix!.endsWith('-');
      if (widget.isPrefixSlot == isSelectedPrefix) {
        return Container(
          padding: EdgeInsets.only(
            left: widget.isPrefixSlot ? 10.w : 6.w,
            right: widget.isPrefixSlot ? 6.w : 10.w,
            top: 12.h,
            bottom: 12.h,
          ),
          child: _buildSnappedAffix(widget.selectedAffix!),
        );
      }
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        HapticFeedback.lightImpact();
        _isHovering.value = true;
        return true;
      },
      onLeave: (data) {
        _isHovering.value = false;
      },
      onAcceptWithDetails: (details) {
        _isHovering.value = false;
        widget.onAffixSelected(details.data, widget.isPrefixSlot);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(
            left: widget.isPrefixSlot ? 10.w : 6.w,
            right: widget.isPrefixSlot ? 6.w : 10.w,
            top: 12.h,
            bottom: 12.h,
          ),
          child: SizedBox(
            width: 100.w,
            height: 64.h,
            child: Align(
              alignment: widget.isPrefixSlot
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isHovering,
                builder: (context, isHover, child) {
                  return AnimatedContainer(
                    duration: 200.ms,
                    width: isHover ? 100.w : 90.w,
                    height: isHover ? 62.h : 54.h,
                    decoration: BoxDecoration(
                      color: isHover
                          ? widget.primaryColor.withValues(alpha: 0.18)
                          : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(
                        color: isHover
                            ? widget.primaryColor
                            : (widget.isDark ? Colors.white38 : Colors.black26),
                        width: isHover ? 2.5 : 1.5,
                        style: BorderStyle.solid,
                      ),
                      boxShadow: isHover
                          ? [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isHover
                        ? Icon(
                            Icons.arrow_downward_rounded,
                            color: widget.primaryColor,
                            size: 26.r,
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_rounded,
                                  color: widget.isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                  size: 18.r,
                                ),
                                SizedBox(height: 2.h),
                                Text(
                                  widget.isPrefixSlot ? "PREFIX" : "SUFFIX",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDark
                                        ? Colors.white54
                                        : Colors.black45,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSnappedAffix(String affix) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.35),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          affix.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    ).animate().scale(
      begin: const Offset(1.15, 1.15),
      end: const Offset(1.0, 1.0),
      duration: 200.ms,
      curve: Curves.easeOutCubic,
    );
  }
}
