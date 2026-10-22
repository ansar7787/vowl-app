import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_audition_card.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/widgets/repeat_sentence_instruction.dart';

class RepeatSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const RepeatSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.repeatSentence,
  });

  @override
  State<RepeatSentenceScreen> createState() => _RepeatSentenceScreenState();
}

class _RepeatSentenceScreenState extends State<RepeatSentenceScreen>
    with
        GameScreenMixin<RepeatSentenceScreen>,
        SpeakingGameScreenMixin<RepeatSentenceScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
        'speaking_games.repeat_sentence_completed',
        fallback: 'REPEAT SENTENCE COMPLETED!',
      );

  final ValueNotifier<bool> _ttsFinished = ValueNotifier(false);
  Timer? _ttsTimer;
  Timer? _autoPlayTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    initGameLifecycle();
    initSpeakingGame();
  }

  @override
  void onQuestionReset() {
    _ttsFinished.value = false;
    _ttsTimer?.cancel();
    _autoPlayTimer?.cancel();
    if (mounted) {
      final state = context.read<SpeakingBloc>().state;
      if (state is SpeakingLoaded && !state.answerStatus.isAnswered) {
        if (VowlMotion.lowAnimationModeOverride.value) {
          _triggerAutoPlay(state.currentQuest);
        } else {
          _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
            if (mounted) _triggerAutoPlay(state.currentQuest);
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _ttsTimer?.cancel();
    _ttsFinished.dispose();
    _scrollController.dispose();
    disposeSpeakingGame();
    super.dispose();
  }

  void _triggerAutoPlay(GameQuest quest) {
    if (quest.textToSpeak != null) {
      try {
        soundService.playTts(quest.textToSpeak!);
      } catch (_) {}
      _ttsTimer?.cancel();
      if (VowlMotion.lowAnimationModeOverride.value) {
        _ttsFinished.value = true;
        _scrollToBottom();
      } else {
        _ttsTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            _ttsFinished.value = true;
            _scrollToBottom();
          }
        });
      }
    } else {
      _ttsFinished.value = true;
    }
  }

  void _scrollToBottom() {
    if (VowlMotion.lowAnimationModeOverride.value) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
      return;
    }
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

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(
        quest: quest,
        userAnswer: '[Pronunciation Error]',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) => onSpeakingStateChanged(context, state),
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
              _ttsFinished,
            ]),
            builder: (context, _) {
              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                isFinalFailure: state is SpeakingLoaded
                    ? state.isFinalFailure
                    : false,
                showConfetti: showConfettiNotifier.value,
                disablePadding: true,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () {},
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
                                  absorbing: !_ttsFinished.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      RepeatSentenceInstruction(
                                        key: const Key(
                                          'repeat_sentence_instruction',
                                        ),
                                        primaryColor: theme.primaryColor,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      RepeatSentenceAuditionCard(
                                        key: const Key(
                                          'repeat_sentence_audition_card',
                                        ),
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
                                            quest.textToSpeak ?? "",
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (!isAnsweredNotifier.value)
                              SliverToBoxAdapter(
                                child: AnimatedOpacity(
                                  opacity: _ttsFinished.value ? 1.0 : 0.4,
                                  duration: const Duration(milliseconds: 300),
                                  child: AbsorbPointer(
                                    absorbing: !_ttsFinished.value,
                                    child: ShadowPlaybackCompare(
                                      key: const Key(
                                        'repeat_sentence_shadow_compare',
                                      ),
                                      expectedText: quest.textToSpeak ?? "",
                                      primaryColor: theme.primaryColor,
                                      isPositioned: false,
                                      showExpectedText: false,
                                      onConfirmed: () =>
                                          _submitVerbalEvaluation(true, quest),
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false, quest),
                                    ),
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height: 120.h,
                              ),
                            ),
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
