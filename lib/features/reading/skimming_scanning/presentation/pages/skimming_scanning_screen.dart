import 'package:vowl/core/utils/instruction_helper.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/presentation/layout/reading_base_layout.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_target_badge.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_terminal.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_result.dart';
import 'package:vowl/core/presentation/game_mechanics/speed_challenge_timer.dart';

class SkimmingScanningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SkimmingScanningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.skimmingScanning,
  });

  @override
  State<SkimmingScanningScreen> createState() => _SkimmingScanningScreenState();
}

class _SkimmingScanningScreenState extends State<SkimmingScanningScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  late ScrollController _scrollController;
  late ScrollController _mainScrollController;
  final GlobalKey<SpeedChallengeTimerState> _timerKey =
      GlobalKey<SpeedChallengeTimerState>();
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _mainScrollController = ScrollController();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted || _isAnswered.value) return;
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
    if (_isAnswered.value) return;
    _hapticService.success();
    _soundService.playCorrect();
    _isAnswered.value = true;
    _isCorrect.value = true;
    _timerKey.currentState?.stop();
    context.read<ReadingBloc>().add(SubmitAnswer(true));
  }

  void _submitIncorrectAnswer() {
    if (_isAnswered.value) return;
    _hapticService.error();
    _soundService.playWrong();
    _isAnswered.value = true;
    _isCorrect.value = false;
    _timerKey.currentState?.stop();
    context.read<ReadingBloc>().add(SubmitAnswer(false));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _mainScrollController.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ReadingBloc, ReadingState>(
      listener: (context, state) {
        if (state is ReadingLoaded) {
          final isNewQuestion = state.currentIndex != _lastProcessedIndex;
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
            _timerKey.currentState?.start();
            _startAutoScroll();
          } else if (state.answerStatus.isAnswered && !_isAnswered.value) {
            _isAnswered.value = true;
            _isCorrect.value = state.answerStatus.asBoolOrNull;
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: context.tr(
              'reading_games.scanning_ace',
              fallback: 'SCANNING ACE!',
            ),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([
            _isAnswered,
            _isCorrect,
            _showConfetti,
          ]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
              onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
              onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
              child: quest == null
                  ? const SizedBox()
                  : RawScrollbar(
                      controller: _mainScrollController,
                      thumbColor: theme.primaryColor.withValues(alpha: 0.5),
                      radius: Radius.circular(8.r),
                      thickness: 4.w,
                      child: CustomScrollView(
                        controller: _mainScrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 24.w),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                children: [
                                  SizedBox(height: 16.h),
                                  SkimmingScanningTargetBadge(
                                    item:
                                        quest.targetInfo ??
                                        quest.targetItem ??
                                        "",
                                    color: theme.primaryColor,
                                  ),
                                  SizedBox(height: 16.h),

                                  if (!_isAnswered.value)
                                    SpeedChallengeTimer(
                                      key: _timerKey,
                                      durationSeconds: 30,
                                      primaryColor: theme.primaryColor,
                                      onTimeUp: _submitIncorrectAnswer,
                                      showBonusLabel: false,
                                    ),

                                  SizedBox(height: 16.h),

                                  // Scanning Terminal Box
                                  SizedBox(
                                    height: 260.h,
                                    width: double.infinity,
                                    child: SkimmingScanningTerminal(
                                      text: quest.passage ?? "",
                                      correct: quest.correctAnswer ?? "",
                                      color: theme.primaryColor,
                                      scrollController: _scrollController,
                                      isAnswered: _isAnswered.value,
                                      onTapWord: (clean) {
                                        if (clean.toLowerCase() ==
                                            (quest.correctAnswer ?? "")
                                                .toLowerCase()) {
                                          _submitCorrectAnswer();
                                        } else {
                                          _submitIncorrectAnswer();
                                        }
                                      },
                                    ),
                                  ),
                                  SizedBox(height: 20.h),
                                  Text(
                                    _isAnswered.value
                                        ? "TARGET ACQUIRED!"
                                        : (InstructionHelper.getInstruction(
                                            quest,
                                          ).toUpperCase()),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      color: _isAnswered.value
                                          ? Colors.greenAccent
                                          : theme.primaryColor,
                                      fontSize: 12.sp,
                                      letterSpacing: 2,
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
                                  if (_isAnswered.value) ...[
                                    SizedBox(height: 24.h),
                                    SkimmingScanningResult(
                                      quest: quest,
                                      isCorrect: _isCorrect.value == true,
                                      isDark: isDark,
                                    ),
                                  ],
                                  SizedBox(height: 50.h),
                                ],
                              ),
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
