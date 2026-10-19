import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopicDraggableWord extends StatefulWidget {
  final String word;
  final Function(double velocity, double dropOffset) onFlick;
  final Color primaryColor;
  final bool isDark;

  const TopicDraggableWord({
    super.key,
    required this.word,
    required this.onFlick,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  State<TopicDraggableWord> createState() => _TopicDraggableWordState();
}

class _TopicDraggableWordState extends State<TopicDraggableWord> {
  final ValueNotifier<double> _dragOffset = ValueNotifier(0);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);

  @override
  void dispose() {
    _dragOffset.dispose();
    _isDragging.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _isDragging.value = true,
      onHorizontalDragUpdate: (details) {
        _dragOffset.value += details.delta.dx;
      },
      onHorizontalDragCancel: () {
        _dragOffset.value = 0;
        _isDragging.value = false;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 500 || _dragOffset.value.abs() > 60) {
          // Determine intent: If flicked hard, trust velocity.
          // If dragged into position (velocity low but offset high), trust offset.
          final double intentVelocity = velocity.abs() > 500
              ? velocity
              : (_dragOffset.value > 0 ? 1000 : -1000);

          widget.onFlick(intentVelocity, _dragOffset.value);
        }
        _dragOffset.value = 0;
        _isDragging.value = false;
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([_dragOffset, _isDragging]),
        builder: (context, _) {
          return Transform.translate(
                offset: Offset(_dragOffset.value, 0),
                child: Transform.rotate(
                  angle: _dragOffset.value / 500,
                  child: Container(
                    width: 156.w,
                    height: 64.h,
                    decoration: BoxDecoration(
                      color: widget.isDark ? AppColors.slate800 : Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: widget.primaryColor.withValues(
                          alpha: _isDragging.value ? 0.8 : 0.4,
                        ),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(
                            alpha: _isDragging.value ? 0.35 : 0.15,
                          ),
                          blurRadius: _isDragging.value ? 16 : 8,
                          spreadRadius: _isDragging.value ? 2 : 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _formatWord(widget.word),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .animate(target: _isDragging.value ? 1 : 0)
              .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
        },
      ),
    );
  }

  String _formatWord(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((segment) {
      if (segment.isEmpty) return segment;
      return '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
