import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/mixins/vocabulary_game_screen_mixin.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_painters.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_lcd.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_vault_handle.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_option_key.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_literal_comparison.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';

class PhrasalVerbsScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const PhrasalVerbsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.phrasalVerbs,
  });

  @override
  State<PhrasalVerbsScreen> createState() => _PhrasalVerbsScreenState();
}

class _PhrasalVerbsScreenState extends State<PhrasalVerbsScreen>with SingleTickerProviderStateMixin, VocabularyGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

    
          final ValueNotifier<String?> _selectedOption = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
    VocabularyQuest? _lastQuest;

  late AnimationController _vaultController;

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

    _vaultController = AnimationController(vsync: this, duration: 1.seconds);
    initVocabularyGame();
  }

  @override
  void dispose() {
                    _selectedOption.dispose();
    _scrollController.dispose();
    _vaultController.dispose();
    disposeVocabularyGame();
    super.dispose();
  }

  void _submitChoice(String selected, String correct) async {
    if (isAnsweredNotifier.value ||
        isFirstStagePassedNotifier.value ||
        _selectedOption.value != null) {
      return;
    }

    _selectedOption.value = selected;
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      hapticService.selection();
      _vaultController.forward(from: 0);
      isFirstStagePassedNotifier.value = true;

      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  String? _getFormattedExampleSentence(VocabularyQuest quest) {
    String? sentence = quest.contextSentence;

    if (sentence == null || sentence.isEmpty) {
      if (quest.explanation != null && quest.explanation!.isNotEmpty) {
        final matches = RegExp(r"'([^']+)'").allMatches(quest.explanation!);
        if (matches.isNotEmpty) {
          sentence = matches.last.group(1);
        }
      }
    }

    if (sentence == null || sentence.isEmpty) return null;

    final word = quest.word ?? "";
    final answer = quest.correctAnswer ?? "";

    // Determine which part of the phrasal verb is missing in the sentence
    final replacementWord = sentence.contains(answer) ? word : answer;

    if (sentence.contains('__')) {
      return sentence.replaceAll('__', replacementWord);
    }
    return sentence;
  }

  void _submitFinalAnswer(bool nailedIt) {
    if (isAnsweredNotifier.value) return;

    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = nailedIt;

    if (nailedIt) {
      hapticService.success();
      soundService.playCorrect();
      context.read<VocabularyBloc>().add(SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<VocabularyBloc>().add(SubmitAnswer(false));
    }
  }

  @override

  void onQuestionReset() {

    _selectedOption.value = null;

  }

  @override

  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<VocabularyBloc, VocabularyState>(
      listenWhen: vocabularyListenWhen,
      listener: onVocabularyStateChanged,
      builder: (context, state) {
        final theme = LevelThemeHelper.getTheme(
          'vocabulary',
          level: widget.level,
        );

        final quest = (state is VocabularyLoaded)
            ? state.currentQuest
            : _lastQuest;
        final isFinalFailure = (state is VocabularyLoaded)
            ? state.isFinalFailure
            : false;

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
                  (isCorrectNotifier.value != null || !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              hasStage2: true,
              onContinue: () {
                final currentState = context.read<VocabularyBloc>().state;
                if (currentState is VocabularyLoaded &&
                    !currentState.isFinalFailure &&
                    isCorrectNotifier.value == false) {
                  isAnsweredNotifier.value = false;
                  isCorrectNotifier.value = null;
                  isFirstStagePassedNotifier.value = false;
                  _selectedOption.value = null;
                  _vaultController.reset();
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
                  : _PhrasalVerbsStageLayout(
                      quest: quest,
                      level: widget.level,
                      theme: theme,
                      isDark: isDark,
                      scrollController: _scrollController,
                      vaultController: _vaultController,
                      isFirstStagePassed: isFirstStagePassedNotifier.value,
                      isAnswered: isAnsweredNotifier.value,
                      isCorrect: isCorrectNotifier.value,
                      selectedOption: _selectedOption.value,
                      isFinalFailure: isFinalFailure,
                      hintUsed: state is VocabularyLoaded
                          ? state.hintUsed
                          : false,
                      onChoiceSubmit: _submitChoice,
                      onFinalSubmit: _submitFinalAnswer,
                      formattedExampleSentence: _getFormattedExampleSentence(
                        quest,
                      ),
                    ), // LayoutBuilder
            ); // VocabularyBaseLayout
          }, // ListenableBuilder builder
        ); // ListenableBuilder
      }, // BlocConsumer builder
    ); // BlocConsumer
  } // build method
}

class _PhrasalVerbsStageLayout extends StatelessWidget {
  final VocabularyQuest quest;
  final int level;
  final ThemeResult theme;
  final bool isDark;
  final ScrollController scrollController;
  final AnimationController vaultController;
  final bool isFirstStagePassed;
  final bool isAnswered;
  final bool? isCorrect;
  final String? selectedOption;
  final bool isFinalFailure;
  final bool hintUsed;
  final void Function(String, String) onChoiceSubmit;
  final void Function(bool) onFinalSubmit;
  final String? formattedExampleSentence;

  const _PhrasalVerbsStageLayout({
    required this.quest,
    required this.level,
    required this.theme,
    required this.isDark,
    required this.scrollController,
    required this.vaultController,
    required this.isFirstStagePassed,
    required this.isAnswered,
    required this.isCorrect,
    required this.selectedOption,
    required this.isFinalFailure,
    required this.hintUsed,
    required this.onChoiceSubmit,
    required this.onFinalSubmit,
    required this.formattedExampleSentence,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final isCompact = maxHeight < 580;

        final double estimatedContentHeight =
            (isCompact ? 30.h : 40.h) +
            (InstructionHelper.getInstruction(quest).isNotEmpty
                ? (isCompact ? 60.h : 80.h)
                : 0) +
            (isCompact ? 70.h : 90.h) +
            (isCompact ? 110.h : 160.h) +
            (isCompact ? 90.h : 130.h) +
            20.h;
        final remainingHeight = maxHeight - estimatedContentHeight;

        final double gapUnit = remainingHeight > 0 ? remainingHeight / 6 : 0;
        final double gapTop = remainingHeight > 0
            ? (gapUnit * 1).clamp(6.0, 24.0)
            : 6.0;
        final double gapMiddle = remainingHeight > 0
            ? (gapUnit * 1.5).clamp(10.0, 30.0)
            : 10.0;
        final double gapBottom = remainingHeight > 0
            ? (gapUnit * 2).clamp(12.0, 40.0)
            : 12.0;

        return Stack(
          children: [
            RawScrollbar(
              controller: scrollController,
              thumbColor: theme.primaryColor.withValues(alpha: 0.5),
              radius: Radius.circular(8.r),
              thickness: 4.w,
              child: CustomScrollView(
                controller: scrollController,
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: maxHeight),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: GridPainter(
                                theme.primaryColor.withValues(
                                  alpha: isDark ? 0.05 : 0.03,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              IgnorePointer(
                                ignoring: isFirstStagePassed,
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: gapTop),
                                        isCompact
                                            ? SizedBox(
                                                height: 30.h,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: _buildVaultStatus(
                                                    theme.primaryColor,
                                                    isDark,
                                                  ),
                                                ),
                                              )
                                            : _buildVaultStatus(
                                                theme.primaryColor,
                                                isDark,
                                              ),
                                        if (quest.instruction.isNotEmpty) ...[
                                          SizedBox(height: gapTop / 2),
                                          _buildInstruction(
                                            InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                            theme.primaryColor,
                                            isCompact,
                                          ),
                                        ],
                                        SizedBox(height: gapMiddle),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                          ),
                                          child: PhrasalVerbsLcd(
                                            text:
                                                quest.hint?.replaceFirst(
                                                  "DEFINITION: ",
                                                  "",
                                                ) ??
                                                "ANALYZING VAULT...",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                        ),
                                      ],
                                    ),

                                    // The Central Vault Handle
                                    isCompact
                                        ? SizedBox(
                                            height: 110.h,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: PhrasalVerbsVaultHandle(
                                                verb: quest.word ?? "VERB",
                                                color: theme.primaryColor,
                                                isDark: isDark,
                                                vaultController:
                                                    vaultController,
                                              ),
                                            ),
                                          )
                                        : PhrasalVerbsVaultHandle(
                                            verb: quest.word ?? "VERB",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            vaultController: vaultController,
                                          ),

                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(height: gapMiddle),
                                        // Key Options (Particles)
                                        isCompact
                                            ? SizedBox(
                                                height: 90.h,
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: SizedBox(
                                                    width: constraints.maxWidth,
                                                    child: _buildOptionsWrap(
                                                      quest,
                                                      theme.primaryColor,
                                                      isDark,
                                                      isFinalFailure,
                                                      isCompact,
                                                      hintUsed,
                                                    ),
                                                  ),
                                                ),
                                              )
                                            : _buildOptionsWrap(
                                                quest,
                                                theme.primaryColor,
                                                isDark,
                                                isFinalFailure,
                                                isCompact,
                                                hintUsed,
                                              ),
                                        SizedBox(height: gapBottom),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isFirstStagePassed && !isAnswered)
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  child: Column(
                                    children: [
                                      SizedBox(height: 10.h),
                                      if (quest.literalVsFigurative != null &&
                                          quest
                                              .literalVsFigurative!
                                              .isNotEmpty) ...[
                                        PhrasalVerbsLiteralComparison(
                                          literalVsFigurative:
                                              quest.literalVsFigurative!,
                                          color: theme.primaryColor,
                                        ),
                                        SizedBox(height: 10.h),
                                      ],
                                    ],
                                  ),
                                ),
                              SizedBox(height: 60.h),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isFirstStagePassed && !isAnswered)
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          ContextSentenceBuilder(
                            targetKeyword:
                                "${quest.word} ${quest.correctAnswer}".trim(),
                            primaryColor: theme.primaryColor,
                            onConfirmed: () => onFinalSubmit(true),
                            onSkipped: () => onFinalSubmit(false),
                            isPositioned: false,
                            exampleSentence: formattedExampleSentence,
                          ),
                          SizedBox(height: 60.h),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVaultStatus(Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vpn_key_rounded, size: 16.r, color: color),
          SizedBox(width: 10.w),
          AutoSizeText(
            "VAULT SECURITY: L-$level",
            maxLines: 1,
            minFontSize: 4,
            stepGranularity: 0.5,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }

  Widget _buildInstruction(String text, Color color, bool isCompact) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: isCompact ? 60.h : 80.h),
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.9),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildOptionsWrap(
    VocabularyQuest quest,
    Color color,
    bool isDark,
    bool isFinalFailure,
    bool isCompact,
    bool hintUsed,
  ) {
    return Wrap(
      spacing: 15.w,
      runSpacing: isCompact ? 10.h : 15.h,
      alignment: WrapAlignment.center,
      children: (quest.options ?? []).asMap().entries.map((entry) {
        return PhrasalVerbsOptionKey(
          text: entry.value,
          correct: quest.correctAnswer ?? "",
          color: color,
          isDark: isDark,
          isAnswered: isAnswered && (isCorrect != null || !isFirstStagePassed),
          isCorrect: isCorrect,
          selectedOption: selectedOption,
          isFinalFailure: isFinalFailure,
          index: entry.key,
          isHintUsed: hintUsed,
          onTap: () => onChoiceSubmit(entry.value, quest.correctAnswer ?? ""),
        );
      }).toList(),
    );
  }
}
