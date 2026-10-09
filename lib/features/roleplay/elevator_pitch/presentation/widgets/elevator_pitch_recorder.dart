import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;

enum PitchState { ready, pitching, evaluating, failed }

class ElevatorPitchRecorder extends StatefulWidget {
  final int timeLimit;
  final String expectedText;
  final Color primaryColor;
  final VoidCallback onConfirmed;
  final VoidCallback onFailed;

  const ElevatorPitchRecorder({
    super.key,
    required this.timeLimit,
    required this.expectedText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onFailed,
  });

  @override
  State<ElevatorPitchRecorder> createState() => _ElevatorPitchRecorderState();
}

class _ElevatorPitchRecorderState extends State<ElevatorPitchRecorder> {
  final _speechService = di.sl<SpeechService>();
  final _soundService = di.sl<SoundService>();
  final _hapticService = di.sl<HapticService>();

  late final ValueNotifier<PitchState> _state;
  late final ValueNotifier<int> _secondsLeft;
  late final ValueNotifier<double> _currentAmplitude;
  late final ValueNotifier<bool> _isPlaying;

  Timer? _countdownTimer;

  int _silentSeconds = 0;
  String _finalTranscript = "";
  bool _passedAutoGrade = false;
  
  int _wordCount = 0;
  int _matchedKeywords = 0;
  late Set<String> _targetKeywords;

  @override
  void initState() {
    super.initState();
    _state = ValueNotifier(PitchState.ready);
    _secondsLeft = ValueNotifier(widget.timeLimit);
    _currentAmplitude = ValueNotifier(-50.0);
    _isPlaying = ValueNotifier(false);
    _targetKeywords = _extractKeywords(widget.expectedText);
  }

  Set<String> _extractKeywords(String text) {
    final cleanText = text.replaceAll(RegExp(r'[^\w\s]'), '').toLowerCase();
    final words = cleanText.split(RegExp(r'\s+'));
    final stopWords = {'this', 'is', 'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by', 'from', 'made', 'it', 'that', 'which', 'you', 'can', 'are', 'we', 'they'};
    return words.where((w) => w.length > 3 && !stopWords.contains(w)).toSet();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    if (_speechService.isListening) {
      _speechService.cancel();
    }
    _soundService.stopTts();
    _state.dispose();
    _secondsLeft.dispose();
    _currentAmplitude.dispose();
    _isPlaying.dispose();
    super.dispose();
  }

  Future<void> _startPitch() async {
    final initialized = await _speechService.initializeStt();
    if (!initialized) return;

    await _soundService.stopTts();
    await _soundService.stopAudio();

    _hapticService.selection();
    _secondsLeft.value = widget.timeLimit;
    _silentSeconds = 0;
    _finalTranscript = "";
    _state.value = PitchState.pitching;

    await _speechService.listen(
      onResult: (candidates, isFinal) {
        if (candidates.isNotEmpty) {
          _finalTranscript = candidates.first;
        }
      },
      onDone: () {},
      onSoundLevelChange: (level) {
        if (!mounted) return;
        // Level is typically between -50 and +50
        _currentAmplitude.value = level;
        
        if (level < -40.0) {
          _silentSeconds++;
        } else {
          _silentSeconds = 0;
        }

        if (_silentSeconds >= 12) { // 6 seconds (called ~twice a second)
          _abortPitchDueToSilence();
        }
      },
      pauseFor: Duration(seconds: widget.timeLimit), // Don't auto-stop
    );

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsLeft.value > 0) {
        _secondsLeft.value--;
      } else {
        _finishPitch();
      }
    });
  }

  Future<void> _abortPitchDueToSilence() async {
    _countdownTimer?.cancel();
    _hapticService.heavy();
    await _speechService.stop();

    if (mounted) {
      _state.value = PitchState.failed;
    }
  }

  Future<void> _finishPitch() async {
    _countdownTimer?.cancel();
    _hapticService.success();
    await _speechService.stop();

    _evaluateTranscript();

    if (mounted) {
      _state.value = PitchState.evaluating;
    }
  }

  int get _requiredKeywords => _targetKeywords.length < 2 ? _targetKeywords.length : 2;

  void _evaluateTranscript() {
    final words = _finalTranscript.trim().split(RegExp(r'\s+'));
    _wordCount = _finalTranscript.trim().isEmpty ? 0 : words.length;

    final lowerTranscript = _finalTranscript.toLowerCase();
    _matchedKeywords = _targetKeywords.where((k) => lowerTranscript.contains(k)).length;

    final expectedWordsCount = widget.expectedText.trim().split(RegExp(r'\s+')).length;
    final requiredWords = expectedWordsCount < 15 ? (expectedWordsCount * 0.5).ceil() : 15;

    if (_wordCount >= requiredWords && _matchedKeywords >= _requiredKeywords) {
      _passedAutoGrade = true;
    } else {
      _passedAutoGrade = false;
    }
  }


  Future<void> _playNative() async {
    if (_isPlaying.value) return;
    _isPlaying.value = true;
    try {
      await _soundService.playTts(widget.expectedText).timeout(const Duration(seconds: 45));
    } catch (_) {}
    if (mounted) _isPlaying.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: widget.primaryColor.withValues(alpha: 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ValueListenableBuilder<PitchState>(
        valueListenable: _state,
        builder: (context, state, _) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildStateContent(context, state, isDark),
          );
        },
      ),
    );
  }

  Widget _buildStateContent(BuildContext context, PitchState state, bool isDark) {
    switch (state) {
      case PitchState.ready:
        return _buildReadyState();
      case PitchState.pitching:
        return _buildPitchingState();
      case PitchState.failed:
        return _buildFailedState();
      case PitchState.evaluating:
        return _buildEvaluatingState(context, isDark);
    }
  }

  Widget _buildReadyState() {
    return Column(
      key: const ValueKey('ready'),
      children: [
        Icon(
          Icons.mic_none_rounded,
          size: 48.sp,
          color: widget.primaryColor,
        ),
        SizedBox(height: 16.h),
        Text(
          "GET READY",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: widget.primaryColor,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "Read the reference below to learn, then pitch it in your own words. The listener will grade your fluency.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 16.h),
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: widget.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: widget.primaryColor.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "REFERENCE PITCH",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: widget.primaryColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                widget.expectedText,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: _startPitch,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          child: Text(
            "START PITCH",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPitchingState() {
    return Column(
      key: const ValueKey('pitching'),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 10.r,
              height: 10.r,
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fade(begin: 0.2, end: 1.0, duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 600.ms),
            SizedBox(width: 8.w),
            Text(
              "RECORDING...",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ValueListenableBuilder<int>(
          valueListenable: _secondsLeft,
          builder: (context, seconds, _) {
            return Text(
              "00:${seconds.toString().padLeft(2, '0')}",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                color: seconds <= 5 ? Colors.redAccent : widget.primaryColor,
              ),
            );
          },
        ),
        SizedBox(height: 24.h),
        GestureDetector(
          onTap: _finishPitch,
          child: Container(
            height: 120.r,
            width: 120.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.primaryColor.withValues(alpha: 0.05),
              border: Border.all(color: widget.primaryColor.withValues(alpha: 0.3), width: 2),
            ),
            child: Center(
              child: ValueListenableBuilder<double>(
                valueListenable: _currentAmplitude,
                builder: (context, amplitude, _) {
                  // STT amplitude is usually -50 to 50. Let's normalize it.
                  final normalizedAmp = ((amplitude + 50) / 100).clamp(0.0, 1.0);
                  final innerScale = 1.0 + (normalizedAmp * 0.3);
                  final outerScale = 1.0 + (normalizedAmp * 0.6);
                  
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: outerScale,
                        child: Container(
                          width: 80.r,
                          height: 80.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryColor.withValues(alpha: 0.15 * normalizedAmp),
                          ),
                        ),
                      ),
                      Transform.scale(
                        scale: innerScale,
                        child: Container(
                          width: 60.r,
                          height: 60.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryColor.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.mic,
                            color: widget.primaryColor,
                            size: 32.sp,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        SizedBox(height: 24.h),
        ValueListenableBuilder<int>(
          valueListenable: _secondsLeft,
          builder: (context, seconds, _) {
            final progress = 1.0 - (seconds / widget.timeLimit);
            return ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12.h,
                backgroundColor: widget.primaryColor.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation(widget.primaryColor),
              ),
            );
          },
        ),
        SizedBox(height: 16.h),
        Text(
          "Tap the mic to finish early",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11.sp,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState() {
    return Column(
      key: const ValueKey('failed'),
      children: [
        Icon(Icons.sensor_door_outlined, size: 64.sp, color: Colors.redAccent),
        SizedBox(height: 16.h),
        Text(
          "THE DOORS OPENED",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.redAccent,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          "You went silent. You lost their attention.",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.sp,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 24.h),
        ElevatedButton(
          onPressed: () {
            widget.onFailed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          child: Text(
            "CONTINUE",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvaluatingState(BuildContext context, bool isDark) {
    return Column(
      key: const ValueKey('evaluating'),
      children: [
        Text(
          _passedAutoGrade ? "PITCH SUCCESSFUL" : "PITCH FAILED",
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: _passedAutoGrade ? Colors.green : Colors.redAccent,
          ),
        ),
        SizedBox(height: 16.h),
        
        // AI Grade Card
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: (_passedAutoGrade ? Colors.green : Colors.redAccent).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: (_passedAutoGrade ? Colors.green : Colors.redAccent).withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AI ANALYSIS",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: _passedAutoGrade ? Colors.green : Colors.redAccent,
                ),
              ),
              SizedBox(height: 12.h),
              _buildGradeRow(
                icon: Icons.speed_rounded,
                title: "Fluency (Word Count)",
                value: "$_wordCount words",
                passed: _wordCount >= 15,
                isDark: isDark,
              ),
              SizedBox(height: 8.h),
              _buildGradeRow(
                icon: Icons.key_rounded,
                title: "Vocabulary (Keywords)",
                value: "$_matchedKeywords hits",
                passed: _matchedKeywords >= _requiredKeywords,
                isDark: isDark,
              ),
            ],
          ),
        ),
        
        SizedBox(height: 24.h),
        
        // Native example fallback
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Want to hear a perfect pitch?",
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                color: Colors.grey,
              ),
            ),
            SizedBox(width: 12.w),
            GestureDetector(
              onTap: _playNative,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isPlaying,
                builder: (context, isPlaying, _) {
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: Row(
                      children: [
                        Icon(isPlaying ? Icons.stop_circle_rounded : Icons.play_arrow_rounded, color: widget.primaryColor, size: 16.r),
                        SizedBox(width: 4.w),
                        Text(
                          "LISTEN",
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: widget.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        SizedBox(height: 24.h),
        
        // Action buttons
        ElevatedButton(
          onPressed: () {
            _soundService.stopTts();
            if (_passedAutoGrade) {
              widget.onConfirmed();
            } else {
              widget.onFailed();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.primaryColor,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 16.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100.r),
            ),
          ),
          child: Text(
            "CONTINUE",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradeRow({
    required IconData icon,
    required String title,
    required String value,
    required bool passed,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: isDark ? Colors.white70 : Colors.black87),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: passed ? Colors.green : Colors.redAccent,
          ),
        ),
        SizedBox(width: 8.w),
        Icon(
          passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          size: 16.r,
          color: passed ? Colors.green : Colors.redAccent,
        ),
      ],
    );
  }
}
