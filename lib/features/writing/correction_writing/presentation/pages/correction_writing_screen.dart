import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
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
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';

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

class _CorrectionWritingScreenState extends State<CorrectionWritingScreen> with WritingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
  final ValueNotifier<String?> _selectedCorrection = ValueNotifier(null);
  WritingQuest? _lastQuest;

    final ValueNotifier<bool> _showEvidence = ValueNotifier(false);

  late final ScrollController _scrollController;

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

    _scrollController = ScrollController();
    initWritingGame();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedCorrection.dispose();
        _showEvidence.dispose();
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
        CustomSnackBar.show(
          context: context,
          message: "Please start your sentence with a capital letter.",
          type: CustomSnackBarType.warning,
        );
        hapticService.selection();
        return;
      }

      final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
      if (!['.', '!', '?'].contains(lastChar)) {
        CustomSnackBar.show(
          context: context,
          message:
              "Please end your sentence with proper punctuation (., !, or ?).",
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
      hapticService.success();
      soundService.playCorrect();
      if ((quest.options?.isNotEmpty ?? false) &&
          _selectedCorrection.value != null) {
        _showEvidence.value = true;
      } else {
        context.read<WritingBloc>().add(SubmitAnswer(correct));
      }
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<WritingBloc>().add(SubmitAnswer(correct));
    }
  }

  @override

  void onQuestionReset() {

    _selectedCorrection.value = null;

    _showEvidence.value = false;

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
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _selectedCorrection,
              _showEvidence,
            ]),
            builder: (context, _) {
              return activeQuest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : Stack(
                      children: [
                        RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
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
                                      if (activeQuest.errorCount != null)
                                        Container(
                                          margin: EdgeInsets.only(bottom: 16.h),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16.w,
                                            vertical: 8.h,
                                          ),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.bug_report,
                                                color: theme.primaryColor,
                                                size: 16.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                "${activeQuest.errorCount} ERRORS REMAINING",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme.primaryColor,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      SizedBox(height: 8.h),

                                      CorrectionWritingSentenceCard(
                                        passage: activeQuest.passage ?? "",
                                        selectedCorrection: widget.level >= 6
                                            ? null
                                            : _selectedCorrection.value,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 32.h),

                                      if (widget.level >= 6) ...[
                                        GestureDetector(
                                          onTap: () {
                                            CustomSnackBar.show(
                                              context: context,
                                              message:
                                                  "Hard Mode! Tapping is disabled. Please type your answer below.",
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!isAnswered && widget.level < 6)
                                        ScaleButton(
                                          onTap:
                                              _selectedCorrection.value != null
                                              ? () => _submitAnswer(isAnswered)
                                              : null,
                                          child: Container(
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color:
                                                  _selectedCorrection.value !=
                                                      null
                                                  ? theme.primaryColor
                                                  : Colors.grey,
                                              boxShadow: [
                                                if (_selectedCorrection.value !=
                                                    null)
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 15,
                                                  ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "AUDIT SYNTAX",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      SizedBox(
                                        height: !isAnswered
                                            ? MediaQuery.viewInsetsOf(
                                                    context,
                                                  ).bottom +
                                                  40.h
                                            : 160.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showEvidence.value && !isAnswered)
                          EvidenceHighlightWrapper(
                            passage: (activeQuest.passage ?? "").replaceAll(
                              RegExp(r'\[(.*?)\]'),
                              _selectedCorrection.value ?? "",
                            ),
                            evidenceWords: [_selectedCorrection.value ?? ""],
                            primaryColor: theme.primaryColor,
                            onCorrectHighlight: () {
                              _showEvidence.value = false;
                              context.read<WritingBloc>().add(
                                const SubmitAnswer(true),
                              );
                            },
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

