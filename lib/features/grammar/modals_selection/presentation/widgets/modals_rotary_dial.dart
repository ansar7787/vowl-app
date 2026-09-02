import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ModalsRotaryDial extends StatefulWidget {
  final List<String> options;
  final bool isAnswered;
  final bool isDark;
  final Color primaryColor;
  final ValueChanged<int> onSelectionChanged;
  final bool isCompact;

  const ModalsRotaryDial({
    super.key,
    required this.options,
    required this.isAnswered,
    required this.isDark,
    required this.primaryColor,
    required this.onSelectionChanged,
    this.isCompact = false,
  });

  @override
  State<ModalsRotaryDial> createState() => _ModalsRotaryDialState();
}

class _ModalsRotaryDialState extends State<ModalsRotaryDial> {
  final _hapticService = di.sl<HapticService>();
  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  double _panStartAngle = 0.0;
  final ValueNotifier<int> _selectedIndex = ValueNotifier(0);

  @override
  void dispose() {
    _rotation.dispose();
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ModalsRotaryDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset on new question (detected by isAnswered going from true to false)
    if (!widget.isAnswered && oldWidget.isAnswered) {
      _rotation.value = 0.0;
      _selectedIndex.value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final outerSize = widget.isCompact ? 180.r : 280.r;
    final physicalDialSize = widget.isCompact ? 110.r : 170.r;
    final dialOffset = widget.isCompact ? 80.r : 125.r;
    final gestureCenter = Offset(physicalDialSize / 2, physicalDialSize / 2);

    return ListenableBuilder(
      listenable: Listenable.merge([_rotation, _selectedIndex]),
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outer Halo
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.05),
                  width: 2.r,
                ),
              ),
            ),
            // Dial Words (Holographic Ring)
            ...List.generate(widget.options.length, (i) {
              final angle = (i * (2 * pi / widget.options.length)) - (pi / 2);
              final isSelected = _selectedIndex.value == i;
              return Transform.translate(
                offset: Offset(
                  cos(angle) * dialOffset,
                  sin(angle) * dialOffset,
                ),
                child: AnimatedScale(
                  duration: 300.ms,
                  scale: isSelected ? (widget.isCompact ? 1.15 : 1.25) : 0.9,
                  child: AnimatedDefaultTextStyle(
                    duration: 300.ms,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: widget.isCompact ? 12.sp : 16.sp,
                      fontWeight: isSelected
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSelected
                          ? widget.primaryColor
                          : (widget.isDark ? Colors.white30 : Colors.black26),
                      letterSpacing: 1,
                    ),
                    child: Text(widget.options[i]),
                  ),
                ),
              );
            }),
            // The Physical Dial (Glass Morph)
            GestureDetector(
              onPanStart: (details) {
                if (widget.isAnswered) return;
                final pos = details.localPosition;
                _panStartAngle =
                    atan2(
                      pos.dy - gestureCenter.dy,
                      pos.dx - gestureCenter.dx,
                    ) -
                    _rotation.value;
              },
              onPanUpdate: (details) {
                if (widget.isAnswered) return;
                final pos = details.localPosition;
                final currentAngle = atan2(
                  pos.dy - gestureCenter.dy,
                  pos.dx - gestureCenter.dx,
                );
                final newRotation = currentAngle - _panStartAngle;

                final count = widget.options.length;
                final normalizedRot = (newRotation + pi / 2) % (2 * pi);
                final rawIndex =
                    (count - (normalizedRot / (2 * pi) * count).round()) %
                    count;
                final selected = rawIndex.clamp(0, count - 1);

                if (selected != _selectedIndex.value) {
                  _hapticService.selection();
                  widget.onSelectionChanged(selected);
                }

                _rotation.value = newRotation;
                _selectedIndex.value = selected;
              },
              child: Transform.rotate(
                angle: _rotation.value,
                child: Container(
                  width: physicalDialSize,
                  height: physicalDialSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDark
                          ? [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.02),
                            ]
                          : [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.01),
                            ],
                    ),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: widget.isCompact ? 10 : 20,
                        offset: const Offset(5, 5),
                      ),
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Indicators (Glass Etchings)
                      ...List.generate(
                        24,
                        (i) => Transform.rotate(
                          angle: i * (2 * pi / 24),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 2.r,
                              height: widget.isCompact ? 4.r : 8.r,
                              margin: EdgeInsets.only(
                                top: widget.isCompact ? 6.r : 10.r,
                              ),
                              color: widget.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      // The Glowing Pointer
                      Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: widget.isCompact ? 4.r : 6.r,
                          height: widget.isCompact ? 22.r : 35.r,
                          margin: EdgeInsets.only(
                            top: widget.isCompact ? 10.r : 15.r,
                          ),
                          decoration: BoxDecoration(
                            color: widget.primaryColor,
                            borderRadius: BorderRadius.circular(3.r),
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor,
                                blurRadius: 15,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
