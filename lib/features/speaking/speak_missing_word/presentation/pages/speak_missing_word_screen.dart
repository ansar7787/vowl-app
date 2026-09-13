import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';

import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_instruction.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_vortex_sentence.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_magnet_arena.dart';

class SpeakMissingWordScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SpeakMissingWordScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.speakMissingWord,
  });

  @override
  State<SpeakMissingWordScreen> createState() => _SpeakMissingWordScreenState();
}

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen>
    with TickerProviderStateMixin {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late AnimationController _vortexController;
  late AnimationController _pullController;

  int _lastProcessedIndex = -1;
  int? _lastLives;

  // Option states
  final ValueNotifier<List<String>> _dynamicOptions = ValueNotifier([]);
  final ValueNotifier<String?> _selectedWord = ValueNotifier(null);
  final ValueNotifier<bool> _isListening = ValueNotifier(false);
  final ValueNotifier<bool> _isWordPlaced = ValueNotifier(false);

  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vortexController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pullController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _pullController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (_isAnswered.value || _isWordPlaced.value) return;
        _isWordPlaced.value = true;

        final state = context.read<SpeakingBloc>().state;
        if (state is SpeakingLoaded) {
          final expectedWord = state.currentQuest.missingWord ?? "";
          final wordIsCorrect =
              _selectedWord.value?.toLowerCase() == expectedWord.toLowerCase();

          if (!wordIsCorrect) {
            _submitVerbalEvaluation(
              false,
              expectedWord,
              forceImmediateFail: true,
            );
            return;
          }
        }

        _hapticService.success();
        _soundService.playClick();
        _scrollToBottom();
      }
    });

    context.read<SpeakingBloc>().add(
      FetchSpeakingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _pullController.dispose();
    _dynamicOptions.dispose();
    _selectedWord.dispose();
    _isListening.dispose();
    _isWordPlaced.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _triggerAutoPlay(SpeakingQuest quest) {
    if (quest.textToSpeak != null && quest.missingWord != null) {
      // The JSON's textToSpeak already contains underscores (e.g. "___")
      // We read the underscores as "blank" so the voice doesn't read symbol names
      final blankedText = quest.textToSpeak!.replaceAll(RegExp(r'_+'), "blank");
      _soundService.playTts(blankedText);
    }
  }

  void _generateDynamicOptions(String correctWord) {
    final List<String> commonWords = [
      "apple",
      "car",
      "book",
      "house",
      "friend",
      "time",
      "day",
      "night",
      "water",
      "food",
      "money",
      "family",
      "school",
      "city",
      "music",
      "happy",
      "sad",
      "fast",
      "slow",
      "good",
      "run",
      "walk",
      "read",
      "write",
      "speak",
      "bread",
      "coffee",
      "doctor",
      "kitchen",
      "beautiful",
      "delicious",
      "expensive",
      "phone",
      "bag",
      "key",
      "system",
      "module",
      "portal",
      "shield",
      "drone",
    ];

    commonWords.removeWhere(
      (w) => w.toLowerCase() == correctWord.toLowerCase(),
    );
    commonWords.shuffle();

    final newOptions = [
      correctWord.toLowerCase(),
      commonWords[0],
      commonWords[1],
    ];

    newOptions.shuffle();
    _dynamicOptions.value = newOptions;
  }

  void _onPullStart(String word) {
    if (_isAnswered.value || _isWordPlaced.value) return;
    _hapticService.selection();
    _selectedWord.value = word;
    _isListening.value = true;
    _pullController.forward();
  }

  void _onPullEnd() {
    if (_isAnswered.value || _isWordPlaced.value) return;
    _isListening.value = false;
    if (_pullController.status != AnimationStatus.completed) {
      _pullController.reverse();
      _selectedWord.value = null;
    }
  }

  void _onTap(String word) {
    if (_isAnswered.value || _isWordPlaced.value) return;
    _hapticService.selection();
    _selectedWord.value = word;
    _pullController.value = 1.0; // Instantly complete the pull
  }

  void _submitVerbalEvaluation(
    bool nailedIt,
    String expectedWord, {
    bool forceImmediateFail = false,
  }) {
    if (_isAnswered.value) return;

    final bool wordIsCorrect =
        _selectedWord.value?.toLowerCase() == expectedWord.toLowerCase();
    final bool isOverallCorrect =
        wordIsCorrect && nailedIt && !forceImmediateFail;

    _isAnswered.value = true;
    _isCorrect.value = isOverallCorrect;

    if (isOverallCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();

      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        ErrorJournalCollector.record(
          userId: authState.user!.id,
          gameType: widget.gameType.name,
          question: expectedWord,
          userAnswer: _selectedWord.value ?? '[None]',
          correctAnswer: expectedWord,
          level: widget.level,
        );
      }

      context.read<SpeakingBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('speaking', level: widget.level);
    final mediaQuery = MediaQuery.of(context);

    return BlocConsumer<SpeakingBloc, SpeakingState>(
      listener: (context, state) {
        if (state is SpeakingLoaded) {
          final livesChanged = (state.livesRemaining > (_lastLives ?? 3));
          if (state.currentIndex != _lastProcessedIndex ||
              livesChanged ||
              (!state.answerStatus.isAnswered && _isAnswered.value)) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _isListening.value = false;
            _pullController.reset();
            _selectedWord.value = null;
            _isWordPlaced.value = false;
            _generateDynamicOptions(state.currentQuest.missingWord ?? "drone");
            Future.delayed(const Duration(milliseconds: 300), () {
              if (mounted) _triggerAutoPlay(state.currentQuest);
            });
          } else if (state.answerStatus == AnswerStatus.incorrect) {
            _isCorrect.value = false;
            _isAnswered.value = true; // Always show feedback card on incorrect
          }
          _lastLives = state.livesRemaining;

          if (state.isLetterRevealed && _dynamicOptions.value.length > 1) {
            final correctWord =
                state.currentQuest.missingWord?.toLowerCase() ?? "";
            if (_dynamicOptions.value.contains(correctWord)) {
              _dynamicOptions.value = [correctWord];
            }
          }
        }
        if (state is SpeakingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'speaking_games.verbal_vortex',
              fallback: 'VERBAL VORTEX DRIVER!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _isAnswered,
              _isCorrect,
              _showConfetti,
              _dynamicOptions,
              _selectedWord,
              _pullController,
              _isWordPlaced,
              _isListening,
            ]),
            builder: (context, _) {
              final String rawSentence =
                  quest?.textToSpeak ?? "The robot operates the system safely.";
              final String missingWord = quest?.missingWord ?? "robot";

              // The JSON's textToSpeak already contains underscores (e.g. "___")
              final String initialBlankSentence = rawSentence;

              final bool isSelectedCorrect =
                  _selectedWord.value?.toLowerCase() ==
                  missingWord.toLowerCase();

              final String userCompletedSentence =
                  _isWordPlaced.value && _selectedWord.value != null
                  ? (isSelectedCorrect && quest?.correctAnswer != null
                        ? quest!.correctAnswer!
                        : initialBlankSentence.replaceFirst(
                            RegExp(r'_+'),
                            _selectedWord.value!,
                          ))
                  : initialBlankSentence;

              return SpeakingBaseLayout(
                gameType: widget.gameType,
                level: widget.level,
                isAnswered: _isAnswered.value,
                isCorrect: _isCorrect.value,
                showConfetti: _showConfetti.value,
                disablePadding: true,
                onContinue: () =>
                    context.read<SpeakingBloc>().add(const NextQuestion()),
                onHint: () =>
                    context.read<SpeakingBloc>().add(const SpeakingHintUsed()),
                child: quest == null
                    ? GameShimmerLoading(primaryColor: theme.primaryColor)
                    : RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            SliverPadding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 20.w,
                                vertical: 16.h,
                              ),
                              sliver: SliverToBoxAdapter(
                                child: AbsorbPointer(
                                  absorbing: _isWordPlaced.value,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SpeakMissingWordInstruction(
                                        primaryColor: theme.primaryColor,
                                        isWordPlaced: _isWordPlaced.value,
                                        instruction:
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      ),
                                      SizedBox(height: 24.h),
                                      SpeakMissingWordVortexSentence(
                                        text: _isWordPlaced.value
                                            ? userCompletedSentence
                                            : initialBlankSentence,
                                        insertedWord: _isWordPlaced.value
                                            ? (_selectedWord.value ?? "")
                                            : "",
                                        primaryColor: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 32.h),
                                      if (!_isWordPlaced.value)
                                        SpeakMissingWordMagnetArena(
                                          dynamicOptions: _dynamicOptions.value,
                                          selectedWord: _selectedWord.value,
                                          pullForce: _pullController.value,
                                          primaryColor: theme.primaryColor,
                                          isDark: isDark,
                                          vortexController: _vortexController,
                                          onPullStart: _onPullStart,
                                          onPullEnd: _onPullEnd,
                                          onTap: _onTap,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (_isWordPlaced.value && !_isAnswered.value)
                              SliverToBoxAdapter(
                                child: ShadowPlaybackCompare(
                                  expectedText: userCompletedSentence,
                                  primaryColor: theme.primaryColor,
                                  isPositioned: false,
                                  showExpectedText: false,
                                  onConfirmed: () => _submitVerbalEvaluation(
                                    true,
                                    missingWord,
                                  ),
                                  onSkipped: () => _submitVerbalEvaluation(
                                    false,
                                    missingWord,
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(child: SizedBox(height: 120.h)),
                          ],
                        ),
                      ),
              );
            },
          ),
        );
      },
    );
  }
}
