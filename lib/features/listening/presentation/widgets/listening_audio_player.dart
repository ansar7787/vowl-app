import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Premium audio-playback row used in the listening game.
///
/// Wrapped in a [RepaintBoundary] so the circular progress animation repaints
/// only the play-button subtree on every animation tick, not the entire card.
class ListeningAudioPlayer extends StatelessWidget {
  final dynamic theme;
  final bool isDark;
  final String audioUrl;
  final AnimationController audioController;
  final VoidCallback onPlay;

  const ListeningAudioPlayer({
    super.key,
    required this.theme,
    required this.isDark,
    required this.audioUrl,
    required this.audioController,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Audio player. Tap the play button to hear the audio clip.',
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(
            color: theme.primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // RepaintBoundary isolates the animation tick repaints to the
            // circular-progress subtree only.
            RepaintBoundary(
              child: _PlayButton(
                theme: theme,
                audioController: audioController,
                onPlay: onPlay,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LISTEN CAREFULLY',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: theme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Tap to play audio clip',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Decorative equalizer icon — hidden from screen readers.
            ExcludeSemantics(
              child: Icon(
                Icons.graphic_eq_rounded,
                color: theme.primaryColor.withValues(alpha: 0.5),
                size: 30.r,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: -0.2, end: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PlayButton
// ─────────────────────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final dynamic theme;
  final AnimationController audioController;
  final VoidCallback onPlay;

  const _PlayButton({
    required this.theme,
    required this.audioController,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Play audio',
      child: GestureDetector(
        onTap: onPlay,
        child: Container(
          width: 60.r,
          height: 60.r,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.primaryColor,
                theme.primaryColor.withValues(alpha: 0.7),
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: audioController,
            builder: (_, _) => Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 50.r,
                  height: 50.r,
                  child: CircularProgressIndicator(
                    value: audioController.value,
                    strokeWidth: 3,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                Icon(Icons.play_arrow_rounded, color: Colors.white, size: 35.r),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
