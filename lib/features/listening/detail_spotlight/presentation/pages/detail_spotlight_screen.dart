import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_instruction.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_emitter.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_prompt.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_dark_field.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class DetailSpotlightScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DetailSpotlightScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.detailSpotlight,
  });

  @override
  State<DetailSpotlightScreen> createState() => _DetailSpotlightScreenState();
}

class _DetailSpotlightScreenState extends State<DetailSpotlightScreen>
    with
        GameScreenMixin<DetailSpotlightScreen>,
        ListeningGameScreenMixin<DetailSpotlightScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<int?> _pendingSelectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pendingSelectedIndex.dispose();
    _spotlightPos.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  final ValueNotifier<Offset> _spotlightPos = ValueNotifier(const Offset(0, 0));

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initListeningGame();
  }

  void _submitFinalAnswer(GameQuest quest) {
    if (isAnsweredNotifier.value || _pendingSelectedIndex.value == null) return;

    final correct = quest.correctAnswerIndex ?? 0;
    bool isCorrect = _pendingSelectedIndex.value == correct;

    _selectedIndex.value = _pendingSelectedIndex.value;
    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      String uAns =
          _pendingSelectedIndex.value != null &&
              quest.options != null &&
              _pendingSelectedIndex.value! < quest.options!.length
          ? quest.options![_pendingSelectedIndex.value!]
          : '[None]';

      submitWrongAnswer(quest: quest, userAnswer: uAns);
    }
  }

  void _submitWrongAnswer(dynamic quest) {
    if (quest is GameQuest) {
      submitWrongAnswer(quest: quest, userAnswer: '[Timeout]');
    }
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;

    _pendingSelectedIndex.value = null;

    _spotlightPos.value = const Offset(0, 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listenWhen: listeningListenWhen,
      listener: onListeningStateChanged,
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
              onHint: dispatchHintUsed,
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
                                      Padding(
                                        padding: EdgeInsets.only(bottom: 16.h),
                                        child: SpeedChallengeTimer(
                                          key: timerKey,
                                          durationSeconds: 30,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () =>
                                              _submitWrongAnswer(quest),
                                        ),
                                      ),
                                      DetailSpotlightInstruction(
                                        isAnswered: isAnsweredNotifier.value,
                                        color: theme.primaryColor,
                                        instruction:
                                            'Wipe and tap what you hear',
                                      ),
                                      SizedBox(height: 24.h),
                                      DetailSpotlightEmitter(
                                        onTap: () {
                                          soundService.playTts(
                                            quest.textToSpeak ?? "",
                                          );
                                          hapticService.selection();
                                        },
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                        isCorrectState: isCorrectNotifier.value,
                                      ),
                                      SizedBox(height: 32.h),
                                      DetailSpotlightPrompt(
                                        isAnswered: isAnsweredNotifier.value,
                                        detail: quest.targetDetail ?? "Detail",
                                        color: theme.primaryColor,
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
                                      SizedBox(
                                        height: 350.h,
                                        child: DetailSpotlightDarkField(
                                          options: quest.options ?? [],
                                          correctAnswerIndex:
                                              quest.correctAnswerIndex ?? 0,
                                          color: theme.primaryColor,
                                          isAnswered: isAnsweredNotifier.value,
                                          isCorrectState:
                                              isCorrectNotifier.value,
                                          selectedIndex: _selectedIndex.value,
                                          spotlightPos: _spotlightPos,
                                          onSearch: (pos) {
                                            if (!isAnsweredNotifier.value) {
                                              _spotlightPos.value = pos;
                                            }
                                          },
                                          onSelect: (index) {
                                            if (isAnsweredNotifier.value ||
                                                _pendingSelectedIndex.value !=
                                                    null) {
                                              return;
                                            }
                                            _pendingSelectedIndex.value = index;
                                            _submitFinalAnswer(quest);
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        height: isAnsweredNotifier.value
                                            ? 200.h
                                            : 60.h,
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
