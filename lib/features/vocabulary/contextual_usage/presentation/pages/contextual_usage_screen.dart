import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_painters.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_card.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_option_chip.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_register_meter.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class ContextualUsageScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ContextualUsageScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.contextualUsage,
  });

  @override
  State<ContextualUsageScreen> createState() => _ContextualUsageScreenState();
}

class _ContextualUsageScreenState extends State<ContextualUsageScreen>
    with
        GameScreenMixin<ContextualUsageScreen>,
        VocabularyGameScreenMixin<ContextualUsageScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  Timer? _answerTimer;
  Timer? _scrollTimer;

  VocabularyQuest? _lastQuest;

  @override
  void dispose() {
    _answerTimer?.cancel();
    _scrollTimer?.cancel();
    _selectedOption.dispose();
    _scrollController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initVocabularyGame();
  }

  void _submitAnswer(String selected, String correct, GameQuest quest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    _selectedOption.value = selected;
    isAnsweredNotifier.value = true;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    _answerTimer?.cancel();
    _answerTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      if (isCorrect) {
        hapticService.success();
        isFirstStagePassedNotifier.value = true;
        _scrollTimer?.cancel();
        _scrollTimer = Timer(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        isAnsweredNotifier.value = false;
        submitWrongAnswer(quest: quest, userAnswer: selected);
      }
    });
  }

  void _submitFinalAnswer(
    bool nailedIt, {
    GameQuest? quest,
    String? wrongWord,
  }) {
    if (isAnsweredNotifier.value && isCorrectNotifier.value != null) return;

    if (wrongWord != null && wrongWord.isNotEmpty) {
      _selectedOption.value = wrongWord;
    }

    isAnsweredNotifier.value = false;
    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      final q = quest ?? _lastQuest;
      if (q != null) {
        submitWrongAnswer(quest: q, userAnswer: wrongWord);
      } else {
        submitWrongAnswer(quest: quest!, userAnswer: '');
      }
    }
  }

  @override
  void onQuestionReset() {
    _answerTimer?.cancel();
    _scrollTimer?.cancel();
    _selectedOption.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );
        if (state is VocabularyLoaded) {
          _lastQuest = state.currentQuestOrNull;
        }

        final quest = (state is VocabularyLoaded)
            ? state.currentQuestOrNull
            : _lastQuest;

        final isDarkMode = Theme.of(context).brightness == Brightness.dark;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _selectedOption,
          ]),
          builder: (context, _) {
            return VocabularyBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    currentState.livesRemaining > 0 &&
                    isCorrectNotifier.value == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  isFirstStagePassedNotifier.value = false;
                  _selectedOption.value = null;
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                } else {
                  context.read<VocabularyBloc>().add(NextQuestion());
                }
              },
              onHint: () =>
                  context.read<VocabularyBloc>().add(VocabularyHintUsed()),
              useScrolling: false,
              disablePadding: true,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final keyboardHeight = MediaQuery.of(
                          context,
                        ).viewInsets.bottom;
                        final trueMaxHeight =
                            constraints.maxHeight + keyboardHeight;

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
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: IgnorePointer(
                                      ignoring:
                                          isFirstStagePassedNotifier.value,
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minHeight: trueMaxHeight,
                                        ),
                                        child: Stack(
                                          children: [
                                            Positioned.fill(
                                              child: CustomPaint(
                                                painter: GridPainter(
                                                  theme.primaryColor.withValues(
                                                    alpha: isDarkMode
                                                        ? 0.05
                                                        : 0.03,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                Container(
                                                  constraints: BoxConstraints(
                                                    minHeight: trueMaxHeight,
                                                  ),
                                                  alignment: Alignment.center,
                                                  child: _buildUnfoldContent(
                                                    quest,
                                                    theme.primaryColor,
                                                    isDarkMode,
                                                    constraints.maxWidth,
                                                    trueMaxHeight,
                                                    _selectedOption.value !=
                                                            null
                                                        ? _selectedOption.value!
                                                                  .trim()
                                                                  .toLowerCase() ==
                                                              (quest.correctAnswer ??
                                                                      "")
                                                                  .trim()
                                                                  .toLowerCase()
                                                        : null,
                                                  ),
                                                ),
                                                if (isFirstStagePassedNotifier
                                                    .value)
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.w,
                                                        ),
                                                    child: Column(
                                                      children: [
                                                        SizedBox(height: 10.h),
                                                        if (quest.registerLevel !=
                                                                null ||
                                                            quest.nuanceDifference !=
                                                                null ||
                                                            quest.usageExample !=
                                                                null ||
                                                            quest.contextSentence !=
                                                                null)
                                                          ContextualUsageRegisterMeter(
                                                            registerLevel: quest
                                                                .registerLevel,
                                                            nuanceDifference: quest
                                                                .nuanceDifference,
                                                            usageExample:
                                                                quest
                                                                    .usageExample ??
                                                                quest
                                                                    .contextSentence,
                                                            color: theme
                                                                .primaryColor,
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                SizedBox(
                                                  height:
                                                      (isAnsweredNotifier
                                                              .value ||
                                                          isFirstStagePassedNotifier
                                                              .value)
                                                      ? 10.h
                                                      : 60.h,
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isFirstStagePassedNotifier.value &&
                                      (!isAnsweredNotifier.value ||
                                          isCorrectNotifier.value == null))
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                        ),
                                        child: Column(
                                          children: [
                                            SpeakToConfirmOverlay(
                                              expectedText: (quest.prompt ?? "")
                                                  .replaceAll(
                                                    RegExp(r'_+'),
                                                    quest.correctAnswer ?? "",
                                                  ),
                                              primaryColor: theme.primaryColor,
                                              onConfirmed: () =>
                                                  _submitFinalAnswer(
                                                    true,
                                                    quest: quest,
                                                  ),
                                              onSkipped: () => _submitFinalAnswer(
                                                false,
                                                quest: quest,
                                              ),
                                              isPositioned: false,
                                            ),
                                            SizedBox(height: 60.h),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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

  Widget _buildInstruction(
    VocabularyQuest quest,
    Color color,
    bool isDark,
  ) {
    final rawInstruction = InstructionHelper.getInstruction(quest);
    final instructionText = rawInstruction.isNotEmpty
        ? rawInstruction
        : 'Select the word that best completes the sentence.';
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final widget = Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 310.w),
        child: Text(
          instructionText,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 14.5.sp,
            fontWeight: FontWeight.w600,
            color: isDark
                ? Colors.white.withValues(alpha: 0.9)
                : const Color(0xFF1E293B),
            height: 1.4,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    if (reduceMotion) return widget;
    return widget.animate().fadeIn(duration: 400.ms);
  }

  Widget _buildUnfoldContent(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    double maxWidth,
    double maxHeight,
    bool? currentOptionCorrect,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: 20.h),
        _buildInstruction(quest, color, isDark),
        SizedBox(height: 24.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: ContextualUsageCard(
            question: quest.prompt ?? quest.question ?? "",
            color: color,
            isDark: isDark,
            isAnswered: isAnsweredNotifier.value,
            isCorrect: isCorrectNotifier.value ?? currentOptionCorrect,
            selectedOption: _selectedOption.value,
          ),
        ),
        SizedBox(height: 24.h),
        _buildChipsWrap(
          quest,
          color,
          isDark,
          currentOptionCorrect,
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildChipsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool? currentOptionCorrect,
  ) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double chipWidth = (constraints.maxWidth - 12.w) / 2;

          final wrap = Wrap(
            spacing: 12.w,
            runSpacing: 12.h,
            alignment: WrapAlignment.center,
            children: (quest.options ?? []).map((o) {
              return ContextualUsageOptionChip(
                width: chipWidth,
                text: o,
                color: color,
                isDark: isDark,
                isSelected: _selectedOption.value == o,
                isCorrect: _selectedOption.value == o
                    ? currentOptionCorrect
                    : null,
                onTap: () => _submitAnswer(o, quest.correctAnswer ?? "", quest),
              );
            }).toList(),
          );

          if (reduceMotion) return wrap;
          return wrap
              .animate()
              .fadeIn(delay: 200.ms, duration: 400.ms)
              .slideY(begin: 0.1, curve: Curves.easeOutCubic);
        },
      ),
    );
  }
}
