import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
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
    extends State<DialectDrillHologramConsole> {
  final _hapticService = di.sl<HapticService>();
  int? _hoveredTowerIndex;

  @override
  void didUpdateWidget(covariant DialectDrillHologramConsole oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest != widget.quest ||
        (!widget.isAnswered && oldWidget.isAnswered)) {
      setState(() {
        _hoveredTowerIndex = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScaleButton(
          onTap: widget.onPlayTargetAudio,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: widget.color.withValues(alpha: 0.3)),
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
                Icon(Icons.volume_up_rounded, color: widget.color, size: 28.r),
                SizedBox(width: 8.w),
                Text(
                  context
                      .tr('games.play_audio', fallback: 'PLAY AUDIO')
                      .toUpperCase(),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w900,
                    color: widget.color,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 48.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [_buildDragTarget(0), _buildDragTarget(1)],
        ),
        SizedBox(height: 48.h),
        if (!widget.isAnswered)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Draggable<int>(
                data: 0,
                onDragStarted: () => _hapticService.selection(),
                onDraggableCanceled: (_, _) => _hapticService.error(),
                feedback: Material(
                  color: Colors.transparent,
                  child: DialectDrillDataProbePin(
                    color: widget.color,
                    isAnswered: widget.isAnswered,
                    isCorrect: widget.isCorrect,
                    hasTargetGlow: _hoveredTowerIndex != null,
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
                  hasTargetGlow: _hoveredTowerIndex != null,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                "DRAG PIN TO SELECT",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: widget.color.withValues(alpha: 0.6),
                ),
              ).animate().fadeIn().slideY(begin: 0.2),
            ],
          )
        else
          SizedBox(height: 64.r),
      ],
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildDragTarget(int index) {
    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        if (!widget.isAnswered) {
          if (_hoveredTowerIndex != index) {
            _hapticService.selection();
            setState(() => _hoveredTowerIndex = index);
          }
          return true;
        }
        return false;
      },
      onLeave: (data) {
        if (_hoveredTowerIndex == index) {
          setState(() => _hoveredTowerIndex = null);
        }
      },
      onAcceptWithDetails: (details) {
        final correctIndex = widget.quest.correctAnswerIndex ?? 0;
        widget.onSubmitAnswer(
          index,
          correctIndex,
          MediaQuery.of(context).size.width,
        );
        setState(() => _hoveredTowerIndex = index); // Lock selection visually
      },
      builder: (context, candidateData, rejectedData) {
        String label =
            widget.quest.options != null && widget.quest.options!.length > index
            ? widget.quest.options![index]
            : "TRANS 0${index + 1}";

        label = label.replaceAll(RegExp(r'\s*\(American\)|\s*\(British\)'), '');

        return DialectDrillTransmissionTower(
          index: index,
          label: label,
          maxWidth: MediaQuery.of(context).size.width,
          color: widget.color,
          isDark: widget.isDark,
          isHovered: _hoveredTowerIndex == index || candidateData.isNotEmpty,
          isAnswered: widget.isAnswered,
          isCorrect: widget.isCorrect,
          hoveredTowerIndex: _hoveredTowerIndex,
        );
      },
    );
  }
}
