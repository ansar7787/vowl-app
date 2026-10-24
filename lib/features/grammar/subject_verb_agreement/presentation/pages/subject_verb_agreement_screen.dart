import 'dart:async';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/presentation/mixins/grammar_game_screen_mixin.dart';
import 'package:vowl/features/grammar/presentation/layout/grammar_base_layout.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:flutter/physics.dart';

/// Screen presenting the subject-verb agreement grammar exercise.
class SubjectVerbAgreementScreen extends StatefulWidget {
  /// The level number of the current session.
  final int level;

  /// The game subtype for tracking and analytics.
  final GameSubtype gameType;

  /// Creates a [SubjectVerbAgreementScreen] widget.
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
    with
        SingleTickerProviderStateMixin,
        GameScreenMixin<SubjectVerbAgreementScreen>,
        GrammarGameScreenMixin<SubjectVerbAgreementScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<Offset> _ringOffset = ValueNotifier(Offset.zero);
  final ValueNotifier<bool> _pendingTypeSubmit = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  late final AnimationController _springController;
  int _currentCorrectIndex = 0;

  @override
  void initState() {
    super.initState();
    initGrammarGame();
    _springController = AnimationController(vsync: this);
    _springController.addListener(() {
      _ringOffset.value = Offset(_springController.value, 0);
      _checkHarmony(_currentCorrectIndex);
    });
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
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

      _scrollTimer?.cancel();
      _scrollTimer = Timer(const Duration(milliseconds: 100), () {
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
    _scrollTimer?.cancel();
    _ringOffset.value = Offset.zero;
    _pendingTypeSubmit.value = false;
  }

  String _formatInstruction(String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Select the verb that agrees with the subject';
    }
    final trimmed = raw.trim();
    final upper = trimmed.toUpperCase();
    if (upper == 'COMPLETE THE AGREEMENT' || upper == 'COMPLETE THE SENTENCE') {
      return 'Select the verb that agrees with the subject';
    }
    if (trimmed == upper && trimmed.length > 2) {
      return trimmed[0].toUpperCase() + trimmed.substring(1).toLowerCase();
    }
    return trimmed;
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
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isCompact =
                            constraints.maxHeight < 700 ||
                            MediaQuery.sizeOf(context).height < 700;

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
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: isCompact ? 10.h : 20.h,
                                              ),

                                              // Instruction Badge
                                              _buildInstructionPill(
                                                context,
                                                theme,
                                                _formatInstruction(
                                                  quest.instruction,
                                                ),
                                                isCompact,
                                              ),

                                              SizedBox(
                                                height: isCompact ? 10.h : 16.h,
                                              ),

                                              // Question Sentence Card
                                              _buildSentenceCard(
                                                context,
                                                theme,
                                                quest,
                                                isDark,
                                                isCompact,
                                              ),

                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 24.w,
                                                  ),
                                                  child: Stack(
                                                    alignment: Alignment.center,
                                                    children: [
                                                      // Connection Track
                                                      Container(
                                                        height: isCompact
                                                            ? 3.h
                                                            : 4.h,
                                                        width: double.infinity,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                2.r,
                                                              ),
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              theme.primaryColor
                                                                  .withValues(
                                                                    alpha: 0.05,
                                                                  ),
                                                              theme.primaryColor
                                                                  .withValues(
                                                                    alpha: 0.4,
                                                                  ),
                                                              theme.primaryColor
                                                                  .withValues(
                                                                    alpha: 0.05,
                                                                  ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),

                                                      // Verb Option Targets
                                                      _buildVerbTerminal(
                                                        context,
                                                        0,
                                                        options[0],
                                                        theme.primaryColor,
                                                        Alignment.centerLeft,
                                                        quest.correctAnswerIndex ??
                                                            0,
                                                        isCompact,
                                                        () => _onConnect(
                                                          0,
                                                          quest.correctAnswerIndex ??
                                                              0,
                                                        ),
                                                      ),
                                                      _buildVerbTerminal(
                                                        context,
                                                        1,
                                                        options[1],
                                                        theme.primaryColor,
                                                        Alignment.centerRight,
                                                        quest.correctAnswerIndex ??
                                                            0,
                                                        isCompact,
                                                        () => _onConnect(
                                                          1,
                                                          quest.correctAnswerIndex ??
                                                              0,
                                                        ),
                                                      ),

                                                      // Interactive Verb Slider
                                                      Builder(
                                                        builder: (context) {
                                                          final coreWidget = GestureDetector(
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            onHorizontalDragUpdate:
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
                                                            onHorizontalDragEnd:
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
                                                                context,
                                                                theme
                                                                    .primaryColor,
                                                                isCompact,
                                                              ),
                                                            ),
                                                          );
                                                          final reduceMotion =
                                                              VowlMotion.shouldReduceMotion(
                                                                context,
                                                              );
                                                          if (reduceMotion) {
                                                            return coreWidget;
                                                          }
                                                          return coreWidget
                                                              .animate()
                                                              .scale(
                                                                duration:
                                                                    400.ms,
                                                                curve: Curves
                                                                    .easeOutBack,
                                                              );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: isCompact ? 10.h : 28.h,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_pendingTypeSubmit.value &&
                                      !isAnsweredNotifier.value &&
                                      cleanTargetSentence.isNotEmpty)
                                    SliverToBoxAdapter(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 20.w,
                                          vertical: 10.h,
                                        ),
                                        child: TypeToConfirmOverlay(
                                          key: const ValueKey(
                                            'sva_type_overlay',
                                          ),
                                          expectedText: cleanTargetSentence,
                                          title: 'Type to confirm',
                                          subtitle:
                                              'Type the completed sentence below',
                                          primaryColor: theme.primaryColor,
                                          displayFontSize:
                                              MediaQuery.of(
                                                    context,
                                                  ).size.height <
                                                  600
                                              ? 16.sp
                                              : 18.sp,
                                          displayFontWeight: FontWeight.w600,
                                          displayTextAlign: TextAlign.center,
                                          onConfirmed: () =>
                                              _submitFinalAnswer(true),
                                          onSkipped: () =>
                                              _submitFinalAnswer(false),
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

  void _checkHarmony(int correctIndex) {
    final bool isCompact = MediaQuery.sizeOf(context).shortestSide < 600;
    final double threshold = isCompact ? 90.w : 110.w;
    if (_ringOffset.value.dx < -threshold) {
      _onConnect(0, correctIndex);
    } else if (_ringOffset.value.dx > threshold) {
      _onConnect(1, correctIndex);
    }
  }

  Widget _buildInstructionPill(
    BuildContext context,
    dynamic theme,
    String instructionText,
    bool isCompact,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final pill = Padding(
      key: const ValueKey('sva_instruction'),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 14.w,
          vertical: isCompact ? 6.h : 8.h,
        ),
        decoration: BoxDecoration(
          color: (theme.primaryColor as Color).withValues(
            alpha: isDark ? 0.12 : 0.08,
          ),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: (theme.primaryColor as Color).withValues(
              alpha: isDark ? 0.25 : 0.18,
            ),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: isCompact ? 13.r : 15.r,
              color: theme.primaryColor as Color,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                instructionText,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 12.sp : 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.9)
                      : AppColors.slate800,
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (reduceMotion) return pill;
    return pill.animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }

  Widget _buildSentenceCard(
    BuildContext context,
    dynamic theme,
    GrammarQuest quest,
    bool isDark,
    bool isCompact,
  ) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final hasCompleted =
        (_pendingTypeSubmit.value || isCorrectNotifier.value == true) &&
        quest.correctAnswer != null;
    final String displayText = hasCompleted
        ? (quest.question ?? "").replaceAll('___', quest.correctAnswer!)
        : (quest.question ??
              "Select the correct verb to complete the sentence");

    final card = Padding(
      key: const ValueKey('sva_harmony_hub'),
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 20.w,
          vertical: isCompact ? 14.h : 20.h,
        ),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2230) : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: (theme.primaryColor as Color).withValues(
              alpha: isDark ? 0.28 : 0.16,
            ),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          displayText,
          textAlign: TextAlign.center,
          softWrap: true,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: isCompact ? 16.sp : 19.sp,
            color: isDark ? Colors.white : AppColors.slate900,
            height: 1.45,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    if (reduceMotion) return card;
    return card.animate().fadeIn(duration: 600.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildVerbTerminal(
    BuildContext context,
    int index,
    String verb,
    Color primaryColor,
    Alignment alignment,
    int correctIndex,
    bool isCompact,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final isCorrect =
        (isAnsweredNotifier.value || _pendingTypeSubmit.value) &&
        isCorrectNotifier.value != false &&
        index == correctIndex;
    final isWrong =
        isAnsweredNotifier.value &&
        isCorrectNotifier.value == false &&
        index != correctIndex;
    final terminalSize = isCompact ? 72.r : 84.r;

    final terminal = GestureDetector(
      key: ValueKey('sva_terminal_$index'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: terminalSize,
        height: terminalSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isCorrect
              ? AppColors.gameCorrect.withValues(alpha: 0.15)
              : (isWrong
                    ? AppColors.gameIncorrect.withValues(alpha: 0.15)
                    : (isDark ? const Color(0xFF1E2230) : Colors.white)),
          border: Border.all(
            color: isCorrect
                ? AppColors.gameCorrect
                : (isWrong
                      ? AppColors.gameIncorrect
                      : primaryColor.withValues(alpha: isDark ? 0.35 : 0.25)),
            width: isCompact ? 2.r : 2.5.r,
          ),
          boxShadow: [
            BoxShadow(
              color: isCorrect
                  ? AppColors.gameCorrect.withValues(alpha: 0.2)
                  : (isWrong
                        ? AppColors.gameIncorrect.withValues(alpha: 0.2)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.05)),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                verb.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: isCompact ? 14.sp : 16.sp,
                  fontWeight: FontWeight.w700,
                  color: isCorrect
                      ? AppColors.gameCorrect
                      : (isWrong
                            ? AppColors.gameIncorrect
                            : (isDark ? Colors.white : AppColors.slate900)),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return Align(alignment: alignment, child: terminal);
    }

    return Align(
      alignment: alignment,
      child: terminal
          .animate(target: isCorrect ? 1 : 0)
          .shimmer(duration: 1.seconds)
          .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08)),
    );
  }

  Widget _buildQuantumCore(
    BuildContext context,
    Color primaryColor,
    bool isCompact,
  ) {
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final Color coreColor =
        (isAnsweredNotifier.value || _pendingTypeSubmit.value)
        ? (isCorrectNotifier.value != false
              ? AppColors.gameCorrect
              : AppColors.gameIncorrect)
        : primaryColor;
    final coreSize = isCompact ? 48.r : 56.r;
    final innerSize = isCompact ? 16.r : 20.r;

    final innerIcon = Icon(
      Icons.drag_indicator_rounded,
      color: Colors.white,
      size: innerSize,
    );

    return Container(
      key: const ValueKey('sva_quantum_core'),
      width: coreSize,
      height: coreSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: coreColor,
        boxShadow: [
          BoxShadow(
            color: coreColor.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: reduceMotion
            ? innerIcon
            : innerIcon
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1.08, 1.08),
                    duration: 1.5.seconds,
                  ),
      ),
    );
  }
}
