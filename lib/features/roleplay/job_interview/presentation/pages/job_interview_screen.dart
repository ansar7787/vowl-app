import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_instruction.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_explanation_panel.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_telemetry_dashboard.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_interviewer_panel.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_response_console.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _reactorController;

  int _lastProcessedIndex = -1;
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);

  // Shuffled state
  final ValueNotifier<List<String>> _shuffledOptions = ValueNotifier([]);
  final ValueNotifier<int> _shuffledCorrectIndex = ValueNotifier(-1);

  // Track professionalism thermometer score (default start at 0.5)
  final ValueNotifier<double> _mercuryLevel = ValueNotifier(0.5);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _reactorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    context.read<RoleplayBloc>().add(
      FetchRoleplayQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _reactorController.dispose();
    _selectedIndex.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _shuffledOptions.dispose();
    _shuffledCorrectIndex.dispose();
    _mercuryLevel.dispose();
    _isFirstStagePassed.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.instruction);
    if (quest.interviewerQuestion != null) {
      Future.delayed(const Duration(milliseconds: 1400), () {
        if (mounted) _soundService.playTts(quest.interviewerQuestion!);
      });
    }
  }

  void _onOptionSelected(int index, int correctIndex) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    final bool isCorrect = index == correctIndex;

    _selectedIndex.value = index;

    if (isCorrect) {
      _hapticService.selection();
      _isFirstStagePassed.value = true;
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      _mercuryLevel.value = (_mercuryLevel.value - 0.2).clamp(0.0, 1.0);
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;
    if (nailedIt) {
      _mercuryLevel.value = (_mercuryLevel.value + 0.25).clamp(0.0, 1.0);
    } else {
      _mercuryLevel.value = (_mercuryLevel.value - 0.2).clamp(0.0, 1.0);
    }

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listener: (context, state) {
        if (state is RoleplayLoaded) {
          if (state.currentIndex != _lastProcessedIndex) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _selectedIndex.value = null;
            _isFirstStagePassed.value = false;

            if (state.currentQuest.options != null) {
              final options = List<String>.from(state.currentQuest.options!);
              final correctOption =
                  options[state.currentQuest.correctAnswerIndex ?? 0];
              options.shuffle();
              _shuffledOptions.value = options;
              _shuffledCorrectIndex.value = options.indexOf(correctOption);
            }
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CORPORATE LEADER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
            _selectedIndex,
            _shuffledOptions,
            _shuffledCorrectIndex,
            _mercuryLevel,
            _isFirstStagePassed,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? const SizedBox()
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
                                    hasScrollBody: false,
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
                                                          quest.instruction,
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
                                                          _isAnswered.value &&
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
                                                          _isAnswered.value ||
                                                          _isFirstStagePassed
                                                              .value,
                                                      isCorrect:
                                                          _isCorrect.value,
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
                                                                _isCorrect
                                                                    .value,
                                                            primaryColor: theme
                                                                .primaryColor,
                                                          ),
                                                      crossFadeState:
                                                          _isAnswered.value
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
                                          (_isFirstStagePassed.value &&
                                              !_isAnswered.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_isFirstStagePassed.value &&
                                !_isAnswered.value &&
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
