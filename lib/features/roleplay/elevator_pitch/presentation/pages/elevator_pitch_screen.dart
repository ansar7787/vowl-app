import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_recorder.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/widgets/elevator_pitch_prompt_card.dart';
import 'package:vowl/core/presentation/widgets/game_scrollbar.dart';

class ElevatorPitchScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ElevatorPitchScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.elevatorPitch,
  });

  @override
  State<ElevatorPitchScreen> createState() => _ElevatorPitchScreenState();
}

class _ElevatorPitchScreenState extends State<ElevatorPitchScreen>
    with
        GameScreenMixin<ElevatorPitchScreen>,
        RoleplayGameScreenMixin<ElevatorPitchScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    initRoleplayGame();
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      _scrollToBottom();
      submitWrongAnswer(quest: quest, userAnswer: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              fullScreenContent: true,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : GameScrollbar(
                      controller: _scrollController,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                SizedBox(height: 16.h),
                                ElevatorPitchPromptCard(
                                  instruction: InstructionHelper.getInstruction(quest),
                                  prompt: quest.prompt ?? "",
                                  timeLimit: quest.timeLimit ?? 30,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 24.h),
                                if (!isAnsweredNotifier.value)
                                  ElevatorPitchRecorder(
                                    expectedText:
                                        quest.correctAnswer ??
                                        "Elevator Pitch Example",
                                    primaryColor: theme.primaryColor,
                                    timeLimit: quest.timeLimit ?? 30,
                                    onConfirmed: () {
                                      context.read<RoleplayBloc>().add(
                                        const RoleplaySpeakConfirmed(5),
                                      );
                                      _submitVerbalEvaluation(true, quest);
                                    },
                                    onFailed: () {
                                      _submitVerbalEvaluation(false, quest);
                                    },
                                  ),
                                SizedBox(
                                  height: 120.h,
                                ), // Bottom padding for feedback card
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
