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
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType, level: widget.level, isAnswered: _isAnswered, isCorrect: _isCorrect, 
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            child: quest == null ? const SizedBox() : LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                final bool isCompact = maxHeight < 580;
                
                final double estimatedContentHeight = 24.h + (isCompact ? 90.h : 120.h) + (isCompact ? 80.h : 110.h) + (isCompact ? 130.h : 172.h) + (_isAnswered ? (isCompact ? 110.h : 160.h) : 0);
                final remainingHeight = maxHeight - estimatedContentHeight;
                
                final double gapUnit = remainingHeight > 0 ? remainingHeight / 8 : 0;
                final double gapTop = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 24.0) : 8.0;
                final double gapInstruction = remainingHeight > 0 ? (gapUnit * 1).clamp(8.0, 24.0) : 8.0;
                final double gapPrompt = remainingHeight > 0 ? (gapUnit * 1.5).clamp(12.0, 32.0) : 12.0;
                final double gapSpeaker = remainingHeight > 0 ? (gapUnit * 2).clamp(16.0, 48.0) : 16.0;
                final double gapSlider = remainingHeight > 0 ? (gapUnit * 1.5).clamp(12.0, 40.0) : 12.0;
                final double gapBottom = remainingHeight > 0 ? (gapUnit * 1).clamp(12.0, 40.0) : 12.0;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: gapTop),
                              isCompact 
                                ? SizedBox(
                                    height: 32.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: MinimalPairsInstruction(color: theme.primaryColor),
                                    ),
                                  )
                                : MinimalPairsInstruction(color: theme.primaryColor),
                              SizedBox(height: gapInstruction),
                              
                              isCompact 
                                ? SizedBox(
                                    height: 90.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: MinimalPairsPromptCard(color: theme.primaryColor, isDark: isDark),
                                    ),
                                  )
                                : MinimalPairsPromptCard(color: theme.primaryColor, isDark: isDark),
                              SizedBox(height: gapPrompt),
                              
                              isCompact
                                ? SizedBox(
                                    width: 80.r,
                                    height: 80.r,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: MinimalPairsSpeakerCore(
                                        text: quest.textToSpeak ?? "",
                                        color: theme.primaryColor,
                                        onPlayTts: _playTts,
                                      ),
                                    ),
                                  )
                                : MinimalPairsSpeakerCore(
                                    text: quest.textToSpeak ?? "",
                                    color: theme.primaryColor,
                                    onPlayTts: _playTts,
                                  ),
                            ],
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(height: gapSpeaker),
                              isCompact
                                ? SizedBox(
                                    height: 110.h,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
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
                                    ),
                                  )
                                : Row(
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
                                SizedBox(height: gapSlider),
                                isCompact
                                  ? SizedBox(
                                      height: 110.h,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: MinimalPairsExplanationCard(
                                          quest: quest,
                                          color: theme.primaryColor,
                                          isDark: isDark,
                                          isCorrect: _isCorrect,
                                        ),
                                      ),
                                    )
                                  : MinimalPairsExplanationCard(
                                      quest: quest,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      isCorrect: _isCorrect,
                                    ),
                              ],
                              SizedBox(height: gapBottom),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
