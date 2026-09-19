import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'dart:async';
import 'package:record/record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

import 'components/shadow_waveform_visualizer.dart';
import 'components/shadow_playback_button.dart';
import 'components/shadow_eval_controls.dart';

/// Enhanced speaking self-evaluation with visual waveform comparison.
///
/// Records the user's voice, then shows a side-by-side waveform comparison
/// between the TTS model and the user's recording. Used for pronunciation
/// and accent training games.
///
/// Usage:
/// ```dart
/// ShadowPlaybackCompare(
///   expectedText: 'She sells seashells by the seashore',
///   primaryColor: theme.primaryColor,
///   onConfirmed: () => _handleNailedIt(),
///   onSkipped: () => _handleNeedsWork(),
/// )
/// ```
class ShadowPlaybackCompare extends StatefulWidget {
  /// Text to speak / compare against TTS.
  final String expectedText;

  /// Optional display text (if different from expectedText).
  final String? displayText;

  /// Theme accent colour.
  final Color primaryColor;

  /// Fires when user self-evaluates as "Nailed It".
  final VoidCallback onConfirmed;

  /// Fires when user self-evaluates as "Needs Work".
  final VoidCallback onSkipped;

  /// Whether to show the waveform visualization.
  final bool showWaveform;

  /// Speed multiplier for TTS playback (e.g. 0.75 for slow).
  final double speedMultiplier;

  /// Whether to wrap in a Positioned widget (for Stack layouts).
  final bool isPositioned;

  /// Whether to show the expected text (useful to hide if already displayed elsewhere).
  final bool showExpectedText;

  /// Optional callback for when recording state changes.
  final ValueChanged<bool>? onRecordingStateChanged;

  const ShadowPlaybackCompare({
    super.key,
    required this.expectedText,
    this.displayText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.showWaveform = true,
    this.speedMultiplier = 1.0,
    this.isPositioned = true,
    this.showExpectedText = true,
    this.onRecordingStateChanged,
  });

  @override
  State<ShadowPlaybackCompare> createState() => _ShadowPlaybackCompareState();
}

class _ShadowPlaybackCompareState extends State<ShadowPlaybackCompare> {
  final _audioRecorder = di.sl<AudioRecordingService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isRecording = ValueNotifier(false);
  final ValueNotifier<bool> _hasRecorded = ValueNotifier(false);
  final ValueNotifier<bool> _isPlaying = ValueNotifier(false);
  final ValueNotifier<String> _playingLabel = ValueNotifier('');
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);
  final ValueNotifier<double> _soundLevel = ValueNotifier(0.0);

  String? _recordingPath;
  int _playbackSessionId = 0;
  bool _isProcessingAudioAction = false;
  DateTime? _recordStartTime;
  Duration _recordDuration = Duration.zero;
  double _maxSoundLevel = 0.0;
  bool _showMicWarning = false;

  StreamSubscription<Amplitude>? _amplitudeSub;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _amplitudeSub?.cancel();
    _soundLevel.dispose();
    if (_audioRecorder.isRecording) {
      _audioRecorder.stopRecording();
    }
    _soundService.stopTts();

    _isRecording.dispose();
    _hasRecorded.dispose();
    _isPlaying.dispose();
    _playingLabel.dispose();
    _isSubmitting.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(ShadowPlaybackCompare oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expectedText != widget.expectedText) {
      _playbackSessionId++;
      _soundService.stopTts();
      if (_audioRecorder.isRecording) {
        _audioRecorder.stopRecording();
      }

      _isRecording.value = false;
      _hasRecorded.value = false;
      _isPlaying.value = false;
      _recordingPath = null;
      _isSubmitting.value = false;
    }
  }

  Future<void> _startRecording() async {
    if (_isPlaying.value || _isRecording.value || _isProcessingAudioAction) {
      return;
    }
    _isProcessingAudioAction = true;

    try {
      // Aggressively stop any background TTS/audio so the mic doesn't catch it
      await _soundService.stopTts();
      await _soundService.stopAudio();

      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        _hapticService.selection();
        final started = await _audioRecorder.startRecording();
        if (started && mounted) {
          _isRecording.value = true;
          widget.onRecordingStateChanged?.call(true);
          _hasRecorded.value = false;
          _recordingPath = null;
          _recordStartTime = DateTime.now();

          setState(() {
            _maxSoundLevel = 0.0;
            _showMicWarning = false;
          });

          _amplitudeSub?.cancel();
          _amplitudeSub = _audioRecorder
              .onAmplitudeChanged(const Duration(milliseconds: 50))
              .listen((Amplitude amp) {
                // Amp max is usually 0, min is often -160. But actual speech happens between -50 and 0.
                final double level = amp.current;
                final double normalized = ((level + 50) / 50).clamp(0.0, 1.0);
                if (mounted) {
                  _soundLevel.value = normalized;
                  if (normalized > _maxSoundLevel) {
                    _maxSoundLevel = normalized;
                  }
                }
              });
        }
      }
    } finally {
      _isProcessingAudioAction = false;
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording.value || _isProcessingAudioAction) return;
    _isProcessingAudioAction = true;

    try {
      _hapticService.selection();
      final path = await _audioRecorder.stopRecording();
      if (_recordStartTime != null) {
        _recordDuration = DateTime.now().difference(_recordStartTime!);
      }
      _amplitudeSub?.cancel();
      _amplitudeSub = null;
      if (mounted) {
        _soundLevel.value = 0.0;
      }

      if (mounted) {
        _isRecording.value = false;
        widget.onRecordingStateChanged?.call(false);

        // Validation for empty or failed capture
        if (_recordDuration.inMilliseconds < 500 ||
            _maxSoundLevel < 0.05 ||
            path == null) {
          setState(() {
            _showMicWarning = true;
          });
          // Do not transition to the compare phase, let them try again
          _recordingPath = null;
          _hasRecorded.value = false;
        } else {
          _recordingPath = path;
          _hasRecorded.value = true;
          setState(() {
            _showMicWarning = false;
          });
        }
      }
    } finally {
      _isProcessingAudioAction = false;
    }
  }

  Future<void> _playModel() async {
    if (_isPlaying.value) return;
    _playbackSessionId++;
    final sessionId = _playbackSessionId;

    _playingLabel.value = 'MODEL';
    _isPlaying.value = true;

    try {
      await _soundService
          .playTts(widget.expectedText)
          .timeout(const Duration(seconds: 45));
    } catch (_) {}

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted && sessionId == _playbackSessionId) {
      _isPlaying.value = false;
    }
  }

  Future<void> _playUser() async {
    if (_isPlaying.value || _recordingPath == null) return;
    _playbackSessionId++;
    final sessionId = _playbackSessionId;

    _playingLabel.value = 'YOU';
    _isPlaying.value = true;

    try {
      await _soundService
          .playFile(_recordingPath!)
          .timeout(const Duration(seconds: 45));
    } catch (_) {}

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(_recordDuration + const Duration(milliseconds: 300));

    if (mounted && sessionId == _playbackSessionId) {
      _isPlaying.value = false;
    }
  }

  Future<void> _playBothCompare() async {
    if (_isPlaying.value || _recordingPath == null) return;
    _playbackSessionId++;
    final sessionId = _playbackSessionId;

    // Play model first
    _playingLabel.value = 'MODEL';
    _isPlaying.value = true;

    try {
      await _soundService
          .playTts(widget.expectedText)
          .timeout(const Duration(seconds: 45));
    } catch (_) {}

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(const Duration(milliseconds: 1000));
    if (sessionId != _playbackSessionId) return;

    // Then play user
    if (mounted) {
      _playingLabel.value = 'YOU';

      try {
        await _soundService
            .playFile(_recordingPath!)
            .timeout(const Duration(seconds: 45));
      } catch (_) {}
    }

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(_recordDuration + const Duration(milliseconds: 300));

    if (mounted && sessionId == _playbackSessionId) {
      _isPlaying.value = false;
    }
  }

  void _handleNailedIt() {
    if (_isSubmitting.value) return;
    _isSubmitting.value = true;

    _playbackSessionId++;
    _isPlaying.value = false;
    _soundService.stopTts();

    widget.onConfirmed();
  }

  void _handleNeedsWork() {
    if (_isSubmitting.value) return;
    _isSubmitting.value = true;

    _playbackSessionId++;
    _isPlaying.value = false;
    _soundService.stopTts();

    widget.onSkipped();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.slate900;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final content = Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.only(
          left: widget.isPositioned ? 0 : 20.w,
          right: widget.isPositioned ? 0 : 20.w,
          bottom: widget.isPositioned ? 0 : 16.h,
        ),
        child: Container(
          padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: widget.isPositioned
                ? BorderRadius.vertical(top: Radius.circular(32.r))
                : BorderRadius.circular(32.r),
            border: Border.all(
              color: widget.primaryColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.primaryColor.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 48.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: subtitleColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),

                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: Icon(
                        Icons.compare_arrows_rounded,
                        color: widget.primaryColor,
                        size: 22.r,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          AutoSizeText(
                            'SHADOW & COMPARE',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            minFontSize: 6,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w900,
                              color: widget.primaryColor,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          AutoSizeText(
                            'Record yourself, then compare with the model',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            minFontSize: 6,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w500,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),

                // Expected text display
                if (widget.showExpectedText) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 16.h,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.black.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: widget.primaryColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: AutoSizeText(
                      widget.displayText ?? widget.expectedText,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      minFontSize: 10,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],

                // Main interaction area
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOutCubic,
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _hasRecorded,
                    builder: (context, hasRecorded, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        layoutBuilder: (currentChild, previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              ?currentChild,
                            ],
                          );
                        },
                        child: !hasRecorded
                            ? ValueListenableBuilder<bool>(
                                key: const ValueKey('recording_phase'),
                                valueListenable: _isRecording,
                                builder: (context, isRecording, _) {
                                  return Column(
                                    children: [
                                      Semantics(
                                        button: true,
                                        label: isRecording
                                            ? 'Stop recording'
                                            : 'Start recording',
                                        child: GestureDetector(
                                          onTap: () {
                                            if (isRecording) {
                                              _stopRecording();
                                            } else {
                                              _startRecording();
                                            }
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOutCubic,
                                            width: isRecording ? 180.w : 80.r,
                                            height: isRecording ? 60.h : 80.r,
                                            decoration: BoxDecoration(
                                              color: isRecording
                                                  ? tokens.gameIncorrect
                                                  : widget.primaryColor,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    isRecording ? 30.r : 40.r,
                                                  ),
                                              boxShadow: isRecording
                                                  ? null
                                                  : [
                                                      BoxShadow(
                                                        color: widget
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 16,
                                                        spreadRadius: 0,
                                                      ),
                                                    ],
                                            ),
                                            child: Center(
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                child: isRecording
                                                    ? ShadowWaveformVisualizer(
                                                        soundLevel: _soundLevel,
                                                      )
                                                    : Icon(
                                                        Icons.mic_rounded,
                                                        color: Colors.white,
                                                        size: 40.r,
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 16.h),
                                      AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        child: Column(
                                          key: ValueKey(
                                            '${isRecording}_$_showMicWarning',
                                          ),
                                          children: [
                                            Text(
                                              isRecording
                                                  ? 'Recording... Tap to stop'
                                                  : 'Tap to Record',
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w600,
                                                color: isRecording
                                                    ? tokens.gameIncorrect
                                                    : subtitleColor,
                                              ),
                                            ),
                                            if (!isRecording &&
                                                _showMicWarning) ...[
                                              SizedBox(height: 8.h),
                                              Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 12.w,
                                                          vertical: 6.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange
                                                          .withValues(
                                                            alpha: 0.1,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.r,
                                                          ),
                                                      border: Border.all(
                                                        color: Colors.orange
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.mic_off_rounded,
                                                          size: 14.r,
                                                          color: Colors.orange,
                                                        ),
                                                        SizedBox(width: 6.w),
                                                        Text(
                                                          "We couldn't hear you. Try again?",
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: 11.sp,
                                                            color:
                                                                Colors.orange,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                  .animate()
                                                  .shake(
                                                    hz: 3,
                                                    curve: Curves.easeInOut,
                                                  )
                                                  .fadeIn(),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              )
                            : ListenableBuilder(
                                key: const ValueKey('comparison_phase'),
                                listenable: Listenable.merge([
                                  _isPlaying,
                                  _playingLabel,
                                  _isSubmitting,
                                ]),
                                builder: (context, _) {
                                  final isPlaying = _isPlaying.value;
                                  final playingLabel = _playingLabel.value;
                                  final isSubmitting = _isSubmitting.value;

                                  return Column(
                                    children: [
                                      if (widget.showWaveform) ...[
                                        // Model waveform
                                        ShadowPlaybackButton(
                                          label: context.tr(
                                            'eval.native',
                                            fallback: 'NATIVE',
                                          ),
                                          color: widget.primaryColor,
                                          isActive:
                                              isPlaying &&
                                              playingLabel == 'MODEL',
                                          onPlay: _playModel,
                                          isDark: isDark,
                                          isPlaying: isPlaying,
                                        ),
                                        SizedBox(height: 12.h),

                                        // User waveform
                                        ShadowPlaybackButton(
                                          label: context.tr(
                                            'eval.you',
                                            fallback: 'YOU',
                                          ),
                                          color: const Color(0xFF22C55E),
                                          isActive:
                                              isPlaying &&
                                              playingLabel == 'YOU',
                                          onPlay: _playUser,
                                          isDark: isDark,
                                          isPlaying: isPlaying,
                                        ),
                                        SizedBox(height: 12.h),

                                        // Compare button
                                        if (!isPlaying)
                                          Semantics(
                                            button: true,
                                            label: 'Play comparison',
                                            child: GestureDetector(
                                              onTap: _playBothCompare,
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 20.w,
                                                  vertical: 10.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: widget.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        20.r,
                                                      ),
                                                  border: Border.all(
                                                    color: widget.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.play_arrow_rounded,
                                                      color:
                                                          widget.primaryColor,
                                                      size: 20.r,
                                                    ),
                                                    SizedBox(width: 6.w),
                                                    AutoSizeText(
                                                      context.tr(
                                                        'eval.play_comparison',
                                                        fallback:
                                                            'PLAY COMPARISON',
                                                      ),
                                                      maxLines: 1,
                                                      minFontSize: 8,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color:
                                                            widget.primaryColor,
                                                        letterSpacing: 1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                      ] else ...[
                                        // Simplified without waveform (fallback)
                                        if (isPlaying)
                                          Container(
                                                height: 70.r,
                                                width: 70.r,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: widget.primaryColor
                                                      .withValues(alpha: 0.15),
                                                ),
                                                child: Center(
                                                  child: Icon(
                                                    Icons.graphic_eq_rounded,
                                                    color: widget.primaryColor,
                                                    size: 32.sp,
                                                  ),
                                                ),
                                              )
                                              .animate(
                                                onPlay: (c) =>
                                                    c.repeat(reverse: true),
                                              )
                                              .scale(
                                                begin: const Offset(0.9, 0.9),
                                                end: const Offset(1.15, 1.15),
                                                duration: 600.ms,
                                              ),
                                      ],

                                      SizedBox(height: 20.h),

                                      // Self-evaluation buttons
                                      ShadowEvalControls(
                                        isSubmitting: isSubmitting,
                                        onNeedsWork: _handleNeedsWork,
                                        onNailedIt: _handleNailedIt,
                                      ),
                                      SizedBox(height: 12.h),
                                      Text(
                                        context.tr(
                                          'eval.be_honest_native',
                                          fallback:
                                              'Be honest! Did you match the native speaker?',
                                        ),
                                        style: TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w500,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut).fadeIn(duration: 300.ms),
    );

    if (widget.isPositioned) {
      return Positioned(bottom: 0, left: 0, right: 0, child: content);
    }

    return content;
  }
}
