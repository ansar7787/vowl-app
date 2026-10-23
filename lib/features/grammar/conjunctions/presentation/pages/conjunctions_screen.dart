import 'dart:async';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_instruction.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_brick_sheet.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

/// Screen host for Conjunctions exercises, training conjunction types and rhetorical relationships between clauses.
class ConjunctionsScreen extends StatefulWidget {
  /// Current level index.
  final int level;

  /// Game subtype identifier.
  final GameSubtype gameType;

  /// Creates a [ConjunctionsScreen] widget.
  const ConjunctionsScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conjunctions,
  });

  @override
  State<ConjunctionsScreen> createState() => _ConjunctionsScreenState();
}

class _ConjunctionsScreenState extends State<ConjunctionsScreen>
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<ConjunctionsScreen>,
        GrammarGameScreenMixin<ConjunctionsScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _placedBrick = ValueNotifier(null);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _placedBrick.dispose();
    _pendingJigsaw.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  void _scrollToBottom() {
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _formatInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Choose the conjunction to connect the sentence';
    }
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    if (upper == 'JOIN THE JUNCTION' ||
        upper == 'COMPLETE THE SENTENCE' ||
        upper.contains('JUNCTION')) {
      return 'Choose the conjunction to connect the sentence';
    }
    if (trimmed == upper && trimmed.length > 2) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
  }

  String _formatRule(String? rule, String? purpose) {
    if (rule == null && purpose == null) return '';
    if (rule != null && purpose != null) {
      if (rule.toLowerCase().contains(purpose.toLowerCase())) {
        return rule;
      }
      return '$rule • $purpose';
    }
    return rule ?? purpose ?? '';
  }

  void _onBridge(
    String conj,
    int correctIndex,
    List<String> options,
    GameQuest quest,
  ) {
    final grammarState = context.read<GrammarBloc>().state;
    final isAlreadyAnswered = isAnsweredNotifier.value ||
        _pendingJigsaw.value ||
        (grammarState is GrammarLoaded &&
            grammarState.answerStatus != AnswerStatus.unanswered);
    if (isAlreadyAnswered) return;

    bool isCorrect = conj == options[correctIndex];

    if (isCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      _placedBrick.value = conj;
      _pendingJigsaw.value = true;
      _scrollToBottom();
    } else {
      _placedBrick.value = conj;
      submitWrongAnswer(quest: quest, userAnswer: conj);
      _scrollToBottom();
    }
  }

  void _submitFinalAnswer(bool correct, GameQuest quest) {
    _pendingJigsaw.value = false;

    if (correct) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: _placedBrick.value);
    }
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void onQuestionReset() {
    _placedBrick.value = null;
    _pendingJigsaw.value = false;
    _scrollTimer?.cancel();
    _scrollTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
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
        final options = quest?.options ?? ["and", "but", "or"];
        final question = quest?.question ?? "I like apples... I like oranges.";
        final parts = question.contains("...")
            ? question.split("...")
            : question.split("___");

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _placedBrick,
            _pendingJigsaw,
          ]),
          builder: (context, _) {
            String cleanTargetSentence = "";
            if (quest != null && _placedBrick.value != null) {
              String fullSentence = question;
              if (question.contains("...")) {
                fullSentence = question.replaceFirst(
                  RegExp(r'\.{3,}'),
                  " ${_placedBrick.value} ",
                );
              } else if (question.contains("___")) {
                fullSentence = question.replaceFirst(
                  RegExp(r'_{3,}'),
                  " ${_placedBrick.value} ",
                );
              } else if (quest.correctSentence != null &&
                  quest.correctSentence!.isNotEmpty) {
                fullSentence = quest.correctSentence!;
              } else {
                fullSentence = "$question ${_placedBrick.value}";
              }
              cleanTargetSentence = fullSentence
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
            }

            final isAnswered = isAnsweredNotifier.value ||
                (state is GrammarLoaded &&
                    state.answerStatus != AnswerStatus.unanswered);
            final isCorrect = isCorrectNotifier.value ??
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
                        final shouldReduceMotion =
                            VowlMotion.shouldReduceMotion(context);
                        final isCompact = constraints.maxHeight < 600;
                        final isNarrow = constraints.maxWidth < 360;

                        return Stack(
                          children: [
                            RawScrollbar(
                              controller: _scrollController,
                              thumbColor: theme.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              radius: Radius.circular(8.r),
                              thickness: 4.w,
                              crossAxisMargin: 2,
                              child: CustomScrollView(
                                controller: _scrollController,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isNarrow ? 12.w : 18.w,
                                        vertical: isCompact ? 8.h : 14.h,
                                      ),
                                      child: Column(
                                        children: [
                                          // 1. Top-anchored Instruction Pill
                                          Center(
                                            child: ConjunctionsInstruction(
                                              primaryColor: theme.primaryColor,
                                              instruction: _formatInstruction(
                                                quest.instruction,
                                              ),
                                            ),
                                          ),

                                          // Optional Rule / Category Box (anchored right below instruction)
                                          if (quest.grammarRule != null ||
                                              quest.conjunctionPurpose !=
                                                  null) ...[
                                            SizedBox(
                                              height: isCompact ? 6.h : 10.h,
                                            ),
                                            _buildRuleBox(
                                              quest,
                                              theme.primaryColor,
                                              isDark,
                                              isCompact,
                                              shouldReduceMotion,
                                            ),
                                          ],

                                          // 2. Main Game Stage (Sentence Board + Bricks grouped together)
                                          Expanded(
                                            child: LayoutBuilder(
                                              builder:
                                                  (context, stageConstraints) {
                                                return SingleChildScrollView(
                                                  physics:
                                                      const BouncingScrollPhysics(),
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      minHeight: stageConstraints
                                                          .maxHeight,
                                                    ),
                                                    child: Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SizedBox(
                                                          height: isCompact
                                                              ? 8.h
                                                              : 12.h,
                                                        ),

                                                        // Unified Production-Grade Sentence Board
                                                        _buildSentenceBoard(
                                                          context: context,
                                                          parts: parts,
                                                          quest: quest,
                                                          options: options,
                                                          theme: theme,
                                                          isDark: isDark,
                                                          isCompact: isCompact,
                                                          shouldReduceMotion:
                                                              shouldReduceMotion,
                                                          isNarrow: isNarrow,
                                                        ),

                                                        SizedBox(
                                                          height: isCompact
                                                              ? 16.h
                                                              : 24.h,
                                                        ),

                                                        // Conjunction Option Cards (Bricks)
                                                        ConjunctionsBrickSheet(
                                                          options: options,
                                                          placedBrick:
                                                              _placedBrick
                                                                  .value,
                                                          primaryColor: theme
                                                              .primaryColor,
                                                          isDark: isDark,
                                                          isCompact: isCompact,
                                                          isAnswered:
                                                              isAnswered ||
                                                                  _pendingJigsaw
                                                                      .value,
                                                          onBrickTapped:
                                                              (brickText) {
                                                            final index =
                                                                options.indexOf(
                                                                    brickText);
                                                            if (index != -1) {
                                                              _onBridge(
                                                                brickText,
                                                                quest.correctAnswerIndex ??
                                                                    0,
                                                                options,
                                                                quest,
                                                              );
                                                            }
                                                          },
                                                        ),

                                                        SizedBox(
                                                          height: isCompact
                                                              ? 8.h
                                                              : 12.h,
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  // Type-to-confirm mechanism card
                                  if (_pendingJigsaw.value &&
                                      !isAnsweredNotifier.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isNarrow ? 12.w : 18.w,
                                          vertical: 10.h,
                                        ),
                                        child: TypeToConfirmOverlay(
                                          expectedText: cleanTargetSentence,
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true, quest),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false, quest),
                                          isPositioned: false,
                                          title: "Type to confirm",
                                          subtitle:
                                              "Type the completed sentence below",
                                          displayFontSize: isCompact
                                              ? 16.sp
                                              : 18.sp,
                                          displayFontWeight: FontWeight.w600,
                                          displayTextAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),

                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height: MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                              30.h
                                          : 40.h,
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

  Widget _buildSentenceBoard({
    required BuildContext context,
    required List<String> parts,
    required GameQuest quest,
    required List<String> options,
    required dynamic theme,
    required bool isDark,
    required bool isCompact,
    required bool shouldReduceMotion,
    required bool isNarrow,
  }) {
    final primaryColor = theme.primaryColor as Color;
    return Container(
      key: const ValueKey('conjunction_sentence_board'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.w : 22.w,
        vertical: isCompact ? 16.h : 22.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222B) : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: isDark ? 0.22 : 0.16,
          ),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.35)
                : primaryColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Clause 1
          if (parts.first.trim().isNotEmpty)
            Text(
              parts.first.trim(),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 15.sp : 17.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.slate900,
                height: 1.45,
                letterSpacing: 0.2,
              ),
            ),

          SizedBox(height: isCompact ? 12.h : 16.h),

          // Visual Connector Bridge with Magnetic Junction Slot
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Left gradient guide rail
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.0),
                        primaryColor.withValues(
                          alpha: isDark ? 0.35 : 0.22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: _buildMagneticJunction(
                  quest,
                  options,
                  quest.correctAnswerIndex ?? 0,
                  primaryColor,
                  isDark,
                  isCompact,
                  shouldReduceMotion,
                  isNarrow,
                ),
              ),
              // Right gradient guide rail
              Expanded(
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(
                          alpha: isDark ? 0.35 : 0.22,
                        ),
                        primaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: isCompact ? 12.h : 16.h),

          // Clause 2
          if (parts.length > 1 && parts.last.trim().isNotEmpty)
            Builder(
              builder: (context) {
                final textWidget = Text(
                  parts.last.trim(),
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: isCompact ? 15.sp : 17.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.slate900,
                    height: 1.45,
                    letterSpacing: 0.2,
                  ),
                );
                return shouldReduceMotion
                    ? textWidget
                    : textWidget.animate().fadeIn(delay: 200.ms);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildRuleBox(
    GrammarQuest quest,
    Color primaryColor,
    bool isDark,
    bool isCompact,
    shouldReduceMotion,
  ) {
    return Container(
      key: const ValueKey('conjunction_rule_box'),
      padding: EdgeInsets.symmetric(
        horizontal: 14.w,
        vertical: 8.h,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(
          alpha: isDark ? 0.12 : 0.08,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: primaryColor.withValues(
            alpha: isDark ? 0.25 : 0.18,
          ),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          Text(
            _formatRule(
              quest.grammarRule,
              quest.conjunctionPurpose,
            ),
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 11.sp : 12.sp,
              color: primaryColor,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (quest.grammarRule == "Coordinating Conjunctions") ...[
            SizedBox(height: 6.h),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6.w,
              runSpacing: 4.h,
              children: [
                "For",
                "And",
                "Nor",
                "But",
                "Or",
                "Yet",
                "So",
              ]
                  .map(
                    (word) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        "${word[0]} = $word",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.5.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    ).animate(target: shouldReduceMotion ? 0 : 1).fadeIn(duration: 400.ms);
  }

  Widget _buildMagneticJunction(
    GameQuest quest,
    List<String> options,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
    bool shouldReduceMotion,
    bool isNarrow,
  ) {
    return DragTarget<String>(
      key: const ValueKey('magnetic_junction'),
      onAcceptWithDetails: (details) =>
          _onBridge(details.data, correctIndex, options, quest),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final isPlaced = _placedBrick.value != null;
        final nodeColor = isPlaced
            ? ((isAnsweredNotifier.value || _pendingJigsaw.value) &&
                      isCorrectNotifier.value != false
                  ? AppColors.gameCorrect
                  : AppColors.gameIncorrect)
            : (isHighlight
                ? primaryColor
                : primaryColor.withValues(alpha: 0.45));

        return Container(
          constraints: BoxConstraints(
            minWidth: isCompact ? (isNarrow ? 120.w : 135.w) : 155.w,
            maxWidth: 220.w,
            minHeight: isCompact ? 42.h : 48.h,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 14.w,
            vertical: isCompact ? 6.h : 8.h,
          ),
          decoration: BoxDecoration(
            color: nodeColor.withValues(
              alpha: isPlaced ? 0.12 : (isHighlight ? 0.16 : 0.06),
            ),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: nodeColor.withValues(
                alpha: isPlaced ? 0.65 : (isHighlight ? 0.75 : 0.35),
              ),
              width: 1.5,
            ),
            boxShadow: [
              if (isHighlight || isPlaced)
                BoxShadow(
                  color: nodeColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
            ],
          ),
          child: Center(
            child: isPlaced
                ? Text(
                    _placedBrick.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 16.sp : 18.sp,
                      fontWeight: FontWeight.w700,
                      color: nodeColor,
                    ),
                  )
                    .animate(target: shouldReduceMotion ? 0 : 1)
                    .scale(
                      duration: 300.ms,
                      curve: Curves.easeOutBack,
                    )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isHighlight
                            ? Icons.download_rounded
                            : Icons.add_rounded,
                        color: primaryColor.withValues(
                          alpha: isHighlight ? 0.95 : 0.65,
                        ),
                        size: isCompact ? 15.r : 17.r,
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          "Choose conjunction",
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 12.sp : 13.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryColor.withValues(
                              alpha: isHighlight ? 0.95 : 0.7,
                            ),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
