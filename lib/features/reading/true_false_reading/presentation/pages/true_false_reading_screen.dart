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
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_instruction.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_passage.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_statement.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_coin_zone.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_result.dart';

class TrueFalseReadingScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const TrueFalseReadingScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.trueFalseReading,
  });

  @override
  State<TrueFalseReadingScreen> createState() => _TrueFalseReadingScreenState();
}

class _TrueFalseReadingScreenState extends State<TrueFalseReadingScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  double _coinX = 0.0;
  double _coinY = 0.0;
  double _coinRotation = 0.0;
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

  void _onFlick(Offset delta) {
    if (_isAnswered) return;
    setState(() {
      _coinX += delta.dx;
      _coinY += delta.dy;
      _coinRotation += (delta.dx + delta.dy) / 100;
      _hapticService.selection();
    });

    if (_coinX.abs() > 100.w) {
      _submitAnswer(
        _coinX > 0,
        (context.read<ReadingBloc>().state as ReadingLoaded)
                .currentQuest
                .correctAnswer ??
            "",
      );
    }
  }

  void _submitAnswer(bool val, String correct) {
    if (_isAnswered) return;
    bool isCorrect = (val ? "true" : "false") == correct.trim().toLowerCase();

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _coinX = val ? 120.w : -120.w;
      _coinY = 0.0;
    });

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      context.read<ReadingBloc>().add(SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _coinX = 0.0;
              _coinY = 0.0;
              _coinRotation = 0.0;
            });
          } else if (state.lastAnswerCorrect != null && !_isAnswered) {
            setState(() {
              _isAnswered = true;
              _isCorrect = state.lastAnswerCorrect;
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
            title: 'FACT CHECKER!',
            enableDoubleUp: true,
          );
        } else if (state is ReadingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<ReadingBloc>().add(RestoreLife()),
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
                        TrueFalseReadingInstruction(
                          primaryColor: theme.primaryColor,
                          instruction: quest.instruction,
                        ),
                        SizedBox(height: 24.h),
                        TrueFalseReadingPassage(
                          passage: quest.passage ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 32.h),
                        TrueFalseReadingStatement(
                          statement: quest.question ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 40.h),
                        TrueFalseReadingCoinZone(
                          coinX: _coinX,
                          coinY: _coinY,
                          coinRotation: _coinRotation,
                          onFlick: _onFlick,
                          isDark: isDark,
                          themeColor: theme.primaryColor,
                        ),
                        if (_isAnswered) ...[
                          SizedBox(height: 30.h),
                          TrueFalseReadingResult(
                            quest: quest,
                            isCorrect: _isCorrect == true,
                            isDark: isDark,
                          ),
                        ],
                        SizedBox(height: 60.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
