import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/mixins/reading_game_screen_mixin.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_target_badge.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_terminal.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

/// Interactive reading game screen measuring skimming and scanning proficiency under time constraints.
class SkimmingScanningScreen extends StatefulWidget {
  /// The difficulty or curriculum level of the reading quest.
  final int level;

  /// The specific reading game subtype represented by this screen.
  final GameSubtype gameType;

  /// Creates a [SkimmingScanningScreen] instance.
  const SkimmingScanningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.skimmingScanning,
  });

  @override
  State<SkimmingScanningScreen> createState() => _SkimmingScanningScreenState();
}

class _SkimmingScanningScreenState extends State<SkimmingScanningScreen>
    with
        GameScreenMixin<SkimmingScanningScreen>,
        ReadingGameScreenMixin<SkimmingScanningScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  late ScrollController _scrollController;
  late ScrollController _mainScrollController;
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mainScrollController = ScrollController();
    initReadingGame();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted || isAnsweredNotifier.value) return;
      if (VowlMotion.shouldReduceMotion(context)) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 28),
          curve: Curves.linear,
        );
      }
    });
  }

  void _submitCorrectAnswer() {
    if (isAnsweredNotifier.value) return;
    _timerKey.currentState?.stop();
    _autoScrollTimer?.cancel();
    submitCorrectAnswer();
  }

  void _submitIncorrectAnswer(ReadingQuest quest, [String? word]) {
    if (isAnsweredNotifier.value) return;
    _timerKey.currentState?.stop();
    _autoScrollTimer?.cancel();
    submitWrongAnswer(quest: quest, userAnswer: word ?? '[Time up]');
  }

  @override
  void onQuestionReset() {
    _autoScrollTimer?.cancel();
    _lastQuestId = null;
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0.0);
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    _mainScrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  String? _lastQuestId;

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final tokens = Theme.of(context).extension<AppColorTokens>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: (context, state) {
        onReadingStateChanged(context, state);
        if (state is ReadingLoaded) {
          final quest = state.currentQuest as ReadingQuest?;
          if (quest != null && quest.id != _lastQuestId) {
            _lastQuestId = quest.id;
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0.0);
            }
            _startAutoScroll();
          }
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        // Ensure initial quest id is set
        if (quest != null && _lastQuestId == null) {
          _lastQuestId = quest.id;
        }

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
              onHint: () {},
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _mainScrollController,
                      thumbColor: theme.primaryColor.withValues(
                        alpha: isDark ? 0.4 : 0.3,
                      ),
                      radius: Radius.circular(8.r),
                      thickness: 3.w,
                      child: CustomScrollView(
                        controller: _mainScrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 12.h),
                                  SkimmingScanningTargetBadge(
                                    item:
                                        quest.targetInfo ??
                                        quest.targetItem ??
                                        "",
                                    color: theme.primaryColor,
                                  ),
                                  SizedBox(height: 12.h),

                                  if (!isAnsweredNotifier.value)
                                    SpeedChallengeTimer(
                                      key: _timerKey,
                                      durationSeconds: quest.timeLimit ?? 30,
                                      primaryColor: theme.primaryColor,
                                      onTimeUp: () =>
                                          _submitIncorrectAnswer(quest),
                                    ),

                                  if (!isAnsweredNotifier.value)
                                    SizedBox(height: 12.h),

                                  // Instruction Card
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                      vertical: 11.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAnsweredNotifier.value
                                          ? tokens.gameCorrect.withValues(
                                              alpha: isDark ? 0.15 : 0.08,
                                            )
                                          : theme.primaryColor.withValues(
                                              alpha: isDark ? 0.12 : 0.06,
                                            ),
                                      borderRadius: BorderRadius.circular(16.r),
                                      border: Border.all(
                                        color: (isAnsweredNotifier.value
                                                ? tokens.gameCorrect
                                                : theme.primaryColor)
                                            .withValues(
                                              alpha: isDark ? 0.35 : 0.2,
                                            ),
                                        width: 1.2,
                                      ),
                                    ),
                                    child: Text(
                                      isAnsweredNotifier.value
                                          ? "TARGET FOUND!"
                                          : InstructionHelper.getInstruction(
                                              quest,
                                            ),
                                      textAlign: TextAlign.center,
                                      softWrap: true,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        color: isAnsweredNotifier.value
                                            ? tokens.gameCorrect
                                            : (isDark
                                                ? Colors.white.withValues(
                                                    alpha: 0.95,
                                                  )
                                                : theme.primaryColor),
                                        fontSize: 13.5.sp,
                                        fontWeight: FontWeight.w600,
                                        height: 1.4,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10.h),

                                  // Interaction Prompt
                                  if (!isAnsweredNotifier.value)
                                    Padding(
                                      padding: EdgeInsets.only(bottom: 8.h),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.touch_app_rounded,
                                            color: isDark
                                                ? Colors.white60
                                                : const Color(0xFF64748B),
                                            size: 15.r,
                                          ),
                                          SizedBox(width: 6.w),
                                          Flexible(
                                            child: Text(
                                              "Tap the target in the text below",
                                              textAlign: TextAlign.center,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontFamily: 'Outfit',
                                                color: isDark
                                                    ? Colors.white60
                                                    : const Color(0xFF64748B),
                                                fontSize: 12.5.sp,
                                                fontWeight: FontWeight.w500,
                                                letterSpacing: 0.2,
                                                height: 1.35,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Scanning Terminal Box
                                  SizedBox(
                                    width: double.infinity,
                                    child: SkimmingScanningTerminal(
                                      text: quest.passage ?? "",
                                      correct: quest.correctAnswer ?? "",
                                      color: theme.primaryColor,
                                      scrollController: _scrollController,
                                      isAnswered: isAnsweredNotifier.value,
                                      onTapWord: (clean, isCorrectTarget) {
                                        if (isCorrectTarget) {
                                          _submitCorrectAnswer();
                                        } else {
                                          _submitIncorrectAnswer(quest, clean);
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [SizedBox(height: 50.h)],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom +
                                        40.h
                                  : 120.h,
                            ),
                          ),
                        ],
                      ),
                    ),
            );
          },
        );
      },
    );
  }
}
