import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';

/// Production-grade audio speaker button for on-demand Text-to-Speech narration.
///
/// Ensures deterministic lifecycle management:
/// - Only speaks when explicitly tapped.
/// - Automatically stops any existing/other TTS playback across the app before starting.
/// - Tapping while active immediately cancels speech (toggle).
/// - Provides a global [stopAll] entry point for the Continue button and navigation.
/// - Automatically resets its visual state when speech finishes or another speaker starts.
class TtsSpeakerButtonWidget extends StatefulWidget {
  final String text;
  final Color color;
  final bool isKids;
  final double? size;
  final String? locale;

  const TtsSpeakerButtonWidget({
    super.key,
    required this.text,
    required this.color,
    this.isKids = false,
    this.size,
    this.locale,
  });

  /// Globally stops active TTS speech synthesis and resets all active
  /// [TtsSpeakerButtonWidget] indicators to idle.
  static Future<void> stopAll() async {
    _activeSessionNotifier.value = null;
    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().stop();
      }
    } catch (_) {}
  }

  static final ValueNotifier<int?> _activeSessionNotifier = ValueNotifier<int?>(
    null,
  );
  static int _sessionCounter = 0;

  @override
  State<TtsSpeakerButtonWidget> createState() => _TtsSpeakerButtonWidgetState();
}

class _TtsSpeakerButtonWidgetState extends State<TtsSpeakerButtonWidget> {
  int? _mySessionId;
  bool _isSpeaking = false;
  Timer? _watchdogTimer;

  @override
  void initState() {
    super.initState();
    TtsSpeakerButtonWidget._activeSessionNotifier.addListener(
      _onActiveSessionChanged,
    );
    if (di.sl.isRegistered<TtsService>()) {
      try {
        di.sl<TtsService>().isSpeakingNotifier.addListener(
          _onEngineSpeakingChanged,
        );
      } catch (_) {}
    }
  }

  @override
  void didUpdateWidget(covariant TtsSpeakerButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text && _isSpeaking) {
      TtsSpeakerButtonWidget.stopAll();
    }
  }

  @override
  void dispose() {
    TtsSpeakerButtonWidget._activeSessionNotifier.removeListener(
      _onActiveSessionChanged,
    );
    if (di.sl.isRegistered<TtsService>()) {
      try {
        di.sl<TtsService>().isSpeakingNotifier.removeListener(
          _onEngineSpeakingChanged,
        );
      } catch (_) {}
    }
    _watchdogTimer?.cancel();
    if (_isSpeaking &&
        TtsSpeakerButtonWidget._activeSessionNotifier.value == _mySessionId) {
      TtsSpeakerButtonWidget.stopAll();
    }
    super.dispose();
  }

  void _onActiveSessionChanged() {
    final activeId = TtsSpeakerButtonWidget._activeSessionNotifier.value;
    if (activeId != _mySessionId && _isSpeaking) {
      _watchdogTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  void _onEngineSpeakingChanged() {
    if (!mounted) return;
    bool isSpeakingNow = false;
    try {
      isSpeakingNow = di.sl<TtsService>().isSpeakingNotifier.value;
    } catch (_) {}
    if (!isSpeakingNow &&
        _isSpeaking &&
        TtsSpeakerButtonWidget._activeSessionNotifier.value == _mySessionId) {
      _watchdogTimer?.cancel();
      TtsSpeakerButtonWidget._activeSessionNotifier.value = null;
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _speak({bool slow = false}) async {
    if (widget.text.trim().isEmpty) return;

    if (_isSpeaking) {
      await TtsSpeakerButtonWidget.stopAll();
      return;
    }

    // Fast-path: Only wait for stop if an engine is actively speaking right now,
    // avoiding redundant MethodChannel delays on cold/idle taps.
    final bool isEngineActive = di.sl.isRegistered<TtsService>() &&
        di.sl<TtsService>().isSpeaking;
    if (isEngineActive) {
      await TtsSpeakerButtonWidget.stopAll();
    }

    final sessionId = ++TtsSpeakerButtonWidget._sessionCounter;
    _mySessionId = sessionId;
    TtsSpeakerButtonWidget._activeSessionNotifier.value = sessionId;

    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }

    try {
      final double? targetRate = slow ? 0.3 : null;
      if (widget.isKids &&
          widget.locale == null &&
          di.sl.isRegistered<KidsTTSService>()) {
        await di.sl<KidsTTSService>().speak(widget.text, force: true);
      } else if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().speak(
          widget.text,
          rate: targetRate,
          isKids: widget.isKids,
          locale: widget.locale,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
      return;
    }

    // Defensive single watchdog timeout: fires ONLY if native OEM drops completion event completely
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(const Duration(seconds: 30), () {
      if (mounted &&
          _isSpeaking &&
          TtsSpeakerButtonWidget._activeSessionNotifier.value == sessionId) {
        TtsSpeakerButtonWidget._activeSessionNotifier.value = null;
        setState(() {
          _isSpeaking = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = (widget.size ?? 16).r;

    // Check TTS engine availability — show disabled state if unavailable
    bool isEngineReady = true;
    if (di.sl.isRegistered<TtsService>()) {
      try {
        isEngineReady =
            di.sl<TtsService>().engineStatus == TtsEngineStatus.ready;
      } catch (_) {
        isEngineReady = true;
      }
    }

    return Semantics(
      label: !isEngineReady
          ? 'Audio narration unavailable'
          : (_isSpeaking
                ? 'Stop audio narration'
                : 'Listen to audio narration. Long press for slow pronunciation.'),
      button: true,
      child: Tooltip(
        message: !isEngineReady
            ? 'Text-to-speech unavailable on this device'
            : (_isSpeaking
                  ? 'Tap to stop'
                  : 'Tap to listen • Hold for slow pronunciation'),
        child: ScaleButton(
          onTap: isEngineReady ? () => _speak(slow: false) : null,
          onLongPress: isEngineReady ? () => _speak(slow: true) : null,
          child: Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: widget.color.withValues(
                alpha: !isEngineReady ? 0.05 : (_isSpeaking ? 0.25 : 0.1),
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(
                  alpha: !isEngineReady ? 0.1 : (_isSpeaking ? 0.5 : 0.2),
                ),
                width: 1,
              ),
            ),
            child: Icon(
              !isEngineReady
                  ? Icons.volume_off_rounded
                  : (_isSpeaking
                        ? Icons.stop_rounded
                        : Icons.volume_up_rounded),
              color: widget.color.withValues(alpha: isEngineReady ? 1.0 : 0.3),
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
