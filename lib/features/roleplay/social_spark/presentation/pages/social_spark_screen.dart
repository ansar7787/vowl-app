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
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_instruction.dart';
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
    with TickerProviderStateMixin, RoleplayGameScreenMixin {
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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    initRoleplayGame();
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

  void _submitAnswer(List<String> shuffledWords, String correctAnswer) {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        _selectedIndices.value.isEmpty) {
      return;
    }

    // Assemble sentence in correct tapped order
    final String result = _selectedIndices.value
        .map((idx) => shuffledWords[idx])
        .join(' ');

    // Sanitize punctuation comparisons cleanly
    final sanitizedResult = result.replaceAll(' ?', '?').trim().toLowerCase();
    final sanitizedAnswer = correctAnswer
        .replaceAll(' ?', '?')
        .trim()
        .toLowerCase();

    final bool isCorrect = sanitizedResult == sanitizedAnswer;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      // Wait for Phase 2
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
    }
  }

  void _submitVerbalEvaluation(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<RoleplayBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<RoleplayBloc>().add(SubmitAnswer(false));
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

        // Build active joined text representation
        final String currentText = _selectedIndices.value
            .map((idx) => words[idx])
            .join(' ');

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _selectedIndices,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
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
                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              child: CustomScrollView(
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isCompact =
                                                  constraints.maxHeight < 580;
                                              return Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: isCompact
                                                      ? 5.h
                                                      : 10.h,
                                                ),
                                                child: Column(
                                                  children: [
                                                    SocialSparkInstruction(
                                                      primaryColor:
                                                          theme.primaryColor,
                                                      instruction:
                                                          InstructionHelper.getInstruction(
                                                            quest,
                                                          ),
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 10.h
                                                          : 16.h,
                                                    ),

                                                    SocialSparkConnectionMonitor(
                                                      text: currentText,
                                                      socialContext:
                                                          quest.socialContext,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value &&
                                                          (isCorrectNotifier
                                                                      .value !=
                                                                  null ||
                                                              !isFirstStagePassedNotifier
                                                                  .value),
                                                      isCorrect:
                                                          isCorrectNotifier
                                                              .value,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 12.h
                                                          : 20.h,
                                                    ),

                                                    SocialSparkGalaxyBoard(
                                                      words: words,
                                                      color: theme.primaryColor,
                                                      isDark: isDark,
                                                      selectedIndices:
                                                          _selectedIndices
                                                              .value,
                                                      isAnswered:
                                                          isAnsweredNotifier
                                                              .value &&
                                                          (isCorrectNotifier
                                                                      .value !=
                                                                  null ||
                                                              !isFirstStagePassedNotifier
                                                                  .value),
                                                      isCorrect:
                                                          isCorrectNotifier
                                                              .value,
                                                      pulseValue:
                                                          _pulseController
                                                              .value,
                                                      onStarTap: _onStarTap,
                                                    ),
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 12.h
                                                          : 20.h,
                                                    ),

                                                    // Trigger Action Buttons
                                                    if (!isAnsweredNotifier
                                                            .value &&
                                                        _selectedIndices
                                                            .value
                                                            .isNotEmpty)
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          ScaleButton(
                                                            onTap:
                                                                _clearSelection,
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        isCompact
                                                                        ? 16.w
                                                                        : 24.w,
                                                                    vertical:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 12.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color: theme
                                                                    .primaryColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.1,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                border: Border.all(
                                                                  color: theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.3,
                                                                      ),
                                                                ),
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .refresh_rounded,
                                                                    color: theme
                                                                        .primaryColor,
                                                                    size:
                                                                        isCompact
                                                                        ? 16.r
                                                                        : 18.r,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    "CLEAR PATH",
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          isCompact
                                                                          ? 10.sp
                                                                          : 12.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: theme
                                                                          .primaryColor,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            width: isCompact
                                                                ? 10.w
                                                                : 16.w,
                                                          ),
                                                          ScaleButton(
                                                            onTap: () =>
                                                                _submitAnswer(
                                                                  words,
                                                                  quest.correctAnswer ??
                                                                      "",
                                                                ),
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        isCompact
                                                                        ? 20.w
                                                                        : 32.w,
                                                                    vertical:
                                                                        isCompact
                                                                        ? 10.h
                                                                        : 12.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      30.r,
                                                                    ),
                                                                gradient: LinearGradient(
                                                                  colors: [
                                                                    theme
                                                                        .primaryColor,
                                                                    theme
                                                                        .primaryColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.8,
                                                                        ),
                                                                  ],
                                                                ),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: theme
                                                                        .primaryColor
                                                                        .withValues(
                                                                          alpha:
                                                                              0.35,
                                                                        ),
                                                                    blurRadius:
                                                                        isCompact
                                                                        ? 10
                                                                        : 15,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .bolt_rounded,
                                                                    color: Colors
                                                                        .white,
                                                                    size:
                                                                        isCompact
                                                                        ? 16.r
                                                                        : 18.r,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    "IGNITE SPARK",
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          isCompact
                                                                          ? 10.sp
                                                                          : 12.sp,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color: Colors
                                                                          .white,
                                                                      letterSpacing:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ).animate().fadeIn(
                                                        duration: 300.ms,
                                                      ),

                                                    // Post-answer review cards
                                                    SizedBox(
                                                      height: isCompact
                                                          ? 20.h
                                                          : 40.h,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          (isFirstStagePassedNotifier.value &&
                                              !isAnsweredNotifier.value)
                                          ? 380.h
                                          : 60.h,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isFirstStagePassedNotifier.value &&
                                !isAnsweredNotifier.value)
                              SpeakToConfirmOverlay(
                                expectedText:
                                    quest.correctAnswer ?? currentText,
                                primaryColor: theme.primaryColor,
                                isPositioned: true,
                                onConfirmed: () {
                                  context.read<RoleplayBloc>().add(
                                    const RoleplaySpeakConfirmed(5),
                                  );
                                  _submitVerbalEvaluation(true);
                                },
                                onSkipped: () => _submitVerbalEvaluation(false),
                              ),
                          ],
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
