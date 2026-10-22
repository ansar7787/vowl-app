import 'package:flutter/material.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_instruction.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_sentence_card.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_vault.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_keyboard_input.dart';

class CorrectionWritingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const CorrectionWritingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.correctionWriting,
  });

  @override
  State<CorrectionWritingScreen> createState() =>
      _CorrectionWritingScreenState();
}

class _CorrectionWritingScreenState extends State<CorrectionWritingScreen>
    with
        GameScreenMixin<CorrectionWritingScreen>,
        WritingGameScreenMixin<CorrectionWritingScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _selectedCorrection = ValueNotifier(null);
  WritingQuest? _lastQuest;

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    initWritingGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedCorrection.dispose();
    disposeWritingGame();
    super.dispose();
  }

  void _onSelectCorrection(String choice, bool isAnswered) {
    if (isAnswered) return;
    hapticService.selection();
    _selectedCorrection.value = choice;
  }

  static String _normalizeAnswer(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  void _submitAnswer(bool isAnswered, [String? typedText]) {
    if (!mounted) return;
    final currentState = context.read<WritingBloc>().state;
    if (currentState is! WritingLoaded) return;

    final WritingQuest? quest = currentState.currentQuest as WritingQuest?;
    final isHardMode = widget.level >= 6;

    if (quest == null ||
        isAnswered ||
        (!isHardMode && _selectedCorrection.value == null) ||
        (isHardMode && typedText == null)) {
      return;
    }

    bool correct = false;
    if (isHardMode && typedText != null) {
      final rawText = typedText.trim();
      if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
        if (!mounted) return;
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'games.correctionWriting.error_capital_letter',
            fallback: "Please start your sentence with a capital letter.",
          ),
          type: CustomSnackBarType.warning,
        );
        hapticService.selection();
        return;
      }

      final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
      if (!['.', '!', '?'].contains(lastChar)) {
        if (!mounted) return;
        CustomSnackBar.show(
          context: context,
          message: context.tr(
            'games.correctionWriting.error_punctuation',
            fallback:
                "Please end your sentence with proper punctuation (., !, or ?).",
          ),
          type: CustomSnackBarType.warning,
        );
        hapticService.selection();
        return;
      }

      String expectedSentence = (quest.passage ?? "").replaceAll(
        RegExp(r'\[(.*?)\]'),
        quest.correctAnswer ?? "",
      );
      correct =
          _normalizeAnswer(typedText) == _normalizeAnswer(expectedSentence);
    } else {
      correct = _selectedCorrection.value == quest.correctAnswer;
    }

    if (correct) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(
        quest: quest,
        userAnswer: isHardMode ? typedText : _selectedCorrection.value,
      );
    }
  }

  @override
  void onQuestionReset() {
    _selectedCorrection.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        if (quest != null) {
          _lastQuest = quest;
        }

        final activeQuest = quest ?? _lastQuest;

        final options = activeQuest?.options ?? [];
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () {},
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _selectedCorrection,
            ]),
            builder: (context, _) {
              return activeQuest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        key: const Key('correction_writing_scroll_view'),
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  CorrectionWritingInstruction(
                                    instruction: activeQuest.instruction,
                                    primaryColor: theme.primaryColor,
                                  ),
                                  SizedBox(height: 16.h),

                                  CorrectionWritingSentenceCard(
                                    passage: activeQuest.passage ?? "",
                                    selectedCorrection: widget.level >= 6
                                        ? (isAnswered && isCorrect == true
                                              ? activeQuest.correctAnswer
                                              : null)
                                        : _selectedCorrection.value,
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    isAnswered: isAnswered,
                                    isCorrect: isCorrect,
                                  ),
                                  SizedBox(height: 32.h),

                                  if (widget.level >= 6) ...[
                                    GestureDetector(
                                      key: const Key(
                                        'correction_hard_mode_vault_detector',
                                      ),
                                      onTap: () {
                                        if (!mounted) return;
                                        CustomSnackBar.show(
                                          context: context,
                                          message: context.tr(
                                            'games.correctionWriting.hard_mode_tap_disabled',
                                            fallback:
                                                "Hard Mode! Tapping is disabled. Please type your answer below.",
                                          ),
                                          type: CustomSnackBarType.info,
                                        );
                                      },
                                      child: AbsorbPointer(
                                        child: Opacity(
                                          opacity: 0.8,
                                          child: CorrectionWritingVault(
                                            options: options,
                                            selectedCorrection: null,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            onSelectCorrection: (_) {},
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 16.h),
                                    CorrectionWritingKeyboardInput(
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onSubmit: (text) =>
                                          _submitAnswer(isAnswered, text),
                                    ),
                                  ] else
                                    CorrectionWritingVault(
                                      options: options,
                                      selectedCorrection:
                                          _selectedCorrection.value,
                                      color: theme.primaryColor,
                                      isDark: isDark,
                                      onSelectCorrection: (choice) =>
                                          _onSelectCorrection(
                                            choice,
                                            isAnswered,
                                          ),
                                    ),
                                  SizedBox(height: 36.h),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (!isAnswered && widget.level < 6) ...[
                                    Builder(
                                      builder: (context) {
                                        final bool hasSelection =
                                            _selectedCorrection.value != null;
                                        return ScaleButton(
                                          key: const Key(
                                            'correction_writing_check_button',
                                          ),
                                          onTap: hasSelection
                                              ? () => _submitAnswer(isAnswered)
                                              : null,
                                          child: Container(
                                            width: double.infinity,
                                            height: 56.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(18.r),
                                              color: hasSelection
                                                  ? theme.primaryColor
                                                  : (isDark
                                                      ? Colors.white.withValues(
                                                          alpha: 0.1,
                                                        )
                                                      : Colors.black.withValues(
                                                          alpha: 0.08,
                                                        )),
                                              boxShadow: [
                                                if (hasSelection)
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                context.tr(
                                                  'games.correctionWriting.actionText',
                                                  fallback: "Check Answer",
                                                ),
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: hasSelection
                                                      ? Colors.white
                                                      : (isDark
                                                          ? Colors.white38
                                                          : Colors.black38),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                  SizedBox(height: !isAnswered ? 60.h : 160.h),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
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
  }
}
