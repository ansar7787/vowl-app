import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_instruction.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_quantum_painter.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

/// Screen presenting the relative clauses connection grammar exercise.
class RelativeClausesScreen extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The game subtype for tracking and analytics.
  final GameSubtype gameType;

  /// Creates a [RelativeClausesScreen] widget.
  const RelativeClausesScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.relativeClauses,
  });

  @override
  State<RelativeClausesScreen> createState() => _RelativeClausesScreenState();
}

class _RelativeClausesScreenState extends State<RelativeClausesScreen>
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<RelativeClausesScreen>,
        GrammarGameScreenMixin<RelativeClausesScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'Level Complete!';

  final ValueNotifier<Offset?> _hookPoint = ValueNotifier(null);
  final ValueNotifier<int> _targetFish = ValueNotifier(-1);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  late AnimationController _particleController;
  Timer? _scrollTimer;

  @override
  void dispose() {
    _scrollTimer?.cancel();
    _hookPoint.dispose();
    _targetFish.dispose();
    _pendingJigsaw.dispose();
    _scrollController.dispose();
    _particleController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    initGrammarGame();
  }

  void _onCatch(int fishIndex, int correctIndex) {
    if (isAnsweredNotifier.value || _pendingJigsaw.value) return;

    bool isCorrect = fishIndex == correctIndex;

    if (isCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      isCorrectNotifier.value = true;
      _targetFish.value = fishIndex;
      _pendingJigsaw.value = true;
      _particleController.forward(from: 0.0);

      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _targetFish.value = fishIndex;
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingJigsaw.value = false;
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = correct;

    if (correct) {
      hapticService.heavy();
      soundService.playCorrect();
      context.read<GrammarBloc>().add(const SubmitAnswer(true));
    } else {
      hapticService.error();
      soundService.playWrong();
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  @override
  void onQuestionReset() {
    _scrollTimer?.cancel();
    _hookPoint.value = null;

    _targetFish.value = -1;

    _pendingJigsaw.value = false;
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
        final fishOptions =
            quest?.options ?? ["WHO IS SMART", "WHICH IS RED", "THAT I LIKE"];

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _targetFish,
            _pendingJigsaw,
          ]),
          builder: (context, _) {
            String cleanTargetSentence = "";
            if (quest != null) {
              final sentence = quest.question ?? "";
              String fullSentence = sentence;
              if (_targetFish.value != -1) {
                fullSentence = sentence.replaceFirst(
                  RegExp(r'_{2,}'),
                  fishOptions[_targetFish.value],
                );
              }
              cleanTargetSentence = fullSentence
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();
            }

            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              isFinalFailure: state is GrammarLoaded && state.isFinalFailure,
              showConfetti: showConfettiNotifier.value,
              useScrolling:
                  false, // Stack needs finite space to anchor to bottom
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          crossAxisMargin: 2,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: SizedBox(
                                  height: constraints.maxHeight,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Builder(
                                          builder: (context) {
                                            final maxHeight = MediaQuery.of(
                                              context,
                                            ).size.height;
                                            final isCompact = maxHeight < 700;

                                            return Column(
                                              children: [
                                                SizedBox(
                                                  height: isCompact ? 4.h : 8.h,
                                                ),
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20.w,
                                                  ),
                                                  child:
                                                      RelativeClausesInstruction(
                                                        instruction:
                                                            quest.instruction,
                                                        primaryColor:
                                                            theme.primaryColor,
                                                      ),
                                                ),
                                                SizedBox(
                                                  height: isCompact
                                                      ? 8.h
                                                      : 14.h,
                                                ),

                                                if (quest.clauseType !=
                                                    null) ...[
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.w,
                                                        ),
                                                    child: Container(
                                                      key: const ValueKey(
                                                        'clause_box',
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 14.w,
                                                            vertical: 8.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: isDark
                                                                  ? 0.12
                                                                  : 0.08,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16.r,
                                                            ),
                                                        border: Border.all(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: isDark
                                                                    ? 0.25
                                                                    : 0.18,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Builder(
                                                        builder: (context) {
                                                          final isNonDefining =
                                                              quest.clauseType!
                                                                  .toLowerCase()
                                                                  .contains(
                                                                    'non',
                                                                  );
                                                          return Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .info_outline_rounded,
                                                                    size: 14.r,
                                                                    color: theme
                                                                        .primaryColor,
                                                                  ),
                                                                  SizedBox(
                                                                    width: 6.w,
                                                                  ),
                                                                  Text(
                                                                    isNonDefining
                                                                        ? 'Non-defining Clause'
                                                                        : 'Defining Clause',
                                                                    style: TextStyle(
                                                                      fontFamily:
                                                                          'Outfit',
                                                                      fontSize:
                                                                          12.5.sp,
                                                                      color: theme
                                                                          .primaryColor,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w700,
                                                                      letterSpacing:
                                                                          0.3,
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                height: 3.h,
                                                              ),
                                                              Text(
                                                                isNonDefining
                                                                    ? 'Adds extra information • Separated by commas'
                                                                    : 'Essential information • No commas needed',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      11.sp,
                                                                  color: isDark
                                                                      ? Colors
                                                                            .white70
                                                                      : Colors
                                                                            .black87,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                ),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ).animate().fadeIn(
                                                    duration: 400.ms,
                                                  ),
                                                  SizedBox(
                                                    height: isCompact
                                                        ? 8.h
                                                        : 14.h,
                                                  ),
                                                ],

                                                // Context Card
                                                Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20.w,
                                                          ),
                                                      child: Container(
                                                        key: const ValueKey(
                                                          'relative_clauses_context_card',
                                                        ),
                                                        width: double.infinity,
                                                        padding:
                                                            EdgeInsets.symmetric(
                                                              horizontal:
                                                                  isCompact
                                                                  ? 16.w
                                                                  : 20.w,
                                                              vertical:
                                                                  isCompact
                                                                  ? 12.h
                                                                  : 18.h,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? Colors.white
                                                                    .withValues(
                                                                      alpha:
                                                                          0.05,
                                                                    )
                                                              : Colors.black
                                                                    .withValues(
                                                                      alpha:
                                                                          0.03,
                                                                    ),
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                isCompact
                                                                    ? 16.r
                                                                    : 20.r,
                                                              ),
                                                          border: Border.all(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.18,
                                                                ),
                                                            width: 1.5,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          quest.question?.replaceFirst(
                                                                RegExp(
                                                                  r'_{2,}',
                                                                ),
                                                                (isAnsweredNotifier.value ||
                                                                            _pendingJigsaw.value) &&
                                                                        _targetFish.value !=
                                                                            -1
                                                                    ? fishOptions[_targetFish
                                                                          .value]
                                                                    : '_____',
                                                              ) ??
                                                              "Loading sentence...",
                                                          textAlign:
                                                              TextAlign.center,
                                                          softWrap: true,
                                                          style: TextStyle(
                                                            fontFamily:
                                                                'Outfit',
                                                            fontSize: isCompact
                                                                ? 15.sp
                                                                : 18.sp,
                                                            color: isDark
                                                                ? Colors.white
                                                                : Colors
                                                                      .black87,
                                                            height: 1.45,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                    .animate(
                                                      autoPlay:
                                                          !VowlMotion.shouldReduceMotion(
                                                            context,
                                                          ),
                                                    )
                                                    .fadeIn(duration: 600.ms)
                                                    .slideY(begin: 0.2, end: 0),

                                                // Result

                                                // Game Arena
                                                Expanded(
                                                  child: _buildQuantumArena(
                                                    fishOptions,
                                                    quest.correctAnswerIndex ??
                                                        0,
                                                    theme.primaryColor,
                                                    isDark,
                                                    isCompact,
                                                  ),
                                                ),

                                                SizedBox(
                                                  height: isCompact
                                                      ? 8.h
                                                      : 20.h,
                                                ),
                                              ],
                                            );
                                          },
                                        ), // Builder
                                      ), // Expanded
                                    ],
                                  ),
                                ), // SizedBox
                              ), // SliverToBoxAdapter
                              if (_pendingJigsaw.value &&
                                  !isAnsweredNotifier.value &&
                                  cleanTargetSentence.isNotEmpty)
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 20.w,
                                      vertical: 14.h,
                                    ),
                                    child: TypeToConfirmOverlay(
                                      expectedText: cleanTargetSentence,
                                      primaryColor: theme.primaryColor,
                                      onConfirmed: () =>
                                          _submitFinalAnswer(true),
                                      onSkipped: () =>
                                          _submitFinalAnswer(false),
                                      isPositioned: false,
                                      subtitle: "Type the completed sentence",
                                      hintText: "Type the sentence here...",
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
                                      : 60.h,
                                ),
                              ),
                            ],
                          ), // CustomScrollView
                        ); // RawScrollbar
                      }, // LayoutBuilder
                    ), // LayoutBuilder
            ); // GrammarBaseLayout
          },
        );
      },
    );
  }

  Widget _buildQuantumArena(
    List<String> nodes,
    int correctIndex,
    Color primaryColor,
    bool isDark,
    bool isCompact,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final nodeRadius = isCompact ? 36.r : 44.r;
        final sideMargin = nodeRadius + 16.w;
        final startPoint = Offset(
          constraints.maxWidth / 2,
          isCompact ? 16.h : 24.h,
        );
        final bottomMargin = nodeRadius + 14.h;
        final staggerOffset = isCompact ? 12.h : 20.h;
        final baseY = (constraints.maxHeight - bottomMargin - staggerOffset)
            .clamp(
              startPoint.dy + nodeRadius + 30.h,
              constraints.maxHeight - bottomMargin,
            );

        final nodePoints = List.generate(nodes.length, (i) {
          final xOffset = nodes.length > 1
              ? sideMargin +
                    (i *
                        (constraints.maxWidth - (sideMargin * 2)) /
                        (nodes.length - 1))
              : constraints.maxWidth / 2;
          final yOffset = baseY + (i.isOdd ? staggerOffset : 0);
          return Offset(xOffset, yOffset);
        });
        final hitRadius = nodeRadius + 14.r;

        return GestureDetector(
          key: const ValueKey('relative_clauses_arena'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final blocState = context.read<GrammarBloc>().state;
            if (blocState is GrammarLoaded &&
                blocState.answerStatus.isAnswered) {
              return;
            }
            if (isAnsweredNotifier.value || _pendingJigsaw.value) return;
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  hitRadius) {
                _onCatch(i, correctIndex);
                break;
              }
            }
          },
          onTapUp: (details) {
            final blocState = context.read<GrammarBloc>().state;
            if (blocState is GrammarLoaded &&
                blocState.answerStatus.isAnswered) {
              return;
            }
            if (isAnsweredNotifier.value || _pendingJigsaw.value) return;
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  hitRadius) {
                _onCatch(i, correctIndex);
                break;
              }
            }
          },
          onPanUpdate: (details) {
            final blocState = context.read<GrammarBloc>().state;
            if (blocState is GrammarLoaded &&
                blocState.answerStatus.isAnswered) {
              return;
            }
            if (isAnsweredNotifier.value || _pendingJigsaw.value) return;
            _hookPoint.value = details.localPosition;
            if (details.localPosition.dy.toInt() % 10 == 0) {
              hapticService.selection();
            }
            for (int i = 0; i < nodePoints.length; i++) {
              if ((details.localPosition - nodePoints[i]).distance <
                  hitRadius) {
                _onCatch(i, correctIndex);
              }
            }
          },
          onPanEnd: (_) => _hookPoint.value = null,
          child: ListenableBuilder(
            listenable: Listenable.merge([_hookPoint, _particleController]),
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: RelativeClausesQuantumPainter(
                  hookPoint: _hookPoint.value,
                  startPoint: startPoint,
                  nodePoints: nodePoints,
                  nodeLabels: nodes,
                  primaryColor: primaryColor,
                  isAnswered: isAnsweredNotifier.value || _pendingJigsaw.value,
                  isCorrect: isCorrectNotifier.value,
                  targetNode: _targetFish.value,
                  isDark: isDark,
                  isCompact: isCompact,
                  particleValue: _particleController.value,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
