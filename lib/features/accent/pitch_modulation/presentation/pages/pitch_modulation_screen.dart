import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/presentation/layout/accent_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_instruction.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_prompt_card.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_pulse_speaker.dart';
import 'package:vowl/features/accent/pitch_modulation/presentation/widgets/pitch_modulation_dial_control.dart';
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

class PitchModulationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PitchModulationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pitchModulation,
  });

  @override
  State<PitchModulationScreen> createState() => _PitchModulationScreenState();
}

class _PitchModulationScreenState extends State<PitchModulationScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = 3;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<double> _dialRotation = ValueNotifier(0.0);
  final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  final ValueNotifier<int> _spokenMeaningsCount = ValueNotifier(0);
  AccentQuest? _lastQuest;

  @override
  void dispose() {
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _dialRotation.dispose();
    _isDragging.dispose();
    _selectedIndex.dispose();
    _isFirstStagePassed.dispose();
    _spokenMeaningsCount.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
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

  void _onDialRotate(DragUpdateDetails details, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _isDragging.value = true;
    _dialRotation.value = (_dialRotation.value - details.delta.dy / 150.0).clamp(-1.0, 1.0);

    // Auto-lock when reaching ends
    if (_dialRotation.value < -0.8) {
      _submitChoice(0, correct);
    } else if (_dialRotation.value > 0.8) {
      _submitChoice(1, correct);
    }
  }

  void _onDialRelease() {
    if (_isAnswered.value || _isFirstStagePassed.value || !_isDragging.value) return;
    _isDragging.value = false;
    if (!_isAnswered.value) {
      _dialRotation.value = 0.0;
    }
  }

  void _submitChoice(int index, int correct) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;
    _selectedIndex.value = index;
    _dialRotation.value = index == 0 ? -0.8 : 0.8;
    _isDragging.value = false;

    bool isCorrect = index == correct;

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isFirstStagePassed.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<AccentBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (_isAnswered.value) return;

    _isAnswered.value = true;
    _isCorrect.value = nailedIt;

    if (nailedIt) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<AccentBloc>().add(const AccentSpeakConfirmed(5));
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
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _dialRotation.value = 0.0;
            _selectedIndex.value = null;
            _isDragging.value = false;
            _isFirstStagePassed.value = false;
            _spokenMeaningsCount.value = 0;
            // Proactively auto-play sound on question load
            final quest = state.currentQuest as AccentQuest?;
            if (quest != null) {
              _lastQuest = quest;
            }
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
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'TONAL EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
        final options = quest?.options ?? ["A", "B"];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dialRotation, _isDragging, _selectedIndex, _isFirstStagePassed, _spokenMeaningsCount]),
            builder: (context, _) {
              return AccentBaseLayout(
            gameType: widget.gameType,
            level: widget.level,
            isAnswered: _isAnswered.value,
            isCorrect: _isCorrect.value,
            showConfetti: _showConfetti.value,
            onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
            onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
            useScrolling: false,
            child: quest == null
                ? const SizedBox()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final maxHeight = constraints.maxHeight;

                      final double estimatedContentHeight =
                          24.h + 90.h + 80.h + 140.h;
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 8
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 24.0)
                          : 8.0;
                      final double gapPrompt = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(12.0, 32.0)
                          : 12.0;
                      final double gapSpeaker = remainingHeight > 0
                          ? (gapUnit * 2).clamp(16.0, 48.0)
                          : 16.0;

                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1).clamp(12.0, 40.0)
                          : 12.0;

                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      children: [
                                        Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(height: gapTop),
                                            PitchModulationInstruction(
                                              color: theme.primaryColor,
                                              instruction: _isFirstStagePassed.value
                                                  ? "Great job! Now record yourself saying the word."
                                                  : context.tr(
                                                      'games.pitch_modulation_instruction',
                                                      fallback:
                                                          "Listen carefully and choose the pitch pattern you hear.",
                                                    ),
                                            ),
                                            SizedBox(height: gapInstruction),

                                            PitchModulationPromptCard(
                                              word: quest.word ?? "",
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                            ),
                                            SizedBox(height: gapPrompt),

                                            PitchModulationPulseSpeaker(
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
                                            PitchModulationDialControl(
                                              options: options,
                                              correctIndex:
                                                  quest.correctAnswerIndex ?? 0,
                                              color: theme.primaryColor,
                                              isDark: isDark,
                                              isAnswered:
                                                  _isAnswered.value || _isFirstStagePassed.value,
                                              isDragging: _isDragging.value,
                                              dialRotation: _dialRotation.value,
                                              selectedIndex: _selectedIndex.value,
                                              onDialRotate: _onDialRotate,
                                              onDialRelease: _onDialRelease,
                                              onSubmitChoice: _submitChoice,
                                            ),

                                            SizedBox(height: gapBottom),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isFirstStagePassed.value && !_isAnswered.value)
                                  SpeakToConfirmOverlay(
                                    expectedText: quest.textToSpeak ?? "",
                                    displayText: '${quest.textToSpeak ?? ""}\n\n(Meaning: ${options[_spokenMeaningsCount.value]})',
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      if (_spokenMeaningsCount.value == 0) {
                                        _spokenMeaningsCount.value = 1;
                                        _soundService.playCorrect();
                                      } else {
                                        context.read<AccentBloc>().add(
                                          const AccentSpeakConfirmed(10),
                                        );
                                        _submitVerbalEvaluation(true);
                                      }
                                    },
                                    onSkipped: () => _submitVerbalEvaluation(false),
                                  ),
                                SizedBox(height: _isAnswered.value ? 180.h : 20.h),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
              );
            },
          ),
        );
      },
    );
  }
}
