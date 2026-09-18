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
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';

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

class _YesNoSpeakingScreenState extends State<YesNoSpeakingScreen> with SpeakingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
    
  final ValueNotifier<double> _tiltValue = ValueNotifier(0.0);
  final ValueNotifier<bool> _isSnapped = ValueNotifier(false);

        Timer? _autoplayTimer;
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
    _autoplayTimer?.cancel();
    _tiltValue.dispose();
    _isSnapped.dispose();
                _scrollController.dispose();
    disposeSpeakingGame();
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

  void _onTiltDragged(DragUpdateDetails details, double trackWidth) {
    if (isAnsweredNotifier.value || _isSnapped.value) return;

    final state = context.read<SpeakingBloc>().state;
    if (state is! SpeakingLoaded) return;

    final quest = state.currentQuest;
    final String rawPrompt = quest.prompt ?? "";
    final String rawSample = quest.sampleAnswer ?? "";
    final bool doTheyMatch =
        rawPrompt.trim().toLowerCase() == rawSample.trim().toLowerCase();

    final double deltaNormalized = details.delta.dx / (trackWidth / 2);
    hapticService.selection();

    _tiltValue.value = (_tiltValue.value + deltaNormalized).clamp(-1.0, 1.0);

    if (_tiltValue.value <= -0.85 || _tiltValue.value >= 0.85) {
      final bool chosenMatch = _tiltValue.value >= 0.85;
      _tiltValue.value = chosenMatch ? 1.0 : -1.0;
      _isSnapped.value = true;
      _scrollToBottom();

      final bool binaryIsCorrect = chosenMatch == doTheyMatch;

      if (!binaryIsCorrect) {
        isAnsweredNotifier.value = true;
        isCorrectNotifier.value = false;
        hapticService.error();
        soundService.playWrong();

        final authState = context.read<AuthBloc>().state;
        if (authState.status == AuthStatus.authenticated &&
            authState.user != null) {
          ErrorJournalCollector.record(
            userId: authState.user!.id,
            gameType: widget.gameType.name,
            question: 'Yes/No Listening Match',
            userAnswer: chosenMatch ? 'Yes' : 'No',
            correctAnswer: doTheyMatch ? 'Yes' : 'No',
            level: widget.level,
          );
        }

        context.read<SpeakingBloc>().add(const SubmitAnswer(false));
      } else {
        // Correctly answered the Phase 1 interaction. Proceed to Phase 2 (Speaking).
        soundService.playClick();
        hapticService.selection();
      }
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, String expectedText) {
    if (isAnsweredNotifier.value || !_isSnapped.value) return;

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
          question: expectedText,
          userAnswer: '[Failed Self-Evaluation]',
          correctAnswer: expectedText,
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override

  void onQuestionReset() {

    _tiltValue.value = 0.0;

    _isSnapped.value = false;

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

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _isSnapped,
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
                                child: AbsorbPointer(
                                  absorbing: _isSnapped.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      YesNoSpeakingHeaderInstruction(
                                        primaryColor: theme.primaryColor,
                                        isSnapped: _isSnapped.value,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      YesNoSpeakingAuditionCard(
                                        quest: quest,
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                        onPlayTts: () {
                                          if (di
                                              .sl<AudioRecordingService>()
                                              .isRecording) {
                                            return;
                                          }
                                          soundService.playTts(
                                            quest.prompt ?? "",
                                          );
                                        },
                                      ),
                                      SizedBox(height: 32.h),
                                      ValueListenableBuilder<double>(
                                        valueListenable: _tiltValue,
                                        builder: (context, tiltValue, _) {
                                          return YesNoSpeakingTiltArena(
                                            tiltValue: tiltValue,
                                            isSnapped: _isSnapped.value,
                                            primaryColor: theme.primaryColor,
                                            isDark: isDark,
                                            onTiltDragged: _onTiltDragged,
                                            onTiltDragEnd: () {
                                              if (!_isSnapped.value) {
                                                _tiltValue.value = 0.0;
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_isSnapped.value && !isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: ShadowPlaybackCompare(
                                  key: ValueKey(quest.id),
                                  expectedText: quest.sampleAnswer ?? "",
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  showExpectedText: false,
                                  onConfirmed: () => _submitVerbalEvaluation(
                                    true,
                                    quest.sampleAnswer ?? "",
                                  ),
                                  onSkipped: () => _submitVerbalEvaluation(
                                    false,
                                    quest.sampleAnswer ?? "",
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
