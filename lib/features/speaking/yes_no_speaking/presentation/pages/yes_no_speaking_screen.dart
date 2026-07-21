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
import 'package:vowl/core/utils/text_similarity_helper.dart';

import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_header_instruction.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_audition_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tilt_arena.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_telemetry_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tactile_mic.dart';

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
  List<String> _spokenCandidates = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Timer? _autoplayTimer;
  int _attempts = 0;

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );
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
      onResult: (candidates) {
          if (candidates.isEmpty) return;
          _spokenCandidates = candidates;
          final text = candidates.first;
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

    final bool speechIsCorrect = TextSimilarityHelper.isMatch(
      _spokenText,
      expectedText,
      threshold: 0.70,
    );

    final bool isCorrect = binaryIsCorrect && speechIsCorrect;

    setState(() {
      _attempts++;
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

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
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
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _attempts = 0;
              _isSnapped = false;
              _tiltValue = 0.0;
              _spokenText = "";
            });
            _autoplayTimer?.cancel();
            _autoplayTimer = Timer(const Duration(milliseconds: 300), () {
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
            title: 'BINARY RESPONDER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        final String rawPrompt = quest?.prompt ?? "";
        final String rawSample = quest?.sampleAnswer ?? "";
        final bool doTheyMatch =
            rawPrompt.trim().toLowerCase() == rawSample.trim().toLowerCase();

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: SpeakingBaseLayout(
            onTutorPass: _tutorPass,
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

                      final double estimatedContentHeight =
                          24.h +
                          (isCompact ? 90.h : 120.h) +
                          (isCompact ? 80.h : 110.h) +
                          (isCompact ? 100.h : 140.h) +
                          (isCompact ? 60.h : 80.h);
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(6.0, 16.0)
                          : 6.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 16.0)
                          : 8.0;
                      final double gapAudition = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapTilt = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(10.0, 24.0)
                          : 10.0;
                      final double gapTelemetry = remainingHeight > 0
                          ? (gapUnit * 2).clamp(12.0, 30.0)
                          : 12.0;
                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
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
                                              child:
                                                  YesNoSpeakingHeaderInstruction(
                                                    primaryColor:
                                                        theme.primaryColor,
                                                    isSnapped: _isSnapped,
                                                    instruction:
                                                        quest.instruction,
                                                  ),
                                            ),
                                          )
                                        : YesNoSpeakingHeaderInstruction(
                                            primaryColor: theme.primaryColor,
                                            isSnapped: _isSnapped,
                                            instruction: quest.instruction,
                                          ),
                                    SizedBox(height: gapInstruction),

                                    isCompact
                                        ? SizedBox(
                                            height: 100.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child:
                                                    YesNoSpeakingAuditionCard(
                                                      quest: quest,
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      isDark: isDark,
                                                      onPlayTts: () =>
                                                          _soundService.playTts(
                                                            quest.prompt ?? "",
                                                          ),
                                                    ),
                                              ),
                                            ),
                                          )
                                        : YesNoSpeakingAuditionCard(
                                            quest: quest,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onPlayTts: () => _soundService
                                                .playTts(quest.prompt ?? ""),
                                          ),
                                    SizedBox(height: gapAudition),

                                    isCompact
                                        ? SizedBox(
                                            height: 80.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: SizedBox(
                                                width:
                                                    constraints.maxWidth - 16.w,
                                                child: YesNoSpeakingTiltArena(
                                                  tiltValue: _tiltValue,
                                                  isSnapped: _isSnapped,
                                                  primaryColor:
                                                      theme.primaryColor,
                                                  isDark: isDark,
                                                  onTiltDragged: _onTiltDragged,
                                                  onTiltDragEnd: () {
                                                    if (!_isSnapped) {
                                                      setState(
                                                        () => _tiltValue = 0.0,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          )
                                        : YesNoSpeakingTiltArena(
                                            tiltValue: _tiltValue,
                                            isSnapped: _isSnapped,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onTiltDragged: _onTiltDragged,
                                            onTiltDragEnd: () {
                                              if (!_isSnapped) {
                                                setState(
                                                  () => _tiltValue = 0.0,
                                                );
                                              }
                                            },
                                          ),
                                  ],
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(height: gapTilt),
                                    if (_isSnapped) ...[
                                      isCompact
                                          ? SizedBox(
                                              height: 70.h,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: SizedBox(
                                                  width:
                                                      constraints.maxWidth -
                                                      16.w,
                                                  child:
                                                      YesNoSpeakingTelemetryCard(
                                                        spokenText: _spokenText,
                                                        isDark: isDark,
                                                      ),
                                                ),
                                              ),
                                            )
                                          : YesNoSpeakingTelemetryCard(
                                              spokenText: _spokenText,
                                              isDark: isDark,
                                            ),
                                      SizedBox(height: gapTelemetry),

                                      if (!_isAnswered)
                                        isCompact
                                            ? SizedBox(
                                                height: 70.h,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: YesNoSpeakingTactileMic(
                                                    isSpeechActive:
                                                        _isSpeechActive,
                                                    primaryColor:
                                                        theme.primaryColor,
                                                    onLongPressStart:
                                                        _startSpeechListening,
                                                    onLongPressEnd: () =>
                                                        _stopSpeechListening(
                                                          quest.sampleAnswer ??
                                                              "",
                                                          doTheyMatch,
                                                        ),
                                                    attempts: _attempts,
                                                    isAnswered: _isAnswered,
                                                    
                                                  ),
                                                ),
                                              )
                                            : YesNoSpeakingTactileMic(
                                                isSpeechActive: _isSpeechActive,
                                                primaryColor:
                                                    theme.primaryColor,
                                                onLongPressStart:
                                                    _startSpeechListening,
                                                onLongPressEnd: () =>
                                                    _stopSpeechListening(
                                                      quest.sampleAnswer ?? "",
                                                      doTheyMatch,
                                                    ),
                                                attempts: _attempts,
                                                isAnswered: _isAnswered,
                                                
                                              ),
                                    ],

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

