import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

/// Interactive rotary dial widget enabling angular selection of modal verbs.
class ModalsRotaryDial extends StatefulWidget {
  /// Candidate modal verb options.
  final List<String> options;

  /// Notifier signaling whether the question has been answered.
  final ValueNotifier<bool> isAnsweredNotifier;

  /// Notifier signaling pending confirmation state.
  final ValueNotifier<bool> pendingJigsawNotifier;

  /// Notifier tracking the selected modal verb index.
  final ValueNotifier<int> selectedIndexNotifier;

  /// Index of the correct modal option.
  final int correctAnswerIndex;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Theme accent color.
  final Color primaryColor;

  /// Creates a [ModalsRotaryDial] widget.
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
    widget.isAnsweredNotifier.removeListener(_onAnsweredChanged);
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
    if (widget.options.isNotEmpty &&
        widget.selectedIndexNotifier.value >= widget.options.length) {
      widget.selectedIndexNotifier.value = 0;
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
    if (widget.selectedIndexNotifier.value >= count) return;

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
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
        );
    _snapController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final outerSize = 250.r;
    final physicalDialSize = 150.r;
    final dialOffset = 110.r;
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
          key: const ValueKey('modals_rotary_dial'),
          alignment: Alignment.center,
          children: [
            // Outer Halo
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.08),
                  width: 1.5.r,
                ),
              ),
            ),
            // Dial Words (Options Ring)
            ...List.generate(widget.options.length, (i) {
              final angle = (i * (2 * pi / widget.options.length)) - (pi / 2);
              final isSelected = widget.selectedIndexNotifier.value == i;
              return Transform.translate(
                offset: Offset(
                  cos(angle) * dialOffset,
                  sin(angle) * dialOffset,
                ),
                child: GestureDetector(
                  key: ValueKey('modal_option_$i'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (_isLocked) return;
                    if (widget.selectedIndexNotifier.value != i) {
                      _hapticService.selection();
                      widget.selectedIndexNotifier.value = i;
                      _snapToCurrentIndex();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? widget.primaryColor.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: AnimatedScale(
                      duration: reduceMotion ? Duration.zero : 250.ms,
                      scale: isSelected ? 1.12 : 0.95,
                      child: AnimatedDefaultTextStyle(
                        duration: reduceMotion ? Duration.zero : 250.ms,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 15.sp,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: isSelected
                              ? widget.primaryColor
                              : (widget.isDark
                                  ? Colors.white.withValues(alpha: 0.65)
                                  : Colors.black.withValues(alpha: 0.60)),
                          letterSpacing: 0.5,
                        ),
                        child: Text(widget.options[i]),
                      ),
                    ),
                  ),
                ),
              );
            }),
            // The Physical Dial (Glass Morph)
            GestureDetector(
              key: const ValueKey('modals_rotary_dial_gesture'),
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
                      color: widget.primaryColor.withValues(alpha: 0.22),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(4, 4),
                      ),
                      BoxShadow(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Indicators (Etchings)
                      ...List.generate(
                        24,
                        (i) => Transform.rotate(
                          angle: i * (2 * pi / 24),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 2.r,
                              height: 7.r,
                              margin: EdgeInsets.only(top: 8.r),
                              color: widget.primaryColor.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                      // Center Pivot Knob
                      Container(
                        width: 24.r,
                        height: 24.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.primaryColor.withValues(alpha: 0.15),
                          border: Border.all(
                            color: widget.primaryColor.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                      ),
                      // The Glowing Pointer
                      Align(
                        alignment: Alignment.topCenter,
                        child: isCorrectSelected
                            ? (reduceMotion
                                ? Container(
                                    width: 5.r,
                                    height: 30.r,
                                    margin: EdgeInsets.only(top: 12.r),
                                    decoration: BoxDecoration(
                                      color: widget.primaryColor,
                                      borderRadius: BorderRadius.circular(3.r),
                                      boxShadow: [
                                        BoxShadow(
                                          color: widget.primaryColor,
                                          blurRadius: 15,
                                          spreadRadius: 2,
                                        ),
                                      ],
                                    ),
                                  )
                                : Container(
                                        width: 5.r,
                                        height: 30.r,
                                        margin: EdgeInsets.only(top: 12.r),
                                        decoration: BoxDecoration(
                                          color: widget.primaryColor,
                                          borderRadius:
                                              BorderRadius.circular(3.r),
                                          boxShadow: [
                                            BoxShadow(
                                              color: widget.primaryColor,
                                              blurRadius: 12,
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
                                        end: const Offset(1.15, 1.05),
                                        duration: 600.ms,
                                        curve: Curves.easeInOut,
                                      )
                                      .boxShadow(
                                        begin: BoxShadow(
                                          color: widget.primaryColor,
                                          blurRadius: 12,
                                          spreadRadius: 1,
                                        ),
                                        end: BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.4,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 3,
                                        ),
                                        duration: 600.ms,
                                        curve: Curves.easeInOut,
                                      ))
                            : Container(
                                width: 5.r,
                                height: 30.r,
                                margin: EdgeInsets.only(top: 12.r),
                                decoration: BoxDecoration(
                                  color: widget.primaryColor,
                                  borderRadius: BorderRadius.circular(3.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: widget.primaryColor,
                                      blurRadius: 12,
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
