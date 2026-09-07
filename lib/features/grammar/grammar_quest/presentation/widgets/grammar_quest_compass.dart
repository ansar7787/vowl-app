import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass_components.dart';

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

  final ValueNotifier<double> _needleRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
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
    _needleRotation.dispose();
    _isDragging.dispose();
    _bgRotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GrammarQuestCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset compass needles on new questions or retries
    if (widget.isAnswered == false && oldWidget.isAnswered == true) {
      _needleRotation.value = 0.0;
      _isDragging.value = false;
      _lastHapticQuadrant = -1;
    }
  }

  void _handleDragUpdate(DragUpdateDetails details, Offset center) {
    if (widget.isAnswered) return;

    final localPosition = details.localPosition;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    _needleRotation.value = math.atan2(dy, dx) + (math.pi / 2);
    _isDragging.value = true;

    // Subtle tick when passing near quadrants
    final normalizedAngle =
        (_needleRotation.value % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
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

    _isDragging.value = false;

    // Normalize rotation and find nearest quadrant
    final normalizedAngle =
        (_needleRotation.value % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final index = (normalizedAngle / (math.pi / 2)).round() % 4;

    // Snap needle to quadrant center
    _needleRotation.value = (index * (math.pi * 2) / 4);

    widget.onQuadrantSelect(index);
  }

  void _handleTapUp(TapUpDetails details, Offset center) {
    if (widget.isAnswered) return;

    final localPosition = details.localPosition;
    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;

    final tapAngle = math.atan2(dy, dx) + (math.pi / 2);
    final normalizedAngle =
        (tapAngle % (2 * math.pi) + (2 * math.pi)) % (2 * math.pi);
    final index = (normalizedAngle / (math.pi / 2)).round() % 4;

    _needleRotation.value = (index * (math.pi * 2) / 4);
    widget.onQuadrantSelect(index);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCompact ? 180.r : 280.r;
    final center = Offset(size / 2, size / 2);
    final needleHeight = widget.isCompact ? 110.h : 170.h;

    return GestureDetector(
      onTapUp: (details) => _handleTapUp(details, center),
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
            CompassHolographicRing(
              size: size,
              primaryColor: widget.primaryColor,
              turns: _bgRotationController,
            ),
            CompassStaticDial(size: size, primaryColor: widget.primaryColor),
            ...List.generate(4, (index) {
              final angle = index * (math.pi * 2) / 4;
              final optionText = index < widget.options.length
                  ? widget.options[index]
                  : "";

              return ValueListenableBuilder<double>(
                valueListenable: _needleRotation,
                builder: (context, needleRotation, _) {
                  final isSelected =
                      widget.isAnswered &&
                      (index ==
                          ((needleRotation % (2 * math.pi) + 2 * math.pi) %
                                      (2 * math.pi) /
                                      (math.pi / 2))
                                  .round() %
                              4);
                  return CompassQuadrant(
                    angle: angle,
                    optionText: optionText,
                    isSelected: isSelected,
                    size: size,
                    primaryColor: widget.primaryColor,
                    isDark: widget.isDark,
                    isCompact: widget.isCompact,
                  );
                },
              );
            }),
            ValueListenableBuilder<bool>(
              valueListenable: _isDragging,
              builder: (context, isDragging, _) {
                return ValueListenableBuilder<double>(
                  valueListenable: _needleRotation,
                  builder: (context, needleRotation, _) {
                    return CompassPhotonNeedle(
                      needleRotation: needleRotation,
                      isDragging: isDragging,
                      needleHeight: needleHeight,
                      primaryColor: widget.primaryColor,
                      isCompact: widget.isCompact,
                    );
                  },
                );
              },
            ),
            CompassCentralHub(
              size: size,
              primaryColor: widget.primaryColor,
              isCompact: widget.isCompact,
            ),
          ],
        ),
      ),
    );
  }
}
