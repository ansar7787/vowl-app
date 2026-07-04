import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'dialect_drill_radar_painter.dart';
import 'dialect_drill_transmission_tower.dart';
import 'dialect_drill_data_probe_pin.dart';

class DialectDrillHologramConsole extends StatefulWidget {
  final AccentQuest quest;
  final Color color;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final VoidCallback onPlayTargetAudio;
  final Function(int selectedIndex, int correctIndex, double maxWidth)
  onSubmitAnswer;

  const DialectDrillHologramConsole({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrect,
    required this.onPlayTargetAudio,
    required this.onSubmitAnswer,
  });

  @override
  State<DialectDrillHologramConsole> createState() =>
      _DialectDrillHologramConsoleState();
}

class _DialectDrillHologramConsoleState
    extends State<DialectDrillHologramConsole>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  late AnimationController _radarController;

  bool _isPinInitialized = false;
  double _pinX = 0;
  double _pinY = 0;
  int? _hoveredTowerIndex;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant DialectDrillHologramConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest ||
        (!widget.isAnswered && oldWidget.isAnswered)) {
      setState(() {
        _isPinInitialized = false;
        _hoveredTowerIndex = null;
      });
    }
    // When answered, optionally lock pin
    if (widget.isAnswered &&
        _hoveredTowerIndex != null &&
        MediaQuery.of(context).size.width > 0) {
      final maxWidth =
          MediaQuery.of(context).size.width - 32.w; // approx container width
      _pinX = (maxWidth / 2) + (_hoveredTowerIndex == 0 ? -110.w : 110.w);
      _pinY = 220.h;
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  void _onPinDragUpdate(DragUpdateDetails details, double maxWidth) {
    if (widget.isAnswered) return;
    setState(() {
      _pinX += details.delta.dx;
      _pinY += details.delta.dy;

      // Clamp boundaries inside coordinates zone
      _pinX = _pinX.clamp(20.w, maxWidth - 20.w);
      _pinY = _pinY.clamp(40.h, 450.h);
    });

    _checkTowerHover(maxWidth);
  }

  void _checkTowerHover(double maxWidth) {
    double leftTargetX = (maxWidth / 2) - 110.w;
    double rightTargetX = (maxWidth / 2) + 110.w;
    double targetY = 220.h;

    double distanceToLeft = math.sqrt(
      math.pow(_pinX - leftTargetX, 2) + math.pow(_pinY - targetY, 2),
    );
    double distanceToRight = math.sqrt(
      math.pow(_pinX - rightTargetX, 2) + math.pow(_pinY - targetY, 2),
    );

    if (distanceToLeft < 60.r) {
      if (_hoveredTowerIndex != 0) {
        _hapticService.selection();
        setState(() => _hoveredTowerIndex = 0);
      }
    } else if (distanceToRight < 60.r) {
      if (_hoveredTowerIndex != 1) {
        _hapticService.selection();
        setState(() => _hoveredTowerIndex = 1);
      }
    } else {
      if (_hoveredTowerIndex != null) {
        setState(() => _hoveredTowerIndex = null);
      }
    }
  }

  void _onPinDragEnd(double maxWidth, int correctIndex) {
    if (widget.isAnswered) return;

    if (_hoveredTowerIndex == null) {
      // Return pin to starting position
      setState(() {
        _pinX = maxWidth / 2;
        _pinY = 380.h;
      });
      return;
    }

    widget.onSubmitAnswer(_hoveredTowerIndex!, correctIndex, maxWidth);
  }

  @override
  Widget build(BuildContext context) {
    final Color outerGlow = widget.color.withValues(alpha: 0.3);

    return Container(
      width: 1.sw,
      height: 480.h,
      decoration: BoxDecoration(
        color: widget.isDark
            ? const Color(0xFF0F0F1B)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(36.r),
        border: Border.all(
          color: widget.color.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(color: outerGlow, blurRadius: 20, spreadRadius: -5),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36.r),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_isPinInitialized) {
              _pinX = constraints.maxWidth / 2;
              _pinY = 380.h;
              _isPinInitialized = true;
            }

            return Stack(
              children: [
                AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: HologramRadarPainter(
                        sweepAngle: _radarController.value * 2 * math.pi,
                        themeColor: widget.color,
                        isDark: widget.isDark,
                      ),
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  },
                ),

                Center(
                  child: Transform.translate(
                    offset: Offset(0, -140.h),
                    child: ScaleButton(
                      onTap: widget.onPlayTargetAudio,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 32.w,
                          vertical: 16.h,
                        ),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: widget.color.withValues(alpha: 0.3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.2),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.volume_up_rounded,
                              color: widget.color,
                              size: 28.r,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              widget.quest.word ?? "",
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 28.sp,
                                fontWeight: FontWeight.w900,
                                color: widget.color,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                DialectDrillTransmissionTower(
                  index: 0,
                  label:
                      widget.quest.options != null &&
                          widget.quest.options!.isNotEmpty
                      ? widget.quest.options![0]
                      : "TRANS 01",
                  maxWidth: constraints.maxWidth,
                  color: widget.color,
                  isDark: widget.isDark,
                  isHovered: _hoveredTowerIndex == 0,
                  isAnswered: widget.isAnswered,
                  isCorrect: widget.isCorrect,
                  hoveredTowerIndex: _hoveredTowerIndex,
                ),
                DialectDrillTransmissionTower(
                  index: 1,
                  label:
                      widget.quest.options != null &&
                          widget.quest.options!.length > 1
                      ? widget.quest.options![1]
                      : "TRANS 02",
                  maxWidth: constraints.maxWidth,
                  color: widget.color,
                  isDark: widget.isDark,
                  isHovered: _hoveredTowerIndex == 1,
                  isAnswered: widget.isAnswered,
                  isCorrect: widget.isCorrect,
                  hoveredTowerIndex: _hoveredTowerIndex,
                ),

                DialectDrillDataProbePin(
                  color: widget.color,
                  isAnswered: widget.isAnswered,
                  isCorrect: widget.isCorrect,
                  hasTargetGlow: _hoveredTowerIndex != null,
                  pinX: _pinX,
                  pinY: _pinY,
                  maxWidth: constraints.maxWidth,
                  correctIndex: widget.quest.correctAnswerIndex ?? 0,
                  onPinDragUpdate: _onPinDragUpdate,
                  onPinDragEnd: _onPinDragEnd,
                ),
              ],
            );
          },
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }
}
