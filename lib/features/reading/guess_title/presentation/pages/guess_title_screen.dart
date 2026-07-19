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
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_instruction.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_cargo_crate.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_label_rack.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_result.dart';

class GuessTitleScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const GuessTitleScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.guessTitle,
  });

  @override
  State<GuessTitleScreen> createState() => _GuessTitleScreenState();
}

class _GuessTitleScreenState extends State<GuessTitleScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  String? _selectedTitle;
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

  void _submitAnswer(String selected, String correct) {
    if (_isAnswered) return;
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    setState(() {
      _isAnswered = true;
      _isCorrect = isCorrect;
      _selectedTitle = selected;
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
              _selectedTitle = null;
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
            title: 'TITLE EXPERT!',
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
                        GuessTitleInstruction(
                          primaryColor: theme.primaryColor,
                          instruction: quest.instruction,
                        ),
                        SizedBox(height: 24.h),
                        GuessTitleCargoCrate(
                          passage: quest.passage ?? "",
                          correct: quest.correctAnswer ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                          selectedTitle: _selectedTitle,
                          isAnswered: _isAnswered,
                          isCorrect: _isCorrect,
                          onAccept: (title) =>
                              _submitAnswer(title, quest.correctAnswer ?? ""),
                        ),
                        SizedBox(height: 32.h),
                        GuessTitleLabelRack(
                          labels: quest.options ?? [],
                          correct: quest.correctAnswer ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                          selectedTitle: _selectedTitle,
                          isAnswered: _isAnswered,
                        ),
                        if (_isAnswered) ...[
                          SizedBox(height: 30.h),
                          GuessTitleResult(
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
