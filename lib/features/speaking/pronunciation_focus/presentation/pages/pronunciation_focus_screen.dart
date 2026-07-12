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
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
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
  int _attempts = 0;

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
      _attempts++;
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

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
      _heatLevel = 1.0;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _isListening = false;
              _heatLevel = 0.0;
              _spokenText = "";
              _showGuide = false;
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.lastAnswerCorrect == false) {
            setState(() {
              _isCorrect = false;
              if (state.isFinalFailure || state.livesRemaining <= 0) {
                _isAnswered = true;
              } else {
                _isAnswered = false;
              }
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
            onRestore: () => context.read<SpeakingBloc>().add(const RestoreLife()),
            onTutorPass: _tutorPass,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<SpeakingBloc>().add(NextQuestion()),
            onHint: () => context.read<SpeakingBloc>().add(SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      final bool isCompact = maxHeight < 580;
                      
                      final double estimatedContentHeight = 24.h + (isCompact ? 90.h : 120.h) + (isCompact ? 80.h : 110.h) + (isCompact ? 100.h : 140.h) + (isCompact ? 60.h : 80.h);
                      final remainingHeight = maxHeight - estimatedContentHeight;
                      
                      final double gapUnit = remainingHeight > 0 ? remainingHeight / 8 : 0;
                      final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(6.0, 16.0) : 6.0;
                      final double gapInstruction = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 12.0) : 8.0;
                      final double gapCrucible = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
                      final double gapGrid = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
                      final double gapSentence = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
                      final double gapTelemetry = remainingHeight > 0 ? (gapUnit * 2).clamp(12.0, 30.0) : 12.0;
                      final double gapBottom = remainingHeight > 0 ? (gapUnit * 1).clamp(12.0, 40.0) : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: maxHeight,
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTop),
                                    isCompact 
                                      ? SizedBox(
                                          height: 32.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: PronunciationFocusHeader(
                                              primaryColor: theme.primaryColor,
                                              instruction: quest.instruction,
                                            ),
                                          ),
                                        )
                                      : PronunciationFocusHeader(
                                          primaryColor: theme.primaryColor,
                                          instruction: quest.instruction,
                                        ),
                                    SizedBox(height: gapInstruction),
                                    
                                    isCompact
                                      ? SizedBox(
                                          height: 100.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 16.w,
                                              child: PronunciationFocusPhonemeCrucible(
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
                                            ),
                                          ),
                                        )
                                      : PronunciationFocusPhonemeCrucible(
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
                                    SizedBox(height: gapCrucible),

                                    isCompact
                                      ? SizedBox(
                                          height: 80.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 16.w,
                                              child: PronunciationFocusThermalGrid(
                                                heatLevel: _heatLevel,
                                                isListening: _isListening,
                                                timeVal: _timeVal,
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        )
                                      : PronunciationFocusThermalGrid(
                                          heatLevel: _heatLevel,
                                          isListening: _isListening,
                                          timeVal: _timeVal,
                                          isDark: isDark,
                                        ),
                                    SizedBox(height: gapGrid),

                                    isCompact
                                      ? SizedBox(
                                          height: 80.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 16.w,
                                              child: PronunciationFocusHighlightedSentence(
                                                quest: quest,
                                                primaryColor: theme.primaryColor,
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        )
                                      : PronunciationFocusHighlightedSentence(
                                          quest: quest,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                        ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapSentence),
                                    if (_spokenText.isNotEmpty)
                                      isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth - 16.w,
                                                child: PronunciationFocusTelemetryCard(
                                                  spokenText: _spokenText,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : PronunciationFocusTelemetryCard(
                                            spokenText: _spokenText,
                                            isDark: isDark,
                                          ),

                                    AnimatedCrossFade(
                                      firstChild: const SizedBox(),
                                      secondChild: isCompact
                                        ? SizedBox(
                                            height: 100.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth - 16.w,
                                                child: PronunciationFocusExplanationCard(
                                                  quest: quest,
                                                  isCorrect: _isCorrect ?? false,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : PronunciationFocusExplanationCard(
                                            quest: quest,
                                            isCorrect: _isCorrect ?? false,
                                            isDark: isDark,
                                          ),
                                      crossFadeState: _isAnswered
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 400),
                                    ),
                                    SizedBox(height: gapTelemetry),

                                    if (!_isAnswered)
                                      isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: PronunciationFocusMicCoreButton(
                                                isListening: _isListening,
                                                timeVal: _timeVal,
                                                primaryColor: theme.primaryColor,
                                                isDark: isDark,
                                                onLongPressStart: _startListening,
                                                onLongPressEnd: () => _stopListening(quest.textToSpeak ?? ""),
                                                attempts: _attempts,
                                                isAnswered: _isAnswered,
                                                onTutorPass: _tutorPass,
                                              ),
                                            ),
                                          )
                                        : PronunciationFocusMicCoreButton(
                                            isListening: _isListening,
                                            timeVal: _timeVal,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onLongPressStart: _startListening,
                                            onLongPressEnd: () => _stopListening(quest.textToSpeak ?? ""),
                                            attempts: _attempts,
                                            isAnswered: _isAnswered,
                                            onTutorPass: _tutorPass,
                                          ),
                                    SizedBox(height: gapBottom),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
