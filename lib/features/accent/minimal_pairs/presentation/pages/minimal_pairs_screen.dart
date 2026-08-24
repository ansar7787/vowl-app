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
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_speaker_core.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_drone_option.dart';
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_mouth_diagram.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';

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
  int _lastLives = AccentGameConstants.maxLives;
  AccentQuest? _lastQuest;
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int? _selectedDroneIndex;

  bool _isFirstStagePassed = false;

  String? _shuffledQuestId;
  List<Map<String, String>> _currentOptions = [];
  int _currentCorrectIndex = 0;

  void _ensureOptionsShuffled(AccentQuest quest) {
    if (_shuffledQuestId == quest.id) return;

    _shuffledQuestId = quest.id;

    final originalOptions = [
      {'word': quest.word1 ?? '', 'ipa': quest.ipa1 ?? ''},
      {'word': quest.word2 ?? '', 'ipa': quest.ipa2 ?? ''},
    ];

    final correctAnswerStr = quest.correctAnswer;

    _currentOptions = List.from(originalOptions)..shuffle();
    if (correctAnswerStr != null) {
      _currentCorrectIndex = _currentOptions.indexWhere(
        (opt) => opt['word'] == correctAnswerStr,
      );
    } else {
      _currentCorrectIndex = _currentOptions.indexWhere(
        (opt) =>
            opt['word'] ==
            originalOptions[quest.correctAnswerIndex ?? 0]['word'],
      );
    }
    if (_currentCorrectIndex == -1) _currentCorrectIndex = 0;
  }

  @override
  void initState() {
    super.initState();
    context.read<AccentBloc>().add(
      FetchAccentQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _submitVerbalEvaluation(bool nailedIt) {
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

  void _playTts(String text) {
    _hapticService.selection();
    _soundService.playTts(text);
  }

  void _onShoot(int index, int correctIndex) {
    if (_isAnswered || _isFirstStagePassed) return;

    final bool correct = index == correctIndex;
    setState(() {
      _selectedDroneIndex = index;
    });

    if (correct) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isFirstStagePassed = true;
      });
      // Do NOT submit yet! Wait for Phase 2.
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('accent', level: widget.level);

    return BlocConsumer<AccentBloc, AccentState>(
      listener: (context, state) {
        if (state is AccentLoaded) {
          _lastQuest = state.currentQuest as AccentQuest?;
          final livesChanged = (state.livesRemaining > _lastLives);
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered)) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _selectedDroneIndex = null;
              _isFirstStagePassed = false;
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
          _lastLives = state.livesRemaining;
        }
        if (state is AccentGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'PHONETIC EXPERT!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;

        if (quest != null && !_isAnswered) {
          _ensureOptionsShuffled(quest);
        }



        return AccentBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<AccentBloc>().add(NextQuestion()),
          onHint: () => context.read<AccentBloc>().add(AccentHintUsed()),
          useScrolling: false,
          child: quest == null
              ? const SizedBox()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final maxHeight = constraints.maxHeight;
                          final maxWidth = constraints.maxWidth;
                          final bool isCompact = maxHeight < 580;

                          final double estimatedContentHeight =
                              24.h +
                              (isCompact ? 90.h : 120.h) +
                              100.h +
                              (isCompact ? 130.h : 172.h);
                          final remainingHeight =
                              maxHeight - estimatedContentHeight;

                          final double gapUnit = remainingHeight > 0
                              ? remainingHeight / 8
                              : 0;
                          final double gapTop = remainingHeight > 0
                              ? (gapUnit * 1).clamp(8.0, 24.0)
                              : 8.0;
                          final double gapInstruction = remainingHeight > 0
                              ? (gapUnit * 1.5).clamp(12.0, 32.0)
                              : 12.0;

                          final double gapSpeaker = remainingHeight > 0
                              ? (gapUnit * 2).clamp(16.0, 48.0)
                              : 16.0;

                          final double gapBottom = remainingHeight > 0
                              ? (gapUnit * 1).clamp(12.0, 40.0)
                              : 12.0;

                          return Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(height: gapTop),
                                          MinimalPairsInstruction(
                                            color: theme.primaryColor,
                                            instruction: _isFirstStagePassed
                                                ? "Great job! Now confirm by speaking the word."
                                                : context.tr(
                                                    'games.minimal_pairs_instruction',
                                                    fallback: quest.instruction,
                                                  ),
                                          ),
                                          SizedBox(height: gapInstruction),
                                        ],
                                      ),
                                      MinimalPairsSpeakerCore(
                                        text: quest.textToSpeak ?? "",
                                        color: theme.primaryColor,
                                        onPlayTts: _playTts,
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
                                                    child: SizedBox(
                                                      width: maxWidth - 48.w,
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceEvenly,
                                                        children: [
                                                          MinimalPairsDroneOption(
                                                            index: 0,
                                                            word:
                                                                _currentOptions
                                                                    .isNotEmpty
                                                                ? _currentOptions[0]['word']!
                                                                : quest.word1 ??
                                                                      "",
                                                            ipa:
                                                                _currentOptions
                                                                    .isNotEmpty
                                                                ? _currentOptions[0]['ipa']!
                                                                : quest.ipa1 ??
                                                                      "",
                                                            correctIndex:
                                                                _currentOptions
                                                                    .isNotEmpty
                                                                ? _currentCorrectIndex
                                                                : quest.correctAnswerIndex ??
                                                                      0,
                                                            color: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                            isAnswered:
                                                                _isAnswered ||
                                                                _isFirstStagePassed,
                                                            selectedDroneIndex:
                                                                _selectedDroneIndex,
                                                            onShoot: _onShoot,
                                                          ),
                                                          MinimalPairsDroneOption(
                                                            index: 1,
                                                            word:
                                                                _currentOptions
                                                                    .isNotEmpty
                                                                ? _currentOptions[1]['word']!
                                                                : quest.word2 ??
                                                                      "",
                                                            ipa:
                                                                _currentOptions
                                                                    .isNotEmpty
                                                                ? _currentOptions[1]['ipa']!
                                                                : quest.ipa2 ??
                                                                      "",
                                                            correctIndex:
                                                                _currentOptions
                                                                    .isNotEmpty
                                                                ? _currentCorrectIndex
                                                                : quest.correctAnswerIndex ??
                                                                      0,
                                                            color: theme
                                                                .primaryColor,
                                                            isDark: isDark,
                                                            isAnswered:
                                                                _isAnswered ||
                                                                _isFirstStagePassed,
                                                            selectedDroneIndex:
                                                                _selectedDroneIndex,
                                                            onShoot: _onShoot,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    MinimalPairsDroneOption(
                                                      index: 0,
                                                      word:
                                                          _currentOptions
                                                              .isNotEmpty
                                                          ? _currentOptions[0]['word']!
                                                          : quest.word1 ?? "",
                                                      ipa:
                                                          _currentOptions
                                                              .isNotEmpty
                                                          ? _currentOptions[0]['ipa']!
                                                          : quest.ipa1 ?? "",
                                                      correctIndex:
                                                          _currentOptions
                                                              .isNotEmpty
                                                          ? _currentCorrectIndex
                                                          : quest.correctAnswerIndex ??
                                                                0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          _isAnswered ||
                                                          _isFirstStagePassed,
                                                      selectedDroneIndex:
                                                          _selectedDroneIndex,
                                                      onShoot: _onShoot,
                                                    ),
                                                    MinimalPairsDroneOption(
                                                      index: 1,
                                                      word:
                                                          _currentOptions
                                                              .isNotEmpty
                                                          ? _currentOptions[1]['word']!
                                                          : quest.word2 ?? "",
                                                      ipa:
                                                          _currentOptions
                                                              .isNotEmpty
                                                          ? _currentOptions[1]['ipa']!
                                                          : quest.ipa2 ?? "",
                                                      correctIndex:
                                                          _currentOptions
                                                              .isNotEmpty
                                                          ? _currentCorrectIndex
                                                          : quest.correctAnswerIndex ??
                                                                0,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          _isAnswered ||
                                                          _isFirstStagePassed,
                                                      selectedDroneIndex:
                                                          _selectedDroneIndex,
                                                      onShoot: _onShoot,
                                                    ),
                                                  ],
                                                ),

                                          SizedBox(
                                            height: isCompact ? 16.h : 24.h,
                                          ),
                                            SizedBox(height: gapBottom),
                                          ],
                                        ),
                                        if (_isFirstStagePassed && quest.mouthPosition != null) ...[
                                          MinimalPairsMouthDiagram(
                                            mouthPosition: quest.mouthPosition,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                          SizedBox(height: 16.h),
                                        ],
                                      ],
                                  ),
                                ),
                              ),
                                if (_isFirstStagePassed && !_isAnswered)
                                  ShadowPlaybackCompare(
                                    expectedText: _currentOptions.isNotEmpty
                                        ? _currentOptions[_currentCorrectIndex]['word']!
                                        : (quest.correctAnswer ?? quest.word1 ?? ""),
                                    displayText: _currentOptions.isNotEmpty
                                        ? _currentOptions[_currentCorrectIndex]['word']!
                                        : (quest.correctAnswer ?? quest.word1 ?? ""),
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      context.read<AccentBloc>().add(
                                        const AccentSpeakConfirmed(5),
                                      );
                                      _submitVerbalEvaluation(true);
                                    },
                                    onSkipped: () => _submitVerbalEvaluation(
                                      false,
                                    ),
                                  ),
                                SizedBox(height: (_isAnswered || _isFirstStagePassed) ? 380.h : 20.h),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                );
                  },
                ),
        );
      },
    );
  }
}
