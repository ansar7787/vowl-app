import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_placement_instruction.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_magnetic_arena.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

/// Screen host for Modifier Placement exercises, avoiding dangling and misplaced modifiers.
class ModifierPlacementScreen extends StatefulWidget {
  /// Current level index.
  final int level;

  /// Game subtype identifier.
  final GameSubtype gameType;

  /// Creates a [ModifierPlacementScreen] widget.
  const ModifierPlacementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.modifierPlacement,
  });

  @override
  State<ModifierPlacementScreen> createState() =>
      _ModifierPlacementScreenState();
}

class _ModifierPlacementScreenState extends State<ModifierPlacementScreen>
    with
        GameScreenMixin<ModifierPlacementScreen>,
        GrammarGameScreenMixin<ModifierPlacementScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  GrammarQuest? _lastQuest;

  final ValueNotifier<int> _targetIndex = ValueNotifier(-1);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ValueNotifier<String?> _assembledSentence = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _targetIndex.dispose();
    _pendingJigsaw.dispose();
    _assembledSentence.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initGrammarGame();
  }

  void _submitAnswer(
    GrammarQuest quest,
    String modifier,
    List<String> baseWords,
  ) {
    if (isAnsweredNotifier.value ||
        _targetIndex.value == -1 ||
        _pendingJigsaw.value) {
      return;
    }
    final state = context.read<GrammarBloc>().state;
    if (state is GrammarLoaded &&
        state.answerStatus != AnswerStatus.unanswered) {
      return;
    }

    final resultingWords = List<String>.from(baseWords);
    resultingWords.insert(_targetIndex.value, modifier);

    final result = resultingWords.join(' ');

    final normResult = result.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    final normAnswer = (quest.correctAnswer ?? "").toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );

    bool isCorrect = normResult == normAnswer;

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _assembledSentence.value = quest.correctAnswer;
      _pendingJigsaw.value = true;

      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
          );
        }
      });
    } else {
      _assembledSentence.value = quest.correctAnswer;
      submitWrongAnswer(quest: quest, userAnswer: result);
    }
  }

  void _submitFinalAnswer(bool correct, GameQuest quest) {
    _scrollTimer?.cancel();
    _pendingJigsaw.value = false;

    if (correct) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: _assembledSentence.value);
    }
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
    _targetIndex.value = -1;
    _pendingJigsaw.value = false;
    _assembledSentence.value = null;
  }

  Widget _buildGrammarRule(
    String rule,
    Color primaryColor,
    double horizontalMargin, {
    bool isDark = false,
  }) {
    return Container(
      key: const ValueKey('grammar_rule_box'),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lightbulb_outline, color: primaryColor, size: 16.sp),
              SizedBox(width: 6.w),
              Text(
                "Grammar Rule",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            rule,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 13.sp,
              color: isDark ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModifierTypeChip(String modifierType, Color primaryColor) {
    return Container(
      key: const ValueKey('modifier_type_chip'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Text(
        "Modifier: $modifierType",
        style: TextStyle(
          fontFamily: 'Outfit',
          fontSize: 12.sp,
          color: primaryColor,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('grammar', level: widget.level);

    return BlocConsumer<GrammarBloc, GrammarState>(
      listenWhen: grammarListenWhen,
      listener: onGrammarStateChanged,
      builder: (context, state) {
        if (state is GrammarLoaded) {
          _lastQuest = state.currentQuest;
        }

        final quest = (state is GrammarLoaded)
            ? state.currentQuest
            : _lastQuest;

        String modifier = "";
        List<String> words = [];
        if (quest != null) {
          final sentence = quest.sentence ?? "";
          final match = RegExp(
            r'''modifier ['"]([^'"]+)['"]''',
          ).firstMatch(sentence);
          modifier = match?.group(1) ?? "";

          final answer = quest.correctAnswer ?? "";
          if (modifier.isNotEmpty) {
            final modRegex = RegExp(
              RegExp.escape(modifier),
              caseSensitive: false,
            );
            final answerMatch = modRegex.firstMatch(answer);
            if (answerMatch != null) {
              final prefix = answer.substring(0, answerMatch.start);
              final suffix = answer.substring(answerMatch.end);
              final combined = "$prefix $suffix";
              words = combined.split(' ').where((w) {
                final trimmed = w.trim();
                return trimmed.isNotEmpty &&
                    RegExp(r'[a-zA-Z0-9]').hasMatch(trimmed);
              }).toList();
            }
          }

          // Fallback to shuffledWords if regex/answer parsing fails
          if (modifier.isEmpty || words.isEmpty) {
            final allWords = quest.shuffledWords ?? [];
            if (allWords.isNotEmpty) {
              modifier = allWords[0];
              words = allWords.skip(1).toList();
            }
          }
        }

        final hasValidQuest =
            quest != null && modifier.isNotEmpty && words.isNotEmpty;

        String cleanTargetSentence = "";
        if (quest != null) {
          final targetSent = quest.correctAnswer ?? quest.sentence ?? "";
          if (targetSent.isNotEmpty) {
            cleanTargetSentence = targetSent
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_assembledSentence.value != null) {
            cleanTargetSentence = _assembledSentence.value!;
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _targetIndex,
            _pendingJigsaw,
            _assembledSentence,
          ]),
          builder: (context, _) {
            final isAnswered =
                isAnsweredNotifier.value ||
                (state is GrammarLoaded &&
                    state.answerStatus != AnswerStatus.unanswered);
            final isCorrect =
                (isCorrectNotifier.value == true) ||
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
              child: !hasValidQuest
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final currentQuest = quest;
                        final isNarrow = constraints.maxWidth < 360;
                        final horizontalPadding = isNarrow ? 16.w : 24.w;

                        return Stack(
                    children: [
                      RawScrollbar(
                        controller: _scrollController,
                        thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                        radius: Radius.circular(8.r),
                        thickness: 4.w,
                        crossAxisMargin: 2,
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Builder(
                                builder: (context) {
                                  final maxHeight = constraints.maxHeight;
                                  final isCompact = maxHeight < 650;
                                  final ruleText =
                                      currentQuest.grammarRule ??
                                      currentQuest.ruleExplanation;

                                  return Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 6.h : 12.h,
                                          ),
                                          ModifierPlacementInstruction(
                                            primaryColor: theme.primaryColor,
                                            instructionText:
                                                currentQuest.instruction,
                                            horizontalMargin: horizontalPadding,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 8.h : 14.h,
                                          ),

                                          if (ruleText != null &&
                                              ruleText.isNotEmpty) ...[
                                            _buildGrammarRule(
                                              ruleText,
                                              theme.primaryColor,
                                              horizontalPadding,
                                              isDark: isDark,
                                            ),
                                            SizedBox(
                                              height: isCompact ? 8.h : 12.h,
                                            ),
                                          ],

                                          if (currentQuest.modifierType !=
                                              null) ...[
                                            _buildModifierTypeChip(
                                              currentQuest.modifierType!,
                                              theme.primaryColor,
                                            ),
                                            SizedBox(
                                              height: isCompact ? 8.h : 12.h,
                                            ),
                                          ],

                                          // Context Card
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: horizontalPadding,
                                            ),
                                            child: Container(
                                              key: const ValueKey(
                                                'modifier_context_card',
                                              ),
                                              width: double.infinity,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isCompact
                                                    ? 16.w
                                                    : 20.w,
                                                vertical: isCompact
                                                    ? 12.h
                                                    : 16.h,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.white.withValues(
                                                        alpha: 0.05,
                                                      )
                                                    : Colors.black.withValues(
                                                        alpha: 0.03,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      isCompact ? 16.r : 20.r,
                                                    ),
                                                border: Border.all(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.18),
                                                  width: 1.2,
                                                ),
                                              ),
                                              child: Text(
                                                currentQuest.sentence ?? "",
                                                textAlign: TextAlign.center,
                                                softWrap: true,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: isCompact
                                                      ? 14.5.sp
                                                      : 16.sp,
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: isCompact ? 12.h : 18.h,
                                          ),

                                          // Magnetic Arena
                                          ModifierMagneticArena(
                                            words: words,
                                            modifier: modifier,
                                            targetIndex: _targetIndex.value,
                                            isAnswered:
                                                isAnswered ||
                                                _pendingJigsaw.value,
                                            isDark: isDark,
                                            primaryColor: theme.primaryColor,
                                            onSlotAccepted: (idx) =>
                                                _targetIndex.value = idx,
                                            onSlotReset: () =>
                                                _targetIndex.value = -1,
                                            isCompact: isCompact,
                                          ),
                                        ],
                                      ),

                                      // Bottom section: Magnet or Confirm Button
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            height: isCompact ? 10.h : 16.h,
                                          ),
                                          if (!isAnswered &&
                                              !_pendingJigsaw.value &&
                                              _targetIndex.value == -1)
                                            Draggable<String>(
                                              key: const ValueKey(
                                                'draggable_modifier_magnet',
                                              ),
                                              data: modifier,
                                              feedback: _buildTactileMagnet(
                                                modifier,
                                                theme.primaryColor,
                                                isDragging: true,
                                                isCompact: isCompact,
                                              ),
                                              childWhenDragging: Opacity(
                                                opacity: 0.2,
                                                child: _buildTactileMagnet(
                                                  modifier,
                                                  theme.primaryColor,
                                                  isCompact: isCompact,
                                                ),
                                              ),
                                              child: _buildTactileMagnet(
                                                modifier,
                                                theme.primaryColor,
                                                isCompact: isCompact,
                                              ),
                                            ),

                                          if (!isAnswered &&
                                              !_pendingJigsaw.value &&
                                              _targetIndex.value != -1) ...[
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: horizontalPadding,
                                              ),
                                              child: ScaleButton(
                                                key: const ValueKey(
                                                  'finalize_syntax_button',
                                                ),
                                                onTap: () => _submitAnswer(
                                                  currentQuest,
                                                  modifier,
                                                  words,
                                                ),
                                                child: Container(
                                                  width: double.infinity,
                                                  height: isCompact
                                                      ? 48.h
                                                      : 54.h,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          isCompact
                                                              ? 14.r
                                                              : 18.r,
                                                        ),
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        theme.primaryColor,
                                                        theme.primaryColor
                                                            .withValues(
                                                              alpha: 0.85,
                                                            ),
                                                      ],
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.3,
                                                            ),
                                                        blurRadius: 16,
                                                        offset: const Offset(
                                                          0,
                                                          6,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      "Confirm Placement",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: isCompact
                                                            ? 14.sp
                                                            : 15.5.sp,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.white,
                                                        letterSpacing: 0.6,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                          SizedBox(
                                            height: isCompact ? 12.h : 24.h,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                            if (_pendingJigsaw.value &&
                                !isAnswered &&
                                cleanTargetSentence.isNotEmpty)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: horizontalPadding,
                                    vertical: 8.h,
                                  ),
                                  child: TypeToConfirmOverlay(
                                    key: const ValueKey(
                                      'modifier_type_overlay',
                                    ),
                                    expectedText: cleanTargetSentence,
                                    primaryColor: theme.primaryColor,
                                    onConfirmed: () =>
                                        _submitFinalAnswer(true, currentQuest),
                                    onSkipped: () =>
                                        _submitFinalAnswer(false, currentQuest),
                                    isPositioned: false,
                                    allowSkip: true,
                                    displayText:
                                        "Type the complete sentence to confirm",
                                  ),
                                ),
                              ),
                            SliverToBoxAdapter(
                              child: SizedBox(
                                height:
                                    MediaQuery.of(context).viewInsets.bottom > 0
                                    ? MediaQuery.of(context).viewInsets.bottom +
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

  Widget _buildTactileMagnet(
    String modifier,
    Color primaryColor, {
    bool isDragging = false,
    bool isCompact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: isCompact
            ? EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h)
            : EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(isCompact ? 14.r : 18.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.35),
              blurRadius: isDragging ? 20 : 10,
              offset: isDragging ? const Offset(0, 8) : const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              size: isCompact ? 16.r : 18.r,
              color: Colors.white70,
            ),
            SizedBox(width: 6.w),
            Text(
              modifier,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 15.sp : 17.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
