import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TopicDraggableWord extends StatefulWidget {
  final String word;
  final Function(double velocity) onFlick;
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
      onHorizontalDragStart: (_) => _isDragging.value = true,
      onHorizontalDragUpdate: (details) {
        _dragOffset.value += details.delta.dx;
      },
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity.abs() > 500 || _dragOffset.value.abs() > 60) {
          // Lower threshold for extra small card
          widget.onFlick(
            velocity != 0 ? velocity : (_dragOffset.value > 0 ? 1000 : -1000),
          );
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
                    width: 140.w, // Extra Small
                    height: 70.h, // Extra Small
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: widget.primaryColor.withValues(
                            alpha: _isDragging.value ? 0.4 : 0.2,
                          ),
                          blurRadius: _isDragging.value ? 20 : 10,
                          spreadRadius: _isDragging.value ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        widget.word.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp, // Reduced font for extra small card
                          fontWeight: FontWeight.bold,
                          color: widget.isDark ? Colors.white : Colors.black87,
                          letterSpacing: 1,
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
}
