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
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking_self_evaluation_controls.dart';

import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_header_instruction.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_audition_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tilt_arena.dart';

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

  int _lastProcessedIndex = -1;
  int? _lastLives;

  double _tiltValue = 0.0;
  bool _isSnapped = false;

  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  Timer? _autoplayTimer;

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

  void _submitVerbalEvaluation(bool nailedIt, bool expectedMatch) {
    if (_isAnswered || !_isSnapped) return;

    final bool chosenMatch = _tiltValue > 0;
    final bool binaryIsCorrect = chosenMatch == expectedMatch;
    final bool isOverallCorrect = binaryIsCorrect && nailedIt;

    setState(() {
      _isAnswered = true;
      _isCorrect = isOverallCorrect;
    });

    if (isOverallCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
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
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _isSnapped = false;
              _tiltValue = 0.0;
            });
            _autoplayTimer?.cancel();
            _autoplayTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
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
            title: context.tr('speaking_games.binary_responder', fallback: 'BINARY RESPONDER!'),
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
            onContinue: () =>
                context.read<SpeakingBloc>().add(const NextQuestion()),
            onHint: () =>
                context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
            child: quest == null
                ? const SizedBox()
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 16.h,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              YesNoSpeakingHeaderInstruction(
                                primaryColor: theme.primaryColor,
                                isSnapped: _isSnapped,
                                instruction: quest.instruction,
                              ),
                              SizedBox(height: 24.h),
                              YesNoSpeakingAuditionCard(
                                quest: quest,
                                primaryColor: theme.primaryColor,
                                isDark: isDark,
                                onPlayTts: () => _soundService.playTts(
                                  quest.prompt ?? "",
                                ),
                              ),
                              SizedBox(height: 32.h),
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
                            ],
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (_isSnapped && !_isAnswered)
                                SpeakingSelfEvaluationControls(
                                  expectedText: quest.sampleAnswer ?? "",
                                  primaryColor: theme.primaryColor,
                                  isDark: isDark,
                                  onConfirmed: () =>
                                      _submitVerbalEvaluation(
                                        true,
                                        doTheyMatch,
                                      ),
                                  onSkipped: () =>
                                      _submitVerbalEvaluation(
                                        false,
                                        doTheyMatch,
                                      ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
