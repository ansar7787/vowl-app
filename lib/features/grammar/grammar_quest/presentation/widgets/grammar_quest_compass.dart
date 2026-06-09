import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass_ticks_painter.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentinel_needle_painter.dart';

class GrammarQuestCompass extends StatefulWidget {
  final List<String> options;
  final int correctAnswerIndex;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool? isCorrect;
  final Function(int index) onQuadrantSelect;
  final bool isCompact;

  const GrammarQuestCompass({
    super.key,
    required this.options,
    required this.correctAnswerIndex,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    this.isCorrect,
    required this.onQuadrantSelect,
    this.isCompact = false,
  });

  @override
  State<GrammarQuestCompass> createState() => _GrammarQuestCompassState();
}

class _GrammarQuestCompassState extends State<GrammarQuestCompass>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  late AnimationController _bgRotationController;

  double _needleRotation = 0.0;
  bool _isDragging = false;
  int _lastHapticQuadrant = -1;

  @override
  void initState() {
    super.initState();
    _bgRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _bgRotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrammarQuestCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset compass needles on new questions or retries
    if (widget.isAnswered == false && oldWidget.isAnswered == true) {
      setState(() {
        _needleRotation = 0.0;
        _isDragging = false;
        _lastHapticQuadrant = -1;
      });
    }
  }

  void _handleDragUpdate(DragUpdateDetails details, Offset center) {
    if (widget.isAnswered) return;

    final localPosition = details.localPosition;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    setState(() {
      _needleRotation = math.atan2(dy, dx) + (math.pi / 2);
      _isDragging = true;
    });

    // Subtle tick when passing near quadrants
    final normalizedAngle =
        (_needleRotation % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final nearestQuadrant = (normalizedAngle / (math.pi / 2)).round() % 4;
    final quadrantAngle = nearestQuadrant * (math.pi / 2);
    if ((normalizedAngle - quadrantAngle).abs() < 0.1 &&
        nearestQuadrant != _lastHapticQuadrant) {
      _hapticService.light();
      _lastHapticQuadrant = nearestQuadrant;
    }
  }

  void _handleDragEnd() {
    if (widget.isAnswered) return;

    setState(() => _isDragging = false);

    // Normalize rotation and find nearest quadrant
    final normalizedAngle =
        (_needleRotation % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final index = (normalizedAngle / (math.pi / 2)).round() % 4;

    // Snap needle to quadrant center
    setState(() {
      _needleRotation = (index * (math.pi * 2) / 4);
    });

    widget.onQuadrantSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCompact ? 180.r : 280.r;
    final center = Offset(size / 2, size / 2);
    final needleHeight = widget.isCompact ? 110.h : 170.h;

    return GestureDetector(
      onPanUpdate: (details) => _handleDragUpdate(details, center),
      onPanEnd: (_) => _handleDragEnd(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withValues(alpha: 0.1),
              blurRadius: widget.isCompact ? 20 : 40,
              spreadRadius: widget.isCompact ? 2 : 5,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Outer Rotating Holographic Ring
            RotationTransition(
              turns: _bgRotationController,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    width: 1.r,
                  ),
                ),
                child: CustomPaint(
                  painter: CompassTicksPainter(
                    widget.primaryColor.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
            // Inner Static Dial
            Container(
              width: size * 0.9,
              height: size * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.primaryColor.withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                ),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.15),
                  width: 2.r,
                ),
              ),
            ),
            // Quadrants and Selection Beams
            ...List.generate(4, (index) {
              final angle = index * (math.pi * 2) / 4;
              final optionText = index < widget.options.length ? widget.options[index] : "";
              final isSelected =
                  widget.isAnswered &&
                  (index ==
                      ((_needleRotation % (2 * math.pi) + 2 * math.pi) %
                                  (2 * math.pi) /
                                  (math.pi / 2))
                              .round() %
                          4);

              return Transform.rotate(
                angle: angle,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    // Selection Beam
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 400),
                      opacity: isSelected ? 1.0 : 0.0,
                      child: Container(
                        width: widget.isCompact ? 25.w : 40.w,
                        height: size * 0.45,
                        margin: EdgeInsets.only(bottom: size * 0.45),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              widget.primaryColor.withValues(alpha: 0.0),
                              widget.primaryColor.withValues(alpha: 0.2),
                              widget.primaryColor.withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Option Text (Glass-Morphic Tag - Interior Placement)
                    Positioned(
                      top: size * 0.1, // Positioning inside the dial
                      child: Transform.rotate(
                        angle: -angle,
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 300),
                          scale: isSelected ? 1.1 : 1.0,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: size * 0.35),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(widget.isCompact ? 8.r : 12.r),
                              child: BackdropFilter(
                                filter: ui.ImageFilter.blur(
                                  sigmaX: 8,
                                  sigmaY: 8,
                                ),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: widget.isCompact ? 8.w : 12.w,
                                    vertical: widget.isCompact ? 4.h : 6.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? widget.primaryColor.withValues(alpha: 0.3)
                                        : (widget.isDark
                                              ? Colors.white.withValues(
                                                  alpha: 0.12,
                                                )
                                              : Colors.black.withValues(
                                                  alpha: 0.06,
                                                )),
                                    borderRadius: BorderRadius.circular(widget.isCompact ? 8.r : 12.r),
                                    border: Border.all(
                                      color: isSelected
                                          ? Colors.white
                                          : widget.primaryColor.withValues(alpha: 0.3),
                                      width: 1.5.r,
                                    ),
                                  ),
                                  child: Text(
                                    optionText,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.visible,
                                    style: TextStyle(
                                      fontFamily: 'Outfit', 
                                      fontSize: widget.isCompact ? 8.sp : 10.sp,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected
                                          ? Colors.white
                                          : (widget.isDark
                                                ? Colors.white
                                                : Colors.black87),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // The Tapered Photon Needle
            TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: _isDragging ? 50 : 600),
              curve: _isDragging ? Curves.linear : Curves.elasticOut,
              tween: Tween<double>(begin: 0, end: _needleRotation),
              builder: (context, value, child) {
                return Transform.rotate(angle: value, child: child);
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Needle Shadow
                  Transform.translate(
                    offset: const Offset(3, 3),
                    child: _buildNeedleShape(
                      Colors.black.withValues(alpha: 0.2),
                      needleHeight,
                    ),
                  ),
                  // Asymmetric HUD Vector Needle
                  _buildNeedleShape(widget.primaryColor, needleHeight, isGlass: true),
                  // Pointer Emitter (Top)
                  Positioned(
                    top: widget.isCompact ? 2.h : 5.h,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Pulsing Halo (Visual Feedback)
                        RepaintBoundary(
                          child: Container(
                            width: widget.isCompact ? 16.r : 24.r,
                            height: widget.isCompact ? 16.r : 24.r,
                            decoration: BoxDecoration(
                              color: widget.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              shape: BoxShape.circle,
                            ),
                          )
                          .animate(onPlay: (c) => c.repeat())
                          .scale(
                            begin: const Offset(0.8, 0.8),
                            end: const Offset(1.2, 1.2),
                            duration: 1.seconds,
                          )
                          .fadeOut(),
                        ),
                        // Emitter Core
                        RepaintBoundary(
                          child: Container(
                            width: widget.isCompact ? 8.r : 12.r,
                            height: widget.isCompact ? 8.r : 12.r,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: widget.primaryColor,
                                  blurRadius: 15,
                                  spreadRadius: 4,
                                ),
                                const BoxShadow(
                                  color: Colors.white,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Container(
                                width: widget.isCompact ? 2.r : 4.r,
                                height: widget.isCompact ? 2.r : 4.r,
                                decoration: BoxDecoration(
                                  color: widget.primaryColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Counter-weight (Bottom Orbital - Minimalist)
                  Positioned(
                    bottom: 0,
                    child: Container(
                      width: widget.isCompact ? 10.r : 16.r,
                      height: widget.isCompact ? 10.r : 16.r,
                      decoration: const BoxDecoration(shape: BoxShape.circle),
                      child: Center(
                        child: Container(
                          width: widget.isCompact ? 4.r : 6.r,
                          height: widget.isCompact ? 4.r : 6.r,
                          decoration: BoxDecoration(
                            color: widget.primaryColor.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Central Hub (Refractive Glass)
            Container(
              width: widget.isCompact ? 40.r : 60.r,
              height: widget.isCompact ? 40.r : 60.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.2),
                  width: 1.5.r,
                ),
              ),
              child: Center(
                child: Container(
                  width: widget.isCompact ? 6.r : 10.r,
                  height: widget.isCompact ? 6.r : 10.r,
                  decoration: BoxDecoration(
                    color: widget.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedleShape(Color color, double height, {bool isGlass = false}) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(widget.isCompact ? 20.r : 32.r, height),
        painter: SentinelNeedlePainter(color: color, isGlass: isGlass),
      ),
    );
  }
}
