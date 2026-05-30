import 'dart:async';
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
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_instruction.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_scene_display.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_explanation_panel.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_reaction_zone.dart';

class SituationalResponseScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SituationalResponseScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.situationalResponse,
  });

  @override
  State<SituationalResponseScreen> createState() => _SituationalResponseScreenState();
}

class _SituationalResponseScreenState extends State<SituationalResponseScreen> with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  
  late AnimationController _timerController;
  late AnimationController _pulseController;
  
  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedOrbIndex;
  
  // Real-time ticking sound throttling
  int _lastTickSecond = -1;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);

    _timerController.addListener(() {
      setState(() {});
      _checkTickWarnings();
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _triggerTimeoutFailure();
      }
    });

    context.read<RoleplayBloc>().add(FetchRoleplayQuests(gameType: widget.gameType, level: widget.level));
  }

  @override
  void dispose() {
    _timerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerAutoPlay(RoleplayQuest quest) {
    _soundService.playTts(quest.scene ?? "");
  }

  void _checkTickWarnings() {
    if (_isAnswered) return;
    
    // Warn when time is running out (less than 4 seconds remaining)
    final double elapsedRatio = _timerController.value;
    final int remainingSec = (12 * (1.0 - elapsedRatio)).ceil();
    
    if (remainingSec <= 4 && remainingSec > 0 && remainingSec != _lastTickSecond) {
      _lastTickSecond = remainingSec;
      _hapticService.selection();
      _soundService.playHint(); // Play warning beep
    }
  }

  void _startTimer() {
    _timerController.forward(from: 0.0);
    _lastTickSecond = -1;
  }

  void _stopTimer() {
    _timerController.stop();
  }

  void _triggerTimeoutFailure() {
    if (_isAnswered) return;
    _stopTimer();
    _hapticService.error();
    _soundService.playWrong();
    
    setState(() {
      _isAnswered = true;
      _isCorrect = false;
      _selectedOrbIndex = null;
    });
    
    context.read<RoleplayBloc>().add(SubmitAnswer(false));
  }

  void _onOrbTap(int index, int correctIndex) {
    if (_isAnswered) return;
    _stopTimer();
    
    final isCorrect = index == correctIndex;
    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _selectedOrbIndex = index;
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
              _selectedOrbIndex = null;
            });
            _startTimer();
            // Auto play dialogue context
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          }
        }
        if (state is RoleplayGameComplete) {
          _stopTimer();
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SOCIAL GENIUS!',
            enableDoubleUp: true,
          );
        } else if (state is RoleplayGameOver) {
          _stopTimer();
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
                      SituationalResponseInstruction(primaryColor: theme.primaryColor),
                      SizedBox(height: 16.h),
                      SituationalResponseSceneDisplay(
                        quest: quest,
                        color: theme.primaryColor,
                        isDark: isDark,
                        onListen: () => _triggerAutoPlay(quest),
                      ),
                      SizedBox(height: 24.h),
                      SituationalResponseReactionZone(
                        options: options,
                        correctIndex: quest.correctAnswerIndex ?? 0,
                        color: theme.primaryColor,
                        isDark: isDark,
                        timerValue: _timerController.value,
                        pulseValue: _pulseController.value,
                        isAnswered: _isAnswered,
                        isCorrect: _isCorrect,
                        selectedOrbIndex: _selectedOrbIndex,
                        onOrbTap: _onOrbTap,
                      ),
                      SizedBox(height: 20.h),
                      
                      // Explanations Card when answered
                      AnimatedCrossFade(
                        firstChild: const SizedBox(),
                        secondChild: SituationalResponseExplanationPanel(
                          quest: quest,
                          isDark: isDark,
                          isCorrect: _isCorrect,
                        ),
                        crossFadeState: _isAnswered
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 450),
                      ),
                      SizedBox(height: 80.h), // Safe spacing for base layouts
                    ],
                  ),
                ),
        );
      },
    );
  }
}
