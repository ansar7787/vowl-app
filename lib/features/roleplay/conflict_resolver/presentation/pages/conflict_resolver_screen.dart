import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/mixins/roleplay_game_screen_mixin.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_instruction.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_conflict_card.dart';
import 'package:vowl/features/roleplay/conflict_resolver/presentation/widgets/conflict_resolver_dial_console.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class ConflictResolverScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ConflictResolverScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.conflictResolver,
  });

  @override
  State<ConflictResolverScreen> createState() => _ConflictResolverScreenState();
}

class _ConflictResolverScreenState extends State<ConflictResolverScreen>
    with
        TickerProviderStateMixin,
        GameScreenMixin<ConflictResolverScreen>,
        RoleplayGameScreenMixin<ConflictResolverScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late AnimationController _waveController;

  final ValueNotifier<double> _rotation = ValueNotifier(
    0.0,
  ); // Slider score level (0.0 to 1.0)
  final ScrollController _scrollController = ScrollController();
  List<RoleplayQuest> _currentOptions = [];

  int? get _focusedIndex {
    double val = _rotation.value;
    if ((val - 0.125).abs() < 0.1) return 0;
    if ((val - 0.375).abs() < 0.1) return 1;
    if ((val - 0.625).abs() < 0.1) return 2;
    if ((val - 0.875).abs() < 0.1) return 3;
    return null;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    initRoleplayGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) {
      if (_waveController.isAnimating) _waveController.stop();
    } else {
      if (!_waveController.isAnimating) _waveController.repeat();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _rotation.dispose();
    _scrollController.dispose();
    disposeRoleplayGame();
    super.dispose();
  }

  // Realistic Physical dial rotation updater utilizing trigonometry
  void _onDialDragged(DragUpdateDetails details, Offset localDialCenter) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final Offset touchPos = details.localPosition;
    final double dx = touchPos.dx - localDialCenter.dx;
    final double dy = touchPos.dy - localDialCenter.dy;

    // Calculate angle in radians (-pi to pi)
    double angle = math.atan2(dy, dx);

    // Normalize to 0 to 2pi
    if (angle < 0) {
      angle += 2 * math.pi;
    }

    // Convert angle to progress scale (0.0 to 1.0)
    // -pi/2 (top center) is 0.0
    double progress = (angle + math.pi / 2) / (2 * math.pi);
    if (progress > 1.0) progress -= 1.0;

    final previousIndex = _focusedIndex;
    _rotation.value = progress.clamp(0.0, 1.0);

    if (previousIndex != _focusedIndex) {
      hapticService.selection();
    }
  }

  void _stepLeft() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    int currentIndex = _focusedIndex ?? 0;
    int nextIndex = (currentIndex - 1) % 4;
    if (nextIndex < 0) nextIndex = 3;
    _rotation.value = 0.125 + (nextIndex * 0.25);
  }

  void _stepRight() {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;
    hapticService.selection();
    int currentIndex = _focusedIndex ?? 0;
    int nextIndex = (currentIndex + 1) % 4;
    _rotation.value = 0.125 + (nextIndex * 0.25);
  }

  void _submitAnswer(GameQuest currentQuest) {
    if (isAnsweredNotifier.value || isFirstStagePassedNotifier.value) return;

    final focused = _focusedIndex;
    if (focused == null ||
        _currentOptions.isEmpty ||
        focused >= _currentOptions.length)
      return;

    final selectedQuest = _currentOptions[focused];
    bool isCorrect = selectedQuest.id == currentQuest.id;

    if (isCorrect) {
      hapticService.selection();
      isFirstStagePassedNotifier.value = true;
      _scrollToBottom();
      // Wait for Phase 2
    } else {
      _scrollToBottom();
      submitWrongAnswer(
        quest: currentQuest,
        userAnswer: selectedQuest.correctAnswer,
      );
    }
  }

  void _submitVerbalEvaluation(bool nailedIt, GameQuest quest) {
    if (isAnsweredNotifier.value) return;

    if (nailedIt) {
      submitCorrectAnswer();
    } else {
      _scrollToBottom();
      submitWrongAnswer(quest: quest, userAnswer: null);
    }
  }

  void _generateOptions() {
    if (!mounted) return;
    final state = context.read<RoleplayBloc>().state;
    if (state is RoleplayLoaded) {
      final currentQuest = state.currentQuest;
      final allQuests = state.quests
          .where((q) => q.id != currentQuest.id)
          .toList();
      allQuests.shuffle();

      _currentOptions = allQuests.take(3).toList();
      _currentOptions.add(currentQuest);
      _currentOptions.shuffle();
      _currentOptions.sort(
        (a, b) => (a.empathyScore ?? 0.0).compareTo(b.empathyScore ?? 0.0),
      );
    }
  }

  @override
  void onQuestionReset() {
    _rotation.value = 0.0;
    _generateOptions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('roleplay', level: widget.level);

    return BlocConsumer<RoleplayBloc, RoleplayState>(
      listenWhen: roleplayListenWhen,
      listener: onRoleplayStateChanged,
      builder: (context, state) {
        final quest = (state is RoleplayLoaded) ? state.currentQuest : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _rotation,
            isFirstStagePassedNotifier,
          ]),
          builder: (context, _) {
            return RoleplayBaseLayout(
              fullScreenContent: true,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered:
                  isAnsweredNotifier.value &&
                  (isCorrectNotifier.value != null ||
                      !isFirstStagePassedNotifier.value),
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () =>
                  context.read<RoleplayBloc>().add(NextQuestion()),
              onHint: () =>
                  context.read<RoleplayBloc>().add(RoleplayHintUsed()),
              useScrolling: false,
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return RawScrollbar(
                          controller: _scrollController,
                          thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                          radius: Radius.circular(8.r),
                          thickness: 4.w,
                          child: CustomScrollView(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(child: SizedBox(height: 24.h)),
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Builder(
                                  builder: (context) {
                                    final isCompact =
                                        MediaQuery.sizeOf(context).height < 600;
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: isCompact ? 5.h : 10.h,
                                      ),
                                      child: Column(
                                        children: [
                                          ConflictResolverInstruction(
                                            primaryColor: theme.primaryColor,
                                            instruction:
                                                InstructionHelper.getInstruction(
                                                  quest,
                                                ),
                                          ),
                                          SizedBox(
                                            height: isCompact ? 10.h : 16.h,
                                          ),
                                          ConflictResolverConflictCard(
                                            scene: quest.scene ?? "",
                                            escalationLevel:
                                                quest.escalationLevel ?? 5,
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 16.h : 24.h,
                                          ),

                                          // Circular audio dials
                                          ConflictResolverDialConsole(
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            rotation: _rotation.value,
                                            waveAnimation: _waveController,
                                            onDialDragged: _onDialDragged,
                                            onStepLeft: _stepLeft,
                                            onStepRight: _stepRight,
                                            focusedText:
                                                _focusedIndex != null &&
                                                    _currentOptions
                                                        .isNotEmpty &&
                                                    _focusedIndex! <
                                                        _currentOptions.length
                                                ? _currentOptions[_focusedIndex!]
                                                      .correctAnswer
                                                : null,
                                            isAnswered:
                                                isAnsweredNotifier.value,
                                            isCorrect: isCorrectNotifier.value,
                                            isFirstStagePassed:
                                                isFirstStagePassedNotifier
                                                    .value,
                                          ),
                                          SizedBox(
                                            height: isCompact ? 20.h : 28.h,
                                          ),

                                          // Submit control button
                                          if (!isAnsweredNotifier.value &&
                                              !isFirstStagePassedNotifier.value)
                                            ScaleButton(
                                              onTap: () => _submitAnswer(quest),
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 24.w,
                                                  vertical: isCompact
                                                      ? 10.h
                                                      : 14.h,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        30.r,
                                                      ),
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      theme.primaryColor,
                                                      theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: theme.primaryColor
                                                          .withValues(
                                                            alpha: 0.35,
                                                          ),
                                                      blurRadius: isCompact
                                                          ? 10
                                                          : 15,
                                                    ),
                                                  ],
                                                ),
                                                child: Wrap(
                                                  alignment:
                                                      WrapAlignment.center,
                                                  crossAxisAlignment:
                                                      WrapCrossAlignment.center,
                                                  spacing: 8.w,
                                                  children: [
                                                    Icon(
                                                      Icons.security_rounded,
                                                      color: Colors.white,
                                                      size: isCompact
                                                          ? 16.r
                                                          : 18.r,
                                                    ),
                                                    Text(
                                                      "CONFIRM RESPONSE",
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: isCompact
                                                            ? 12.sp
                                                            : 14.sp,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors.white,
                                                        letterSpacing: 1.5,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ).animate().fadeIn(
                                              duration: 300.ms,
                                            ),

                                          // Post-answer review cards
                                          SizedBox(
                                            height: isCompact ? 20.h : 40.h,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),

                              if (isFirstStagePassedNotifier.value &&
                                  !isAnsweredNotifier.value)
                                SliverToBoxAdapter(
                                  child: SpeakToConfirmOverlay(
                                    expectedText:
                                        quest.correctAnswer ??
                                        "De-escalating conflict",
                                    primaryColor: theme.primaryColor,
                                    isPositioned: false,
                                    onConfirmed: () {
                                      context.read<RoleplayBloc>().add(
                                        const RoleplaySpeakConfirmed(5),
                                      );
                                      _submitVerbalEvaluation(true, quest);
                                    },
                                    onSkipped: () =>
                                        _submitVerbalEvaluation(false, quest),
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
                                      : 120.h,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            );
          },
        );
      },
    );
  }
}
