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
import 'package:vowl/features/accent/word_linking/presentation/widgets/word_linking_instruction.dart';
import 'package:vowl/features/accent/word_linking/presentation/widgets/word_linking_pulse_speaker.dart';
import 'package:vowl/features/accent/word_linking/presentation/widgets/word_linking_sentence_field.dart';
import 'package:vowl/core/presentation/game_mechanics/shadow_playback_compare.dart';
import 'package:vowl/features/accent/presentation/constants/accent_game_constants.dart';

class WordLinkingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const WordLinkingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.wordLinking,
  });

  @override
  State<WordLinkingScreen> createState() => _WordLinkingScreenState();
}

class _WordLinkingScreenState extends State<WordLinkingScreen> {
  final ScrollController _scrollController = ScrollController();
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  int _lastProcessedIndex = -1;
  int _lastLives = AccentGameConstants.maxLives;
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<int?> _selectedNodeIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isFirstStagePassed = ValueNotifier(false);
  AccentQuest? _lastQuest;

  @override
  void dispose() {
    _scrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _selectedNodeIndex.dispose();
    _isFirstStagePassed.dispose();
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

  void _onNodeTap(int index, String correctPair, List<String> words) {
    if (_isAnswered.value || _isFirstStagePassed.value) return;

    _selectedNodeIndex.value = index;

    String selectedPair = "${words[index]} ${words[index + 1]}";
    bool isCorrect =
        selectedPair.toLowerCase().trim() == correctPair.toLowerCase().trim();

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
            _selectedNodeIndex.value = null;
            _isFirstStagePassed.value = false;
            // Proactively auto-play phonetic sound on question load
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
            title: 'LINKAGE MASTER!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final AccentQuest? quest = (state is AccentLoaded)
            ? state.currentQuest as AccentQuest?
            : _lastQuest;
        final words = quest?.words ?? [];
        final mediaQuery = MediaQuery.of(context);

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _selectedNodeIndex, _isFirstStagePassed]),
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
                      final maxWidth = constraints.maxWidth;
                      final bool isCompact = maxHeight < 580;

                      final double estimatedContentHeight =
                          24.h +
                          80.h + // Speaker
                          (isCompact ? 130.h : 172.h); // Sentence Field
                      final remainingHeight =
                          maxHeight - estimatedContentHeight;

                      final double gapUnit = remainingHeight > 0
                          ? remainingHeight / 6
                          : 0;
                      final double gapTop = remainingHeight > 0
                          ? (gapUnit * 1).clamp(8.0, 32.0)
                          : 8.0;
                      final double gapInstruction = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(12.0, 40.0)
                          : 12.0;
                      final double gapSpeaker = remainingHeight > 0
                          ? (gapUnit * 2).clamp(16.0, 56.0)
                          : 16.0;

                      final double gapBottom = remainingHeight > 0
                          ? (gapUnit * 1.5).clamp(12.0, 48.0)
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
                                        SizedBox(height: gapTop),
                                        isCompact
                                            ? SizedBox(
                                                height: 32.h,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: maxWidth - 48.w,
                                                    ),
                                                    child: WordLinkingInstruction(
                                                      color: theme.primaryColor,
                                                      instruction: _isFirstStagePassed.value
                                                          ? "Great job! Now record yourself saying the phrase."
                                                          : context.tr(
                                                              'games.word_linking_instruction',
                                                              fallback:
                                                                  quest.instruction,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : WordLinkingInstruction(
                                                color: theme.primaryColor,
                                                instruction: _isFirstStagePassed.value
                                                    ? "Great job! Now record yourself saying the phrase."
                                                    : context.tr(
                                                        'games.word_linking_instruction',
                                                        fallback: quest.instruction,
                                                      ),
                                              ),
                                        SizedBox(height: gapInstruction),
                                        WordLinkingPulseSpeaker(
                                          text: quest.textToSpeak ?? "",
                                          color: theme.primaryColor,
                                          onPlayTts: _playTts,
                                        ),
                                        SizedBox(height: gapSpeaker),
                                        isCompact
                                            ? SizedBox(
                                                height: 110.h,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: SizedBox(
                                                    width: maxWidth - 48.w,
                                                    child: WordLinkingSentenceField(
                                                      words: words,
                                                      correctPair:
                                                          quest.correctAnswer ?? "",
                                                      linkingType: quest.linkingType,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          _isAnswered.value ||
                                                          _isFirstStagePassed.value,
                                                      selectedNodeIndex:
                                                          _selectedNodeIndex.value,
                                                      onNodeTap: _onNodeTap,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : WordLinkingSentenceField(
                                                words: words,
                                                correctPair:
                                                    quest.correctAnswer ?? "",
                                                linkingType: quest.linkingType,
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                isAnswered:
                                                    _isAnswered.value ||
                                                    _isFirstStagePassed.value,
                                                selectedNodeIndex: _selectedNodeIndex.value,
                                                onNodeTap: _onNodeTap,
                                              ),
                                        SizedBox(height: gapBottom),
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isFirstStagePassed.value && !_isAnswered.value)
                                  ShadowPlaybackCompare(
                                    expectedText: quest.textToSpeak ?? "",
                                    displayText: quest.textToSpeak ?? "",
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () => _submitVerbalEvaluation(true),
                                    onSkipped: () => _submitVerbalEvaluation(false),
                                  ),
                                SizedBox(height: (_isAnswered.value || _isFirstStagePassed.value) ? 380.h : 20.h),
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
