import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class SpeakingSelfEvaluationControls extends StatefulWidget {
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onSkipped;
  final bool isDark;

  const SpeakingSelfEvaluationControls({
    super.key,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    required this.isDark,
  });

  @override
  State<SpeakingSelfEvaluationControls> createState() =>
      _SpeakingSelfEvaluationControlsState();
}

class _SpeakingSelfEvaluationControlsState
    extends State<SpeakingSelfEvaluationControls>
    with SingleTickerProviderStateMixin {
  final _audioRecorder = di.sl<AudioRecordingService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  bool _isProcessingAudioAction = false;
  String? _recordingPath;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    if (_audioRecorder.isRecording) {
      _audioRecorder.stopRecording();
    }
    _soundService.stopTts();
    super.dispose();
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
        if (_hasRecorded) {
          _playComparison();
        }
      }
    } finally {
      _isProcessingAudioAction = false;
    }
  }

  Future<void> _playComparison() async {
    if (_isPlaying || _recordingPath == null) return;
    setState(() => _isPlaying = true);
    
    try {
      await _soundService.playTts(widget.expectedText).timeout(const Duration(seconds: 45));
    } catch (e) {
      // Ignore TTS errors
    }
    
    await Future.delayed(const Duration(milliseconds: 1200));
    
    if (mounted) {
      try {
        await _soundService.playFile(_recordingPath!).timeout(const Duration(seconds: 45));
      } catch (e) {
        // Ignore file playback errors
      }
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playNative() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    try {
      await _soundService.playTts(widget.expectedText).timeout(const Duration(seconds: 45));
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (e) {
      // Ignore playback/TTS errors so UI doesn't get stuck
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _playUser() async {
    if (_isPlaying || _recordingPath == null) return;
    setState(() => _isPlaying = true);
    try {
      await _soundService.playFile(_recordingPath!).timeout(const Duration(seconds: 45));
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (e) {
      // Ignore playback/TTS errors so UI doesn't get stuck
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  void _handleNailedIt() {
    _soundService.stopTts();
    widget.onConfirmed();
  }

  void _handleNeedsWork() {
    _soundService.stopTts();
    widget.onSkipped();
  }

  @override
  Widget build(BuildContext context) {
    final subtitleColor = widget.isDark ? Colors.white60 : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_hasRecorded) ...[
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
                color: _isRecording ? Colors.redAccent : widget.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.redAccent : widget.primaryColor)
                        .withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: _isRecording ? 8 : 0,
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 40.r,
              ),
            ).animate(target: _isRecording ? 1 : 0).scale(
                begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          ),
          SizedBox(height: 12.h),
          Text(
            _isRecording ? "Recording... Tap to stop" : "Tap to Record",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _isRecording ? Colors.redAccent : subtitleColor,
            ),
          ).animate(target: _isRecording ? 1 : 0).fade(),
          if (!_isRecording)
            Padding(
              padding: EdgeInsets.only(top: 24.h),
              child: Text(
                "Can't speak right now?\nYou can disable speaking tasks in Settings.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w500,
                  color: subtitleColor.withValues(alpha: 0.6),
                  height: 1.4,
                ),
              ),
            ),
        ] else if (_isPlaying) ...[
          Container(
            height: 70.r,
            width: 70.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor.withValues(alpha: 0.15),
            ),
            child: Center(
              child: Icon(
                Icons.graphic_eq_rounded,
                color: widget.primaryColor,
                size: 32.sp,
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.15, 1.15),
                duration: 600.ms,
                curve: Curves.easeInOut,
              )
              .fade(begin: 0.6, end: 1.0),
          SizedBox(height: 12.h),
          Text(
            "Playing comparison...",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: widget.primaryColor,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(
              begin: 0.5, end: 1.0, duration: 800.ms),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildIsolatedPlaybackButton(
                icon: Icons.record_voice_over_rounded,
                label: "NATIVE",
                onTap: _playNative,
                isDark: widget.isDark,
              ),
              SizedBox(width: 16.w),
              GestureDetector(
                onTap: _playComparison,
                child: Container(
                  height: 64.r,
                  width: 64.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.primaryColor.withValues(alpha: 0.15),
                    border: Border.all(
                      color: widget.primaryColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.play_arrow_rounded,
                        color: widget.primaryColor, size: 36.sp),
                  ),
                ),
              ),
              SizedBox(width: 16.w),
              _buildIsolatedPlaybackButton(
                icon: Icons.headphones_rounded,
                label: "YOU",
                onTap: _playUser,
                isDark: widget.isDark,
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildEvalButton(
                  title: "Needs Work",
                  icon: LucideIcons.x,
                  color: Colors.redAccent,
                  onTap: _handleNeedsWork,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildEvalButton(
                  title: "Nailed It",
                  icon: LucideIcons.check,
                  color: Colors.greenAccent,
                  onTap: _handleNailedIt,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            "Be honest! Did you match the native speaker?",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],


      ],
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
          border: Border.all(color: color.withValues(alpha: 0.5), width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24.sp),
            SizedBox(height: 4.h),
            Text(
              title,
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

  Widget _buildIsolatedPlaybackButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    final color = isDark ? Colors.white70 : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 48.r,
            width: 48.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.05),
              border: Border.all(
                color: color.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(height: 6.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
