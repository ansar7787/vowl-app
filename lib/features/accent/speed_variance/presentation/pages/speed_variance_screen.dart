import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_instruction.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_prompt_card.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_pulse_speaker.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_tempo_dial.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_explanation_card.dart';

class SpeedVarianceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeedVarianceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speedVariance,
  });

  @override
  State<SpeedVarianceScreen> createState() => _SpeedVarianceScreenState();
}

class _SpeedVarianceScreenState extends State<SpeedVarianceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int? _lastLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  double _dialRotation = 0.0;
  bool _isDragging = false;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onDialRotate(DragUpdateDetails details, int correct) {
    if (_isAnswered) return;
    setState(() {
      _isDragging = true;
      _dialRotation = (_dialRotation + details.delta.dx / 100.0).clamp(-1.0, 1.0);
    });
    _hapticService.selection();

    // Auto-lock when reaching ends
    if (_dialRotation < -0.6) {
      _submitChoice(0, correct);
    } else if (_dialRotation > 0.6) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    if (_isAnswered || !_isDragging) return;
    setState(() {
      _isDragging = false;
      if (!_isAnswered) {
        _dialRotation = 0.0;
      }
    });
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _dialRotation = index == 0 ? -0.8 : 0.8;
      _isDragging = false;
    });
    
    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { _isAnswered = true; _isCorrect = true; });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { _isAnswered = true; _isCorrect = false; });
      context.read<AccentBloc>().add(SubmitAnswer(false));
      
      Future.delayed(2.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedIndex = null;
            _dialRotation = 0.0;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex || livesChanged || (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _dialRotation = 0.0;
              _selectedIndex = null;
              _isDragging = false;
            });
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'TEMPO ACE!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;
        final options = quest?.options ?? ["A", "B"];

        return AccentBaseLayout(
          gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          child: quest == null ? const SizedBox() : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  SpeedVarianceInstruction(color: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  SpeedVariancePromptCard(
                    word: quest.word ?? "",
                    color: theme.primaryColor,
                    isDark: isDark,
                  ),
                  SizedBox(height: 24.h),
                  
                  SpeedVariancePulseSpeaker(
                    text: quest.textToSpeak ?? "",
                    color: theme.primaryColor,
                    onPlayTts: _playTts,
                  ),
                  SizedBox(height: 32.h),
                  
                  SpeedVarianceTempoDial(
                    options: options,
                    correctIndex: quest.correctAnswerIndex ?? 0,
                    color: theme.primaryColor,
                    isDark: isDark,
                    isAnswered: _isAnswered,
                    isDragging: _isDragging,
                    dialRotation: _dialRotation,
                    selectedIndex: _selectedIndex,
                    onDialRotate: _onDialRotate,
                    onDialRelease: _onDialRelease,
                    onSubmitChoice: _submitChoice,
                  ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 40.h),
                    SpeedVarianceExplanationCard(
                      quest: quest,
                      color: theme.primaryColor,
                      isDark: isDark,
                      isCorrect: _isCorrect,
                    ),
                  ],
                  SizedBox(height: 60.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
