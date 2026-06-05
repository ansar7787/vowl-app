import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/widgets/speaking_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';

import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_header_instruction.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_audition_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tilt_arena.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_telemetry_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tactile_mic.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_explanation_card.dart';

class YesNoSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const YesNoSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.yesNoSpeaking,
  });

  @override
  State<YesNoSpeakingScreen> createState() => _YesNoSpeakingScreenState();
}

class _YesNoSpeakingScreenState extends State<YesNoSpeakingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;

  double _tiltValue = 0.0;
  bool _isSnapped = false;
  bool _isSpeechActive = false;

  String _spokenText = "";
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Timer? _autoplayTimer;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _autoplayTimer?.cancel();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.prompt != null) {
      _soundService.playTts(quest.prompt!);
    }
  }

  void _onTiltDragged(DragUpdateDetails details, double trackWidth) {
    if (_isAnswered || _isSnapped) return;
    
    final double deltaNormalized = details.delta.dx / (trackWidth / 2);
    _hapticService.selection();

    setState(() {
      _tiltValue = (_tiltValue + deltaNormalized).clamp(-1.0, 1.0);
      
      if (_tiltValue <= -0.85) {
        _tiltValue = -1.0;
        _isSnapped = true;
        _soundService.playClick();
        _hapticService.selection();
      } else if (_tiltValue >= 0.85) {
        _tiltValue = 1.0;
        _isSnapped = true;
        _soundService.playClick();
        _hapticService.selection();
      }
    });
  }

  void _startSpeechListening() async {
    if (_isAnswered || !_isSnapped) return;
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

  void _stopSpeechListening(String expectedText, bool expectedMatch) async {
    await _speechService.stop();
    setState(() => _isSpeechActive = false);
    _verifyBinaryResponse(expectedText, expectedMatch);
  }

  void _verifyBinaryResponse(String expectedText, bool expectedMatch) {
    if (_spokenText.isEmpty || _spokenText.startsWith("Voice capturing")) {
      setState(() {
        _spokenText = "No audible voice input recorded.";
      });
      return;
    }

    final bool chosenMatch = _tiltValue > 0;
    final bool binaryIsCorrect = chosenMatch == expectedMatch;

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final String cleanExpected = expectedText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');

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

    final bool isCorrect = binaryIsCorrect && speechIsCorrect;

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

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isSnapped = false;
              _tiltValue = 0.0;
              _spokenText = "";
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
            title: 'BINARY RESPONDER!',
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

        final String rawPrompt = quest?.prompt ?? "";
        final String rawSample = quest?.sampleAnswer ?? "";
        final bool doTheyMatch = rawPrompt.trim().toLowerCase() == rawSample.trim().toLowerCase();

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
                      YesNoSpeakingHeaderInstruction(
                        primaryColor: theme.primaryColor,
                        isSnapped: _isSnapped,
                      ),
                      SizedBox(height: 16.h),

                      YesNoSpeakingAuditionCard(
                        quest: quest,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                        onPlayTts: () => _soundService.playTts(quest.prompt ?? ""),
                      ),
                      SizedBox(height: 24.h),

                      YesNoSpeakingTiltArena(
                        tiltValue: _tiltValue,
                        isSnapped: _isSnapped,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                        onTiltDragged: _onTiltDragged,
                        onTiltDragEnd: () {
                          if (!_isSnapped) {
                            setState(() => _tiltValue = 0.0);
                          }
                        },
                      ),
                      SizedBox(height: 24.h),

                      if (_isSnapped) ...[
                        YesNoSpeakingTelemetryCard(
                          spokenText: _spokenText,
                          isDark: isDark,
                        ),
                        SizedBox(height: 30.h),

                        if (!_isAnswered)
                          YesNoSpeakingTactileMic(
                            isSpeechActive: _isSpeechActive,
                            primaryColor: theme.primaryColor,
                            onLongPressStart: _startSpeechListening,
                            onLongPressEnd: () => _stopSpeechListening(quest.sampleAnswer ?? "", doTheyMatch),
                          ),
                      ],

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: YesNoSpeakingExplanationCard(
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
