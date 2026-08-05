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
import 'package:vowl/core/presentation/widgets/speak_to_confirm_overlay.dart';

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
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  // Shuffled state
  List<String> _shuffledOptions = [];
  int _shuffledCorrectIndex = -1;

  // Track professionalism thermometer score (default start at 0.5)
  double _mercuryLevel = 0.5;
  bool _isFirstStagePassed = false;

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
    if (_isAnswered || _isFirstStagePassed) return;

    final bool isCorrect = index == correctIndex;

    setState(() {
      _selectedIndex = index;
    });

    if (isCorrect) {
      _hapticService.selection();
      setState(() {
        _isFirstStagePassed = true;
      });
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
        _mercuryLevel = (_mercuryLevel - 0.2).clamp(0.0, 1.0);
      });
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
      if (nailedIt) {
        _mercuryLevel = (_mercuryLevel + 0.25).clamp(0.0, 1.0);
      } else {
        _mercuryLevel = (_mercuryLevel - 0.2).clamp(0.0, 1.0);
      }
    });

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
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedIndex = null;
              _isFirstStagePassed = false;
              
              if (state.currentQuest.options != null) {
                final options = List<String>.from(state.currentQuest.options!);
                final correctOption = options[state.currentQuest.correctAnswerIndex ?? 0];
                options.shuffle();
                _shuffledOptions = options;
                _shuffledCorrectIndex = options.indexOf(correctOption);
              }
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          setState(() => _showConfetti = true);
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

        return Stack(
          children: [
            RoleplayBaseLayout(
              gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 580;
                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: isCompact ? 5.h : 10.h,
                      ),
                      child: Column(
                        children: [
                          JobInterviewInstruction(
                            primaryColor: theme.primaryColor,
                            instruction: quest.instruction,
                            isDark: isDark,
                          ),
                          SizedBox(height: isCompact ? 10.h : 16.h),

                          // Professionalism telemetry reactor bar
                          JobInterviewTelemetryDashboard(
                            color: theme.primaryColor,
                            isDark: isDark,
                            mercuryLevel: _mercuryLevel,
                            reactorAnimation: _reactorController,
                          ),
                          SizedBox(height: isCompact ? 16.h : 24.h),

                          // Holographic Interviewer Dialog Bubble
                          JobInterviewInterviewerPanel(
                            text: quest.interviewerQuestion ?? "",
                            color: theme.primaryColor,
                            isDark: isDark,
                          ),
                          SizedBox(height: isCompact ? 16.h : 24.h),

                          // Option response cards
                          JobInterviewResponseConsole(
                            options: _shuffledOptions,
                            correctIndex: _shuffledCorrectIndex,
                            color: theme.primaryColor,
                            isDark: isDark,
                            selectedIndex: _selectedIndex,
                            isAnswered: _isAnswered || _isFirstStagePassed,
                            isCorrect: _isCorrect,
                            onOptionSelected: _onOptionSelected,
                          ),
                          SizedBox(height: isCompact ? 12.h : 20.h),

                          // Post-answer review cards
                          AnimatedCrossFade(
                            firstChild: const SizedBox(),
                            secondChild: JobInterviewExplanationPanel(
                              quest: quest,
                              isDark: isDark,
                              isCorrect: _isCorrect,
                              primaryColor: theme.primaryColor,
                            ),
                            crossFadeState: _isAnswered
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 450),
                          ),
                          SizedBox(height: isCompact ? 40.h : 80.h),
                        ],
                      ),
                    );
                  },
                ),
            ),
            if (_isFirstStagePassed && !_isAnswered && _selectedIndex != null)
              SpeakToConfirmOverlay(
                expectedText: _shuffledOptions[_selectedIndex!],
                primaryColor: theme.primaryColor,
                onConfirmed: () {
                  context.read<RoleplayBloc>().add(const RoleplaySpeakConfirmed(5));
                  _submitVerbalEvaluation(true);
                },
                onSkipped: () => _submitVerbalEvaluation(false),
              ),
          ],
        );
      },
    );
  }
}

