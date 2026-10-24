import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_instruction.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_gravity_painter.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

/// Screen presenting the pronoun resolution grammar exercise.
class PronounResolutionScreen extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The game subtype for tracking and analytics.
  final GameSubtype gameType;

  /// Creates a [PronounResolutionScreen] widget.
  const PronounResolutionScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.pronounResolution,
  });

  @override
  State<PronounResolutionScreen> createState() =>
      _PronounResolutionScreenState();
}

class _PronounResolutionScreenState extends State<PronounResolutionScreen>
    with
        GameScreenMixin<PronounResolutionScreen>,
        GrammarGameScreenMixin<PronounResolutionScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<double> _rotation = ValueNotifier(0.0);
  final ValueNotifier<int> _targetIndex = ValueNotifier(-1);
  final ValueNotifier<bool> _pendingJigsaw = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _rotation.dispose();
    _targetIndex.dispose();
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

  void _onFire(
    int nodeIndex,
    int correctIndex,
    bool hasSecondStage,
    GameQuest quest,
  ) {
    if (isAnsweredNotifier.value || _pendingJigsaw.value) {
      return;
    }
    final blocState = context.read<GrammarBloc>().state;
    if (blocState is GrammarLoaded && blocState.answerStatus.isAnswered) {
      return;
    }

    bool isCorrect = nodeIndex == correctIndex;

    if (isCorrect) {
      hapticService.heavy();
      soundService.playCorrect();
      _targetIndex.value = nodeIndex;

      if (hasSecondStage) {
        _pendingJigsaw.value = true;
        Future.delayed(const Duration(milliseconds: 150), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      } else {
        // Bypass second stage if curriculum data is missing
        _submitFinalAnswer(true, quest);
      }
    } else {
      _targetIndex.value = nodeIndex;
      String? userAnswer =
          (quest.options != null && nodeIndex < quest.options!.length)
          ? quest.options![nodeIndex]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  void _submitFinalAnswer(bool correct, GameQuest quest) {
    _pendingJigsaw.value = false;

    if (correct) {
      submitCorrectAnswer();
    } else {
      String? userAnswer =
          (_targetIndex.value != -1 &&
              quest.options != null &&
              _targetIndex.value < quest.options!.length)
          ? quest.options![_targetIndex.value]
          : null;
      submitWrongAnswer(quest: quest, userAnswer: userAnswer);
    }
  }

  @override
  void onQuestionReset() {
    _rotation.value = 0.0;
    _targetIndex.value = -1;
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
        final options = quest?.options ?? ["NOUN A", "NOUN B", "NOUN C"];

        String expectedTypeTarget = "";
        if (quest != null) {
          if (quest.correctAnswer != null && quest.correctAnswer!.isNotEmpty) {
            expectedTypeTarget = quest.correctAnswer!
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (quest.correctAnswerIndex != null &&
              quest.correctAnswerIndex! < options.length) {
            expectedTypeTarget = options[quest.correctAnswerIndex!];
          } else if (_targetIndex.value != -1 &&
              _targetIndex.value < options.length) {
            expectedTypeTarget = options[_targetIndex.value];
          }
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _targetIndex,
            _pendingJigsaw,
          ]),
          builder: (context, _) {
            return GrammarBaseLayout(
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
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
                                    child: Builder(
                                      builder: (context) {
                                        final maxHeight = constraints.maxHeight;
                                        final isCompact = maxHeight < 580;

                                        final double estimatedContentHeight =
                                            (isCompact ? 30.h : 40.h) +
                                            (isCompact ? 50.h : 80.h) +
                                            (isCompact ? 160.h : 260.h) +
                                            40.h;
                                        final remainingHeight =
                                            maxHeight - estimatedContentHeight;

                                        final double gapUnit =
                                            remainingHeight > 0
                                            ? remainingHeight / 5
                                            : 0;
                                        final double gapTop =
                                            remainingHeight > 0
                                            ? (gapUnit * 1).clamp(4.0, 15.0)
                                            : 4.0;
                                        final double gapMiddle =
                                            remainingHeight > 0
                                            ? (gapUnit * 1.5).clamp(6.0, 20.0)
                                            : 6.0;

                                        return Column(
                                          children: [
                                            SizedBox(height: gapTop),
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20.w,
                                              ),
                                              child: PronounResolutionInstruction(
                                                primaryColor:
                                                    theme.primaryColor,
                                                instruction:
                                                    quest.instruction.isNotEmpty
                                                        ? quest.instruction
                                                        : "Find what the pronoun refers to",
                                              ),
                                            ),
                                            SizedBox(height: gapMiddle),

                                            if (quest.referentHighlight !=
                                                null) ...[
                                              Builder(
                                                builder: (context) {
                                                  final reduceMotion =
                                                      VowlMotion.shouldReduceMotion(
                                                        context,
                                                      );
                                                  final ruleBox = Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.w,
                                                        ),
                                                    child: Container(
                                                      key: const ValueKey(
                                                        'grammar_rule_box',
                                                      ),
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16.w,
                                                            vertical: 10.h,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.08,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16.r,
                                                            ),
                                                        border: Border.all(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.25,
                                                              ),
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            quest.referentHighlight
                                                                        ?.toUpperCase() ==
                                                                    "TARGET NOUN"
                                                                ? "Find the Matching Word"
                                                                : "Target: ${quest.referentHighlight}",
                                                            textAlign: TextAlign
                                                                .center,
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Outfit',
                                                              fontSize: 13.sp,
                                                              color: theme
                                                                  .primaryColor,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              letterSpacing:
                                                                  0.3,
                                                            ),
                                                          ),
                                                          SizedBox(height: 6.h),
                                                          Row(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Text(
                                                                "Pronoun",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.8,
                                                                      ),
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6.w,
                                                                    ),
                                                                child: Icon(
                                                                  Icons
                                                                      .arrow_forward_rounded,
                                                                  color: theme
                                                                      .primaryColor,
                                                                  size: 14.sp,
                                                                ),
                                                              ),
                                                              Text(
                                                                "Matching Word",
                                                                style: TextStyle(
                                                                  fontFamily:
                                                                      'Outfit',
                                                                  fontSize:
                                                                      12.sp,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: theme
                                                                      .primaryColor,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                          if (state
                                                                  is GrammarLoaded &&
                                                              state.hintUsed &&
                                                              quest.hint !=
                                                                  null) ...[
                                                            SizedBox(
                                                              height: 6.h,
                                                            ),
                                                            Text(
                                                              quest.hint!,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: TextStyle(
                                                                fontFamily:
                                                                    'Outfit',
                                                                fontSize: 12.sp,
                                                                color: theme
                                                                    .primaryColor,
                                                                fontStyle:
                                                                    FontStyle
                                                                        .italic,
                                                                height: 1.3,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                  if (reduceMotion) {
                                                    return ruleBox;
                                                  }
                                                  return ruleBox
                                                      .animate()
                                                      .fadeIn(duration: 400.ms);
                                                },
                                              ),
                                              SizedBox(
                                                height: isCompact ? 10.h : 16.h,
                                              ),
                                            ],

                                            // Context Card
                                            Builder(
                                              builder: (context) {
                                                final reduceMotion =
                                                    VowlMotion.shouldReduceMotion(
                                                      context,
                                                    );
                                                final contextCard = Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 20.w,
                                                  ),
                                                  child: Container(
                                                    key: const ValueKey(
                                                      'pronoun_context_card',
                                                    ),
                                                    width: double.infinity,
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 20.w,
                                                          vertical: isCompact
                                                              ? 14.h
                                                              : 18.h,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: isDark
                                                          ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                )
                                                          : Colors.black
                                                                .withValues(
                                                                  alpha: 0.03,
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
                                                              alpha: 0.2,
                                                            ),
                                                        width: 1.2,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      quest.question ??
                                                          quest.sentence ??
                                                          "Read the sentence and find which word the pronoun replaces.",
                                                      textAlign:
                                                          TextAlign.center,
                                                      softWrap: true,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: isCompact
                                                            ? 14.5.sp
                                                            : 16.5.sp,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: isDark
                                                            ? Colors.white
                                                            : AppColors
                                                                  .slate900,
                                                        height: 1.45,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                                if (reduceMotion) {
                                                  return contextCard;
                                                }
                                                return contextCard
                                                    .animate()
                                                    .fadeIn(duration: 600.ms)
                                                    .slideY(begin: 0.2, end: 0);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  SliverToBoxAdapter(
                                    child: Builder(
                                      builder: (context) {
                                        final isCompact =
                                            constraints.maxHeight < 580;
                                        return SizedBox(
                                          height: isCompact ? 220.h : 320.h,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 10.h,
                                            ),
                                            child: _buildGravityWell(
                                              options,
                                              quest.correctAnswerIndex ?? 0,
                                              quest.targetWord ?? "it",
                                              theme.primaryColor,
                                              isDark,
                                              isCompact,
                                              expectedTypeTarget.isNotEmpty,
                                              quest,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  if (_pendingJigsaw.value &&
                                      !isAnsweredNotifier.value &&
                                      expectedTypeTarget.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                          vertical: 10.h,
                                        ),
                                        child: TypeToConfirmOverlay(
                                          expectedText: expectedTypeTarget,
                                          displayText: expectedTypeTarget,
                                          title: "Confirm Your Answer",
                                          subtitle:
                                              "Type the matching word to confirm",
                                          hintText: "Type the word here...",
                                          primaryColor: theme.primaryColor,
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true, quest),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false, quest),
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

  Widget _buildGravityWell(
    List<String> options,
    int correctIndex,
    String pronoun,
    Color primaryColor,
    bool isDark,
    bool isCompact,
    bool hasSecondStage,
    GameQuest quest,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final centerPoint = PronounResolutionGravityPainter.getCenterPoint(
          size,
          isCompact,
        );
        final nodePoints = PronounResolutionGravityPainter.getNodePoints(
          size,
          options.length,
          isCompact,
        );

        void handlePointer(Offset localPos) {
          if (isAnsweredNotifier.value || _pendingJigsaw.value) {
            return;
          }
          final blocState = context.read<GrammarBloc>().state;
          if (blocState is GrammarLoaded && blocState.answerStatus.isAnswered) {
            return;
          }

          _rotation.value = atan2(
            localPos.dy - centerPoint.dy,
            localPos.dx - centerPoint.dx,
          );

          final dist = (localPos - centerPoint).distance;
          if (dist < 35.r) {
            return;
          }

          for (int i = 0; i < nodePoints.length; i++) {
            final nodeAngle = atan2(
              nodePoints[i].dy - centerPoint.dy,
              nodePoints[i].dx - centerPoint.dx,
            );
            double diff = (_rotation.value - nodeAngle).abs();
            if (diff > pi) {
              diff = 2 * pi - diff;
            }
            if (diff < 0.35) {
              _onFire(i, correctIndex, hasSecondStage, quest);
            }
          }
        }

        final double nodeW = isCompact ? 80.w : 112.w;
        final double nodeH = isCompact ? 34.h : 44.h;

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  key: const ValueKey('pronoun_gravity_canvas'),
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => handlePointer(event.localPosition),
                  onPointerMove: (event) => handlePointer(event.localPosition),
                  child: CustomPaint(
                    size: size,
                    painter: PronounResolutionGravityPainter(
                      rotationNotifier: _rotation,
                      options: options,
                      primaryColor: primaryColor,
                      isAnswered:
                          isAnsweredNotifier.value || _pendingJigsaw.value,
                      isCorrect:
                          isCorrectNotifier.value ?? _pendingJigsaw.value,
                      targetNode: _targetIndex.value,
                      correctNode: correctIndex,
                      pronoun: pronoun,
                      isDark: isDark,
                      isCompact: isCompact,
                    ),
                  ),
                ),
              ),
              for (int i = 0; i < nodePoints.length; i++)
                Positioned(
                  left: nodePoints[i].dx - (nodeW / 2),
                  top: nodePoints[i].dy - (nodeH / 2),
                  width: nodeW,
                  height: nodeH,
                  child: GestureDetector(
                    key: ValueKey('pronoun_node_$i'),
                    behavior: HitTestBehavior.translucent,
                    onTap: () =>
                        _onFire(i, correctIndex, hasSecondStage, quest),
                    child: Semantics(
                      button: true,
                      label: 'Option ${options[i]}',
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
