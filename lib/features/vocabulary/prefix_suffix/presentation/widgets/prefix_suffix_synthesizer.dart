import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PrefixSuffixSynthesizer extends StatefulWidget {
  final String rootWord;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final String? selectedAffix;
  final String? hintedAffix;
  final bool isFirstStagePassed;
  final Color primaryColor;
  final bool isDark;
  final Function(String, bool) onAffixSelected;

  const PrefixSuffixSynthesizer({
    super.key,
    required this.rootWord,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    this.selectedAffix,
    this.hintedAffix,
    required this.isFirstStagePassed,
    required this.primaryColor,
    required this.isDark,
    required this.onAffixSelected,
  });

  @override
  State<PrefixSuffixSynthesizer> createState() => _PrefixSuffixSynthesizerState();
}

class _PrefixSuffixSynthesizerState extends State<PrefixSuffixSynthesizer> {
  // Track hovered state for the drop zones
  bool _isHoveringPrefix = false;
  bool _isHoveringSuffix = false;

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
          if (widget.explanation != null && widget.explanation!.isNotEmpty)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 24.w),
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                color: widget.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: widget.isDark ? Colors.white : Colors.black87,
                  height: 1.4,
                ),
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, duration: 400.ms),
          
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
          ).animate(target: widget.selectedAffix != null ? 0 : 1).scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOut,
          ).fade(duration: 300.ms),
        ]
      ],
    );
  }

  Widget _buildMagneticTrack() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: widget.isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: widget.primaryColor.withValues(alpha: 0.1)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDropZone(isPrefixSlot: true),
              SizedBox(width: 12.w),
              _buildRootBlock(),
              SizedBox(width: 12.w),
              _buildDropZone(isPrefixSlot: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropZone({required bool isPrefixSlot}) {
    // If an affix is selected and snapping into this side
    if (widget.selectedAffix != null) {
      final isSelectedPrefix = widget.selectedAffix!.endsWith('-');
      if (isPrefixSlot == isSelectedPrefix) {
        return _buildSnappedAffix(widget.selectedAffix!);
      }
    }

    final isHovering = isPrefixSlot ? _isHoveringPrefix : _isHoveringSuffix;
    
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) {
        setState(() {
          if (isPrefixSlot) {
            _isHoveringPrefix = true;
          } else {
            _isHoveringSuffix = true;
          }
        });
        return true;
      },
      onLeave: (data) {
        setState(() {
          if (isPrefixSlot) {
            _isHoveringPrefix = false;
          } else {
            _isHoveringSuffix = false;
          }
        });
      },
      onAcceptWithDetails: (details) {
        setState(() {
          _isHoveringPrefix = false;
          _isHoveringSuffix = false;
        });
        widget.onAffixSelected(details.data, isPrefixSlot);
      },
      builder: (context, candidateData, rejectedData) {
        return AnimatedContainer(
          duration: 200.ms,
          width: isHovering ? 100.w : 80.w,
          height: isHovering ? 80.h : 70.h,
          decoration: BoxDecoration(
            color: isHovering 
                ? widget.primaryColor.withValues(alpha: 0.2)
                : (widget.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isHovering ? widget.primaryColor : widget.primaryColor.withValues(alpha: 0.5),
              width: isHovering ? 3 : 2,
              style: isHovering ? BorderStyle.solid : BorderStyle.none, // Dashed look simulated by alpha when not hovering
            ),
            boxShadow: isHovering 
                ? [BoxShadow(color: widget.primaryColor.withValues(alpha: 0.3), blurRadius: 12, spreadRadius: 2)]
                : null,
          ),
          alignment: Alignment.center,
          child: isHovering
              ? Icon(Icons.arrow_downward_rounded, color: widget.primaryColor, size: 32.r)
              : Icon(Icons.add, color: widget.primaryColor.withValues(alpha: 0.3), size: 32.r),
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
          )
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
    ).animate().scale(begin: const Offset(1.3, 1.3), end: const Offset(1.0, 1.0), duration: 250.ms, curve: Curves.easeOutBack);
  }

  Widget _buildRootBlock() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: widget.primaryColor.withValues(alpha: 0.4), width: 2),
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
          color: isHinted ? widget.primaryColor : widget.primaryColor.withValues(alpha: 0.3),
          width: isHinted ? 3 : 2,
        ),
        boxShadow: isHinted
            ? [
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                )
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
      chip = chip.animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.05, 1.05), duration: 500.ms);
    }

    return Draggable<String>(
      data: affix,
      onDragStarted: () {},
      onDragEnd: (details) {
        setState(() {
          _isHoveringPrefix = false;
          _isHoveringSuffix = false;
        });
      },
      feedback: Transform.scale(
        scale: 1.1,
        child: Material(
          color: Colors.transparent,
          child: Opacity(
            opacity: 0.9,
            child: chip,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: chip,
      ),
      child: chip,
    );
  }

  Widget _buildFusedWord() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 24.h),
        decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.8)],
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
    )).animate()
     .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack, duration: 400.ms)
     .shimmer(color: Colors.white.withValues(alpha: 0.5), duration: 800.ms, delay: 200.ms);
  }
}
