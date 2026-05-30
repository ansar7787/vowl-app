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

import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_instruction.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_vortex_sentence.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_magnet_arena.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_telemetry_card.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_tactile_mic.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_explanation_card.dart';

class SpeakMissingWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakMissingWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakMissingWord,
  });

  @override
  State<SpeakMissingWordScreen> createState() => _SpeakMissingWordScreenState();
}

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  late AnimationController _vortexController;

  int _lastProcessedIndex = -1;
  int? _lastLives;

  // Option states
  List<String> _dynamicOptions = [];
  String? _selectedWord;
  double _pullForce = 0.0;
  bool _isListening = false;
  bool _isWordPlaced = false;

  // Speech states
  String _spokenText = "";
  bool _isSpeechActive = false;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  @override
  void initState() {
    super.initState();
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _vortexController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      _soundService.playTts(quest.textToSpeak!);
    }
  }

  void _generateDynamicOptions(String correctWord) {
    final List<String> distractors = [
      "satellite", "reactor", "circuit", "database",
      "system", "portal", "shield", "drone", "module"
    ];

    distractors.remove(correctWord.toLowerCase());
    distractors.shuffle(math.Random(widget.level));

    _dynamicOptions = [
      correctWord.toLowerCase(),
      distractors[0],
      distractors[1],
    ];

    _dynamicOptions.shuffle(math.Random(widget.level));
  }

  String _formatBlankSentence(String text, String missingWord) {
    final String cleanText = text;
    final List<String> nouns = [
      missingWord.toLowerCase(),
      "circuit", "database", "satellite", "shield",
      "reactor", "module", "engine", "network", "laser",
      "drone", "system", "portal", "archive", "data"
    ];

    for (var noun in nouns) {
      final int index = cleanText.toLowerCase().indexOf(noun);
      if (index != -1) {
        return cleanText.replaceRange(index, index + noun.length, " [ ______ ] ");
      }
    }

    return cleanText.replaceAll(missingWord, " [ ______ ] ");
  }

  void _onPullStart(String word) {
    if (_isAnswered || _isWordPlaced) return;
    _hapticService.selection();
    setState(() {
      _selectedWord = word;
      _isListening = true;
    });
  }

  void _onPullEnd() {
    if (_isAnswered || _isWordPlaced) return;
    setState(() {
      _isListening = false;
    });
    if (_pullForce >= 1.0) {
      _hapticService.success();
      _soundService.playClick();
      setState(() {
        _isWordPlaced = true;
      });
    } else {
      setState(() {
        _pullForce = 0.0;
        _selectedWord = null;
      });
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered || !_isWordPlaced) return;
    _hapticService.selection();

    setState(() {
      _isSpeechActive = true;
      _spokenText = "Voice capturing initiated...";
    });

    _speechService.listen(
      onResult: (text) {
        setState(() {
          _spokenText = text;
        });
      },
      onDone: () {
        if (mounted) setState(() => _isSpeechActive = false);
      },
    );
  }

  void _stopSpeechListening(String correctAnswer) async {
    await _speechService.stop();
    setState(() => _isSpeechActive = false);
    _verifySpeech(correctAnswer);
  }

  void _verifySpeech(String expected) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Voice capturing")) {
      setState(() {
        _spokenText = "No speech input recorded.";
      });
      return;
    }

    final bool wordIsCorrect = _selectedWord?.toLowerCase() == expected.toLowerCase();

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
    final bool speechIsCorrect = similarity >= 0.70;

    final bool isCorrect = wordIsCorrect && speechIsCorrect;

    setState(() {
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

    if (_isListening && _pullForce < 1.0) {
      Future.delayed(const Duration(milliseconds: 16), () {
        if (mounted && _isListening) {
          setState(() {
            _pullForce = (_pullForce + 0.045).clamp(0.0, 1.0);
            _hapticService.selection();
          });
        }
      });
    }

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
              _pullForce = 0.0;
              _selectedWord = null;
              _isWordPlaced = false;
              _spokenText = "";
              _generateDynamicOptions(state.currentQuest.missingWord ?? "drone");
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
            title: 'VERBAL VORTEX DRIVER!',
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

        final String rawSentence = quest?.textToSpeak ?? "The robot operates the system safely.";
        final String missingWord = quest?.missingWord ?? "robot";
        
        final String initialBlankSentence = _formatBlankSentence(rawSentence, missingWord);
        final String completedSentence = rawSentence;

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
                      SpeakMissingWordInstruction(
                        primaryColor: theme.primaryColor,
                        isWordPlaced: _isWordPlaced,
                      ),
                      SizedBox(height: 16.h),

                      SpeakMissingWordVortexSentence(
                        text: _isWordPlaced ? completedSentence : initialBlankSentence,
                        insertedWord: _isWordPlaced ? (_selectedWord ?? "") : "",
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(height: 20.h),

                      if (!_isWordPlaced)
                        SpeakMissingWordMagnetArena(
                          dynamicOptions: _dynamicOptions,
                          selectedWord: _selectedWord,
                          pullForce: _pullForce,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          vortexController: _vortexController,
                          onPullStart: _onPullStart,
                          onPullEnd: _onPullEnd,
                        ),

                      if (_isWordPlaced) ...[
                        SpeakMissingWordTelemetryCard(
                          spokenText: _spokenText,
                          isDark: isDark,
                        ),
                        SizedBox(height: 30.h),
                        
                        if (!_isAnswered)
                          SpeakMissingWordTactileMic(
                            isSpeechActive: _isSpeechActive,
                            primaryColor: theme.primaryColor,
                            onLongPressStart: _startSpeechListening,
                            onLongPressEnd: () => _stopSpeechListening(completedSentence),
                          ),
                      ],

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: SpeakMissingWordExplanationCard(
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
