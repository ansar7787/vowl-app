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
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_instruction.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_question_header.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_magnifier_field.dart';
import 'package:vowl/features/reading/find_word_meaning/presentation/widgets/find_word_meaning_result.dart';

class FindWordMeaningScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FindWordMeaningScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.findWordMeaning,
  });

  @override
  State<FindWordMeaningScreen> createState() => _FindWordMeaningScreenState();
}

class _FindWordMeaningScreenState extends State<FindWordMeaningScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  Offset _lensPos = const Offset(200, 300);
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

  void _onLensMove(Offset position) {
    if (_isAnswered) return;
    setState(() {
      _lensPos = position;
      _hapticService.selection();
    });
  }

  void _onWordTap(String word, String correct) {
    if (_isAnswered) return;

    bool isCorrect = word.trim().toLowerCase() == correct.trim().toLowerCase();

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
          final isRetry = _isAnswered && state.lastAnswerCorrect == null;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            setState(() {
              _lastProcessedIndex = state.currentIndex;
              _isAnswered = false;
              _isCorrect = null;
              _lensPos = const Offset(200, 300);
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
            title: 'LEXICAL MASTER!',
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
                        FindWordMeaningInstruction(
                          primaryColor: theme.primaryColor,
                          instruction: quest.instruction,
                        ),
                        SizedBox(height: 24.h),
                        FindWordMeaningQuestionHeader(
                          text: quest.question ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 32.h),
                        FindWordMeaningMagnifierField(
                          passage: quest.passage ?? "",
                          correct: quest.targetWord ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                          lensPos: _lensPos,
                          isAnswered: _isAnswered,
                          onLensMove: _onLensMove,
                          onWordTap: (word) =>
                              _onWordTap(word, quest.targetWord ?? ""),
                        ),
                        if (_isAnswered) ...[
                          SizedBox(height: 30.h),
                          FindWordMeaningResult(
                            quest: quest,
                            isCorrect: _isCorrect == true,
                            isDark: isDark,
                          ),
                        ],
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
