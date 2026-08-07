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
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_instruction.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_pneumatic_port.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_fuel_cells.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';

class ClozeTestScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ClozeTestScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.clozeTest,
  });

  @override
  State<ClozeTestScreen> createState() => _ClozeTestScreenState();
}

class _ClozeTestScreenState extends State<ClozeTestScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  String? _dockedOption;
  String? _pendingDockedOption;
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

  void _onDock(String option, String correct) {
    if (_isAnswered || _pendingDockedOption != null) return;
    _hapticService.selection();
    setState(() => _pendingDockedOption = option);
  }

  void _submitFinalAnswer(bool nailedTyping, String correct) {
    if (_pendingDockedOption == null) return;

    if (!nailedTyping) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _dockedOption = _pendingDockedOption;
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      return;
    }

    final selected = _pendingDockedOption!;
    setState(() => _dockedOption = _pendingDockedOption);
    _submitAnswer(selected, correct);
  }

  void _submitAnswer(String selected, String correct) {
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      setState(() {
        _isAnswered = true;
        _isCorrect = true;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _isAnswered = true;
        _isCorrect = false;
      });
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
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
              _dockedOption = null;
              _pendingDockedOption = null;
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
            title: 'SEMANTIC MASTER!',
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
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            ClozeTestInstruction(
                              primaryColor: theme.primaryColor,
                              instruction: context.tr(
                                'games.clozeTest_instruction',
                                fallback:
                                    'Complete the sentence by docking the correct word.',
                              ),
                            ),
                            SizedBox(height: 32.h),

                            ClozeTestPneumaticPort(
                              text: quest.passage ?? "",
                              correct: quest.correctAnswer ?? "",
                              color: theme.primaryColor,
                              isDark: isDark,
                              dockedOption:
                                  _dockedOption ?? _pendingDockedOption,
                              isAnswered: _isAnswered,
                              onDock: (opt) =>
                                  _onDock(opt, quest.correctAnswer ?? ""),
                            ),
                            SizedBox(height: 40.h),

                            ClozeTestFuelCells(
                              options: quest.options ?? [],
                              color: theme.primaryColor,
                              isDark: isDark,
                              dockedOption:
                                  _dockedOption ?? _pendingDockedOption,
                            ),

                            SizedBox(height: 180.h),
                          ],
                        ),
                      ),
                    ),
                    if (_pendingDockedOption != null && !_isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _pendingDockedOption!,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () =>
                            _submitFinalAnswer(true, quest.correctAnswer ?? ""),
                        onSkipped: () => _submitFinalAnswer(
                          false,
                          quest.correctAnswer ?? "",
                        ),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
