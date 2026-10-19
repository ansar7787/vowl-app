import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MorphInjectionRail extends StatefulWidget {
  final int index;
  final String suffix;
  final Color color;
  final bool isDark;
  final bool isBlocked;
  final Function(String) onMorph;
  final Function(int?) onHover;
  final bool? isPrefix;

  const MorphInjectionRail({
    super.key,
    required this.index,
    required this.suffix,
    required this.color,
    required this.isDark,
    required this.isBlocked,
    required this.onMorph,
    required this.onHover,
    this.isPrefix,
  });

  @override
  State<MorphInjectionRail> createState() => _MorphInjectionRailState();
}

class _MorphInjectionRailState extends State<MorphInjectionRail> {
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  bool _isFusing = false;

  bool get _isPrefix =>
      widget.isPrefix ?? widget.suffix.trim().endsWith('-');

  @override
  void didUpdateWidget(MorphInjectionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlocked != oldWidget.isBlocked && !widget.isBlocked) {
      _progress.value = 0.0;
      _isFusing = false;
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : 1.sw - 48.w;
        final handleWidth = 115.w;
        final maxSlide = (railWidth - handleWidth).clamp(0.0, double.infinity);
        final isPrefix = _isPrefix;

        return Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: widget.color.withValues(
                alpha: widget.isBlocked ? 0.12 : 0.22,
              ),
              width: 1.5,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: Stack(
              children: [
                // Rail Path - Track Guidance Indicators
                _RailPathIndicators(
                  isDark: widget.isDark,
                  color: widget.color,
                  isPrefix: isPrefix,
                ),

                // Dynamic Slide Track Glow
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, value, _) {
                    if (value <= 0.0) return const SizedBox.shrink();
                    final glowWidth =
                        (value * maxSlide) + (handleWidth / 2);

                    return Positioned(
                      left: isPrefix ? null : 0,
                      right: isPrefix ? 0 : null,
                      top: 0,
                      bottom: 0,
                      width: glowWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: isPrefix
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            end: isPrefix
                                ? Alignment.centerLeft
                                : Alignment.centerRight,
                            colors: [
                              widget.color.withValues(alpha: 0.0),
                              widget.color.withValues(alpha: 0.18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Interactive Handle
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, value, _) {
                    final handleLeft = isPrefix
                        ? (1.0 - value) * maxSlide
                        : value * maxSlide;

                    return Positioned(
                      left: handleLeft,
                      top: 0,
                      bottom: 0,
                      child: Semantics(
                        button: true,
                        label: 'Suffix ${widget.suffix}',
                        child: GestureDetector(
                          onTap: () {
                            if (widget.isBlocked || _isFusing) return;
                            _progress.value = 1.0;
                            _isFusing = true;
                            widget.onMorph(widget.suffix);
                          },
                          onHorizontalDragUpdate: (details) {
                            if (widget.isBlocked || _isFusing || maxSlide <= 0) {
                              return;
                            }
                            // Suffix drags right (+dx), Prefix drags left (-dx) towards word
                            final deltaStep = isPrefix
                                ? -details.delta.dx / maxSlide
                                : details.delta.dx / maxSlide;

                            _progress.value =
                                (_progress.value + deltaStep).clamp(0.0, 1.0);

                            if (_progress.value > 0.2) {
                              widget.onHover(widget.index);
                            } else {
                              widget.onHover(null);
                            }

                            if (_progress.value >= 0.95 && !_isFusing) {
                              _isFusing = true;
                              widget.onMorph(widget.suffix);
                            }
                          },
                          onHorizontalDragEnd: (_) {
                            widget.onHover(null);
                            if (!_isFusing) {
                              _progress.value = 0.0;
                            }
                          },
                          child: _HandleDecoration(
                            color: widget.color,
                            suffix: widget.suffix,
                            isBlocked: widget.isBlocked,
                            width: handleWidth,
                            isPrefix: isPrefix,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RailPathIndicators extends StatelessWidget {
  final bool isDark;
  final Color color;
  final bool isPrefix;

  const _RailPathIndicators({
    required this.isDark,
    required this.color,
    required this.isPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final guideColor = isDark ? Colors.white12 : Colors.black12;

    if (isPrefix) {
      // Prefix attaches towards the LEFT side (start of word)
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                color: color.withValues(alpha: 0.5),
                size: 20.r,
              ),
              Icon(Icons.chevron_left_rounded, color: guideColor, size: 18.r),
              Icon(Icons.chevron_left_rounded, color: guideColor, size: 18.r),
              Icon(Icons.chevron_left_rounded, color: guideColor, size: 18.r),
              Icon(Icons.drag_indicator_rounded, color: guideColor, size: 16.r),
            ],
          ),
        ),
      );
    }

    // Suffix attaches towards the RIGHT side (end of word)
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.drag_indicator_rounded, color: guideColor, size: 16.r),
            Icon(Icons.chevron_right_rounded, color: guideColor, size: 18.r),
            Icon(Icons.chevron_right_rounded, color: guideColor, size: 18.r),
            Icon(Icons.chevron_right_rounded, color: guideColor, size: 18.r),
            Icon(
              Icons.add_circle_outline_rounded,
              color: color.withValues(alpha: 0.5),
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}

class _HandleDecoration extends StatelessWidget {
  final Color color;
  final String suffix;
  final bool isBlocked;
  final double width;
  final bool isPrefix;

  const _HandleDecoration({
    required this.color,
    required this.suffix,
    required this.isBlocked,
    required this.width,
    required this.isPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final handleColor = isBlocked ? color.withValues(alpha: 0.5) : color;
    return Container(
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: isPrefix ? Alignment.topRight : Alignment.topLeft,
          end: isPrefix ? Alignment.bottomLeft : Alignment.bottomRight,
          colors: [handleColor, handleColor.withValues(alpha: 0.85)],
        ),
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: handleColor.withValues(alpha: isBlocked ? 0.12 : 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isPrefix) ...[
              const Icon(
                Icons.drag_indicator_rounded,
                color: Colors.white70,
                size: 16,
              ),
              SizedBox(width: 4.w),
            ],
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  suffix.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            if (isPrefix) ...[
              SizedBox(width: 4.w),
              const Icon(
                Icons.drag_indicator_rounded,
                color: Colors.white70,
                size: 16,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
