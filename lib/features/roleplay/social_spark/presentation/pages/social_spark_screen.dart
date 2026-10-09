import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_connection_monitor.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_galaxy_board.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class SocialSparkScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SocialSparkScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.socialSpark,
  });

  @override
  State<SocialSparkScreen> createState() => _SocialSparkScreenState();
}

class _SocialSparkScreenState extends State<SocialSparkScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<SocialSparkScreen>,
        RoleplayGameScreenMixin<SocialSparkScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _pulseController;

  // Track selected words by their original shuffled index to support duplicate words flawlessly
  final ValueNotifier<List<int>> _selectedIndices = ValueNotifier([]);
  final ScrollController _scrollController = ScrollController();

  String _formatSentence(String text) {
    return text
        .replaceAll(RegExp(r'\s+(?=[,.?!])'), '')
        .replaceAll(RegExp(r"\s+'s\b"), "'s")
        .replaceAll(RegExp(r"\s+n't\b"), "n't")
        .trim();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    initRoleplayGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_pulseController.isAnimating) _pulseController.stop();
    } else {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _selectedIndices.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  void _onStarTap(int index) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    soundService.playHint(); // Play little synth tap note

    final current = List<int>.from(_selectedIndices.value);
    if (current.contains(index)) {
      current.remove(index);
    } else {
      current.add(index);
    }
    _selectedIndices.value = current;
  }

  void _clearSelection() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    _selectedIndices.value = [];
  }

  void _submitAnswer(
    List<String> shuffledWords,
    String correctAnswer,
    GameQuest quest,
  ) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        _selectedIndices.value.isEmpty) {
      return;
    }

    // Assemble sentence in correct tapped order
    final String result = _selectedIndices.value
        .map((idx) => shuffledWords[idx])
        .join(' ');

    final formattedResult = _formatSentence(result);
    final formattedAnswer = _formatSentence(correctAnswer);

    // Sanitize punctuation comparisons cleanly
    final sanitizedResult = formattedResult.toLowerCase();
    final sanitizedAnswer = formattedAnswer.toLowerCase();

    final bool isCorrect = sanitizedResult == sanitizedAnswer;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      submitWrongAnswer(quest: quest, userAnswer: formattedResult);
    }
  }

  void _submitVerbalEvaluation(
    bool nailedIt,
    GameQuest quest,
    String userAnswer,
  ) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      _scrollToBottom();
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  @override
  void onQuestionReset() {
    _selectedIndices.value = [];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;
        final words = quest?.shuffledWords ?? [];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            final String currentText = _formatSentence(_selectedIndices.value
                .where((idx) => idx >= 0 && idx < words.length)
                .map((idx) => words[idx])
                .join(' '));

            return RoleplayBaseLayout(
              fullScreenContent: true,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                              SliverToBoxAdapter(
                                child: ListenableBuilder(
                                  listenable: _selectedIndices,
                                  builder: (context, _) {
                                    final String currentText = _formatSentence(_selectedIndices.value
                                        .where((idx) => idx >= 0 && idx < words.length)
                                        .map((idx) => words[idx])
                                        .join(' '));
                                    final isCompact = MediaQuery.of(context).size.height < 580;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: isCompact ? 5.h : 10.h,
                                      ),
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 10.h : 16.h,
                                          ),
                                          SocialSparkConnectionMonitor(
                                            text: currentText,
                                            socialContext: quest.socialContext,
                                            instruction: InstructionHelper.getInstruction(quest),
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            isAnswered: isAnsweredNotifier.value &&
                                                (isCorrectNotifier.value != null ||
                                                    !isFirstStagePassedNotifier.value),
                                            isCorrect: isCorrectNotifier.value,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 12.h : 20.h,
                                          ),
                                          SocialSparkGalaxyBoard(
                                            words: words,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            selectedIndices: _selectedIndices.value
                                                .where((idx) => idx >= 0 && idx < words.length)
                                                .toList(),
                                            isAnswered: isAnsweredNotifier.value &&
                                                (isCorrectNotifier.value != null ||
                                                    !isFirstStagePassedNotifier.value),
                                            isCorrect: isCorrectNotifier.value,
                                            pulseValue: _pulseController.value,
                                            onStarTap: _onStarTap,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 12.h : 20.h,
                                          ),
                                          // Trigger Action Buttons
                                          if (!isAnsweredNotifier.value &&
                                              _selectedIndices.value.isNotEmpty)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                ScaleButton(
                                                  onTap: () => _submitAnswer(
                                                    words,
                                                    quest.correctAnswer ?? "",
                                                    quest,
                                                  ),
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding: EdgeInsets.symmetric(
                                                      vertical: isCompact ? 12.h : 16.h,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(30.r),
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          theme.primaryColor,
                                                          theme.primaryColor.withValues(
                                                            alpha: 0.8,
                                                          ),
                                                        ],
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: theme.primaryColor.withValues(
                                                            alpha: 0.35,
                                                          ),
                                                          blurRadius: isCompact ? 10 : 15,
                                                        ),
                                                      ],
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.bolt_rounded,
                                                          color: Colors.white,
                                                          size: isCompact ? 18.r : 20.r,
                                                        ),
                                                        SizedBox(width: 8.w),
                                                        Text(
                                                          "IGNITE SPARK",
                                                          style: TextStyle(
                                                            fontFamily: 'Outfit',
                                                            fontSize: isCompact ? 14.sp : 16.sp,
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.white,
                                                            letterSpacing: 1.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(height: isCompact ? 12.h : 16.h),
                                                ScaleButton(
                                                  onTap: _clearSelection,
                                                  child: Container(
                                                    alignment: Alignment.center,
                                                    padding: EdgeInsets.symmetric(
                                                      vertical: isCompact ? 10.h : 14.h,
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.refresh_rounded,
                                                          color: theme.primaryColor.withValues(alpha: 0.7),
                                                          size: isCompact ? 16.r : 18.r,
                                                        ),
                                                        SizedBox(width: 6.w),
                                                        Text(
                                                          "CLEAR PATH",
                                                          style: TextStyle(
                                                            fontFamily: 'Outfit',
                                                            fontSize: isCompact ? 12.sp : 14.sp,
                                                            fontWeight: FontWeight.bold,
                                                            color: theme.primaryColor.withValues(alpha: 0.7),
                                                            letterSpacing: 1.5,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ).animate().fadeIn(duration: 300.ms),
                                          // Post-answer review cards
                                          SizedBox(
                                            height: isCompact ? 20.h : 40.h,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value)
                                SliverToBoxAdapter(
                                  child: SpeakToConfirmOverlay(
                                    expectedText:
                                        _formatSentence(quest.correctAnswer ?? currentText),
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      context.read<RoleplayBloc>().add(
                                        const RoleplaySpeakConfirmed(5),
                                      );
                                      _submitVerbalEvaluation(
                                        true,
                                        quest,
                                        currentText,
                                      );
                                    },
                                    onSkipped: () => _submitVerbalEvaluation(
                                      false,
                                      quest,
                                      currentText,
                                    ),
                                  ),
                                ),
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height:
                                      MediaQuery.of(context).viewInsets.bottom >
                                          0
                                      ? MediaQuery.of(
                                              context,
                                            ).viewInsets.bottom +
                                            40.h
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
