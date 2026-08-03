import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

class AccentSelfEvaluationPanel extends StatefulWidget {
  final String textToSpeak;
  final Color primaryColor;
  final bool isCompact;
  final void Function(bool isCorrect) onEvaluate;

  const AccentSelfEvaluationPanel({
    super.key,
    required this.textToSpeak,
    required this.primaryColor,
    required this.isCompact,
    required this.onEvaluate,
  });

  @override
  State<AccentSelfEvaluationPanel> createState() => _AccentSelfEvaluationPanelState();
}

class _AccentSelfEvaluationPanelState extends State<AccentSelfEvaluationPanel> {
  final _audioRecorder = di.sl<AudioRecordingService>();
  final _soundService = di.sl<SoundService>();
  final _hapticService = di.sl<HapticService>();

  bool _isRecording = false;
  bool _hasRecorded = false;
  bool _isPlaying = false;
  String? _recordingPath;

  @override
  void dispose() {
    if (_isRecording) {
      _audioRecorder.stopRecording();
    }
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (_isPlaying) return;
    
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
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
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
  }

  Future<void> _playComparison() async {
    if (_isPlaying || _recordingPath == null) return;
    
    setState(() => _isPlaying = true);
    
    // Play Native
    await _soundService.playTts(widget.textToSpeak);
    await Future.delayed(const Duration(milliseconds: 1200));
    
    // Play User
    if (mounted) {
      await _soundService.playFile(_recordingPath!);
      await Future.delayed(const Duration(milliseconds: 1200));
    }
    
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(color: widget.primaryColor.withValues(alpha: 0.2), thickness: 2),
        SizedBox(height: 8.h),
        Text(
          "PHASE 2: SPEAKING",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: widget.primaryColor,
          ),
        ),
        if (widget.textToSpeak.trim().isNotEmpty) ...[
          SizedBox(height: 12.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: widget.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '"${widget.textToSpeak}"',
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: widget.textToSpeak.length > 30 ? 16.sp : 18.sp,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: 16.h),
        ] else ...[
          SizedBox(height: 16.h),
        ],
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
                color: _isRecording ? Colors.red : widget.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : widget.primaryColor).withValues(alpha: 0.4),
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
            ).animate(target: _isRecording ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          ),
          SizedBox(height: 10.h),
          Text(
            _isRecording ? "Listening... Tap to stop" : "Tap to Record",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: _isRecording ? Colors.red : Colors.grey[600],
            ),
          ).animate(target: _isRecording ? 1 : 0).fade(),
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
          ).animate(onPlay: (controller) => controller.repeat(reverse: true)).fade(begin: 0.5, end: 1.0, duration: 800.ms),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildEvalButton(
                title: "Needs Work",
                icon: LucideIcons.x,
                color: Colors.red,
                onTap: () => widget.onEvaluate(false),
              ),
              GestureDetector(
                onTap: _playComparison,
                child: Container(
                  height: 60.r,
                  width: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.primaryColor.withValues(alpha: 0.15),
                  ),
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 4.r), // Center the play icon visually
                      child: Icon(Icons.play_arrow_rounded, color: widget.primaryColor, size: 36.sp),
                    ),
                  ),
                ),
              ),
              _buildEvalButton(
                title: "Nailed It",
                icon: LucideIcons.check,
                color: Colors.green,
                onTap: () => widget.onEvaluate(true),
              ),
            ],
          ),
          if (!widget.isCompact) ...[
            SizedBox(height: 10.h),
            Text(
              "Be honest! Did you match the native speaker?",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ],
      ],
    ).animate().slideY(begin: 0.2).fadeIn();
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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
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
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
