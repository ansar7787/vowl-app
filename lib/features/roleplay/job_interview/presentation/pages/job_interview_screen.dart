import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/widgets/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_instruction.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_telemetry_dashboard.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_interviewer_panel.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_response_console.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_explanation_card.dart';

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

class _JobInterviewScreenState extends State<JobInterviewScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _reactorController;
  
  int _lastProcessedIndex = -1;
  int? _selectedIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  
  // Track professionalism thermometer score (default start at 0.5)
  double _mercuryLevel = 0.5;

  @override
  void initState() {
    super.initState();
    _reactorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
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
    if (_isAnswered) return;

    final bool isCorrect = index == correctIndex;

    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
      _isCorrect = isCorrect;
      
      // Update professionalism mercury meter dynamically
      if (isCorrect) {
        _mercuryLevel = (_mercuryLevel + 0.25).clamp(0.0, 1.0);
      } else {
        _mercuryLevel = (_mercuryLevel - 0.2).clamp(0.0, 1.0);
      }
    });

    if (isCorrect) {
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
        } else if (state is RoleplayGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<RoleplayBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final options = quest?.options ?? [];

        return RoleplayBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<RoleplayBloc>().add(NextQuestion()),
          onHint: () => context.read<RoleplayBloc>().add(RoleplayHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  child: Column(
                    children: [
                      JobInterviewInstruction(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),

                      // Professionalism telemetry reactor bar
                      JobInterviewTelemetryDashboard(
                        color: theme.primaryColor,
                        isDark: isDark,
                        mercuryLevel: _mercuryLevel,
                        reactorAnimation: _reactorController,
                      ),
                      SizedBox(height: 24.h),

                      // Holographic Interviewer Dialog Bubble
                      JobInterviewInterviewerPanel(
                        text: quest.interviewerQuestion ?? "",
                        color: theme.primaryColor,
                        isDark: isDark,
                      ),
                      SizedBox(height: 24.h),

                      // Option response cards
                      JobInterviewResponseConsole(
                        options: options,
                        correctIndex: quest.correctAnswerIndex ?? 0,
                        color: theme.primaryColor,
                        isDark: isDark,
                        selectedIndex: _selectedIndex,
                        isAnswered: _isAnswered,
                        isCorrect: _isCorrect,
                        onOptionSelected: _onOptionSelected,
                      ),
                      SizedBox(height: 20.h),

                      // Post-answer review cards
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: JobInterviewExplanationCard(
                          quest: quest,
                          isDark: isDark,
                          isCorrect: _isCorrect,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 400),
                      ),
                      SizedBox(height: 80.h),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
