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
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_prompt_card.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_speaker_core.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_drone_option.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_explanation_card.dart';

class MinimalPairsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const MinimalPairsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.minimalPairs,
  });

  @override
  State<MinimalPairsScreen> createState() => _MinimalPairsScreenState();
}

class _MinimalPairsScreenState extends State<MinimalPairsScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedDroneIndex;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(FetchAccentQuests(gameType: widget.gameType, level: widget.level));
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onShoot(int index, int correctIndex) {
    if (_isAnswered) return;
    
    final bool correct = index == correctIndex;
    setState(() {
      _selectedDroneIndex = index;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = true; 
      });
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() { 
        _isAnswered = true; 
        _isCorrect = false; 
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
      
      Future.delayed(2.seconds, () {
        if (mounted) {
          setState(() {
            _isAnswered = false;
            _isCorrect = null;
            _selectedDroneIndex = null;
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
          if (state.currentIndex != _lastProcessedIndex) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedDroneIndex = null;
            });
            // Proactively auto-play phonetic sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null && quest.textToSpeak != null) {
              Future.delayed(500.milliseconds, () {
                if (mounted) {
                  _soundService.playTts(quest.textToSpeak!);
                }
              });
            }
          }
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(context, xp: state.xpEarned, coins: state.coinsEarned, title: 'PHONETIC EXPERT!', enableDoubleUp: true);
        } else if (state is AccentGameOver) {
          GameDialogHelper.showGameOver(context, onRestore: () => context.read<AccentBloc>().add(RestoreLife()));
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded) ? state.currentQuest as AccentQuest? : null;

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
                  MinimalPairsInstruction(color: theme.primaryColor),
                  SizedBox(height: 24.h),
                  
                  MinimalPairsPromptCard(color: theme.primaryColor, isDark: isDark),
                  SizedBox(height: 32.h),
                  
                  MinimalPairsSpeakerCore(
                    text: quest.textToSpeak ?? "",
                    color: theme.primaryColor,
                    onPlayTts: _playTts,
                  ),
                  SizedBox(height: 40.h),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      MinimalPairsDroneOption(
                        index: 0,
                        word: quest.word1 ?? "",
                        ipa: quest.ipa1 ?? "",
                        correctIndex: quest.correctAnswerIndex ?? 0,
                        color: theme.primaryColor,
                        isDark: isDark,
                        isAnswered: _isAnswered,
                        selectedDroneIndex: _selectedDroneIndex,
                        onShoot: _onShoot,
                      ),
                      MinimalPairsDroneOption(
                        index: 1,
                        word: quest.word2 ?? "",
                        ipa: quest.ipa2 ?? "",
                        correctIndex: quest.correctAnswerIndex ?? 0,
                        color: theme.primaryColor,
                        isDark: isDark,
                        isAnswered: _isAnswered,
                        selectedDroneIndex: _selectedDroneIndex,
                        onShoot: _onShoot,
                      ),
                    ],
                  ),
                  
                  if (_isAnswered) ...[
                    SizedBox(height: 40.h),
                    MinimalPairsExplanationCard(
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
