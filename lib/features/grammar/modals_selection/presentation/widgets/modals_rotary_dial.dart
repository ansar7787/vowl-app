import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class ModalsRotaryDial extends StatefulWidget {
  final List<String> options;
  final ValueNotifier<bool> isAnsweredNotifier;
  final ValueNotifier<bool> pendingJigsawNotifier;
  final ValueNotifier<int> selectedIndexNotifier;
  final int correctAnswerIndex;
  final bool isDark;
  final Color primaryColor;

  const ModalsRotaryDial({
    super.key,
    required this.options,
    required this.isAnsweredNotifier,
    required this.pendingJigsawNotifier,
    required this.selectedIndexNotifier,
    required this.correctAnswerIndex,
    required this.isDark,
    required this.primaryColor,
  });

  @override
  State<ModalsRotaryDial> createState() => _ModalsRotaryDialState();
}

class _ModalsRotaryDialState extends State<ModalsRotaryDial>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  double _panStartAngle = 0.0;
  bool _wasAnswered = false;

  late AnimationController _snapController;
  late Animation<double> _snapAnimation;

  @override
  void initState() {
    super.initState();
    _wasAnswered = widget.isAnsweredNotifier.value;
    widget.isAnsweredNotifier.addListener(_onAnsweredChanged);

    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapController.addListener(() {
      _rotation.value = _snapAnimation.value;
    });
  }

  @override
  void dispose() {
    _snapController.dispose();
    _rotation.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ModalsRotaryDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isAnsweredNotifier != widget.isAnsweredNotifier) {
      oldWidget.isAnsweredNotifier.removeListener(_onAnsweredChanged);
      widget.isAnsweredNotifier.addListener(_onAnsweredChanged);
      _wasAnswered = widget.isAnsweredNotifier.value;
    }
  }

  void _onAnsweredChanged() {
    final isAnsweredNow = widget.isAnsweredNotifier.value;
    if (!isAnsweredNow && _wasAnswered) {
      _snapController.stop();
      _rotation.value = 0.0;
      widget.selectedIndexNotifier.value = 0;
    }
    _wasAnswered = isAnsweredNow;
  }

  bool get _isLocked =>
      widget.isAnsweredNotifier.value || widget.pendingJigsawNotifier.value;

  void _snapToCurrentIndex() {
    if (_isLocked) return;
    final count = widget.options.length;
    if (count == 0) return;

    final targetNormalized =
        widget.selectedIndexNotifier.value * (2 * pi / count);
    final currentRotation = _rotation.value;
    final remainder = currentRotation % (2 * pi);
    final positiveRemainder = remainder < 0 ? remainder + 2 * pi : remainder;

    double targetAngle = currentRotation - positiveRemainder + targetNormalized;

    // Shortest path
    if (targetAngle - currentRotation > pi) {
      targetAngle -= 2 * pi;
    } else if (targetAngle - currentRotation < -pi) {
      targetAngle += 2 * pi;
    }

    _snapAnimation = Tween<double>(begin: currentRotation, end: targetAngle)
        .animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutBack),
        );
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final outerSize = 280.r;
    final physicalDialSize = 170.r;
    final dialOffset = 125.r;
    final gestureCenter = Offset(physicalDialSize / 2, physicalDialSize / 2);

    return ListenableBuilder(
      listenable: Listenable.merge([
        _rotation,
        widget.selectedIndexNotifier,
        widget.isAnsweredNotifier,
        widget.pendingJigsawNotifier,
      ]),
      builder: (context, _) {
        final isCorrectSelected =
            widget.selectedIndexNotifier.value == widget.correctAnswerIndex;

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
              final isSelected = widget.selectedIndexNotifier.value == i;
              return Transform.translate(
                offset: Offset(
                  cos(angle) * dialOffset,
                  sin(angle) * dialOffset,
                ),
                child: AnimatedScale(
                  duration: 300.ms,
                  scale: isSelected ? 1.25 : 0.9,
                  child: AnimatedDefaultTextStyle(
                    duration: 300.ms,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
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
                if (_isLocked) return;
                _snapController.stop();
                final pos = details.localPosition;
                _panStartAngle =
                    atan2(
                      pos.dy - gestureCenter.dy,
                      pos.dx - gestureCenter.dx,
                    ) -
                    _rotation.value;
              },
              onPanUpdate: (details) {
                if (_isLocked) return;
                final pos = details.localPosition;
                final currentAngle = atan2(
                  pos.dy - gestureCenter.dy,
                  pos.dx - gestureCenter.dx,
                );
                final newRotation = currentAngle - _panStartAngle;

                final count = widget.options.length;
                final normalizedRot = newRotation % (2 * pi);
                final positiveRot = normalizedRot < 0
                    ? normalizedRot + 2 * pi
                    : normalizedRot;
                final rawIndex =
                    (positiveRot / (2 * pi / count)).round() % count;

                if (rawIndex != widget.selectedIndexNotifier.value) {
                  _hapticService.selection();
                  widget.selectedIndexNotifier.value = rawIndex;
                }

                _rotation.value = newRotation;
              },
              onPanEnd: (_) => _snapToCurrentIndex(),
              onPanCancel: () => _snapToCurrentIndex(),
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
                        blurRadius: 20,
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
                              height: 8.r,
                              margin: EdgeInsets.only(top: 10.r),
                              color: widget.primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      // The Glowing Pointer
                      Align(
                        alignment: Alignment.topCenter,
                        child: isCorrectSelected
                            ? Container(
                                    width: 6.r,
                                    height: 35.r,
                                    margin: EdgeInsets.only(top: 15.r),
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
                                  )
                                  .animate(
                                    onPlay: (controller) =>
                                        controller.repeat(reverse: true),
                                  )
                                  .scale(
                                    begin: const Offset(1.0, 1.0),
                                    end: const Offset(1.2, 1.1),
                                    duration: 600.ms,
                                    curve: Curves.easeInOut,
                                  )
                                  .boxShadow(
                                    begin: BoxShadow(
                                      color: widget.primaryColor,
                                      blurRadius: 15,
                                      spreadRadius: 1,
                                    ),
                                    end: BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: 4,
                                    ),
                                    duration: 600.ms,
                                    curve: Curves.easeInOut,
                                  )
                            : Container(
                                width: 6.r,
                                height: 35.r,
                                margin: EdgeInsets.only(top: 15.r),
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
