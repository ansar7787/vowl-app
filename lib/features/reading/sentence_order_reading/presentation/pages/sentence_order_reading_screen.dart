import 'dart:ui';
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
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_instruction.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_stone_slab.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_capstone.dart';
import 'package:vowl/features/reading/sentence_order_reading/presentation/widgets/sentence_order_reading_result.dart';

class SentenceOrderReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const SentenceOrderReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.sentenceOrderReading,
  });

  @override
  State<SentenceOrderReadingScreen> createState() =>
      _SentenceOrderReadingScreenState();
}

class _SentenceOrderReadingScreenState
    extends State<SentenceOrderReadingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  List<String> _currentOrder = [];
  bool _isAnswered = false;
  bool? _isCorrect;
  bool _showConfetti = false;
  int _lastProcessedIndex = -1;
  int? _lastLives;

  @override
  void initState() {
    super.initState();
    context.read<ReadingBloc>().add(
      FetchReadingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isAnswered) return;
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = _currentOrder.removeAt(oldIndex);
      _currentOrder.insert(newIndex, item);
      _hapticService.selection();
    });
  }

  void _submitAnswer(List<int> correctOrder, List<String> original) {
    if (_isAnswered) return;

    bool isCorrect = true;
    for (int i = 0; i < _currentOrder.length; i++) {
      if (_currentOrder[i] != original[correctOrder[i]]) {
        isCorrect = false;
        break;
      }
    }

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ReadingBloc>().add(SubmitAnswer(false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('reading', level: widget.level);

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
              _currentOrder = List<String>.from(
                state.currentQuest.shuffledSentences ?? [],
              );
            });
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
            title: 'LOGIC FLOW EXPERT!',
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
                        SentenceOrderReadingInstruction(
                          primaryColor: theme.primaryColor,
                          instruction: quest.instruction,
                        ),
                        SizedBox(height: 24.h),
                        ReorderableListView(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          proxyDecorator: (child, index, animation) =>
                              _buildProxy(child, animation, theme.primaryColor),
                          onReorder: _onReorder,
                          children: List.generate(
                            _currentOrder.length,
                            (index) => SentenceOrderReadingStoneSlab(
                              key: ValueKey(_currentOrder[index]),
                              text: _currentOrder[index],
                              index: index,
                              color: theme.primaryColor,
                              isDark: isDark,
                            ),
                          ),
                        ),
                        if (!_isAnswered) ...[
                          SizedBox(height: 24.h),
                          SentenceOrderReadingCapstone(
                            color: theme.primaryColor,
                            onTap: () {
                              _hapticService.heavy();
                              _submitAnswer(
                                quest.correctOrder ?? [],
                                quest.shuffledSentences ?? [],
                              );
                            },
                          ),
                        ],
                        if (_isAnswered) ...[
                          SizedBox(height: 30.h),
                          SentenceOrderReadingResult(
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

  Widget _buildProxy(Widget child, Animation<double> animation, Color color) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double scale = lerpDouble(1, 1.05, animation.value)!;
        return Transform.scale(
          scale: scale,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }
}


