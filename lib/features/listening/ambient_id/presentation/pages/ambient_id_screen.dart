import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';
import 'package:vowl/features/listening/presentation/layout/listening_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_instruction.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_sonar_field.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_emitter_node.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/features/listening/presentation/mixins/listening_game_screen_mixin.dart';

class AmbientIdScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const AmbientIdScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.ambientId,
  });

  @override
  State<AmbientIdScreen> createState() => _AmbientIdScreenState();
}

class _AmbientIdScreenState extends State<AmbientIdScreen>
    with SingleTickerProviderStateMixin, ListeningGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => context.tr(
    'listening.games.ambient_id_title',
    fallback: 'CONTEXT ANCHOR!',
  );

  late AnimationController _radarController;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  _AmbientIdScreenState() {
    timerKey = GlobalKey<SpeedChallengeTimerState>();
  }

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    initListeningGame();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _selectedIndex.dispose();
    _scrollController.dispose();
    disposeListeningGame();
    super.dispose();
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;
  }

  void _submitFinalAnswer(int index, int correct, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    _selectedIndex.value = index;
    bool isCorrect = index == correct;

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: index.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('listening', level: widget.level);

    return BlocConsumer<ListeningBloc, ListeningState>(
      listener: onListeningStateChanged,
      buildWhen: (previous, current) =>
          current is ListeningLoaded || current is ListeningGameOver,
      builder: (context, state) {
        final quest = (state is ListeningLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedIndex,
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
              onHint: () {
                if (quest != null &&
                    quest.hint != null &&
                    quest.hint!.isNotEmpty) {
                  GameDialogHelper.showHintDialog(context, hint: quest.hint!);
                }
              },
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
                                          durationSeconds: 15,
                                          primaryColor: theme.primaryColor,
                                          onTimeUp: () {
                                            submitWrongAnswer(quest: quest);
                                          },
                                        ),
                                      ),
                                      AmbientIdInstruction(
                                        color: theme.primaryColor,
                                        instruction:
                                            quest.instruction.isNotEmpty
                                            ? quest.instruction
                                            : context.tr(
                                                'games.ambientId_instruction',
                                                fallback:
                                                    'Listen and tap the location.',
                                              ),
                                      ),
                                      SizedBox(height: 24.h),
                                      AmbientIdSonarField(
                                        options: quest.options ?? [],
                                        correctAnswerIndex:
                                            quest.correctAnswerIndex ?? 0,
                                        color: theme.primaryColor,
                                        radarController: _radarController,
                                        isAnswered: isAnsweredNotifier.value,
                                        isCorrectState: isCorrectNotifier.value,
                                        selectedIndex: _selectedIndex.value,
                                        onSubmitAnswer: (index) {
                                          _submitFinalAnswer(
                                            index,
                                            quest.correctAnswerIndex ?? 0,
                                            quest,
                                          );
                                        },
                                        imageUrl: null,
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
                                      AmbientIdEmitterNode(
                                        onTap: () {
                                          soundService.playTts(
                                            quest.textToSpeak ?? "",
                                          );
                                          hapticService.selection();
                                        },
                                        color: theme.primaryColor,
                                      ),
                                      SizedBox(height: 100.h),
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
