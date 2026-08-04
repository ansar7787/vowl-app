import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Universal "Speak to Confirm" overlay that slides up after a correct
/// click/drag answer, requiring the user to say the answer aloud before
/// proceeding.
///
/// This bridges the gap between passive recognition (clicking) and active
/// production (speaking), which is critical for Accent, Roleplay, and
/// Grammar modules where clicking alone doesn't teach the skill.
///
/// Usage:
/// ```dart
/// if (showSpeakConfirm)
///   SpeakToConfirmOverlay(
///     expectedText: quest.correctAnswer ?? '',
///     primaryColor: theme.primaryColor,
///     onConfirmed: () => bloc.add(NextQuestion()),
///     onSkipped: () => bloc.add(NextQuestion()),
///   ),
/// ```
class SpeakToConfirmOverlay extends StatefulWidget {
  /// The expected spoken text to match against STT output.
  final String expectedText;

  /// Optional display text shown to the user (if different from expectedText).
  /// Falls back to [expectedText] if null.
  final String? displayText;

  /// Theme accent colour for the overlay chrome.
  final Color primaryColor;

  /// Fires when the user successfully speaks the answer (match ≥ threshold).
  final VoidCallback onConfirmed;

  /// Fires when the user exhausts retries or taps "Skip".
  final VoidCallback onSkipped;

  /// Similarity threshold for STT match (0.0–1.0). Default 0.65 is lenient
  /// because this is a *confirmation* phase, not a pronunciation exam.
  final double threshold;

  /// Maximum number of recording attempts before auto-skip. Default 3.
  final int maxAttempts;

  /// Bonus Coins awarded on success. Null hides the badge entirely.
  final int? bonusCoins;

  /// Whether to show a "Skip" button. Defaults to true for accessibility
  /// (muted environments, device without mic, etc.).
  final bool allowSkip;

  const SpeakToConfirmOverlay({
    super.key,
    required this.expectedText,
    this.displayText,
    required this.primaryColor,
    required this.onConfirmed,
    required this.onSkipped,
    this.threshold = 0.65,
    this.maxAttempts = 3,
    this.bonusCoins = 5,
    this.allowSkip = true,
  });

  @override
  State<SpeakToConfirmOverlay> createState() => _SpeakToConfirmOverlayState();
}

class _SpeakToConfirmOverlayState extends State<SpeakToConfirmOverlay>
    with SingleTickerProviderStateMixin {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  bool _isListening = false;
  String _spokenText = '';
  List<String> _spokenCandidates = [];
  int _attempts = 0;
  _ConfirmResult? _result;
  bool _isLoadingPrefs = true;
  bool _globalSkipEnabled = false;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _checkGlobalSkip();
  }

  Future<void> _checkGlobalSkip() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final skipEnabled = prefs.getBool('skip_speech_enabled') ?? false;
      if (!mounted) return;
      if (skipEnabled) {
        widget.onSkipped();
      } else {
        setState(() => _isLoadingPrefs = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPrefs = false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechService.cancel();
    super.dispose();
  }

  // ── STT lifecycle ──────────────────────────────────────────────────────

  Future<void> _startListening() async {
    if (_isListening || _result == _ConfirmResult.success) return;

    _hapticService.selection();
    setState(() {
      _isListening = true;
      _spokenText = '';
      _spokenCandidates = [];
      _result = null;
    });

    _speechService.listen(
      onResult: (candidates, isFinal) {
        if (candidates.isEmpty) return;
        setState(() {
          _spokenCandidates = candidates;
          _spokenText = candidates.first;
        });
      },
      onDone: () {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      pauseFor: const Duration(seconds: 4),
    );
  }

  Future<void> _stopListening() async {
    await _speechService.stop();
    if (!mounted) return;
    setState(() => _isListening = false);
    await _evaluate();
  }

  Future<void> _evaluate() async {
    if (_spokenText.isEmpty) {
      setState(() => _result = _ConfirmResult.empty);
      return;
    }

    // Language guard — same pattern used in speaking games.
    try {
      final langService = di.sl<LanguageIdService>();
      final lang = await langService.identifyLanguage(_spokenText);
      if (lang != 'en' && lang != 'und') {
        if (!mounted) return;
        setState(() => _result = _ConfirmResult.wrongLanguage);
        _hapticService.error();
        return;
      }
    } catch (_) {
      // LanguageIdService may not be available — proceed without gating.
    }

    bool matched = false;
    for (final candidate in _spokenCandidates.isEmpty
        ? [_spokenText]
        : _spokenCandidates) {
      if (TextSimilarityHelper.isMatch(
        candidate,
        widget.expectedText,
        threshold: widget.threshold,
      )) {
        matched = true;
        _spokenText = candidate;
        break;
      }
    }

    if (!mounted) return;

    setState(() {
      _attempts++;
      _result = matched ? _ConfirmResult.success : _ConfirmResult.mismatch;
    });

    if (matched) {
      _hapticService.success();
      _soundService.playCorrect();
      // Brief celebration before calling back.
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) widget.onConfirmed();
    } else {
      _hapticService.error();
      if (_attempts >= widget.maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) widget.onSkipped();
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingPrefs) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: _buildPanel(isDark)
          .animate()
          .slideY(begin: 1.0, end: 0, duration: 400.ms, curve: Curves.easeOut)
          .fadeIn(duration: 300.ms),
    );
  }

  Widget _buildPanel(bool isDark) {
    final bgColor = isDark ? const Color(0xFF0C0C1A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 32.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
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
            // ── Handle bar ──
            Container(
              width: 48.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: subtitleColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Header ──
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: widget.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Icon(
                    Icons.mic_rounded,
                    color: widget.primaryColor,
                    size: 22.r,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NOW SAY IT!',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: widget.primaryColor,
                          letterSpacing: 2,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'Speak the answer to confirm',
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
                if (widget.bonusCoins != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.primaryColor,
                          widget.primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '+${widget.bonusCoins} Coins',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20.h),

            // ── Expected text display ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                widget.displayText ?? widget.expectedText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: 16.h),

            // ── Spoken text feedback ──
            if (_spokenText.isNotEmpty && !_spokenText.startsWith('Deciphering'))
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: _resultColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      _resultIcon,
                      color: _resultColor,
                      size: 18.r,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _spokenText,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: _resultColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms),

            // ── Status message ──
            if (_result != null && _result != _ConfirmResult.success)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: _resultColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            SizedBox(height: 20.h),

            // ── Mic button ──
            if (_result != _ConfirmResult.success)
              _buildMicButton(isDark),

            // ── Skip button ──
            if (widget.allowSkip && _result != _ConfirmResult.success)
              Padding(
                padding: EdgeInsets.only(top: 12.h),
                child: Column(
                  children: [
                    ScaleButton(
                      onTap: () async {
                        if (_globalSkipEnabled) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('skip_speech_enabled', true);
                        }
                        widget.onSkipped();
                      },
                      child: Text(
                        _attempts >= widget.maxAttempts
                            ? 'CONTINUE'
                            : 'CAN\'T SPEAK NOW',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: subtitleColor,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (_attempts < widget.maxAttempts) ...[
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 24.r,
                            width: 24.r,
                            child: Checkbox(
                              value: _globalSkipEnabled,
                              onChanged: (val) {
                                setState(() {
                                  _globalSkipEnabled = val ?? false;
                                });
                              },
                              activeColor: widget.primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _globalSkipEnabled = !_globalSkipEnabled;
                              });
                            },
                            child: Text(
                              'Skip all speaking tasks for now',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w500,
                                color: subtitleColor.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            // ── Attempt counter ──
            if (_attempts > 0 && _result != _ConfirmResult.success)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '${widget.maxAttempts - _attempts} attempts remaining',
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor.withValues(alpha: 0.6),
                  ),
                ),
              ),

            // ── Success state ──
            if (_result == _ConfirmResult.success)
              Column(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    color: Colors.greenAccent,
                    size: 48.r,
                  ).animate().scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 400.ms,
                        curve: Curves.easeOutBack,
                      ),
                  SizedBox(height: 8.h),
                  Text(
                    'PERFECT! 🎯',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.greenAccent,
                      letterSpacing: 2,
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                ],
              ),
          ],
        ),
      ),
    ));
  }

  Widget _buildMicButton(bool isDark) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final double pulseScale = _isListening
            ? 1.0 + (_pulseController.value * 0.08)
            : 1.0;

        return Transform.scale(
          scale: pulseScale,
          child: GestureDetector(
            onLongPressStart: (_) => _startListening(),
            onLongPressEnd: (_) => _stopListening(),
            child: Container(
              width: 72.r,
              height: 72.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _isListening
                      ? [Colors.redAccent, Colors.red.shade700]
                      : [widget.primaryColor, widget.primaryColor.withValues(alpha: 0.7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? Colors.redAccent : widget.primaryColor)
                        .withValues(alpha: _isListening ? 0.5 : 0.3),
                    blurRadius: _isListening ? 24 : 16,
                    spreadRadius: _isListening ? 4 : 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening
                        ? Icons.graphic_eq_rounded
                        : Icons.mic_rounded,
                    color: Colors.white,
                    size: 28.r,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    _isListening ? 'RELEASE' : 'HOLD',
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 7.sp,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Computed properties ────────────────────────────────────────────────

  Color get _resultColor {
    switch (_result) {
      case _ConfirmResult.success:
        return Colors.greenAccent;
      case _ConfirmResult.mismatch:
      case _ConfirmResult.wrongLanguage:
        return Colors.redAccent;
      case _ConfirmResult.empty:
        return Colors.orangeAccent;
      case null:
        return widget.primaryColor;
    }
  }

  IconData get _resultIcon {
    switch (_result) {
      case _ConfirmResult.success:
        return Icons.check_circle_rounded;
      case _ConfirmResult.mismatch:
      case _ConfirmResult.wrongLanguage:
        return Icons.error_outline_rounded;
      case _ConfirmResult.empty:
        return Icons.mic_off_rounded;
      case null:
        return Icons.hearing_rounded;
    }
  }

  String get _statusMessage {
    switch (_result) {
      case _ConfirmResult.mismatch:
        return "Hmm, that didn't match. Try saying it more clearly!";
      case _ConfirmResult.wrongLanguage:
        return 'Please speak in English!';
      case _ConfirmResult.empty:
        return 'No voice detected. Hold the mic and speak clearly.';
      default:
        return '';
    }
  }
}

enum _ConfirmResult { success, mismatch, wrongLanguage, empty }
