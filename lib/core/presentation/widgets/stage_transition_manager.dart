import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/game_scaffold.dart';

/// Defines the current stage of the game.
enum GameStage {
  /// The initial context/briefing screen showing pedagogical data.
  stage1,

  /// The active game mechanism screen (e.g., swiping cards, typing).
  stage2,
}

/// A manager widget that seamlessly transitions between Stage 1 and Stage 2.
/// It uses an [AnimatedSwitcher] and listens to a [ValueNotifier] to avoid [setState].
class StageTransitionManager extends StatelessWidget {
  /// The ValueNotifier controlling the current stage.
  final ValueNotifier<GameStage> stageNotifier;

  /// Builder for the first stage (Context/Briefing).
  final WidgetBuilder stage1Builder;

  /// Builder for the second stage (Game Mechanism).
  final WidgetBuilder? stage2Builder;

  /// Optional transition duration.
  final Duration transitionDuration;

  const StageTransitionManager({
    super.key,
    required this.stageNotifier,
    required this.stage1Builder,
    this.stage2Builder,
    this.transitionDuration = const Duration(milliseconds: 500),
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GameStage>(
      valueListenable: stageNotifier,
      builder: (context, currentStage, _) {
        return AnimatedSwitcher(
          duration: transitionDuration,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            // A seamless fade and slight scale transition
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: _buildCurrentStage(context, currentStage),
        );
      },
    );
  }

  Widget _buildCurrentStage(BuildContext context, GameStage stage) {
    if (stage == GameStage.stage2 && stage2Builder != null) {
      return KeyedSubtree(
        key: const ValueKey('stage2'),
        child: stage2Builder!(context),
      );
    }

    return KeyedSubtree(
      key: const ValueKey('stage1'),
      child: stage1Builder(context),
    );
  }
}
