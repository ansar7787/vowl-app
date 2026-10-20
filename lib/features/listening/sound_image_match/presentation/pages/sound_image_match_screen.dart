import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_instruction.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_emitter.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_grid.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SoundImageMatchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SoundImageMatchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.soundImageMatch,
  });

  @override
  State<SoundImageMatchScreen> createState() => _SoundImageMatchScreenState();
}

class _SoundImageMatchScreenState extends State<SoundImageMatchScreen>
    with
        GameScreenMixin<SoundImageMatchScreen>,
        ListeningGameScreenMixin<SoundImageMatchScreen> {
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
    'listening.games.sound_image_match_title',
    fallback: 'Sound Image Match',
  );

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initListeningGame();
  }

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pendingSelectedIndex.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;
    _pendingSelectedIndex.value = null;
    timerKey?.currentState?.start();
  }

  void _playAudio(dynamic quest) {
    hapticService.selection();
    if (quest == null) return;
    try {
      final audioUrl = quest.audioUrl as String?;
      if (audioUrl != null && audioUrl.isNotEmpty) {
        soundService.playUrl(audioUrl);
        return;
      }
    } catch (_) {}
    final rawText = quest.textToSpeak ?? quest.prompt ?? quest.question ?? '';
    if (rawText.startsWith('http://') || rawText.startsWith('https://')) {
      soundService.playUrl(rawText);
      return;
    }
    final text = rawText.replaceAll(RegExp(r'\[pause:\d+\]'), ' ');
    if (text.isNotEmpty) {
      soundService.playTts(text);
    }
  }

  void _submitFinalAnswer(GameQuest quest) {
    if (isAnsweredNotifier.value || _pendingSelectedIndex.value == null) return;
    timerKey?.currentState?.stop();
    final correct = quest.correctAnswerIndex ?? 0;

    bool isCorrect = _pendingSelectedIndex.value == correct;

    if (isCorrect) {
      _selectedIndex.value = _pendingSelectedIndex.value;
      submitCorrectAnswer();
    } else {
      _selectedIndex.value = _pendingSelectedIndex.value;
      submitWrongAnswer(
        quest: quest,
        userAnswer: _pendingSelectedIndex.value.toString(),
      );
    }
  }

  void _submitWrongAnswer(dynamic quest) {
    timerKey?.currentState?.stop();
    if (quest is GameQuest) {
      submitWrongAnswer(quest: quest);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listenWhen: listeningListenWhen,
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded ||
          current is ListeningGameOver ||
          current is ListeningGameComplete,
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedIndex,
            _pendingSelectedIndex,
          ]),
          builder: (context, _) {
            return ListeningBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              disablePadding: true,
              onContinue: dispatchNextQuestion,
              onHint: () => hapticService.selection(),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
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
                                      SizedBox(height: 6.h),
                                      if (!isAnsweredNotifier.value)
                                        Padding(
                                          padding: EdgeInsets.only(
                                            bottom: 16.h,
                                          ),
                                          child: SpeedChallengeTimer(
                                            key: timerKey,
                                            durationSeconds: 15,
                                            primaryColor: theme.primaryColor,
                                            onTimeUp: () =>
                                                _submitWrongAnswer(quest),
                                          ),
                                        ),
                                      SoundImageMatchInstruction(
                                        key: const Key(
                                          'sound_image_match_instruction',
                                        ),
                                        color: theme.primaryColor,
                                        instruction:
                                            context.tr(
                                              'games.soundImageMatch_instruction',
                                              fallback:
                                                  InstructionHelper
                                                      .getInstruction(quest),
                                            ),
                                      ),
                                      SizedBox(height: 18.h),
                                      SoundImageMatchEmitter(
                                        key: const Key(
                                          'sound_image_match_emitter',
                                        ),
                                        onTap: () => _playAudio(quest),
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                        isCorrectState: isCorrectNotifier.value,
                                      ),
                                      SizedBox(height: 18.h),
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 8.h,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: SoundImageMatchGrid(
                                          key: const Key(
                                            'sound_image_match_grid',
                                          ),
                                          options: quest.options ?? [],
                                          optionEmojis:
                                              quest.optionEmojis ?? [],
                                          correctAnswerIndex:
                                              quest.correctAnswerIndex ?? 0,
                                          color: theme.primaryColor,
                                          isAnswered: isAnsweredNotifier.value,
                                          isCorrectState:
                                              isCorrectNotifier.value,
                                          selectedIndex: _selectedIndex.value,
                                          onSelect: (index) {
                                            if (isAnsweredNotifier.value) {
                                              return;
                                            }
                                            hapticService.selection();
                                            timerKey?.currentState?.pause();
                                            _pendingSelectedIndex.value = index;
                                            _submitFinalAnswer(quest);
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        height: isAnsweredNotifier.value
                                            ? 180.h
                                            : 40.h,
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
        );
      },
    );
  }
}
