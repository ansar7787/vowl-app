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

  /// Globally stops all active TTS speech engines (Kids and standard TtsService)
  /// and resets all active [TtsSpeakerButtonWidget] indicators to idle.
  static Future<void> stopAll() async {
    _activeSessionNotifier.value = null;
    try {
      if (di.sl.isRegistered<KidsTTSService>()) {
        await di.sl<KidsTTSService>().stop();
      }
    } catch (_) {}
    try {
      if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().stop();
      }
    } catch (_) {}
  }

  static final ValueNotifier<int?> _activeSessionNotifier =
      ValueNotifier<int?>(null);
  static int _sessionCounter = 0;

  @override
  State<TtsSpeakerButtonWidget> createState() => _TtsSpeakerButtonWidgetState();
}

class _TtsSpeakerButtonWidgetState extends State<TtsSpeakerButtonWidget> {
  int? _mySessionId;
  bool _isSpeaking = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    TtsSpeakerButtonWidget._activeSessionNotifier.addListener(
      _onActiveSessionChanged,
    );
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
    _pollTimer?.cancel();
    if (_isSpeaking &&
        TtsSpeakerButtonWidget._activeSessionNotifier.value == _mySessionId) {
      TtsSpeakerButtonWidget.stopAll();
    }
    super.dispose();
  }

  void _onActiveSessionChanged() {
    final activeId = TtsSpeakerButtonWidget._activeSessionNotifier.value;
    if (activeId != _mySessionId && _isSpeaking) {
      _pollTimer?.cancel();
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _handleTap() async {
    if (widget.text.trim().isEmpty) return;

    if (_isSpeaking) {
      await TtsSpeakerButtonWidget.stopAll();
      return;
    }

    // Stop any previous session before starting a new one
    await TtsSpeakerButtonWidget.stopAll();

    final sessionId = ++TtsSpeakerButtonWidget._sessionCounter;
    _mySessionId = sessionId;
    TtsSpeakerButtonWidget._activeSessionNotifier.value = sessionId;

    if (mounted) {
      setState(() {
        _isSpeaking = true;
      });
    }

    try {
      if (widget.isKids &&
          widget.locale == null &&
          di.sl.isRegistered<KidsTTSService>()) {
        await di.sl<KidsTTSService>().speak(widget.text, force: true);
      } else if (di.sl.isRegistered<TtsService>()) {
        await di.sl<TtsService>().speak(
          widget.text,
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

    // Watchdog and polling timer to detect when speech has completed
    _pollTimer?.cancel();
    int ticks = 0;
    // Allow up to 30 seconds for long explanation sentences
    const int maxTicks = 30 * 4;
    _pollTimer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      ticks++;
      if (!mounted ||
          TtsSpeakerButtonWidget._activeSessionNotifier.value != sessionId) {
        timer.cancel();
        return;
      }

      final isEngineSpeaking =
          di.sl.isRegistered<TtsService>() && di.sl<TtsService>().isSpeaking;

      // After giving the engine at least 500ms to spin up, check if it has stopped
      if ((ticks > 2 && !isEngineSpeaking) || ticks >= maxTicks) {
        timer.cancel();
        if (TtsSpeakerButtonWidget._activeSessionNotifier.value == sessionId) {
          TtsSpeakerButtonWidget._activeSessionNotifier.value = null;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = (widget.size ?? 16).r;

    return Semantics(
      label: _isSpeaking ? 'Stop audio narration' : 'Listen to audio narration',
      button: true,
      child: ScaleButton(
        onTap: _handleTap,
        child: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: _isSpeaking ? 0.25 : 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withValues(alpha: _isSpeaking ? 0.5 : 0.2),
              width: 1,
            ),
          ),
          child: Icon(
            _isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
            color: widget.color,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

