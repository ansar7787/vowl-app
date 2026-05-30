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

import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_header.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_fog_scrubber_panel.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_telemetry_card.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_explanation_card.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_scrubbed_mic_trigger.dart';

class SituationSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SituationSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationSpeaking,
  });

  @override
  State<SituationSpeakingScreen> createState() => _SituationSpeakingScreenState();
}

class _SituationSpeakingScreenState extends State<SituationSpeakingScreen> with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _speechService = di.sl<SpeechService>();

  double _scrubProgress = 0.0;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isListening = false;

  late AnimationController _shimmerController;
  double _timeVal = 0.0;
  String _spokenText = "";
  List<String> _acceptedSubstrings = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(FetchSpeakingQuests(gameType: widget.gameType, level: widget.level));

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addListener(() {
        setState(() {
          _timeVal = _shimmerController.value;
        });
      });
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.situationText != null) {
      _soundService.playTts(quest.situationText!);
    }
  }

  void _startSpeechListening() async {
    if (_isAnswered || _scrubProgress < 0.95) return;
    _hapticService.selection();

    setState(() {
      _isListening = true;
      _spokenText = "Calibrating conversational context decoder...";
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
  }

  void _stopSpeechListening() async {
    await _speechService.stop();

    setState(() {
      _isListening = false;
    });

    _verifyResponseSpoken();
  }

  void _verifyResponseSpoken() {
    if (_spokenText.isEmpty || _spokenText.startsWith("Calibrating")) {
      setState(() {
        _spokenText = "No voice frequency signature detected.";
      });
      _hapticService.error();
      return;
    }

    final String cleanSpeech = _spokenText.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    bool matchFound = false;

    for (var sub in _acceptedSubstrings) {
      final String cleanSub = sub.trim().toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
      if (cleanSpeech.contains(cleanSub)) {
        matchFound = true;
        break;
      }
    }

    setState(() {
      _isAnswered = true;
      _isCorrect = matchFound;
    });

    if (matchFound) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(SubmitAnswer(false));
    }
  }

  void _onScrubUpdate(double delta) {
    if (_isAnswered || _scrubProgress >= 1.0) return;
    setState(() {
      _scrubProgress = (_scrubProgress + delta).clamp(0.0, 1.0);
      if (_scrubProgress > 0) _hapticService.selection();
      if (_scrubProgress >= 1.0) {
        _hapticService.success();
        _soundService.playCorrect();
      }
    });
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
              _scrubProgress = 0.0;
              _spokenText = "";
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
            title: 'SITUATIONAL EXPERT!',
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

        if (quest != null) {
          _acceptedSubstrings = quest.acceptedSynonyms ?? [];
        }

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
                      SituationSpeakingHeader(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),

                      SituationSpeakingFogScrubberPanel(
                        quest: quest,
                        primaryColor: theme.primaryColor,
                        isDark: isDark,
                        scrubProgress: _scrubProgress,
                        timeVal: _timeVal,
                        onScrubUpdate: _onScrubUpdate,
                        onPlayTts: () => _soundService.playTts(quest.situationText ?? ""),
                      ),
                      SizedBox(height: 20.h),

                      if (_spokenText.isNotEmpty) ...[
                        SituationSpeakingTelemetryCard(
                          spokenText: _spokenText,
                          isDark: isDark,
                        ),
                        SizedBox(height: 20.h),
                      ],

                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: SituationSpeakingExplanationCard(
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
                        SituationSpeakingScrubbedMicTrigger(
                          isListening: _isListening,
                          scrubProgress: _scrubProgress,
                          primaryColor: theme.primaryColor,
                          isDark: isDark,
                          onLongPressStart: _startSpeechListening,
                          onLongPressEnd: _stopSpeechListening,
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
