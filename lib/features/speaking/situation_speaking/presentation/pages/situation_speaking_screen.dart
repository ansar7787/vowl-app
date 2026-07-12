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
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
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
  int _attempts = 0;

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
      _attempts++;
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

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
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
              _scrubProgress = 0.0;
              _spokenText = "";
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
            title: 'SITUATIONAL EXPERT!',
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

        if (quest != null) {
          _acceptedSubstrings = quest.acceptedSynonyms ?? [];
        }

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
                      final double gapInstruction = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 16.0) : 8.0;
                      final double gapScrubber = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
                      final double gapTelemetry = remainingHeight > 0 ? (gapUnit * 1.5).clamp(10.0, 24.0) : 10.0;
                      final double gapMic = remainingHeight > 0 ? (gapUnit * 2).clamp(12.0, 30.0) : 12.0;
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
                                            child: SituationSpeakingHeader(
                                              primaryColor: theme.primaryColor,
                                              instruction: quest.instruction,
                                            ),
                                          ),
                                        )
                                      : SituationSpeakingHeader(
                                          primaryColor: theme.primaryColor,
                                          instruction: quest.instruction,
                                        ),
                                    SizedBox(height: gapInstruction),
                                    
                                    isCompact
                                      ? SizedBox(
                                          height: 120.h,
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: SizedBox(
                                              width: constraints.maxWidth - 16.w,
                                              child: SituationSpeakingFogScrubberPanel(
                                                quest: quest,
                                                primaryColor: theme.primaryColor,
                                                isDark: isDark,
                                                scrubProgress: _scrubProgress,
                                                timeVal: _timeVal,
                                                onScrubUpdate: _onScrubUpdate,
                                                onPlayTts: () => _soundService.playTts(quest.situationText ?? ""),
                                              ),
                                            ),
                                          ),
                                        )
                                      : SituationSpeakingFogScrubberPanel(
                                          quest: quest,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          scrubProgress: _scrubProgress,
                                          timeVal: _timeVal,
                                          onScrubUpdate: _onScrubUpdate,
                                          onPlayTts: () => _soundService.playTts(quest.situationText ?? ""),
                                        ),
                                    SizedBox(height: gapScrubber),

                                    if (_spokenText.isNotEmpty)
                                      isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth - 16.w,
                                                child: SituationSpeakingTelemetryCard(
                                                  spokenText: _spokenText,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : SituationSpeakingTelemetryCard(
                                            spokenText: _spokenText,
                                            isDark: isDark,
                                          ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTelemetry),
                                    AnimatedCrossFade(
                                      firstChild: const SizedBox(),
                                      secondChild: isCompact
                                        ? SizedBox(
                                            height: 100.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width: constraints.maxWidth - 16.w,
                                                child: SituationSpeakingExplanationCard(
                                                  quest: quest,
                                                  isCorrect: _isCorrect ?? false,
                                                  isDark: isDark,
                                                ),
                                              ),
                                            ),
                                          )
                                        : SituationSpeakingExplanationCard(
                                            quest: quest,
                                            isCorrect: _isCorrect ?? false,
                                            isDark: isDark,
                                          ),
                                      crossFadeState: _isAnswered
                                          ? CrossFadeState.showSecond
                                          : CrossFadeState.showFirst,
                                      duration: const Duration(milliseconds: 400),
                                    ),
                                    SizedBox(height: gapMic),

                                    if (!_isAnswered)
                                      isCompact
                                        ? SizedBox(
                                            height: 70.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SituationSpeakingScrubbedMicTrigger(
                                                isListening: _isListening,
                                                scrubProgress: _scrubProgress,
                                                primaryColor: theme.primaryColor,
                                                isDark: isDark,
                                                onLongPressStart: _startSpeechListening,
                                                onLongPressEnd: _stopSpeechListening,
                                                attempts: _attempts,
                                                isAnswered: _isAnswered,
                                                onTutorPass: _tutorPass,
                                              ),
                                            ),
                                          )
                                        : SituationSpeakingScrubbedMicTrigger(
                                            isListening: _isListening,
                                            scrubProgress: _scrubProgress,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onLongPressStart: _startSpeechListening,
                                            onLongPressEnd: _stopSpeechListening,
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
