import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/widgets/clause_connector_instruction.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Screen host for Clause Connector exercises, practicing compound and complex sentence syntax.
class ClauseConnectorScreen extends StatefulWidget {
  /// Current level index.
  final int level;

  /// Game subtype identifier.
  final GameSubtype gameType;

  /// Creates a [ClauseConnectorScreen] widget.
  const ClauseConnectorScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.clauseConnector,
  });

  @override
  State<ClauseConnectorScreen> createState() => _ClauseConnectorScreenState();
}

class _ClauseConnectorScreenState extends State<ClauseConnectorScreen>
    with
        GameScreenMixin<ClauseConnectorScreen>,
        GrammarGameScreenMixin<ClauseConnectorScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<String?> _draggingConnector = ValueNotifier(null);
  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _draggingConnector.dispose();
    _pendingTypeSubmit.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  void _onSnap(
    String connector,
    int correctIndex,
    List<String> options,
    GameQuest quest,
  ) {
    final blocState = context.read<GrammarBloc>().state;
    final isAlreadyAnswered =
        isAnsweredNotifier.value ||
        (blocState is GrammarLoaded &&
            blocState.answerStatus != AnswerStatus.unanswered);
    if (isAlreadyAnswered || _pendingTypeSubmit.value) return;

    final targetAnswer =
        quest.correctAnswer ??
        (options.isNotEmpty &&
                correctIndex >= 0 &&
                correctIndex < options.length
            ? options[correctIndex]
            : "");
    final isCorrect =
        connector.trim().toLowerCase() == targetAnswer.trim().toLowerCase();

    if (isCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      _draggingConnector.value = connector;
      _pendingTypeSubmit.value = true;
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      _draggingConnector.value = connector;
      submitWrongAnswer(quest: quest, userAnswer: connector);
    }
  }

  void _submitFinalAnswer(bool correct, GameQuest quest) {
    _pendingTypeSubmit.value = false;

    if (correct) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: _draggingConnector.value);
    }
  }

  @override
  void onQuestionReset() {
    _draggingConnector.value = null;
    _pendingTypeSubmit.value = false;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        final quest = (state is GrammarLoaded) ? state.currentQuest : null;
        final parts = (quest?.question ?? "Clause A ____ Clause B").split(
          ' ____ ',
        );
        final clauseA = parts[0];
        final clauseB = parts.length > 1
            ? parts.sublist(1).join(' ____ ')
            : "";
        final options = quest?.options ?? [];

        String cleanTargetSentence = "";
        if (quest != null) {
          final connector =
              quest.correctAnswer ??
              (options.isNotEmpty && quest.correctAnswerIndex != null
                  ? options[quest.correctAnswerIndex!]
                  : "");
          final rawSentence = quest.sentence ?? quest.question ?? "";

          if (rawSentence.contains('____')) {
            cleanTargetSentence = rawSentence
                .replaceAll(RegExp(r'\s*____\s*'), ' $connector ')
                .trim();
          } else {
            cleanTargetSentence = "$clauseA $connector $clauseB".trim();
          }
          cleanTargetSentence = cleanTargetSentence
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('...', '')
              .replaceAll('  ', ' ')
              .trim();
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingTypeSubmit,
            _draggingConnector,
          ]),
          builder: (context, _) {
            final isAnswered =
                isAnsweredNotifier.value ||
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
              useScrolling: false, // Stack layout
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact = constraints.maxHeight < 620 ||
                            constraints.maxWidth < 360;

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
                                  SliverToBoxAdapter(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: constraints.maxHeight,
                                      ),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              constraints.maxWidth < 360
                                                  ? 12.w
                                                  : 20.w,
                                          vertical:
                                              isCompact ? 12.h : 20.h,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            ClauseConnectorInstruction(
                                              primaryColor: theme.primaryColor,
                                              instructionText:
                                                  quest.instruction,
                                            ),
                                            if (quest.connectorCategory !=
                                                null) ...[
                                              SizedBox(height: 10.h),
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 14.w,
                                                  vertical: 6.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        20.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.25),
                                                  ),
                                                ),
                                                child: Text(
                                                  "${quest.connectorCategory} Connector",
                                                  style: TextStyle(
                                                    fontFamily: 'Outfit',
                                                    fontSize: 11.5.sp,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.primaryColor,
                                                    letterSpacing: 0.3,
                                                  ),
                                                ),
                                              ),
                                            ],
                                            SizedBox(
                                              height: isCompact ? 14.h : 22.h,
                                            ),
                                            _buildClauseCard(
                                              clauseA,
                                              theme.primaryColor,
                                              isDark,
                                              isCompact,
                                            ),
                                            SizedBox(
                                              height: isCompact ? 12.h : 18.h,
                                            ),
                                            _buildConnectorSlot(
                                              quest,
                                              options,
                                              theme.primaryColor,
                                              isDark,
                                              isCompact,
                                              isAnswered,
                                              state,
                                            ),
                                            SizedBox(
                                              height: isCompact ? 12.h : 18.h,
                                            ),
                                            Builder(
                                              builder: (context) {
                                                final plateB = _buildClauseCard(
                                                  clauseB,
                                                  theme.primaryColor,
                                                  isDark,
                                                  isCompact,
                                                );
                                                return VowlMotion.shouldReduceMotion(
                                                          context,
                                                        )
                                                    ? plateB
                                                    : plateB.animate().fadeIn(
                                                          delay: 300.ms,
                                                        );
                                              },
                                            ),
                                            SizedBox(
                                              height: isCompact ? 18.h : 30.h,
                                            ),
                                            if (!isAnswered &&
                                                !_pendingTypeSubmit.value)
                                              _buildConnectorPalette(
                                                quest,
                                                options,
                                                theme.primaryColor,
                                                isDark,
                                                quest.correctAnswerIndex ?? 0,
                                                isCompact,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_pendingTypeSubmit.value &&
                                      !isAnsweredNotifier.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal:
                                              constraints.maxWidth < 360
                                                  ? 12.w
                                                  : 20.w,
                                          vertical: 10.h,
                                        ),
                                        child: TypeToConfirmOverlay(
                                          key: const ValueKey(
                                            'clause_connector_type_overlay',
                                          ),
                                          expectedText: cleanTargetSentence,
                                          displayText:
                                              "Type the complete sentence to confirm your answer",
                                          title: "Confirm sentence",
                                          subtitle:
                                              "Type the full sentence below to confirm",
                                          primaryColor: theme.primaryColor,
                                          displayFontSize:
                                              isCompact ? 15.sp : 17.sp,
                                          displayFontWeight: FontWeight.w600,
                                          displayTextAlign: TextAlign.center,
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true, quest),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false, quest),
                                          allowSkip: true,
                                          isPositioned: false,
                                        ),
                                      ),
                                    ),
                                  SliverToBoxAdapter(
                                    child: SizedBox(
                                      height:
                                          MediaQuery.of(
                                                context,
                                              ).viewInsets.bottom >
                                              0
                                          ? MediaQuery.of(
                                                  context,
                                                ).viewInsets.bottom +
                                                40.h
                                          : 60.h,
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

  Widget _buildConnectorSlot(
    GameQuest quest,
    List<String> options,
    Color primaryColor,
    bool isDark,
    bool isCompact,
    bool isAnswered,
    GrammarState state,
  ) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !isAnswered && !_pendingTypeSubmit.value,
      onAcceptWithDetails: (details) =>
          _onSnap(details.data, quest.correctAnswerIndex ?? 0, options, quest),
      builder: (context, candidateData, rejectedData) {
        final isHighlight = candidateData.isNotEmpty;
        final isSuccess = isAnswered
            ? (isCorrectNotifier.value == true ||
                (state is GrammarLoaded &&
                    state.answerStatus == AnswerStatus.correct))
            : _pendingTypeSubmit.value;
        final portColor = (isAnswered || _pendingTypeSubmit.value)
            ? (isSuccess
                  ? AppColors.gameCorrect
                  : AppColors.gameIncorrect)
            : (isHighlight
                  ? primaryColor
                  : primaryColor.withValues(alpha: 0.35));

        final shouldReduceMotion = VowlMotion.shouldReduceMotion(context);
        final resolvedConnector = _draggingConnector.value ??
            (state is GrammarLoaded &&
                    state.answerStatus != AnswerStatus.unanswered
                ? (quest.correctAnswer ??
                    (options.isNotEmpty && quest.correctAnswerIndex != null
                        ? options[quest.correctAnswerIndex!]
                        : ""))
                : "");

        final connectorWidget = _buildConnector(
          resolvedConnector,
          primaryColor,
          isDark,
          isCompact,
          isCorrect: isSuccess,
        );

        return Container(
          constraints: BoxConstraints(
            minWidth: isCompact ? 140.w : 180.w,
            minHeight: isCompact ? 44.h : 52.h,
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12.w : 18.w,
            vertical: isCompact ? 8.h : 10.h,
          ),
          decoration: BoxDecoration(
            color: portColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: portColor.withValues(alpha: 0.35),
              width: 1.5,
              style: (isAnswered || _pendingTypeSubmit.value)
                  ? BorderStyle.none
                  : BorderStyle.solid,
            ),
            boxShadow: [
              if (isHighlight ||
                  isAnsweredNotifier.value ||
                  _pendingTypeSubmit.value)
                BoxShadow(
                  color: portColor.withValues(alpha: 0.18),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: (isAnsweredNotifier.value || _pendingTypeSubmit.value)
                ? (shouldReduceMotion
                    ? connectorWidget
                    : connectorWidget
                        .animate()
                        .scale(duration: 400.ms, curve: Curves.elasticOut))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        color: portColor.withValues(alpha: 0.7),
                        size: isCompact ? 16.sp : 18.sp,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          isHighlight ? "Drop here" : "Choose connector",
                          textAlign: TextAlign.center,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: isCompact ? 11.sp : 13.sp,
                            fontWeight: FontWeight.w600,
                            color: portColor.withValues(alpha: 0.8),
                            letterSpacing: 0.3,
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

  Widget _buildClauseCard(
    String text,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 14.w : 20.w,
        vertical: isCompact ? 12.h : 16.h,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(isCompact ? 14.r : 18.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: isDark ? 0.22 : 0.18),
          width: 1.5,
        ),
      ),
      child: Text(
        text.trim(),
        textAlign: TextAlign.center,
        softWrap: true,
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: isCompact ? 14.5.sp : 16.sp,
          color: isDark ? Colors.white : Colors.black87,
          height: 1.45,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConnectorPalette(
    GameQuest quest,
    List<String> options,
    Color primaryColor,
    bool isDark,
    int correctIndex,
    bool isCompact,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: isCompact ? 10.w : 14.w,
      runSpacing: isCompact ? 10.h : 14.h,
      children: options.asMap().entries.map(
        (entry) {
          final index = entry.key;
          final opt = entry.value;
          return Draggable<String>(
            data: opt,
            feedback: Material(
              color: Colors.transparent,
              child: _buildConnector(
                opt,
                primaryColor,
                isDark,
                isCompact,
                isDragging: true,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.2,
              child: _buildConnector(opt, primaryColor, isDark, isCompact),
            ),
            child: ScaleButton(
              key: ValueKey('connector_option_$index'),
              onTap: () => _onSnap(opt, correctIndex, options, quest),
              child: _buildConnector(opt, primaryColor, isDark, isCompact),
            ),
          );
        },
      ).toList(),
    );
  }

  Widget _buildConnector(
    String text,
    Color primaryColor,
    bool isDark,
    bool isCompact, {
    bool isDragging = false,
    bool? isCorrect,
  }) {
    Color borderColor = primaryColor.withValues(alpha: 0.35);
    if (isCorrect == true) {
      borderColor = AppColors.gameCorrect;
    } else if (isCorrect == false) {
      borderColor = AppColors.gameIncorrect;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 16.w : 22.w,
        vertical: isCompact ? 8.h : 11.h,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          if (isDragging || isCorrect != null)
            BoxShadow(
              color: borderColor.withValues(alpha: 0.2),
              blurRadius: 16,
              spreadRadius: 3,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_rounded,
            size: isCompact ? 14.sp : 16.sp,
            color: isCorrect == true
                ? AppColors.gameCorrect
                : (isCorrect == false
                      ? AppColors.gameIncorrect
                      : (isDark ? Colors.white70 : Colors.black54)),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 13.sp : 15.sp,
              fontWeight: FontWeight.w600,
              color: isCorrect == true
                  ? AppColors.gameCorrect
                  : (isCorrect == false
                        ? AppColors.gameIncorrect
                        : (isDark ? Colors.white : Colors.black87)),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
