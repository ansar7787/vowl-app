import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/locale_service.dart';

/// A performance-optimized interactive microphone controller with double-trigger event safety.
class SonicMicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final Color primaryColor;

  const SonicMicButton({
    super.key,
    required this.isListening,
    required this.onStart,
    required this.onStop,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isListening
          ? context.tr('games.stop_recording', fallback: 'Stop recording')
          : context.tr(
              'games.start_recording_hold',
              fallback: 'Press and hold to record',
            ),
      child: AnimatedContainer(
        duration: 300.ms,
        padding: EdgeInsets.all(isListening ? 12.r : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: primaryColor.withValues(alpha: isListening ? 0.3 : 0),
            width: 4,
          ),
        ),
        child: GestureDetector(
          // BUG FIX: this used to ALSO register onLongPressStart/
          // onLongPressEnd alongside these tap handlers. Plain
          // onTapDown/onTapUp already implements "press and hold to
          // record, release to stop" correctly for *any* hold duration on
          // their own — Flutter's tap recognizer has no maximum hold-time
          // cutoff. Adding a LongPress recognizer to the same
          // GestureDetector put it in direct competition with the Tap
          // recognizer in the gesture arena: once a hold passed the
          // ~500ms long-press threshold, the Tap recognizer lost the
          // arena and fired onTapCancel (→ onStop(), since isListening
          // was already true from the eager onTapDown) immediately
          // followed by onLongPressStart (→ onStart() again) — a brief,
          // unwanted stop/restart "blip" in the recording right at that
          // threshold, on every single press. Removing the redundant
          // LongPress handlers eliminates the arena conflict entirely.
          onTapDown: (_) {
            if (!isListening) onStart();
          },
          onTapUp: (_) {
            if (isListening) onStop();
          },
          onTapCancel: () {
            if (isListening) onStop();
          },
          child: ExcludeSemantics(
            child: RepaintBoundary(
              child: ScaleButton(
                onTap:
                    () {}, // Handled securely by the custom gesture detector above
                child: Container(
                  width: 90.r,
                  height: 90.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isListening
                          ? [Colors.redAccent, Colors.red]
                          : [primaryColor, primaryColor.withValues(alpha: 0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isListening ? Colors.redAccent : primaryColor)
                            .withValues(alpha: 0.4),
                        blurRadius: isListening ? 40 : 20,
                        spreadRadius: isListening ? 10 : 0,
                      ),
                    ],
                  ),
                  child:
                      Icon(
                            isListening
                                ? Icons.graphic_eq_rounded
                                : Icons.mic_rounded,
                            color: Colors.white,
                            size: 40.r,
                          )
                          .animate(target: isListening ? 1 : 0)
                          .scale(duration: 200.ms)
                          .shimmer(duration: 1000.ms, color: Colors.white24),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
