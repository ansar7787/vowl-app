import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrefixSuffixSynthesizer extends StatefulWidget {
  final String rootWord;
  final List<String> options;
  final String correctAnswer;
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
        SizedBox(height: 40.h),

        // ── THE MAGNETIC TRACK (Center) ──
        Container(
          height: 120.h,
          width: double.infinity,
          alignment: Alignment.center,
          child: widget.isFirstStagePassed
              ? _buildFusedWord()
              : _buildMagneticTrack(),
        ),

        SizedBox(height: 60.h),

        // ── EXPLANATION OR ARSENAL DOCK ──
        if (widget.isFirstStagePassed) ...[
          SizedBox(height: 120.h), // extra space for the typing overlay
        ] else ...[
          // Arsenal Dock (Draggable Chips)
          Wrap(
                spacing: 16.w,
                runSpacing: 16.h,
                alignment: WrapAlignment.center,
                children: widget.options.map((option) {
                  return _buildDraggableChip(option);
                }).toList(),
              )
              .animate(target: widget.selectedAffix != null ? 0 : 1)
              .scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.0, 1.0),
                duration: 300.ms,
                curve: Curves.easeOut,
              )
              .fade(duration: 300.ms),
        ],
      ],
    );
  }

  Widget _buildMagneticTrack() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildRootBlock() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        widget.rootWord.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 28.sp,
          fontWeight: FontWeight.w900,
          color: widget.isDark ? Colors.white : Colors.black87,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildDraggableChip(String affix) {
    final bool isHinted = widget.hintedAffix == affix;

    Widget chip = Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isHinted
              ? widget.primaryColor
              : widget.primaryColor.withValues(alpha: 0.3),
          width: isHinted ? 3 : 2,
        ),
        boxShadow: isHinted
            ? [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      child: Text(
        affix.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 20.sp,
          fontWeight: FontWeight.w800,
          color: widget.isDark ? Colors.white : Colors.black87,
        ),
      ),
    );

    if (isHinted) {
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
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: widget.primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Text(
                affix.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
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
    return FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.primaryColor,
                  widget.primaryColor.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              widget.correctAnswer.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 36.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 4,
              ),
            ),
          ),
        )
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          curve: Curves.easeOutBack,
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
            left: widget.isPrefixSlot ? 16.w : 8.w,
            right: widget.isPrefixSlot ? 8.w : 16.w,
            top: 24.h,
            bottom: 24.h,
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
            left: widget.isPrefixSlot ? 16.w : 8.w,
            right: widget.isPrefixSlot ? 8.w : 16.w,
            top: 24.h,
            bottom: 24.h,
          ),
          child: SizedBox(
            width: 130.w,
            height: 85.h,
            child: Align(
              alignment: widget.isPrefixSlot
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isHovering,
                builder: (context, isHover, child) {
                  return AnimatedContainer(
                    duration: 200.ms,
                    width: isHover ? 130.w : 110.w,
                    height: isHover ? 75.h : 65.h,
                    decoration: BoxDecoration(
                      color: isHover
                          ? widget.primaryColor.withValues(alpha: 0.2)
                          : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: isHover
                            ? widget.primaryColor
                            : (widget.isDark ? Colors.white38 : Colors.black26),
                        width: isHover ? 3 : 2,
                        style: BorderStyle.solid,
                      ),
                      boxShadow: isHover
                          ? [
                              BoxShadow(
                                color: widget.primaryColor.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: isHover
                        ? Icon(
                            Icons.bolt_rounded,
                            color: widget.primaryColor,
                            size: 36.r,
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                color: widget.isDark
                                    ? Colors.white54
                                    : Colors.black45,
                                size: 24.r,
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                widget.isPrefixSlot ? "PREFIX" : "SUFFIX",
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w800,
                                  color: widget.isDark
                                      ? Colors.white54
                                      : Colors.black45,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
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
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: widget.primaryColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        affix.toUpperCase(),
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 24.sp,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
        ),
      ),
    ).animate().scale(
      begin: const Offset(1.3, 1.3),
      end: const Offset(1.0, 1.0),
      duration: 250.ms,
      curve: Curves.easeOutBack,
    );
  }
}
