import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_header.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_briefing_card.dart';

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

class _SituationSpeakingScreenState extends State<SituationSpeakingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final ValueNotifier<bool> _isBriefingComplete = ValueNotifier(false);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _isBriefingComplete.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
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

  void _onBriefingComplete() {
    if (_isAnswered.value || _isBriefingComplete.value) return;
    _isBriefingComplete.value = true;
    _scrollToBottom();
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
            _isBriefingComplete.value = false;
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
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
              'speaking_games.situational_expert',
              fallback: 'SITUATIONAL EXPERT!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final hintUsed = (state is SpeakingLoaded) ? state.hintUsed : false;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _isBriefingComplete,
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
                                    SituationSpeakingBriefingCard(
                                      quest: quest,
                                      primaryColor: theme.primaryColor,
                                      isDark: isDark,
                                      isAnswered: _isAnswered.value,
                                      hintUsed: hintUsed,
                                      onBriefingComplete: _onBriefingComplete,
                                      onPlayTts: () {
                                        if (di
                                            .sl<AudioRecordingService>()
                                            .isRecording) {
                                          return;
                                        }
                                        _soundService.playTts(
                                          quest.situationText ?? "",
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!_isAnswered.value && _isBriefingComplete.value)
                              SliverToBoxAdapter(
                                child: SpeakToConfirmOverlay(
                                  expectedText:
                                      quest.correctAnswer ??
                                      quest.textToSpeak ??
                                      "",
                                  acceptedSynonyms:
                                      quest.acceptedSynonyms ?? [],
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  hideExpectedText: true,
                                  allowSkip: false,
                                  title: 'SPEAK THE SITUATION',
                                  subtitle: 'Hold the microphone to answer',
                                  onConfirmed: () {
                                    _submitVerbalEvaluation(
                                      true,
                                      quest.correctAnswer ??
                                          quest.textToSpeak ??
                                          "",
                                    );
                                  },
                                  onSkipped: () {
                                    _submitVerbalEvaluation(
                                      false,
                                      quest.correctAnswer ??
                                          quest.textToSpeak ??
                                          "",
                                    );
                                  },
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
