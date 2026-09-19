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
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:flutter/physics.dart';

class SubjectVerbAgreementScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SubjectVerbAgreementScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.subjectVerbAgreement,
  });

  @override
  State<SubjectVerbAgreementScreen> createState() =>
      _SubjectVerbAgreementScreenState();
}

class _SubjectVerbAgreementScreenState extends State<SubjectVerbAgreementScreen>
    with SingleTickerProviderStateMixin, GrammarGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<Offset> _ringOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _springController;
  int _currentCorrectIndex = 0;

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

    initGrammarGame();
    _springController = AnimationController(vsync: this);
    _springController.addListener(() {
      _ringOffset.value = Offset(_springController.value, 0);
      _checkHarmony(_currentCorrectIndex);
    });
  }

  @override
  void dispose() {
    _springController.dispose();
    _ringOffset.dispose();
    _pendingTypeSubmit.dispose();
    _scrollController.dispose();
    disposeGrammarGame();
    super.dispose();
  }

  void _onConnect(int targetIndex, int correctIndex) {
    if (isAnsweredNotifier.value || _pendingTypeSubmit.value) return;

    bool isCorrect = targetIndex == correctIndex;

    final bool isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    final double snapTarget = targetIndex == 0
        ? (isCompact ? -100.w : -130.w)
        : (isCompact ? 100.w : 130.w);

    if (_springController.isAnimating) {
      _springController.stop();
    }
    _ringOffset.value = Offset(snapTarget, 0.0);

    if (isCorrect) {
      hapticService.success();
      soundService.playCorrect();
      _pendingTypeSubmit.value = true;

      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
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
      context.read<GrammarBloc>().add(const SubmitAnswer(false));
    }
  }

  void _submitFinalAnswer(bool correct) {
    _pendingTypeSubmit.value = false;
    isAnsweredNotifier.value = true;
    isCorrectNotifier.value = correct;

    if (correct) {
      hapticService.success();
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
    _ringOffset.value = Offset.zero;

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
        if (quest != null) {
          _currentCorrectIndex = quest.correctAnswerIndex ?? 0;
        }
        final options = quest?.options ?? ["Is", "Are"];

        String cleanTargetSentence = "";
        if (quest != null) {
          String sentence = "";
          if (quest.question != null &&
              quest.question!.contains('___') &&
              quest.correctAnswer != null) {
            sentence = quest.question!.replaceAll('___', quest.correctAnswer!);
          } else {
            sentence = quest.correctAnswer ?? quest.sentence ?? "";
          }
          cleanTargetSentence = sentence
              .replaceAll('[', '')
              .replaceAll(']', '');
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _pendingTypeSubmit,
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
                                  SliverFillRemaining(
                                    hasScrollBody: true,
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
                                                    height: isCompact
                                                        ? 14.h
                                                        : 34.h,
                                                  ),

                                                  // Atmospheric Harmony Hub
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                          horizontal: 24.w,
                                                        ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding: EdgeInsets.all(
                                                        isCompact ? 14.r : 24.r,
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
                                                                  ? 20.r
                                                                  : 32.r,
                                                            ),
                                                        border: Border.all(
                                                          color: theme
                                                              .primaryColor
                                                              .withValues(
                                                                alpha: 0.2,
                                                              ),
                                                          width: 1.5,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: theme
                                                                .primaryColor
                                                                .withValues(
                                                                  alpha: 0.05,
                                                                ),
                                                            blurRadius: 40,
                                                            spreadRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Text(
                                                        ((_pendingTypeSubmit
                                                                        .value ||
                                                                    isCorrectNotifier
                                                                            .value ==
                                                                        true) &&
                                                                quest.correctAnswer !=
                                                                    null)
                                                            ? (quest.question ??
                                                                      "")
                                                                  .replaceAll(
                                                                    '___',
                                                                    quest
                                                                        .correctAnswer!,
                                                                  )
                                                            : (quest.question ??
                                                                  "Complete the agreement..."),
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: isCompact
                                                              ? 16.sp
                                                              : 22.sp,
                                                          color: isDark
                                                              ? Colors.white
                                                              : Colors.black87,
                                                          height: 1.5,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),

                                                  Expanded(
                                                    child: Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 30.w,
                                                          ),
                                                      child: Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          // Tuner Rails
                                                          Container(
                                                            height: isCompact
                                                                ? 3.h
                                                                : 4.h,
                                                            width:
                                                                double.infinity,
                                                            decoration: BoxDecoration(
                                                              gradient: LinearGradient(
                                                                colors: [
                                                                  theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.0,
                                                                      ),
                                                                  theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.4,
                                                                      ),
                                                                  theme
                                                                      .primaryColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.0,
                                                                      ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),

                                                          // Verb Terminals
                                                          GestureDetector(
                                                            onTap: () => _onConnect(
                                                              0,
                                                              quest.correctAnswerIndex ??
                                                                  0,
                                                            ),
                                                            child: _buildVerbTerminal(
                                                              0,
                                                              options[0],
                                                              theme
                                                                  .primaryColor,
                                                              Alignment
                                                                  .centerLeft,
                                                              quest.correctAnswerIndex ??
                                                                  0,
                                                              isCompact,
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap: () => _onConnect(
                                                              1,
                                                              quest.correctAnswerIndex ??
                                                                  0,
                                                            ),
                                                            child: _buildVerbTerminal(
                                                              1,
                                                              options[1],
                                                              theme
                                                                  .primaryColor,
                                                              Alignment
                                                                  .centerRight,
                                                              quest.correctAnswerIndex ??
                                                                  0,
                                                              isCompact,
                                                            ),
                                                          ),

                                                          // The Quantum Core (Harmony Slider)
                                                          GestureDetector(
                                                            onPanUpdate:
                                                                isAnsweredNotifier
                                                                        .value ||
                                                                    _pendingTypeSubmit
                                                                        .value
                                                                ? null
                                                                : (details) {
                                                                    if (_springController
                                                                        .isAnimating) {
                                                                      _springController
                                                                          .stop();
                                                                    }
                                                                    final double
                                                                    newDx =
                                                                        (_ringOffset.value.dx +
                                                                                details.delta.dx)
                                                                            .clamp(
                                                                              isCompact
                                                                                  ? -100.w
                                                                                  : -130.w,
                                                                              isCompact
                                                                                  ? 100.w
                                                                                  : 130.w,
                                                                            );
                                                                    _ringOffset
                                                                            .value =
                                                                        Offset(
                                                                          newDx,
                                                                          0.0,
                                                                        );
                                                                    _checkHarmony(
                                                                      quest.correctAnswerIndex ??
                                                                          0,
                                                                    );
                                                                  },
                                                            onPanEnd:
                                                                isAnsweredNotifier
                                                                        .value ||
                                                                    _pendingTypeSubmit
                                                                        .value
                                                                ? null
                                                                : (details) {
                                                                    final spring = SpringDescription(
                                                                      mass: 1.0,
                                                                      stiffness:
                                                                          500.0,
                                                                      damping:
                                                                          20.0,
                                                                    );
                                                                    final simulation = SpringSimulation(
                                                                      spring,
                                                                      _ringOffset
                                                                          .value
                                                                          .dx,
                                                                      0.0,
                                                                      details
                                                                          .velocity
                                                                          .pixelsPerSecond
                                                                          .dx,
                                                                    );
                                                                    _springController
                                                                        .animateWith(
                                                                          simulation,
                                                                        );
                                                                  },
                                                            child: ValueListenableBuilder<Offset>(
                                                              valueListenable:
                                                                  _ringOffset,
                                                              builder:
                                                                  (
                                                                    context,
                                                                    offset,
                                                                    child,
                                                                  ) {
                                                                    return Transform.translate(
                                                                      offset:
                                                                          offset,
                                                                      child:
                                                                          child,
                                                                    );
                                                                  },
                                                              child: _buildQuantumCore(
                                                                theme
                                                                    .primaryColor,
                                                                isCompact,
                                                              ),
                                                            ),
                                                          ).animate().scale(
                                                            duration: 400.ms,
                                                            curve: Curves
                                                                .easeOutBack,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: isCompact
                                                        ? 12.h
                                                        : 40.h,
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_pendingTypeSubmit.value &&
                                      !isAnsweredNotifier.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: TypeToConfirmOverlay(
                                        expectedText: cleanTargetSentence,
                                        displayText:
                                            "Type the complete sentence to lock in the rule",
                                        primaryColor: theme.primaryColor,
                                        onConfirmed: () =>
                                            _submitFinalAnswer(true),
                                        onSkipped: () =>
                                            _submitFinalAnswer(false),
                                        allowSkip: true,
                                        isPositioned: false,
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

  void _checkHarmony(int correctIndex) {
    final bool isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    final double threshold = isCompact ? 90.w : 110.w;
    if (_ringOffset.value.dx < -threshold) {
      _onConnect(0, correctIndex);
    } else if (_ringOffset.value.dx > threshold) {
      _onConnect(1, correctIndex);
    }
  }

  Widget _buildVerbTerminal(
    int index,
    String verb,
    Color primaryColor,
    Alignment alignment,
    int correctIndex,
    bool isCompact,
  ) {
    final isCorrect =
        (isAnsweredNotifier.value || _pendingTypeSubmit.value) &&
        isCorrectNotifier.value != false &&
        index == correctIndex;
    final isWrong =
        isAnsweredNotifier.value &&
        isCorrectNotifier.value == false &&
        index != correctIndex;
    final terminalSize = isCompact ? 80.r : 110.r;

    return Align(
      alignment: alignment,
      child:
          Container(
                width: terminalSize,
                height: terminalSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCorrect
                      ? Colors.greenAccent.withValues(alpha: 0.1)
                      : (isWrong
                            ? Colors.redAccent.withValues(alpha: 0.1)
                            : Colors.transparent),
                  border: Border.all(
                    color: isCorrect
                        ? Colors.greenAccent
                        : (isWrong
                              ? Colors.redAccent
                              : primaryColor.withValues(alpha: 0.2)),
                    width: isCompact ? 2.r : 2.5.r,
                  ),
                ),
                child: Center(
                  child: Text(
                    verb.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: isCompact ? 13.sp : 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isCorrect
                          ? Colors.greenAccent
                          : (isWrong ? Colors.redAccent : primaryColor),
                    ),
                  ),
                ),
              )
              .animate(target: isCorrect ? 1 : 0)
              .shimmer(duration: 1.seconds)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
    );
  }

  Widget _buildQuantumCore(Color primaryColor, bool isCompact) {
    final Color coreColor =
        (isAnsweredNotifier.value || _pendingTypeSubmit.value)
        ? (isCorrectNotifier.value != false
              ? Colors.greenAccent
              : Colors.redAccent)
        : primaryColor;
    final coreSize = isCompact ? 50.r : 70.r;
    final innerSize = isCompact ? 14.r : 20.r;

    return Container(
      width: coreSize,
      height: coreSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: coreColor,
        boxShadow: [
          BoxShadow(
            color: coreColor.withValues(alpha: 0.4),
            blurRadius: isCompact ? 14 : 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.seconds),
      ),
    );
  }
}
