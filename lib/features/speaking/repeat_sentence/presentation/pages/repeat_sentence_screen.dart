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

  // Pre-cached dynamic target amplitudes for soundwave guidelines
  final List<double> _waveAmplitudes = [];

  @override
  void initState() {
    super.initState();
    _generateSoundwaveGuide();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
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
                      RepeatSentenceInstruction(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),
                      
                      RepeatSentenceAuditionCard(
                        quest: quest,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                        onPlayTts: () => _soundService.playTts(quest.textToSpeak ?? ""),
                      ),
                      SizedBox(height: 24.h),

                      RepeatSentenceWaveChamber(
                        progress: _progress,
                        isListening: _isListening,
                        themeColor: theme.primaryColor,
                        amplitudes: _waveAmplitudes,
                        isDark: isDark,
                      ),
                      SizedBox(height: 24.h),

                      RepeatSentenceTelemetryCard(
                        spokenText: _spokenText,
                        isDark: isDark,
                      ),
                      SizedBox(height: 30.h),

                      if (!_isAnswered)
                        RepeatSentenceTactileMic(
                          isListening: _isListening,
                          primaryColor: theme.primaryColor,
                          onLongPressStart: _startSpeechListening,
                          onLongPressEnd: () => _stopSpeechListening(quest.correctAnswer ?? ""),
                        ),

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: RepeatSentenceExplanationCard(
                          quest: quest,
                          isCorrect: _isCorrect ?? false,
                          isDark: isDark,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
