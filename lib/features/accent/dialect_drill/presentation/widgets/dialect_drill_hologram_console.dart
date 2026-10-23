import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/theme/vowl_motion.dart';
import 'dialect_drill_transmission_tower.dart';
import 'dialect_drill_data_probe_pin.dart';

/// Interactive holographic console hosting audio sample playback and transmission tower options.
class DialectDrillHologramConsole extends StatefulWidget {
  /// The active accent quest entity.
  final AccentQuest quest;

  /// Theme accent color.
  final Color color;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether the trial has been answered.
  final bool isAnswered;

  /// Evaluation outcome of the answer (`null` if unanswered).
  final bool? isCorrect;

  /// Callback executed to trigger target pronunciation audio playback.
  final VoidCallback onPlayTargetAudio;

  /// Callback executed when the learner selects a dialect tower.
  final Function(int selectedIndex, int correctIndex, double maxWidth)
  onSubmitAnswer;

  /// Creates a [DialectDrillHologramConsole] widget.
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
    extends State<DialectDrillHologramConsole> {
  final _hapticService = di.sl<HapticService>();
  final ValueNotifier<int?> _hoveredTowerIndex = ValueNotifier(null);

  @override
  void didUpdateWidget(covariant DialectDrillHologramConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest ||
        (!widget.isAnswered && oldWidget.isAnswered)) {
      _hoveredTowerIndex.value = null;
    }
  }

  @override
  void dispose() {
    _hoveredTowerIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);

    return ValueListenableBuilder<int?>(
      valueListenable: _hoveredTowerIndex,
      builder: (context, hoveredTowerIndex, child) {
        Widget dragHint = Text(
          "DRAG PIN OR TAP TO SELECT",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
            color: widget.isDark ? Colors.white60 : Colors.black54,
          ),
        );
        if (!reduceMotion) {
          dragHint = dragHint.animate().fadeIn().slideY(begin: 0.15);
        }

        Widget content = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ScaleButton(
              key: const ValueKey('dialect_drill_play_audio'),
              onTap: widget.onPlayTargetAudio,
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 22.w,
                  vertical: 12.h,
                ),
                decoration: BoxDecoration(
                  color: widget.color.withValues(
                    alpha: widget.isDark ? 0.15 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: widget.color.withValues(
                      alpha: widget.isDark ? 0.35 : 0.22,
                    ),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(
                        alpha: widget.isDark ? 0.2 : 0.1,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.volume_up_rounded,
                      color: widget.color,
                      size: 22.r,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      context
                          .tr('games.play_audio', fallback: 'Play audio')
                          .toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: widget.color,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDragTarget(0),
                SizedBox(width: 16.w),
                _buildDragTarget(1),
              ],
            ),
            if (!widget.isAnswered) ...[
              SizedBox(height: 24.h),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Draggable<int>(
                    key: const ValueKey('dialect_probe_pin'),
                    data: 0,
                    onDragStarted: () => _hapticService.selection(),
                    onDraggableCanceled: (_, _) => _hapticService.error(),
                    feedback: Material(
                      color: Colors.transparent,
                      child: DialectDrillDataProbePin(
                        color: widget.color,
                        isAnswered: widget.isAnswered,
                        isCorrect: widget.isCorrect,
                        hasTargetGlow: hoveredTowerIndex != null,
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: DialectDrillDataProbePin(
                        color: widget.color,
                        isAnswered: widget.isAnswered,
                        isCorrect: widget.isCorrect,
                        hasTargetGlow: false,
                      ),
                    ),
                    child: DialectDrillDataProbePin(
                      color: widget.color,
                      isAnswered: widget.isAnswered,
                      isCorrect: widget.isCorrect,
                      hasTargetGlow: hoveredTowerIndex != null,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  dragHint,
                ],
              ),
            ],
          ],
        );

        if (!reduceMotion) {
          content = content
              .animate()
              .fadeIn(duration: 350.ms)
              .scale(begin: const Offset(0.97, 0.97));
        }

        return content;
      },
    );
  }

  Widget _buildDragTarget(int index) {
    return GestureDetector(
      key: ValueKey('dialect_tower_$index'),
      onTap: () {
        if (!widget.isAnswered) {
          _hapticService.selection();
          final correctIndex = widget.quest.correctAnswerIndex ?? 0;
          widget.onSubmitAnswer(
            index,
            correctIndex,
            MediaQuery.of(context).size.width,
          );
          _hoveredTowerIndex.value = index;
        }
      },
      child: DragTarget<int>(
        onWillAcceptWithDetails: (details) {
          if (!widget.isAnswered) {
            if (_hoveredTowerIndex.value != index) {
              _hapticService.selection();
              _hoveredTowerIndex.value = index;
            }
            return true;
          }
          return false;
        },
        onLeave: (data) {
          if (_hoveredTowerIndex.value == index) {
            _hoveredTowerIndex.value = null;
          }
        },
        onAcceptWithDetails: (details) {
          final correctIndex = widget.quest.correctAnswerIndex ?? 0;
          widget.onSubmitAnswer(
            index,
            correctIndex,
            MediaQuery.of(context).size.width,
          );
          _hoveredTowerIndex.value = index; // Lock selection visually
        },
        builder: (context, candidateData, rejectedData) {
          String label =
              widget.quest.options != null &&
                      widget.quest.options!.length > index
                  ? widget.quest.options![index]
                  : "Option 0${index + 1}";

          label = label.replaceAll(
            RegExp(r'\s*\(American\)|\s*\(British\)'),
            '',
          );

          return DialectDrillTransmissionTower(
            index: index,
            label: label,
            maxWidth: MediaQuery.of(context).size.width,
            color: widget.color,
            isDark: widget.isDark,
            isHovered:
                _hoveredTowerIndex.value == index || candidateData.isNotEmpty,
            isAnswered: widget.isAnswered,
            isCorrect: widget.isCorrect,
            hoveredTowerIndex: _hoveredTowerIndex.value,
          );
        },
      ),
    );
  }
}
