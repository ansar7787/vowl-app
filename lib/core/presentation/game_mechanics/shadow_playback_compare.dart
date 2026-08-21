import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

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
  });

  @override
  State<ShadowPlaybackCompare> createState() => _ShadowPlaybackCompareState();
}

class _ShadowPlaybackCompareState extends State<ShadowPlaybackCompare>
    with TickerProviderStateMixin {
  final _audioRecorder = di.sl<AudioRecordingService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  String _playingLabel = '';
  String? _recordingPath;
  int _playbackSessionId = 0;
  bool _isProcessingAudioAction = false;

  // Simulated waveform data for visual representation
  late List<double> _modelWaveform;
  late List<double> _userWaveform;

  late final AnimationController _pulseController;
  late final AnimationController _waveAnimController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waveAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Generate deterministic waveform based on text
    _generateWaveforms();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveAnimController.dispose();
    if (_audioRecorder.isRecording) {
      _audioRecorder.stopRecording();
    }
    _soundService.stopTts();
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
      setState(() {
        _isRecording = false;
        _hasRecorded = false;
        _isPlaying = false;
        _recordingPath = null;
      });
      _generateWaveforms();
    }
  }

  void _generateWaveforms() {
    final random = math.Random(widget.expectedText.hashCode);
    _modelWaveform = List.generate(
      40,
      (_) => 0.3 + random.nextDouble() * 0.7,
    );
    _userWaveform = List.generate(
      40,
      (_) => 0.2 + random.nextDouble() * 0.6,
    );
  }

  Future<void> _startRecording() async {
    if (_isPlaying || _isRecording || _isProcessingAudioAction) return;
    _isProcessingAudioAction = true;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (hasPermission) {
        _hapticService.selection();
        final started = await _audioRecorder.startRecording();
        if (started && mounted) {
          setState(() {
            _isRecording = true;
            _hasRecorded = false;
            _recordingPath = null;
          });
        }
      }
    } finally {
      _isProcessingAudioAction = false;
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _isProcessingAudioAction) return;
    _isProcessingAudioAction = true;

    try {
      _hapticService.selection();
      final path = await _audioRecorder.stopRecording();

      if (mounted) {
        setState(() {
          _isRecording = false;
          if (path != null) {
            _recordingPath = path;
            _hasRecorded = true;
          }
        });
      }
    } finally {
      _isProcessingAudioAction = false;
    }
  }

  Future<void> _playModel() async {
    if (_isPlaying) return;
    _playbackSessionId++;
    final sessionId = _playbackSessionId;

    setState(() {
      _isPlaying = true;
      _playingLabel = 'MODEL';
    });
    _waveAnimController.forward(from: 0.0);

    try {
      await _soundService
          .playTts(widget.expectedText)
          .timeout(const Duration(seconds: 45));
    } catch (_) {}

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted && sessionId == _playbackSessionId) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playUser() async {
    if (_isPlaying || _recordingPath == null) return;
    _playbackSessionId++;
    final sessionId = _playbackSessionId;

    setState(() {
      _isPlaying = true;
      _playingLabel = 'YOU';
    });
    _waveAnimController.forward(from: 0.0);

    try {
      await _soundService
          .playFile(_recordingPath!)
          .timeout(const Duration(seconds: 45));
    } catch (_) {}

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted && sessionId == _playbackSessionId) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playBothCompare() async {
    if (_isPlaying || _recordingPath == null) return;
    _playbackSessionId++;
    final sessionId = _playbackSessionId;

    // Play model first
    setState(() {
      _isPlaying = true;
      _playingLabel = 'MODEL';
    });
    _waveAnimController.forward(from: 0.0);

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
      setState(() => _playingLabel = 'YOU');
      _waveAnimController.forward(from: 0.0);

      try {
        await _soundService
            .playFile(_recordingPath!)
            .timeout(const Duration(seconds: 45));
      } catch (_) {}
    }

    if (sessionId != _playbackSessionId) return;
    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted && sessionId == _playbackSessionId) {
      setState(() => _isPlaying = false);
    }
  }

  void _handleNailedIt() {
    _playbackSessionId++;
    setState(() => _isPlaying = false);
    _soundService.stopTts();
    widget.onConfirmed();
  }

  void _handleNeedsWork() {
    _playbackSessionId++;
    setState(() => _isPlaying = false);
    _soundService.stopTts();
    widget.onSkipped();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    final content = Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(32.r),
          ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoSizeText(
                          'SHADOW & COMPARE',
                          maxLines: 1,
                          minFontSize: 8,
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
                          maxLines: 2,
                          minFontSize: 6,
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

              // Main interaction area
              if (!_hasRecorded) ...[
                // Recording phase
                GestureDetector(
                  onTap: () {
                    if (_isRecording) {
                      _stopRecording();
                    } else {
                      _startRecording();
                    }
                  },
                  child: Container(
                        width: 80.r,
                        height: 80.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording
                              ? Colors.redAccent
                              : widget.primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_isRecording
                                      ? Colors.redAccent
                                      : widget.primaryColor)
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: _isRecording ? 8 : 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording
                              ? Icons.stop_rounded
                              : Icons.mic_rounded,
                          color: Colors.white,
                          size: 40.r,
                        ),
                      )
                      .animate(target: _isRecording ? 1 : 0)
                      .scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.1, 1.1),
                      ),
                ),
                SizedBox(height: 12.h),
                Text(
                  _isRecording
                      ? 'Recording... Tap to stop'
                      : 'Tap to Record',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: _isRecording ? Colors.redAccent : subtitleColor,
                  ),
                ),
              ] else ...[
                // Comparison phase with waveforms
                if (widget.showWaveform) ...[
                  // Model waveform
                  _buildWaveformRow(
                    label: 'MODEL',
                    waveform: _modelWaveform,
                    color: widget.primaryColor,
                    isActive: _isPlaying && _playingLabel == 'MODEL',
                    onPlay: _playModel,
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  // User waveform
                  _buildWaveformRow(
                    label: 'YOU',
                    waveform: _userWaveform,
                    color: const Color(0xFF22C55E),
                    isActive: _isPlaying && _playingLabel == 'YOU',
                    onPlay: _playUser,
                    isDark: isDark,
                  ),
                  SizedBox(height: 12.h),

                  // Compare button
                  if (!_isPlaying)
                    GestureDetector(
                      onTap: _playBothCompare,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color:
                              widget.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: widget.primaryColor
                                .withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.play_arrow_rounded,
                              color: widget.primaryColor,
                              size: 20.r,
                            ),
                            SizedBox(width: 6.w),
                            AutoSizeText(
                              'PLAY COMPARISON',
                              maxLines: 1,
                              minFontSize: 8,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w800,
                                color: widget.primaryColor,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ] else ...[
                  // Simplified without waveform (fallback)
                  if (_isPlaying)
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
                          onPlay: (c) => c.repeat(reverse: true),
                        )
                        .scale(
                          begin: const Offset(0.9, 0.9),
                          end: const Offset(1.15, 1.15),
                          duration: 600.ms,
                        ),
                ],

                SizedBox(height: 20.h),

                // Self-evaluation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildEvalButton(
                        title: 'Needs Work',
                        icon: Icons.close_rounded,
                        color: Colors.redAccent,
                        onTap: _handleNeedsWork,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Expanded(
                      child: _buildEvalButton(
                        title: 'Nailed It',
                        icon: Icons.check_rounded,
                        color: Colors.greenAccent,
                        onTap: _handleNailedIt,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  'Be honest! Did you match the native speaker?',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    )
    .animate()
    .slideY(
      begin: 1.0,
      end: 0,
      duration: 400.ms,
      curve: Curves.easeOut,
    )
    .fadeIn(duration: 300.ms);

    if (widget.isPositioned) {
      return Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: content,
      );
    }

    return content;
  }

  Widget _buildWaveformRow({
    required String label,
    required List<double> waveform,
    required Color color,
    required bool isActive,
    required VoidCallback onPlay,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: _isPlaying ? null : onPlay,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.1)
              : (isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.02)),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isActive
                ? color.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Label
            SizedBox(
              width: 44.w,
              child: AutoSizeText(
                label,
                maxLines: 1,
                minFontSize: 6,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 1,
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Waveform bars
            Expanded(
              child: SizedBox(
                height: 30.h,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                    waveform.length.clamp(0, 30),
                    (i) {
                      final amplitude = waveform[i];
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 100 + i * 10),
                        width: 2.w,
                        height: isActive
                            ? (amplitude * 28.h)
                            : (amplitude * 16.h),
                        decoration: BoxDecoration(
                          color: isActive
                              ? color
                              : color.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(1.r),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            // Play icon
            Icon(
              isActive
                  ? Icons.graphic_eq_rounded
                  : Icons.play_arrow_rounded,
              color: color,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvalButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16.r),
          border:
              Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 4.h),
            AutoSizeText(
              title,
              maxLines: 1,
              minFontSize: 8,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
