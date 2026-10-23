import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_instruction.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_emitter.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_prompt.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_dark_field.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

/// Screen for the Detail Spotlight listening game quest.
///
/// Darkens the interaction area so learners search with a movable spotlight beam
/// across option tiles to locate specific details heard in the audio snippet.
class DetailSpotlightScreen extends StatefulWidget {
  /// Progression level index.
  final int level;

  /// Specific game subtype variant.
  final GameSubtype gameType;

  /// Creates a [DetailSpotlightScreen] instance.
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
  final ValueNotifier<Offset> _spotlightPos = ValueNotifier(const Offset(0, 0));

  @override
  void dispose() {
    _selectedIndex.dispose();
    _pendingSelectedIndex.dispose();
    _spotlightPos.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timerKey = GlobalKey<SpeedChallengeTimerState>();
    initListeningGame();
  }

  void _submitFinalAnswer(GameQuest quest) {
    if (isAnsweredNotifier.value || _pendingSelectedIndex.value == null) return;
    timerKey?.currentState?.stop();

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
    if (isAnsweredNotifier.value) return;
    timerKey?.currentState?.stop();
    if (quest is GameQuest) {
      submitWrongAnswer(quest: quest, userAnswer: '[Timeout]');
    }
  }

  void _playAudio(ListeningQuest quest) {
    final rawAudio = quest.textToSpeak ??
        quest.prompt ??
        quest.question ??
        quest.sentence ??
        quest.audioTranscript ??
        "";
    final text = rawAudio.trim();
    if (text.isEmpty) return;
    if (text.startsWith('http')) {
      soundService.playUrl(text);
    } else {
      soundService.playTts(text, pauseMarkers: quest.pauseMarkers);
    }
    hapticService.selection();
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;
    _pendingSelectedIndex.value = null;
    _spotlightPos.value = const Offset(0, 0);
    timerKey?.currentState?.start();
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
            final targetDetail = quest != null
                ? (quest.targetDetail ?? quest.prompt ?? quest.targetEmotion ?? "Detail")
                : "Detail";

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
                                        key: const Key(
                                          'detail_spotlight_instruction',
                                        ),
                                        isAnswered: isAnsweredNotifier.value,
                                        color: theme.primaryColor,
                                        instruction: context.tr(
                                          'games.detailSpotlight_instruction',
                                          fallback:
                                              quest.instruction.isNotEmpty
                                                  ? quest.instruction
                                                  : 'Listen closely and tap the matching detail',
                                        ),
                                      ),
                                      SizedBox(height: 20.h),
                                      DetailSpotlightEmitter(
                                        key: const Key(
                                          'detail_spotlight_emitter',
                                        ),
                                        onTap: () => _playAudio(quest),
                                        color: theme.primaryColor,
                                        emoji: quest.emoji,
                                        isCorrectState: isCorrectNotifier.value,
                                      ),
                                      SizedBox(height: 20.h),
                                      DetailSpotlightPrompt(
                                        key: const Key(
                                          'detail_spotlight_prompt',
                                        ),
                                        isAnswered: isAnsweredNotifier.value,
                                        detail: targetDetail,
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
                                          key: const Key(
                                            'detail_spotlight_dark_field',
                                          ),
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
                                            hapticService.selection();
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
