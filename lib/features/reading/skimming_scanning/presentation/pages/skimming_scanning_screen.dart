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
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_target_badge.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_terminal.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_result.dart';

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
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _isAnswered) return;
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 12),
          curve: Curves.linear,
        );
      }
    });
  }

  void _submitCorrectAnswer() {
    if (_isAnswered) return;
    _hapticService.success();
    _soundService.playCorrect();
    setState(() {
      _isAnswered = true;
      _isCorrect = true;
    });
    context.read<ReadingBloc>().add(SubmitAnswer(true));
  }

  void _submitIncorrectAnswer() {
    if (_isAnswered) return;
    _hapticService.error();
    _soundService.playWrong();
    context.read<ReadingBloc>().add(SubmitAnswer(false));
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
          final isRetry = _isAnswered && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
            });
            if (_scrollController.hasClients) {
              _scrollController.jumpTo(0);
            }
            _startAutoScroll();
          } else if (state.answerStatus.isAnswered && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.answerStatus.asBoolOrNull;
            });
          }
          _lastLives = state.livesRemaining;
        }
        if (state is ReadingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SCANNING ACE!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ReadingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: _isAnswered,
          isCorrect: _isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<ReadingBloc>().add(NextQuestion()),
          onHint: () => context.read<ReadingBloc>().add(ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        SkimmingScanningTargetBadge(
                          item: quest.targetItem ?? "",
                          color: theme.primaryColor,
                        ),
                        SizedBox(height: 24.h),

                        // Scanning Terminal Box
                        SizedBox(
                          height: 260.h,
                          width: double.infinity,
                          child: SkimmingScanningTerminal(
                            text: quest.passage ?? "",
                            correct: quest.correctAnswer ?? "",
                            color: theme.primaryColor,
                            scrollController: _scrollController,
                            isAnswered: _isAnswered,
                            onTapWord: (clean) {
                              if (clean.toLowerCase() ==
                                  (quest.correctAnswer ?? "").toLowerCase()) {
                                _submitCorrectAnswer();
                              } else {
                                _submitIncorrectAnswer();
                              }
                            },
                          ),
                        ),

                        SizedBox(height: 20.h),
                        Text(
                          _isAnswered
                              ? "TARGET ACQUIRED!"
                              : (quest.instruction.toUpperCase()),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            color: _isAnswered
                                ? Colors.greenAccent
                                : theme.primaryColor,
                            fontSize: 12.sp,
                            letterSpacing: 2,
                          ),
                        ),

                        if (_isAnswered) ...[
                          SizedBox(height: 24.h),
                          SkimmingScanningResult(
                            quest: quest,
                            isCorrect: _isCorrect == true,
                            isDark: isDark,
                          ),
                        ],
                        SizedBox(height: 50.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
