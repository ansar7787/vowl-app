import 'dart:math';
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
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_instruction.dart';
import 'package:vowl/features/grammar/pronoun_resolution/presentation/widgets/pronoun_resolution_gravity_painter.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';

class PronounResolutionScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
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
    with GrammarGameScreenMixin {
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

  void _onFire(int nodeIndex, int correctIndex, bool hasSecondStage) {
    if (isAnsweredNotifier.value || _pendingJigsaw.value) return;

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
        _submitFinalAnswer(true);
      }
    } else {
      hapticService.error();
      soundService.playWrong();
      isAnsweredNotifier.value = true;
      isCorrectNotifier.value = false;
      _targetIndex.value = nodeIndex;
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
          final targetContent = quest.correctAnswer ?? quest.sentence ?? "";
          if (targetContent.isNotEmpty) {
            expectedTypeTarget = targetContent
                .replaceAll('[', '')
                .replaceAll(']', '');
          } else if (_targetIndex.value != -1) {
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
              useScrolling:
                  false, // Stack needs finite space to anchor to bottom
              onContinue: () =>
                  context.read<GrammarBloc>().add(const NextQuestion()),
              onHint: () =>
                  context.read<GrammarBloc>().add(const GrammarHintUsed()),
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
                                            isCompact
                                                ? SizedBox(
                                                    height: 25.h,
                                                    child: FittedBox(
                                                      fit: BoxFit.scaleDown,
                                                      child:
                                                          PronounResolutionInstruction(
                                                            primaryColor: theme
                                                                .primaryColor,
                                                          ),
                                                    ),
                                                  )
                                                : PronounResolutionInstruction(
                                                    primaryColor:
                                                        theme.primaryColor,
                                                  ),
                                            SizedBox(height: gapMiddle),

                                            if (quest.referentHighlight !=
                                                null) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 16.w,
                                                  vertical: 8.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: theme.primaryColor
                                                      .withValues(alpha: 0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        16.r,
                                                      ),
                                                  border: Border.all(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                  ),
                                                ),
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      quest.referentHighlight
                                                                  ?.toUpperCase() ==
                                                              "TARGET NOUN"
                                                          ? "FIND THE MATCH"
                                                          : "REFERENT: ${quest.referentHighlight!.toUpperCase()}",
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 12.sp,
                                                        color:
                                                            theme.primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        letterSpacing: 1.2,
                                                      ),
                                                    ),
                                                    SizedBox(height: 4.h),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          "Pronoun",
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.7,
                                                                ),
                                                          ),
                                                        ),
                                                        Icon(
                                                          Icons
                                                              .arrow_forward_rounded,
                                                          color: theme
                                                              .primaryColor,
                                                          size: 16.sp,
                                                        ),
                                                        Text(
                                                          "Matching Word",
                                                          style: TextStyle(
                                                            fontSize: 10.sp,
                                                            color: theme
                                                                .primaryColor,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ).animate().fadeIn(
                                                duration: 400.ms,
                                              ),
                                              SizedBox(
                                                height: isCompact ? 12.h : 20.h,
                                              ),
                                            ],

                                            // Context Card
                                            Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24.w,
                                                  ),
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: EdgeInsets.all(
                                                      isCompact ? 14.r : 22.r,
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
                                                                ? 18.r
                                                                : 28.r,
                                                          ),
                                                      border: Border.all(
                                                        color: theme
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                        width: 1.5,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      quest.question ??
                                                          quest.sentence ??
                                                          "The antecedent is missing from the gravity field.",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: isCompact
                                                            ? 14.sp
                                                            : 18.sp,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                        height: 1.4,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .animate()
                                                .fadeIn(duration: 600.ms)
                                                .slideY(begin: 0.2, end: 0),

                                            // Result
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                  SliverFillRemaining(
                                    hasScrollBody: false,
                                    child: Builder(
                                      builder: (context) {
                                        final isCompact =
                                            constraints.maxHeight < 580;
                                        return ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: isCompact
                                                ? 220.h
                                                : 320.h,
                                          ),
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 20.h,
                                            ),
                                            child: _buildGravityWell(
                                              options,
                                              quest.correctAnswerIndex ?? 0,
                                              quest.targetWord ?? "it",
                                              theme.primaryColor,
                                              isDark,
                                              isCompact,
                                              expectedTypeTarget.isNotEmpty,
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
                                      child: TypeToConfirmOverlay(
                                        expectedText: expectedTypeTarget,
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        isPositioned: false,
                                        displayText:
                                            "Type the matching word to lock it in",
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
  ) {
    return Builder(
      builder: (context) {
        void handlePointer(Offset localPos) {
          if (isAnsweredNotifier.value || _pendingJigsaw.value) return;

          final RenderBox? box = context.findRenderObject() as RenderBox?;
          if (box == null) return;
          final size = box.size;

          final centerPoint = Offset(
            size.width / 2,
            size.height / 2 + (isCompact ? 10.h : 20.h),
          );
          final nodeCount = options.length;
          final double orbitRadius = isCompact ? 80.r : 130.r;

          final nodePoints = List.generate(nodeCount, (i) {
            final angle = (i * (2 * pi / nodeCount)) - (pi / 2);
            return Offset(
              centerPoint.dx + cos(angle) * orbitRadius,
              centerPoint.dy + sin(angle) * orbitRadius,
            );
          });

          _rotation.value = atan2(
            localPos.dy - centerPoint.dy,
            localPos.dx - centerPoint.dx,
          );

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
              _onFire(i, correctIndex, hasSecondStage);
            }
          }
        }

        return Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) => handlePointer(event.localPosition),
          onPointerMove: (event) => handlePointer(event.localPosition),
          child: CustomPaint(
            size: Size.infinite,
            painter: PronounResolutionGravityPainter(
              rotationNotifier: _rotation,
              options: options,
              primaryColor: primaryColor,
              isAnswered: isAnsweredNotifier.value || _pendingJigsaw.value,
              isCorrect: isCorrectNotifier.value ?? _pendingJigsaw.value,
              targetNode: _targetIndex.value,
              correctNode: correctIndex,
              pronoun: pronoun,
              isDark: isDark,
              isCompact: isCompact,
            ),
          ),
        );
      },
    );
  }
}
