import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_instruction.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_mirror.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';

class DirectIndirectSpeechScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DirectIndirectSpeechScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.directIndirectSpeech,
  });

  @override
  State<DirectIndirectSpeechScreen> createState() =>
      _DirectIndirectSpeechScreenState();
}

class _DirectIndirectSpeechScreenState extends State<DirectIndirectSpeechScreen>
    with
        GameScreenMixin<DirectIndirectSpeechScreen>,
        GrammarGameScreenMixin<DirectIndirectSpeechScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  final ValueNotifier<int> _selectedReflection = ValueNotifier(-1);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    isFirstStagePassedNotifier.removeListener(_onStagePassedScroll);
    _rotation.dispose();
    _selectedReflection.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onStagePassedScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    isFirstStagePassedNotifier.addListener(_onStagePassedScroll);
    initGrammarGame();
  }

  void _onReflectionSelect(int index, int correctIndex, GameQuest quest) {
    final grammarState = context.read<GrammarBloc>().state;
    final isAlreadyAnswered =
        isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        (grammarState is GrammarLoaded &&
            grammarState.answerStatus != AnswerStatus.unanswered);
    if (isAlreadyAnswered) return;
    _selectedReflection.value = index;

    bool isCorrect = index == correctIndex;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      _rotation.value = 3.14159265359;
    } else {
      _rotation.value = 3.14159265359;
      String? userAnswer =
          (quest.options != null && index < quest.options!.length)
          ? quest.options![index]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;
    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      String? userAnswer =
          (_selectedReflection.value != -1 &&
              quest.options != null &&
              _selectedReflection.value < quest.options!.length)
          ? quest.options![_selectedReflection.value]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void onQuestionReset() {
    _rotation.value = 0.0;
    _selectedReflection.value = -1;
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final GrammarQuest? quest = (state is GrammarLoaded)
            ? state.currentQuest as GrammarQuest?
            : null;
        final rawQuestion =
            quest?.question ?? quest?.prompt ?? "Direct Speech";
        String displayDirect = quest?.sentence ?? "";
        if (displayDirect.isEmpty) {
          if (rawQuestion.contains(':')) {
            displayDirect = rawQuestion
                .split(':')
                .last
                .replaceAll('"', '')
                .trim();
          } else {
            displayDirect = rawQuestion;
          }
        }

        String displayIndirect = quest?.correctAnswer ?? "";
        if (displayIndirect.isEmpty &&
            quest != null &&
            quest.options != null &&
            (quest.correctAnswerIndex ?? 0) < quest.options!.length) {
          displayIndirect = quest.options![quest.correctAnswerIndex!];
        }
        if (displayIndirect.isEmpty) displayIndirect = "Indirect Speech";

        final options = quest?.options ?? const <String>[];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            isFirstStagePassedNotifier,
            _selectedReflection,
            _rotation,
          ]),
          builder: (context, _) {
            final isAnswered =
                (isAnsweredNotifier.value &&
                    (isCorrectNotifier.value != null ||
                        !isFirstStagePassedNotifier.value)) ||
                (state is GrammarLoaded &&
                    state.answerStatus != AnswerStatus.unanswered);
            final isCorrect =
                isCorrectNotifier.value ??
                (state is GrammarLoaded &&
                    state.answerStatus == AnswerStatus.correct);

            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnswered,
              isCorrect: isCorrect,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling: false,
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final maxHeight = constraints.maxHeight;
                        final isCompact = maxHeight < 600;
                        final shouldReduceMotion =
                            VowlMotion.shouldReduceMotion(context);
                        final isNarrow = constraints.maxWidth < 360;
                        final standardHorizontalMargin = isNarrow ? 12.w : 20.w;

                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: 2,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    SizedBox(height: isCompact ? 14.h : 20.h),
                                    DirectIndirectSpeechInstruction(
                                      primaryColor: theme.primaryColor,
                                      instruction: quest.instruction,
                                      isCompact: isCompact,
                                    ),
                                    SizedBox(height: isCompact ? 12.h : 18.h),
                                    if (quest.grammarRule != null ||
                                        (quest.changesList != null &&
                                            quest.changesList!.isNotEmpty)) ...[
                                      _buildRuleAndChangesBox(
                                        quest,
                                        theme,
                                        isCompact,
                                        shouldReduceMotion,
                                        isNarrow,
                                        isDark,
                                        standardHorizontalMargin,
                                      ),
                                      SizedBox(height: isCompact ? 12.h : 18.h),
                                    ],
                                    DirectIndirectSpeechMirror(
                                      rotation: _rotation.value,
                                      directText: displayDirect,
                                      indirectText: displayIndirect,
                                      isCorrect: isCorrectNotifier.value,
                                      isDark: isDark,
                                      primaryColor: theme.primaryColor,
                                      isCompact: isCompact,
                                    ),
                                    SizedBox(height: isCompact ? 14.h : 22.h),
                                    if (options.isNotEmpty)
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: standardHorizontalMargin,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            for (
                                              int i = 0;
                                              i < options.length;
                                              i++
                                            ) ...[
                                              if (i > 0)
                                                SizedBox(
                                                  height: isCompact
                                                      ? 8.h
                                                      : 10.h,
                                                ),
                                              _buildReflectionChip(
                                                quest,
                                                options[i],
                                                i,
                                                quest.correctAnswerIndex ?? 0,
                                                theme.primaryColor,
                                                isDark,
                                                isCompact,
                                              ),
                                            ],
                                          ],
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
                                      ? 24.h
                                      : 48.h,
                                ),
                              ),
                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value &&
                                  _selectedReflection.value >= 0 &&
                                  _selectedReflection.value < options.length)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: standardHorizontalMargin,
                                    ),
                                    child: TypeToConfirmOverlay(
                                      expectedText:
                                          options[_selectedReflection.value],
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () =>
                                          _submitVerbalEvaluation(true, quest),
                                      onSkipped: () =>
                                          _submitVerbalEvaluation(false, quest),
                                      isPositioned: false,
                                      title: "Confirm Your Answer",
                                      subtitle:
                                          "Type the indirect sentence to practice",
                                      displayText:
                                          "Type the indirect speech sentence below",
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
                                            32.h
                                      : 96.h,
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

  Widget _buildRuleAndChangesBox(
    GrammarQuest quest,
    ThemeResult theme,
    bool isCompact,
    bool shouldReduceMotion,
    bool isNarrow,
    bool isDark,
    double horizontalMargin,
  ) {
    return Container(
      key: const ValueKey('rule_and_changes_box'),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14.w : 16.w,
        vertical: isCompact ? 10.h : 12.h,
      ),
      decoration: BoxDecoration(
        color: theme.primaryColor.withValues(alpha: isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: isDark ? 0.22 : 0.18),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          if (quest.grammarRule != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: isCompact ? 13.r : 15.r,
                  color: theme.primaryColor,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    quest.grammarRule!,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 11.5.sp : 12.5.sp,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          if (quest.grammarRule != null &&
              quest.changesList != null &&
              quest.changesList!.isNotEmpty)
            SizedBox(height: 8.h),
          if (quest.changesList != null && quest.changesList!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: quest.changesList!.map((change) {
                final delimiter = change.contains('→')
                    ? '→'
                    : (change.contains('->') ? '->' : null);
                final parts = delimiter != null
                    ? change.split(delimiter)
                    : <String>[];
                if (parts.length != 2) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      change,
                      textAlign: TextAlign.center,
                      softWrap: true,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: isCompact ? 11.sp : 12.sp,
                        color: theme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }
                return Padding(
                  padding: EdgeInsets.only(bottom: 4.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          parts[0].trim(),
                          textAlign: TextAlign.right,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 11.5.sp : 12.5.sp,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF334155),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8.w),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: isCompact ? 12.sp : 14.sp,
                          color: theme.primaryColor,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          parts[1].trim(),
                          textAlign: TextAlign.left,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 11.5.sp : 12.5.sp,
                            color: theme.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    ).animate(target: shouldReduceMotion ? 0 : 1).fadeIn(duration: 300.ms);
  }

  Widget _buildReflectionChip(
    GameQuest quest,
    String text,
    int index,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    final isSelected = _selectedReflection.value == index;
    final isCorrect =
        (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) &&
        index == correctIndex;
    final isWrong =
        isAnsweredNotifier.value && isSelected && index != correctIndex;

    final displayColor = isCorrect
        ? AppColors.gameCorrect
        : (isWrong
              ? AppColors.gameIncorrect
              : (isSelected
                    ? primaryColor
                    : (isDark ? Colors.white : const Color(0xFF0F172A))));

    final bgColor = isCorrect
        ? AppColors.gameCorrect.withValues(alpha: isDark ? 0.14 : 0.09)
        : (isWrong
              ? AppColors.gameIncorrect.withValues(alpha: isDark ? 0.14 : 0.09)
              : (isSelected
                    ? primaryColor.withValues(alpha: isDark ? 0.12 : 0.08)
                    : (isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.6)
                          : Colors.white)));

    final borderColor = isCorrect
        ? AppColors.gameCorrect
        : (isWrong
              ? AppColors.gameIncorrect
              : (isSelected
                    ? primaryColor
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.12)
                          : const Color(0xFFE2E8F0))));

    final optionLabel = String.fromCharCode(65 + index); // 'A', 'B', 'C'

    return ScaleButton(
      key: ValueKey('reflection_chip_$index'),
      onTap: () => _onReflectionSelect(index, correctIndex, quest),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 14.w : 18.w,
          vertical: isCompact ? 12.h : 15.h,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: borderColor,
            width: isSelected || isCorrect || isWrong ? 1.8 : 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Option indicator badge
            if (isCorrect)
              Icon(
                Icons.check_circle_rounded,
                size: isCompact ? 20.r : 22.r,
                color: AppColors.gameCorrect,
              )
            else if (isWrong)
              Icon(
                Icons.cancel_rounded,
                size: isCompact ? 20.r : 22.r,
                color: AppColors.gameIncorrect,
              )
            else
              Container(
                width: isCompact ? 24.r : 28.r,
                height: isCompact ? 24.r : 28.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? primaryColor.withValues(alpha: isDark ? 0.22 : 0.14)
                      : (isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : const Color(0xFFF1F5F9)),
                  border: Border.all(
                    color: isSelected
                        ? primaryColor
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.2)
                              : const Color(0xFFCBD5E1)),
                    width: 1.2,
                  ),
                ),
                child: Center(
                  child: Text(
                    optionLabel,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 11.sp : 12.5.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    ),
                  ),
                ),
              ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 14.sp : 15.sp,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: displayColor,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
