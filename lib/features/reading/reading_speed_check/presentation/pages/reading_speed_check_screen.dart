import 'package:vowl/core/utils/instruction_helper.dart';

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
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_instruction.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_pulse_zone.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_question_area.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_option.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';

class ReadingSpeedCheckScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ReadingSpeedCheckScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.readingSpeedCheck,
  });

  @override
  State<ReadingSpeedCheckScreen> createState() =>
      _ReadingSpeedCheckScreenState();
}

class _ReadingSpeedCheckScreenState extends State<ReadingSpeedCheckScreen>
    with ReadingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final ValueNotifier<int> _timerValue = ValueNotifier(12);
  final ValueNotifier<int> _timeLimit = ValueNotifier(12);
  final ValueNotifier<bool> _isRevealed = ValueNotifier(false);
  final ValueNotifier<int?> _selectedIndex = ValueNotifier(null);
  final ValueNotifier<bool> _isLargeText = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _timerValue.dispose();
    _timeLimit.dispose();
    _isRevealed.dispose();
    _selectedIndex.dispose();
    _isLargeText.dispose();
    _scrollController.dispose();
    disposeReadingGame();
    super.dispose();
  }

  final _timerKey = GlobalKey<SpeedChallengeTimerState>();

  @override
  void initState() {
    super.initState();
    timerKey = _timerKey;
    initReadingGame();
  }

  @override
  void onReadingStateChanged(BuildContext context, ReadingState state) {
    if (state is ReadingLoaded) {
      final quest = state.currentQuest;
      final limit = quest.timeLimit ?? 30;
      if (_timeLimit.value != limit) {
        _timeLimit.value = limit;
      }
    }
    super.onReadingStateChanged(context, state);
  }

  void _onDoneReadingTap() {
    if (isAnsweredNotifier.value || _isRevealed.value) return;
    hapticService.selection();
    _timerKey.currentState?.stop();
    _isRevealed.value = true;
  }

  void _onTimeUp() {
    if (!mounted) return;
    if (!_isRevealed.value) {
      _isRevealed.value = true;
    }
  }

  void _onTimerTick(int remaining) {
    if (!mounted) return;
    _timerValue.value = remaining;
  }

  void _submitAnswer(int index, ReadingQuest quest) {
    if (isAnsweredNotifier.value || !_isRevealed.value) return;

    final options = quest.options ?? [];
    if (index < 0 || index >= options.length) return;

    _selectedIndex.value = index;
    final isCorrect =
        options[index].trim().toLowerCase() ==
        (quest.correctAnswer ?? "").trim().toLowerCase();

    if (isCorrect) {
      submitCorrectAnswer();
    } else {
      submitWrongAnswer(quest: quest, userAnswer: options[index]);
    }
  }

  @override
  void onQuestionReset() {
    _timerValue.value = _timeLimit.value;
    _isRevealed.value = false;
    _selectedIndex.value = null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

    return BlocConsumer<ReadingBloc, ReadingState>(
      listenWhen: readingListenWhen,
      listener: onReadingStateChanged,
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            isAnsweredNotifier,
            isCorrectNotifier,
            showConfettiNotifier,
            _isRevealed,
            _timerValue,
            _timeLimit,
            _selectedIndex,
            _isLargeText,
          ]),
          builder: (context, _) {
            final options = quest?.options ?? [];
            return ReadingBaseLayout(
              useScrolling: false,
              disablePadding: true,
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: isAnsweredNotifier.value,
              isCorrect: isCorrectNotifier.value,
              showConfetti: showConfettiNotifier.value,
              onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
              onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
              child: quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
                      controller: _scrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: Center(
                                          child: ReadingSpeedInstruction(
                                            primaryColor: theme.primaryColor,
                                            isRevealed: _isRevealed.value,
                                            instruction:
                                                InstructionHelper.getInstruction(
                                                  quest,
                                                ),
                                          ),
                                        ),
                                      ),
                                      if (!_isRevealed.value)
                                        Positioned(
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              hapticService.selection();
                                              _isLargeText.value =
                                                  !_isLargeText.value;
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(8.r),
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                _isLargeText.value
                                                    ? Icons
                                                          .text_decrease_rounded
                                                    : Icons.format_size_rounded,
                                                color: theme.primaryColor,
                                                size: 20.r,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  SizedBox(height: 32.h),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, -0.1),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: _isRevealed.value
                                        ? ReadingSpeedQuestionArea(
                                            key: const ValueKey('question'),
                                            question: quest.question ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                          )
                                        : Padding(
                                            key: const ValueKey('timer'),
                                            padding: EdgeInsets.only(
                                              bottom: 24.h,
                                            ),
                                            child: SpeedChallengeTimer(
                                              key: _timerKey,
                                              durationSeconds: _timeLimit.value,
                                              primaryColor: theme.primaryColor,
                                              onTimeUp: _onTimeUp,
                                              onTick: _onTimerTick,
                                              autoStart: true,
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 400),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: SlideTransition(
                                          position: Tween<Offset>(
                                            begin: const Offset(0.0, 0.1),
                                            end: Offset.zero,
                                          ).animate(animation),
                                          child: child,
                                        ),
                                      );
                                    },
                                    child: !_isRevealed.value
                                        ? ReadingSpeedPulseZone(
                                            key: const ValueKey('zone'),
                                            passage: quest.passage ?? "",
                                            color: theme.primaryColor,
                                            isDark: isDark,
                                            timerValue: _timerValue.value,
                                            timeLimit: _timeLimit.value,
                                            wordCount:
                                                quest.passageWordCount ??
                                                quest.passage
                                                    ?.split(RegExp(r'\s+'))
                                                    .length ??
                                                0,
                                            wpmTarget: quest.wpmTarget ?? 0,
                                            onTapPulse: _onDoneReadingTap,
                                            largeText: _isLargeText.value,
                                          )
                                        : Column(
                                            key: const ValueKey('options'),
                                            children: [
                                              SizedBox(height: 32.h),
                                              ...options.asMap().entries.map((
                                                entry,
                                              ) {
                                                return ReadingSpeedOption(
                                                  index: entry.key,
                                                  text: entry.value,
                                                  correct:
                                                      quest.correctAnswer ?? "",
                                                  color: theme.primaryColor,
                                                  isDark: isDark,
                                                  selectedIndex:
                                                      _selectedIndex.value,
                                                  isAnswered:
                                                      isAnsweredNotifier.value,
                                                  onTap: () => _submitAnswer(
                                                    entry.key,
                                                    quest,
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
                                  ),

                                  SizedBox(height: 60.h),
                                ],
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
