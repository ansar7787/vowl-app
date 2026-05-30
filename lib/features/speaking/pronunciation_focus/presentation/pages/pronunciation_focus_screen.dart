import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_header.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_phoneme_crucible.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_thermal_grid.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_highlighted_sentence.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_telemetry_card.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_explanation_card.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_mic_core_button.dart';

class PronunciationFocusScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const PronunciationFocusScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronunciationFocus,
  });

  @override
  State<PronunciationFocusScreen> createState() => _PronunciationFocusScreenState();
}

class _PronunciationFocusScreenState extends State<PronunciationFocusScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _heatLevel = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  late AnimationController _tickerController;
  Timer? _heatTimer;
  double _timeVal = 0.0;
  String _spokenText = "";
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _tickerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..addListener(() {
        setState(() {
          _timeVal = _tickerController.value;
        });
      });
    _tickerController.repeat();
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _heatTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _startListening() async {
    if (_isAnswered) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _heatLevel = 0.05;
      _spokenText = "Calibrating mouth audio streams...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );

    _heatTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!mounted || !_isListening) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_heatLevel < 0.95) {
          _heatLevel += 0.015 + (math.Random().nextDouble() * 0.01);
        } else {
          _heatLevel = 0.95 + (math.Random().nextDouble() * 0.05);
        }
      });
    });
  }

  void _stopListening(String expectedText) async {
    _heatTimer?.cancel();
    await _speechService.stop();
    
    setState(() {
      _isListening = false;
    });

    _verifyPronunciation(expectedText);
  }

  void _verifyPronunciation(String expected) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No audible voice input recorded.";
        _heatLevel = 0.0;
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpected = expected.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    final List<String> speechWords = cleanSpeech.split(' ');
    final List<String> expectedWords = cleanExpected.split(' ');

    int matches = 0;
    for (var word in speechWords) {
      if (expectedWords.contains(word)) {
        matches++;
      }
    }

    final double similarity = expectedWords.isNotEmpty ? matches / expectedWords.length : 0.0;
    final bool passed = similarity >= 0.75;

    setState(() {
      _isAnswered = true;
      _isCorrect = passed;
      _heatLevel = passed ? 1.0 : 0.0;
    });

    if (passed) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isListening = false;
              _heatLevel = 0.0;
              _spokenText = "";
              _showGuide = false;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CRITICAL MASS FUSION!',
            enableDoubleUp: true,
          );
        } else if (state is SpeakingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<SpeakingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return SpeakingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
          onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      PronunciationFocusHeader(primaryColor: theme.primaryColor),
                      SizedBox(height: 12.h),

                      PronunciationFocusPhonemeCrucible(
                        quest: quest,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                        heatLevel: _heatLevel,
                        showGuide: _showGuide,
                        onToggleGuide: () {
                          _hapticService.selection();
                          setState(() => _showGuide = !_showGuide);
                        },
                      ),
                      SizedBox(height: 20.h),

                      PronunciationFocusThermalGrid(
                        heatLevel: _heatLevel,
                        isListening: _isListening,
                        timeVal: _timeVal,
                        isDark: isDark,
                      ),
                      SizedBox(height: 20.h),

                      PronunciationFocusHighlightedSentence(
                        quest: quest,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(height: 20.h),

                      if (_spokenText.isNotEmpty) ...[
                        PronunciationFocusTelemetryCard(
                          spokenText: _spokenText,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),
                      ],

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: PronunciationFocusExplanationCard(
                          quest: quest,
                          isCorrect: _isCorrect ?? false,
                          isDark: isDark,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 30.h),

                      if (!_isAnswered)
                        PronunciationFocusMicCoreButton(
                          isListening: _isListening,
                          timeVal: _timeVal,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          onLongPressStart: _startListening,
                          onLongPressEnd: () => _stopListening(quest.textToSpeak ?? ""),
                        ),
                      SizedBox(height: 50.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
