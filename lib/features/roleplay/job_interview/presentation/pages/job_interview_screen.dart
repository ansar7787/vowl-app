import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_instruction.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_explanation_panel.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_telemetry_dashboard.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_interviewer_panel.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_response_console.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class JobInterviewScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const JobInterviewScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.jobInterview,
  });

  @override
  State<JobInterviewScreen> createState() => _JobInterviewScreenState();
}

class _JobInterviewScreenState extends State<JobInterviewScreen>
    with TickerProviderStateMixin, RoleplayGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _reactorController;

  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();

  // Shuffled state
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<int> _shuffledCorrectIndex = ValueNotifier(-1);

  // Track professionalism thermometer score (default start at 0.5)
  final ValueNotifier<double> _mercuryLevel = ValueNotifier(0.5);

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

    _reactorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    initRoleplayGame();
  }

  @override
  void dispose() {
    _reactorController.dispose();
    _selectedIndex.dispose();
    _shuffledOptions.dispose();
    _shuffledCorrectIndex.dispose();
    _mercuryLevel.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _onOptionSelected(int index, int correctIndex) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final bool isCorrect = index == correctIndex;

    _selectedIndex.value = index;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _mercuryLevel.value = (_mercuryLevel.value - 0.2).clamp(0.0, 1.0);
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;
    if (nailedIt) {
      _mercuryLevel.value = (_mercuryLevel.value + 0.25).clamp(0.0, 1.0);
    } else {
      _mercuryLevel.value = (_mercuryLevel.value - 0.2).clamp(0.0, 1.0);
    }

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _selectedIndex.value = null;

    _shuffledOptions.value = [];

    _shuffledCorrectIndex.value = -1;

    _mercuryLevel.value = 0.5;
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
            _selectedIndex,
            _shuffledOptions,
            _shuffledCorrectIndex,
            _mercuryLevel,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxHeight < 580;
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: isCompact
                                                      ? 5.h
                                                      : 10.h,
                                                ),
                                                child: Column(
                                                  children: [
                                                    JobInterviewInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          InstructionHelper.getInstruction(
                                                            quest,
                                                          ),
                                                      isDark: isDark,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),

                                                    // Professionalism telemetry reactor bar
                                                    JobInterviewTelemetryDashboard(
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      mercuryLevel:
                                                          _mercuryLevel.value,
                                                      reactorAnimation:
                                                          _reactorController,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),

                                                    // Holographic Interviewer Dialog Bubble
                                                    JobInterviewInterviewerPanel(
                                                      text:
                                                          quest
                                                              .interviewerQuestion ??
                                                          "",
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      reaction:
                                                          isAnsweredNotifier
                                                                  .value &&
                                                              _selectedIndex
                                                                      .value !=
                                                                  null &&
                                                              quest.interviewerReaction !=
                                                                  null &&
                                                              quest.options !=
                                                                  null
                                                          ? quest
                                                                .interviewerReaction![quest
                                                                .options!
                                                                .indexOf(
                                                                  _shuffledOptions
                                                                      .value[_selectedIndex
                                                                      .value!],
                                                                )]
                                                          : null,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 16.h
                                                          : 24.h,
                                                    ),

                                                    // Option response cards
                                                    JobInterviewResponseConsole(
                                                      options: _shuffledOptions
                                                          .value,
                                                      correctIndex:
                                                          _shuffledCorrectIndex
                                                              .value,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      selectedIndex:
                                                          _selectedIndex.value,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value ||
                                                          isFirstStagePassedNotifier
                                                              .value,
                                                      isCorrect:
                                                          isCorrectNotifier
                                                              .value,
                                                      onOptionSelected:
                                                          _onOptionSelected,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 12.h
                                                          : 20.h,
                                                    ),

                                                    // Post-answer review cards
                                                    AnimatedCrossFade(
                                                      firstChild:
                                                          const SizedBox(),
                                                      secondChild:
                                                          JobInterviewExplanationPanel(
                                                            quest: quest,
                                                            isDark: isDark,
                                                            isCorrect:
                                                                isCorrectNotifier
                                                                    .value,
                                                            primaryColor: theme
                                                                .primaryColor,
                                                          ),
                                                      crossFadeState:
                                                          isAnsweredNotifier
                                                              .value
                                                          ? CrossFadeState
                                                                .showSecond
                                                          : CrossFadeState
                                                                .showFirst,
                                                      duration: const Duration(
                                                        milliseconds: 450,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (isFirstStagePassedNotifier.value &&
                                              !isAnsweredNotifier.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFirstStagePassedNotifier.value &&
                                !isAnsweredNotifier.value &&
                                _selectedIndex.value != null)
                              SpeakToConfirmOverlay(
                                expectedText: _shuffledOptions
                                    .value[_selectedIndex.value!],
                                primaryColor: theme.primaryColor,
                                isPositioned: true,
                                onConfirmed: () {
                                  context.read<RoleplayBloc>().add(
                                    const RoleplaySpeakConfirmed(5),
                                  );
                                  _submitVerbalEvaluation(true);
                                },
                                onSkipped: () => _submitVerbalEvaluation(false),
                              ),
                          ],
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
