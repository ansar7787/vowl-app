import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
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

class _SituationSpeakingScreenState extends State<SituationSpeakingScreen> with SpeakingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  final ValueNotifier<bool> _isBriefingComplete = ValueNotifier(false);
          
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
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
    });

    initSpeakingGame();
  }

  @override
  void dispose() {
    _isBriefingComplete.dispose();
                _scrollController.dispose();
    disposeSpeakingGame();
    disposeSpeakingGame();
    disposeSpeakingGame();
    super.dispose();
  }


  void _submitVerbalEvaluation(bool nailedIt, String textToSpeak) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: 'Situation Speaking',
          userAnswer: '[Self-Evaluation: Needs Work]',
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
    if (isAnsweredNotifier.value || _isBriefingComplete.value) return;
    _isBriefingComplete.value = true;
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listenWhen: speakingListenWhen,
      listener: onSpeakingStateChanged,
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final hintUsed = (state is SpeakingLoaded) ? state.hintUsed : false;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _isBriefingComplete,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                showConfetti: showConfettiNotifier.value,
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
                                      isAnswered: isAnsweredNotifier.value,
                                      hintUsed: hintUsed,
                                      onBriefingComplete: _onBriefingComplete,
                                      onPlayTts: () {
                                        if (di
                                            .sl<AudioRecordingService>()
                                            .isRecording) {
                                          return;
                                        }
                                        soundService.playTts(
                                          quest.situationText ?? "",
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (!isAnsweredNotifier.value && _isBriefingComplete.value)
                              SliverToBoxAdapter(
                                child: SpeakToConfirmOverlay(
                                  expectedText:
                                      quest.correctAnswer ??
                                      quest.textToSpeak ??
                                      "",
                                  ttsText:
                                      quest.textToSpeak ?? quest.correctAnswer,
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
