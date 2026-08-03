import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/game_scrollbar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_instruction.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_prompt_card.dart';

import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_pulse_speaker.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_dialogue_list.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/accent/presentation/widgets/accent_self_evaluation_panel.dart';

class ShadowingChallengeScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShadowingChallengeScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shadowingChallenge,
  });

  @override
  State<ShadowingChallengeScreen> createState() =>
      _ShadowingChallengeScreenState();
}

class _ShadowingChallengeScreenState extends State<ShadowingChallengeScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;

  int? _selectedIndex;
  bool _phase1Passed = false;

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered || _phase1Passed) return;
    setState(() {
      _selectedIndex = index;
    });

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _phase1Passed = true;
      });
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitPhase2Evaluation(bool nailedIt) {
    if (_isAnswered) return;
    
    setState(() {
      _isAnswered = true;
      _isCorrect = nailedIt;
    });

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (state.lastAnswerCorrect == null && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _phase1Passed = false;

              _selectedIndex = null;
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
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SHADOW GHOST!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : null;
        final rawOptions = quest?.options ?? ["A", "B"];
        final options = List<String>.from(rawOptions)
          ..shuffle(Random(quest?.id.hashCode ?? 0));
        
        final correctIndex = quest?.correctAnswer != null 
            ? options.indexOf(quest!.correctAnswer!) 
            : (quest?.correctAnswerIndex ?? 0);
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered,
            isCorrect: _isCorrect,
            showConfetti: _showConfetti,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;
                      return GameScrollbar(
                        controller: _scrollController,
                        child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minHeight: maxHeight),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                ShadowingChallengeInstruction(
                                  color: theme.primaryColor,
                                  instruction: _phase1Passed
                                      ? "Great job! Now record yourself saying the phrase."
                                      : context.tr('games.shadowing_challenge_instruction', fallback: quest.instruction),
                                ),
                                SizedBox(height: 16.h),
                                ShadowingChallengePromptCard(
                                  word: quest.word ?? "",
                                  ipa: quest.phonetic ?? "",
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                ),
                                SizedBox(height: 24.h),
                                ShadowingChallengePulseSpeaker(
                                  text: quest.textToSpeak ?? "",
                                  color: theme.primaryColor,
                                  onPlayTts: _playTts,
                                ),
                                SizedBox(height: 32.h),
                                ShadowingChallengeDialogueList(
                                  options: options,
                                  correctIndex: correctIndex,
                                  color: theme.primaryColor,
                                  isDark: isDark,
                                  isAnswered: _isAnswered || _phase1Passed,
                                  selectedIndex: _selectedIndex,
                                  onSubmitChoice: _submitChoice,
                                ),
                                SizedBox(height: 24.h),
                                if (_phase1Passed)
                                  AccentSelfEvaluationPanel(
                                    textToSpeak: quest.textToSpeak ?? "",
                                    primaryColor: theme.primaryColor,
                                    isCompact: false,
                                    onEvaluate: _submitPhase2Evaluation,
                                  ),
                                SizedBox(height: _isAnswered ? 200.h : 24.h),
                              ],
                            ),
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




