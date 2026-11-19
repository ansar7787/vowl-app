import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_phase.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Renders a compact 3-dot or chip progress indicator showing completion of
/// Learn, Practice, and Test phases.
///
/// If [hideIfEmpty] is true and no phases are completed, renders [SizedBox.shrink]
/// to guarantee zero visual pollution on untouched legacy levels.
class PhaseProgressIndicator extends StatelessWidget {
  /// Set of completed phase identifiers (e.g. {'learn', 'practice'}).
  final Set<String> completedPhases;

  /// Whether to render nothing if [completedPhases] is empty.
  final bool hideIfEmpty;

  /// Optional active tint color for the dots. Defaults to [AppColors.indigo500].
  final Color? activeColor;

  /// Dot diameter.
  final double dotSize;

  const PhaseProgressIndicator({
    super.key,
    required this.completedPhases,
    this.hideIfEmpty = false,
    this.activeColor,
    this.dotSize = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    if (hideIfEmpty && completedPhases.isEmpty) {
      return const SizedBox.shrink();
    }

    final color = activeColor ?? AppColors.indigo500;
    final phases = [GamePhase.learn, GamePhase.practice, GamePhase.mastery];

    return Semantics(
      label: 'Phase progress: ${completedPhases.length} of 3 phases complete',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: phases.map((phase) {
          final isDone = completedPhases.contains(phase.name) ||
              (phase == GamePhase.mastery && completedPhases.contains('test'));
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            width: dotSize.r,
            height: dotSize.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDone ? color : color.withValues(alpha: 0.25),
              boxShadow: isDone
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 3.r,
                        spreadRadius: 1.r,
                      ),
                    ]
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}
