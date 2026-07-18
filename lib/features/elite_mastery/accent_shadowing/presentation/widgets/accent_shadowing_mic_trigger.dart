import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

class AccentShadowingMicTrigger extends StatelessWidget {
  final bool isListening;
  final VoidCallback onTap;

  final Color primaryColor;
  final int attempts;
  final bool isAnswered;

  const AccentShadowingMicTrigger({
    super.key,
    required this.isListening,
    required this.onTap,

    required this.primaryColor,
    required this.attempts,
    required this.isAnswered,
  });

  @override
  Widget build(BuildContext context) {
    if (isAnswered) return const SizedBox.shrink();

    final micButton = ScaleButton(
      onTap: onTap,
      child: Container(
        width: 100.r,
        height: 100.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening ? Colors.red : primaryColor,
          boxShadow: [
            BoxShadow(
              color: (isListening ? Colors.red : primaryColor).withValues(
                alpha: 0.4,
              ),
              blurRadius: 30,
              spreadRadius: isListening ? 10 : 0,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.stop_rounded : Icons.mic_rounded,
          color: Colors.white,
          size: 48.r,
        ),
      ),
    );

    // FIX: previously `.animate(onPlay: (c) => c.repeat())` was attached
    // unconditionally, so the AnimationController kept ticking — and this
    // whole subtree kept rebuilding — for as long as the mic button existed
    // on screen, even while idle (`isListening == false`), where begin/end
    // were identical and produced no visible change. On a game screen the
    // player can sit looking at for a while before tapping, that's a real,
    // sustained, entirely wasted cost on low-end devices. Only attach the
    // repeating pulse effect while actually listening; render a plain,
    // unanimated widget otherwise so no ticker runs at all when idle.
    final animatedMicButton = isListening
        ? micButton
              .animate(onPlay: (controller) => controller.repeat())
              .scale(
                begin: const Offset(1, 1),
                end: const Offset(1.1, 1.1),
                duration: 800.ms,
              )
        : micButton;

    return Column(
      children: [
        Semantics(
          button: true,
          label: isListening
              ? context.tr(
                  'games.semantic_mic_stop',
                  fallback: 'Stop Recording',
                )
              : context.tr(
                  'games.semantic_mic_start',
                  fallback: 'Start Recording',
                ),
          excludeSemantics: true,
          child: animatedMicButton,
        ),
      ],
    );
  }
}
