import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/text_similarity_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:speech_to_text/speech_to_text.dart' show ListenMode;

class SttAutoPassWrapper extends StatefulWidget {
  final Widget child;
  final String expectedText;
  final List<String> acceptedSynonyms;
  final VoidCallback onAutoPass;
  final Color primaryColor;
  final bool isDark;

  const SttAutoPassWrapper({
    super.key,
    required this.child,
    required this.expectedText,
    this.acceptedSynonyms = const [],
    required this.onAutoPass,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  State<SttAutoPassWrapper> createState() => _SttAutoPassWrapperState();
}

class _SttAutoPassWrapperState extends State<SttAutoPassWrapper> {
  final _speechService = di.sl<SpeechService>();
  final _hapticService = di.sl<HapticService>();
  final ValueNotifier<bool> _isListening = ValueNotifier(false);
  final ValueNotifier<String> _currentSpokenText = ValueNotifier("");
  final ValueNotifier<double> _soundLevel = ValueNotifier(-50.0);
  final ValueNotifier<bool> _hasError = ValueNotifier(false);
  bool _hasPassed = false;
  bool _showFallback = false;

  @override
  void dispose() {
    _isListening.dispose();
    _currentSpokenText.dispose();
    _soundLevel.dispose();
    _hasError.dispose();
    if (_speechService.isListening) {
      _speechService.cancel();
    }
    super.dispose();
  }

  void _startListening() async {
    _hapticService.selection();
    _currentSpokenText.value = "";
    _soundLevel.value = -50.0;
    _isListening.value = true;
    _hasPassed = false;
    _hasError.value = false;

    await _speechService.listen(
      onResult: (candidates, isFinal) {
        if (!mounted || _hasPassed) return;
        if (candidates.isNotEmpty) {
          _currentSpokenText.value = candidates.first;
          _checkMatch(candidates);
        }
      },
      onSoundLevelChange: (level) {
        if (mounted) _soundLevel.value = level;
      },
      onDone: () {
        if (mounted) {
          _isListening.value = false;
          _evaluateStop();
        }
      },
      listenMode: ListenMode.dictation,
    );
  }

  void _stopListening() async {
    _hapticService.selection();
    _isListening.value = false;
    await _speechService.stop();
    _evaluateStop();
  }

  void _evaluateStop() {
    if (!mounted) return;

    if (!_hasPassed && _currentSpokenText.value.isNotEmpty) {
      // The user spoke something, but it didn't match. Show error feedback!
      _hasError.value = true;
      _hapticService.error();
    }
  }

  void _checkMatch(List<String> candidates) {
    if (_hasPassed) return;

    bool matched = false;
    for (final c in candidates) {
      if (widget.expectedText.isNotEmpty &&
          TextSimilarityHelper.isMatch(c, widget.expectedText)) {
        matched = true;
        break;
      }
      for (final s in widget.acceptedSynonyms) {
        if (s.isNotEmpty && TextSimilarityHelper.isMatch(c, s)) {
          matched = true;
          break;
        }
      }
      if (matched) break;
    }

    if (matched) {
      _hasPassed = true;
      _isListening.value = false;
      _speechService.stop();
      _hapticService.success();
      widget.onAutoPass();
    }
  }

  Widget _buildModernVisualizer() {
    return ValueListenableBuilder<double>(
      valueListenable: _soundLevel,
      builder: (context, level, child) {
        // Normalize level for iOS (-50 to 0) and Android (-2 to ~10)
        double normalized = 0.0;
        if (Platform.isIOS || Platform.isMacOS) {
          normalized = (level + 50) / 50.0;
        } else {
          // Android typically outputs RMS between -2 (silence) and 10 (loud)
          normalized = (level + 2) / 12.0;
        }
        normalized = normalized.clamp(0.1, 1.0);

        // Add a slight baseline pulse if it's too quiet so it still looks alive
        if (normalized < 0.2) {
          normalized += (DateTime.now().millisecondsSinceEpoch % 1000) / 5000.0;
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final modifier = const [0.4, 0.8, 1.0, 0.8, 0.4][index];
            final targetHeight = 12.h + (36.h * normalized * modifier);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOutQuad,
              margin: EdgeInsets.symmetric(horizontal: 2.w),
              width: 4.w,
              height: targetHeight,
              decoration: BoxDecoration(
                color: widget.primaryColor,
                borderRadius: BorderRadius.circular(2.r),
              ),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showFallback) {
      return widget.child;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // STT Auto-Pass Mechanic
        AnimatedBuilder(
          animation: Listenable.merge([_isListening, _hasError]),
          builder: (context, _) {
            final isListening = _isListening.value;
            final hasError = _hasError.value;

            return GestureDetector(
              onTap: () {
                if (isListening) {
                  _stopListening();
                } else {
                  _startListening();
                }
              },
              child: Animate(
                target: hasError ? 1 : 0,
                effects: const [
                  ShakeEffect(
                    curve: Curves.easeInOutCubic,
                    duration: Duration(milliseconds: 400),
                  ),
                ],
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 24.h,
                    horizontal: 20.w,
                  ),
                  decoration: BoxDecoration(
                    color: hasError
                        ? Colors.redAccent.withValues(alpha: 0.1)
                        : (isListening
                              ? widget.primaryColor.withValues(alpha: 0.15)
                              : (widget.isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.03))),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: hasError
                          ? Colors.redAccent
                          : (isListening
                                ? widget.primaryColor
                                : widget.primaryColor.withValues(alpha: 0.3)),
                      width: isListening || hasError ? 2 : 1,
                    ),
                    boxShadow: isListening && !hasError
                        ? [
                            BoxShadow(
                              color: widget.primaryColor.withValues(alpha: 0.2),
                              blurRadius: 24,
                              spreadRadius: 2,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(
                              scale: animation,
                              child: FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                            ),
                        child: isListening
                            ? SizedBox(
                                key: const ValueKey('visualizer'),
                                height: 48.sp,
                                child: Center(child: _buildModernVisualizer()),
                              )
                            : Icon(
                                Icons.mic_rounded,
                                key: const ValueKey('mic_icon'),
                                color: widget.primaryColor,
                                size: 48.sp,
                              ),
                      ),
                      SizedBox(height: 16.h),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          isListening
                              ? 'Listening... Tap to stop'
                              : 'Tap to Speak',
                          key: ValueKey(isListening),
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: widget.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _currentSpokenText,
                          _hasError,
                        ]),
                        builder: (context, _) {
                          final spokenText = _currentSpokenText.value;
                          final hasError = _hasError.value;

                          if (spokenText.isEmpty) {
                            return Text(
                              'Matches instantly when correct',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w500,
                                color: widget.isDark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                            );
                          }

                          return Column(
                            children: [
                              AutoSizeText(
                                hasError
                                    ? 'Heard: "$spokenText"'
                                    : '"$spokenText"',
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                minFontSize: 8,
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: hasError
                                      ? Colors.redAccent
                                      : (widget.isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                ),
                              ),
                              if (hasError)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Text(
                                    'Incorrect. Tap mic to try again.',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                ).animate().fadeIn().slideY(begin: -0.2),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        SizedBox(height: 16.h),
        ValueListenableBuilder<bool>(
          valueListenable: _hasError,
          builder: (context, hasError, _) {
            return TextButton(
              onPressed: () {
                if (_isListening.value) {
                  _stopListening();
                }
                setState(() {
                  _showFallback = true;
                });
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                  side: BorderSide(
                    color: hasError
                        ? Colors.redAccent.withValues(alpha: 0.3)
                        : widget.primaryColor.withValues(alpha: 0.2),
                    width: hasError ? 1.5 : 1.0,
                  ),
                ),
              ),
              child: AutoSizeText(
                hasError
                    ? 'Did we mishear you? Evaluate manually'
                    : 'Evaluate myself manually',
                maxLines: 1,
                minFontSize: 8,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: hasError
                      ? Colors.redAccent
                      : widget.primaryColor.withValues(alpha: 0.7),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
