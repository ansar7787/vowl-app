import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_header.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_positive_pole_panel.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_plasma_conduit_panel.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_negative_pole_panel.dart';

class SpeakOppositeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;

  const SpeakOppositeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakOpposite,
  });

  @override
  State<SpeakOppositeScreen> createState() => _SpeakOppositeScreenState();
}

class _SpeakOppositeScreenState extends State<SpeakOppositeScreen>
    with SingleTickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<double> _pullProgress = ValueNotifier(0.0);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;

  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();

  late AnimationController _sparkController;
  final ValueNotifier<double> _timeVal = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();

  List<String> _acceptedAntonyms = [];

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );

    _sparkController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addListener(() {
            _timeVal.value = _sparkController.value;
          });
    _sparkController.repeat();
  }

  @override
  void dispose() {
    _sparkController.dispose();
    _pullProgress.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _timeVal.dispose();
    _scrollController.dispose();
    _ttsFinished.dispose();
    _ttsTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      final String cleanSentence = quest.textToSpeak!.replaceAll('*', '');
      _soundService.playTts(cleanSentence);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, String expectedText) {
    if (_isAnswered.value) return;

    _timerKey.currentState?.stop();
    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    _pullProgress.value = nailedIt ? 1.0 : 0.0;

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
          question: 'Speak Opposite',
          userAnswer: '[Failed Antonym/Timer]',
          correctAnswer: expectedText,
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  void _onTimeUp(String expectedText) {
    if (_isAnswered.value) return;
    _submitVerbalEvaluation(false, expectedText);
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
            _pullProgress.value = 0.0;
            _ttsFinished.value = false;
            _ttsTimer?.cancel();
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
            _ttsTimer = Timer(const Duration(seconds: 3), () {
              if (mounted) {
                _ttsFinished.value = true;
                _scrollToBottom();
                _timerKey.currentState?.start();
              }
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            _isAnswered.value = true; // Always show feedback card on incorrect
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
              'speaking_games.polar_antipode',
              fallback: 'POLAR ANTIPODE FUSED!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        if (quest != null) {
          _acceptedAntonyms = quest.acceptedSynonyms ?? [];
        }

        final expectedText = _acceptedAntonyms.isNotEmpty
            ? _acceptedAntonyms.first
            : "";

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _pullProgress,
              _timeVal,
              _ttsFinished,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
                disablePadding: true,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () =>
                    context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: AbsorbPointer(
                                  absorbing: _ttsFinished.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SpeakOppositeHeader(
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      SpeakOppositePositivePolePanel(
                                        quest: quest,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        onPlayTts: () {
                                          if (di
                                              .sl<AudioRecordingService>()
                                              .isRecording) {
                                            return;
                                          }
                                          _soundService.playTts(
                                            (quest.textToSpeak ?? "")
                                                .replaceAll('*', ''),
                                          );
                                        },
                                      ),
                                      SizedBox(height: 32.h),
                                      SpeakOppositePlasmaConduitPanel(
                                        pullProgress: _pullProgress.value,
                                        primaryColor: theme.primaryColor,
                                        isListening: false,
                                        timeVal: _timeVal.value,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 32.h),
                                      SpeakOppositeNegativePolePanel(
                                        pullProgress: _pullProgress.value,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!_isAnswered.value)
                              SliverToBoxAdapter(
                                child: AnimatedOpacity(
                                  opacity: _ttsFinished.value ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 300),
                                  child: AbsorbPointer(
                                    absorbing: !_ttsFinished.value,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 16.h,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.only(
                                              bottom: 24.h,
                                            ),
                                            child: SpeedChallengeTimer(
                                              key: _timerKey,
                                              durationSeconds: 30,
                                              primaryColor: theme.primaryColor,
                                              onTimeUp: () =>
                                                  _onTimeUp(expectedText),
                                              autoStart: true,
                                            ),
                                          ),
                                          SpeakToConfirmOverlay(
                                            expectedText: expectedText,
                                            acceptedSynonyms: _acceptedAntonyms,
                                            primaryColor: theme.primaryColor,
                                            isPositioned: false,
                                            hideExpectedText: true,
                                            allowSkip: false,
                                            title: 'SPEAK AN ANTONYM',
                                            subtitle:
                                                'Say the opposite aloud to confirm',
                                            onConfirmed: () =>
                                                _submitVerbalEvaluation(
                                                  true,
                                                  expectedText,
                                                ),
                                            onSkipped: () =>
                                                _submitVerbalEvaluation(
                                                  false,
                                                  expectedText,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                          ],
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
