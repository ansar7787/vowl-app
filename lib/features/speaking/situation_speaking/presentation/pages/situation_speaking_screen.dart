import 'package:vowl/core/utils/instruction_helper.dart';
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
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_header.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_fog_scrubber_panel.dart';

class SituationSpeakingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SituationSpeakingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationSpeaking,
  });

  @override
  State<SituationSpeakingScreen> createState() =>
      _SituationSpeakingScreenState();
}

class _SituationSpeakingScreenState extends State<SituationSpeakingScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _scrubProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  late AnimationController _shimmerController;
  final ValueNotifier<double> _timeVal = ValueNotifier(0.0);

  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _shimmerController =
        AnimationController(vsync: this, duration: const Duration(seconds: 4))
          ..addListener(() {
            _timeVal.value = _shimmerController.value;
          });
    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _scrubProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.situationText != null) {
      _soundService.playTts(quest.situationText!);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, String textToSpeak) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Situation Speaking',
          userAnswer: '[Failed Context/Timer]',
          correctAnswer: textToSpeak,
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onTimeUp(String textToSpeak) {
    if (_isAnswered.value) return;
    _submitVerbalEvaluation(false, textToSpeak);
  }

  void _tutorPass() {
    GameDialogHelper.showHonestyNudge(context);
    _isAnswered.value = true;
    _isCorrect.value = true;
    context.read<SpeakingBloc>().add(const SpeakingTutorPass());
  }

  void _onScrubUpdate(double delta) {
    if (_isAnswered.value || _scrubProgress.value >= 1.0) return;
    _scrubProgress.value = (_scrubProgress.value + delta).clamp(0.0, 1.0);
    if (_scrubProgress.value > 0) _hapticService.selection();
    if (_scrubProgress.value >= 1.0) {
      _hapticService.success();
      _soundService.playCorrect();
    }
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
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _scrubProgress.value = 0.0;
            _timerKey.currentState?.start();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            if (state.isFinalFailure || state.livesRemaining <= 0) {
              _isAnswered.value = true;
            } else {
              _isAnswered.value = false;
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is SpeakingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'speaking_games.situational_expert',
              fallback: 'SITUATIONAL EXPERT!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _scrubProgress,
              _timeVal,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                onTutorPass: _tutorPass,
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () =>
                    context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
                child: quest == null
                    ? const SizedBox()
                    : Stack(
                        children: [
                          RawScrollbar(
                            controller: _scrollController,
                            thumbColor: theme.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            radius: Radius.circular(8.r),
                            thickness: 4.w,
                            child: CustomScrollView(
                              controller: _scrollController,
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
                                        SituationSpeakingHeader(
                                          primaryColor: theme.primaryColor,
                                          instruction:
                                              InstructionHelper.getInstruction(
                                                quest,
                                              ),
                                        ),
                                        SizedBox(height: 24.h),
                                        SituationSpeakingFogScrubberPanel(
                                          quest: quest,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          scrubProgress: _scrubProgress.value,
                                          timeVal: _timeVal.value,
                                          onScrubUpdate: _onScrubUpdate,
                                          onPlayTts: () =>
                                              _soundService.playTts(
                                                quest.situationText ?? "",
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 16.h,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (!_isAnswered.value)
                                          Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 24.h,
                                            ),
                                            child: SpeedChallengeTimer(
                                              key: _timerKey,
                                              durationSeconds: 20,
                                              primaryColor: theme.primaryColor,
                                              onTimeUp: () => _onTimeUp(
                                                quest.textToSpeak ?? "",
                                              ),
                                              autoStart: true,
                                            ),
                                          ),
                                        if (!_isAnswered.value &&
                                            _scrubProgress.value >= 1.0)
                                          SpeakingSelfEvaluationControls(
                                            expectedText:
                                                quest.textToSpeak ?? "",
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onConfirmed: () {
                                              _timerKey.currentState?.stop();
                                              _submitVerbalEvaluation(
                                                true,
                                                quest.textToSpeak ?? "",
                                              );
                                            },
                                            onSkipped: () {
                                              _timerKey.currentState?.stop();
                                              _submitVerbalEvaluation(
                                                false,
                                                quest.textToSpeak ?? "",
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
