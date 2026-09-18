import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/mixins/speaking_game_screen_mixin.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/services/error_journal_collector.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

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

class _SpeakMissingWordScreenState extends State<SpeakMissingWordScreen>with TickerProviderStateMixin, SpeakingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  late AnimationController _vortexController;
  late AnimationController _pullController;

    
  // Option states
  final ValueNotifier<List<String>> _dynamicOptions = ValueNotifier([]);
  final ValueNotifier<String?> _selectedWord = ValueNotifier(null);
  final ValueNotifier<bool> _isListening = ValueNotifier(false);
  final ValueNotifier<bool> _isWordPlaced = ValueNotifier(false);

        final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
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
    });

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
        if (isAnsweredNotifier.value || _isWordPlaced.value) return;
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

        hapticService.success();
        soundService.playClick();
        _scrollToBottom();
      }
    });

    initSpeakingGame();
  }

  @override
  void dispose() {
    _vortexController.dispose();
    _pullController.dispose();
    _dynamicOptions.dispose();
    _selectedWord.dispose();
    _isListening.dispose();
    _isWordPlaced.dispose();
                _scrollController.dispose();
    disposeSpeakingGame();
    disposeSpeakingGame();
    disposeSpeakingGame();
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



  void _onPullStart(String word) {
    if (isAnsweredNotifier.value || _isWordPlaced.value) return;
    hapticService.selection();
    _selectedWord.value = word;
    _isListening.value = true;
    _pullController.forward();
  }

  void _onPullEnd() {
    if (isAnsweredNotifier.value || _isWordPlaced.value) return;
    _isListening.value = false;
    if (_pullController.status != AnimationStatus.completed) {
      _pullController.reverse();
      _selectedWord.value = null;
    }
  }

  void _onTap(String word) {
    if (isAnsweredNotifier.value || _isWordPlaced.value) return;
    hapticService.selection();
    _selectedWord.value = word;
    _pullController.value = 1.0; // Instantly complete the pull
  }

  void _submitVerbalEvaluation(
    bool nailedIt,
    String expectedWord, {
    bool forceImmediateFail = false,
  }) {
    if (isAnsweredNotifier.value) return;

    final bool wordIsCorrect =
        _selectedWord.value?.toLowerCase() == expectedWord.toLowerCase();
    final bool isOverallCorrect =
        wordIsCorrect && nailedIt && !forceImmediateFail;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = isOverallCorrect;

    if (isOverallCorrect) {
      hapticService.success();
      soundService.playCorrect();
      context.read<SpeakingBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();

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
      listenWhen: speakingListenWhen,
      listener: onSpeakingStateChanged,
      builder: (context, state) {
        final quest = (state is SpeakingLoaded) ? state.currentQuest : null;

        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: mediaQuery.textScaler.clamp(maxScaleFactor: 1.1),
          ),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              isAnsweredNotifier,
              isCorrectNotifier,
              showConfettiNotifier,
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
                isAnswered: isAnsweredNotifier.value,
                isCorrect: isCorrectNotifier.value,
                showConfetti: showConfettiNotifier.value,
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
                            if (_isWordPlaced.value && !isAnsweredNotifier.value)
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
