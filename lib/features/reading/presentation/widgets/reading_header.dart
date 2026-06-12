import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

/// Top header bar for the reading game screen.
///
/// Accessibility:
/// - The [GameProgressHeader] is wrapped in a Semantics that announces level,
///   progress percentage, and lives remaining in a single sentence.
/// - The info button announces "View instructions".
/// - The hint button announces whether it's available or already used, and
///   provides the hint text as the semantic hint for power users.
/// - The hint glow animation is skipped when "reduce motion" is enabled.
///
/// [gameProgressHeader] is pre-built by the parent so this widget never needs
/// to import [LevelThemeHelper] or carry an untyped theme reference.
class ReadingHeader extends StatelessWidget {
  /// Pre-built [GameProgressHeader] widget from the parent (carries the full
  /// theme reference without this widget needing a `dynamic` type).
  final Widget gameProgressHeader;

  final Color primaryColor;
  final ReadingQuest? currentQuest;
  final bool isAnswered;
  final bool hintUsed;
  final int lives;
  final SoundService soundService;
  final VoidCallback onInfoTap;
  final VoidCallback onHint;

  const ReadingHeader({
    super.key,
    required this.gameProgressHeader,
    required this.primaryColor,
    required this.currentQuest,
    required this.isAnswered,
    required this.hintUsed,
    required this.lives,
    required this.soundService,
    required this.onInfoTap,
    required this.onHint,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final showControls = currentQuest != null && !isAnswered;
    final hintShouldGlow = lives < 3 && !isAnswered && !hintUsed;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: [
          Expanded(child: gameProgressHeader),
          if (showControls) ...[
            SizedBox(width: 8.w),
            _buildInfoButton(context),
            SizedBox(width: 8.w),
            _buildHintButton(context, reduceMotion, hintShouldGlow),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sub-widgets
  // ---------------------------------------------------------------------------

  Widget _buildInfoButton(BuildContext context) {
    return Semantics(
      label: 'View level instructions',
      button: true,
      child: ScaleButton(
        onTap: onInfoTap,
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          // Decorative icon — Semantics label above is sufficient.
          child: ExcludeSemantics(
            child: Icon(
              Icons.info_outline_rounded,
              size: 16.r,
              color: primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHintButton(
    BuildContext context,
    bool reduceMotion,
    bool hintShouldGlow,
  ) {
    final hint = currentQuest?.hint ?? '';

    Widget button = Semantics(
      label: hintUsed ? 'Hint already used' : 'Use hint',
      // Expose the hint text as the semantic hint so power users can hear
      // it without activating the button (e.g. via TalkBack "read all").
      hint: hintUsed ? null : hint,
      button: !hintUsed,
      child: QuestHintButton(
        used: hintUsed,
        primaryColor: primaryColor,
        hintText: hint,
        soundService: soundService,
        onTap: onHint,
      ),
    );

    // Glow animation draws attention to the hint on low lives.
    // Skipped entirely when the user has enabled "reduce motion".
    if (hintShouldGlow && !reduceMotion) {
      button = button
          .animate(target: 1, onPlay: (c) => c.repeat(reverse: true))
          .shimmer(
            color: Colors.white.withValues(alpha: 0.5),
            duration: 1.seconds,
          )
          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
    }

    return button;
  }
}
