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

import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_instruction.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_audition_card.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_wave_chamber.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_telemetry_card.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_tactile_mic.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_explanation_card.dart';

class RepeatSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RepeatSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.repeatSentence,
  });

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();
  
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;
  String _spokenText = "";
  double _progress = 0.0; // Vocal trace tracing progress (0.0 to 1.0)
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Timer? _autoplayTimer;

  // Pre-cached dynamic target amplitudes for soundwave guidelines
  final List<double> _waveAmplitudes = [];

  @override
  void initState() {
    super.initState();
    _generateSoundwaveGuide();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    super.dispose();
  }

  void _generateSoundwaveGuide() {
    final math.Random random = math.Random(widget.level);
    _waveAmplitudes.clear();
    for (int i = 0; i <= 65; i++) {
      // Dynamic height profiles mimicking phoneme sound pressure spikes
      _waveAmplitudes.add(10.h + random.nextDouble() * 24.h);
    }
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered) return;
    _hapticService.selection();
    
    setState(() {
      _isListening = true;
      _spokenText = "Deciphering vocal coordinates...";
      _progress = 0.05;
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
          // Progress tracks similarity length comparison
          _progress = (text.length / 32.0).clamp(0.05, 1.0);
        });
      },
      onDone: () {
        if (mounted) setState(() => _isListening = false);
      },
    );
  }

  void _stopSpeechListening(String expectedAnswer) async {
    await _speechService.stop();
    setState(() => _isListening = false);
    _verifySpeech(expectedAnswer);
  }

  void _verifySpeech(String expected) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Deciphering")) {
      setState(() {
        _spokenText = "No audible vocal input recorded.";
        _progress = 0.0;
      });
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpected = expected.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

    // Similarity calculations: word-level matching
    final List<String> speechWords = cleanSpeech.split(' ');
    final List<String> expectedWords = cleanExpected.split(' ');

    int matches = 0;
    for (var word in speechWords) {
      if (expectedWords.contains(word)) {
        matches++;
      }
    }

    final double similarity = expectedWords.isNotEmpty ? matches / expectedWords.length : 0.0;
    final bool isCorrect = similarity >= 0.70; // 70% matching word-level accuracy to pass repeat sentence

    setState(() {
      _progress = 1.0;
      _isAnswered = true;
      _isCorrect = isCorrect;
    });

    if (isCorrect) {
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
              _progress = 0.0;
              _spokenText = "";
              _generateSoundwaveGuide();
            });
            _autoplayTimer?.cancel();
            _autoplayTimer = Timer(const Duration(milliseconds: 300), () {
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
            title: 'SOUND WAVE TRANSCRIBER!',
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
        final mediaQuery = MediaQuery.of(context);

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
                      
                      final double estimatedContentHeight = 24.h + (isCompact ? 90.h : 120.h) + (isCompact ? 70.h : 100.h) + (isCompact ? 60.h : 80.h) + (isCompact ? 60.h : 80.h);
                      final remainingHeight = maxHeight - estimatedContentHeight;
                      
                      final double gapUnit = remainingHeight > 0 ? remainingHeight / 8 : 0;
                      final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(6.0, 16.0) : 6.0;
                      final double gapInstruction = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 16.0) : 8.0;
                      final double gapCard = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
                      final double gapChamber = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
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
                                            child: RepeatSentenceInstruction(
                                              primaryColor: theme.primaryColor,
                                              instruction: quest.instruction,
                                            ),
                                          ),
                                        )
                                      : RepeatSentenceInstruction(
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
                                              child: RepeatSentenceAuditionCard(
                                                quest: quest,
                                                primaryColor: theme.primaryColor,
                                                isDark: isDark,
                                                onPlayTts: () => _soundService.playTts(quest.textToSpeak ?? ""),
                                              ),
                                            ),
                                          ),
                                        )
                                      : RepeatSentenceAuditionCard(
                                          quest: quest,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          onPlayTts: () => _soundService.playTts(quest.textToSpeak ?? ""),
                                        ),
                                    SizedBox(height: gapCard),

                                    isCompact
                                      ? SizedBox(
                                          height: 80.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 16.w,
                                              child: RepeatSentenceWaveChamber(
                                                progress: _progress,
                                                isListening: _isListening,
                                                themeColor: theme.primaryColor,
                                                amplitudes: _waveAmplitudes,
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        )
                                      : RepeatSentenceWaveChamber(
                                          progress: _progress,
                                          isListening: _isListening,
                                          themeColor: theme.primaryColor,
                                          amplitudes: _waveAmplitudes,
                                          isDark: isDark,
                                        ),
                                    SizedBox(height: gapChamber),

                                    isCompact
                                      ? SizedBox(
                                          height: 70.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 16.w,
                                              child: RepeatSentenceTelemetryCard(
                                                spokenText: _spokenText,
                                                isDark: isDark,
                                              ),
                                            ),
                                          ),
                                        )
                                      : RepeatSentenceTelemetryCard(
                                          spokenText: _spokenText,
                                          isDark: isDark,
                                        ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTelemetry),
                                    if (!_isAnswered)
                                      isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: RepeatSentenceTactileMic(
                                                isListening: _isListening,
                                                primaryColor: theme.primaryColor,
                                                onLongPressStart: _startSpeechListening,
                                                onLongPressEnd: () => _stopSpeechListening(quest.textToSpeak ?? ""),
                                              ),
                                            ),
                                          )
                                        : RepeatSentenceTactileMic(
                                            isListening: _isListening,
                                            primaryColor: theme.primaryColor,
                                            onLongPressStart: _startSpeechListening,
                                            onLongPressEnd: () => _stopSpeechListening(quest.textToSpeak ?? ""),
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
                                                child: RepeatSentenceExplanationCard(
                                                  quest: quest,
                                                  isCorrect: _isCorrect ?? false,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : RepeatSentenceExplanationCard(
                                            quest: quest,
                                            isCorrect: _isCorrect ?? false,
                                            isDark: isDark,
                                          ),
                                      crossFadeState: _isAnswered
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 400),
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
