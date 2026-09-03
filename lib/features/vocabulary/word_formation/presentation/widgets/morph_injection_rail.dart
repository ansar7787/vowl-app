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

  const MorphInjectionRail({
    super.key,
    required this.index,
    required this.suffix,
    required this.color,
    required this.isDark,
    required this.isBlocked,
    required this.onMorph,
    required this.onHover,
  });

  @override
  State<MorphInjectionRail> createState() => _MorphInjectionRailState();
}

class _MorphInjectionRailState extends State<MorphInjectionRail> {
  final ValueNotifier<double> _progress = ValueNotifier(0.0);
  bool _isFusing = false;

  @override
  void didUpdateWidget(MorphInjectionRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isBlocked != oldWidget.isBlocked && !widget.isBlocked) {
      _progress.value = 0.0;
      _isFusing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final railWidth = constraints.maxWidth > 0
            ? constraints.maxWidth
            : 1.sw - 48.w;
        final handleWidth = 110.w;
        final maxSlide = railWidth - handleWidth;

        return Container(
          decoration: BoxDecoration(
            color: widget.isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              if (!widget.isDark)
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.r),
            child: Stack(
              children: [
                // Rail Path - Static background indicators
                _RailPathIndicators(isDark: widget.isDark),

                // Dynamic Energy Glow - Positioned with ValueListenable
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, value, _) {
                    return Positioned(
                      left: (value * maxSlide) - 20.w,
                      child: Container(
                        width: handleWidth + 40.w,
                        height: constraints.maxHeight,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              widget.color.withValues(alpha: 0.2),
                              widget.color.withValues(alpha: 0.0),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                    );
                  },
                ),

                // The Handle - Optimized interaction
                ValueListenableBuilder<double>(
                  valueListenable: _progress,
                  builder: (context, value, _) {
                    return Positioned(
                      left: value * maxSlide,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.isBlocked || _isFusing) return;
                          _progress.value = 1.0;
                          _isFusing = true;
                          widget.onMorph(widget.suffix);
                        },
                        onHorizontalDragUpdate: (details) {
                          if (widget.isBlocked || _isFusing) return;
                          _progress.value =
                              (_progress.value + details.delta.dx / maxSlide)
                                  .clamp(0.0, 1.0);

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
  const _RailPathIndicators({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final iconColor = isDark ? Colors.white12 : Colors.black12;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(Icons.drag_handle_rounded, color: iconColor, size: 20),
            Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
            Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
            Icon(Icons.chevron_right_rounded, color: iconColor, size: 20),
            Icon(Icons.bolt_rounded, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }
}

class _HandleDecoration extends StatelessWidget {
  final Color color;
  final String suffix;
  const _HandleDecoration({required this.color, required this.suffix});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110.w,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(22.r),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
            const Icon(
              Icons.drag_indicator_rounded,
              color: Colors.white70,
              size: 18,
            ),
            SizedBox(width: 4.w),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  suffix.toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
