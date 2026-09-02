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
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_instruction.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_pneumatic_port.dart';
import 'package:vowl/features/reading/cloze_test/presentation/widgets/cloze_test_fuel_cells.dart';
import 'package:vowl/core/presentation/game_mechanics/dynamic_anagram_wrapper.dart';

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

  final ValueNotifier<String?> _dockedOption = ValueNotifier(null);
  final ValueNotifier<String?> _pendingDockedOption = ValueNotifier(null);
  final ValueNotifier<bool> _isAnswered = ValueNotifier(false);
  final ValueNotifier<bool?> _isCorrect = ValueNotifier(null);
  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _dockedOption.dispose();
    _pendingDockedOption.dispose();
    _isAnswered.dispose();
    _isCorrect.dispose();
    _showConfetti.dispose();
    _scrollController.dispose();
    super.dispose();
  }
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
    if (_isAnswered.value || _pendingDockedOption.value != null) return;
    _hapticService.selection();
    _pendingDockedOption.value = option;
  }

  void _submitFinalAnswer(bool nailedTyping, String correct) {
    if (_pendingDockedOption.value == null) return;

    if (!nailedTyping) {
      _hapticService.error();
      _soundService.playWrong();
      _dockedOption.value = _pendingDockedOption.value;
      _isAnswered.value = true;
      _isCorrect.value = false;
      context.read<ReadingBloc>().add(const SubmitAnswer(false));
      return;
    }

    final selected = _pendingDockedOption.value!;
    _dockedOption.value = _pendingDockedOption.value;
    _submitAnswer(selected, correct);
  }

  void _submitAnswer(String selected, String correct) {
    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    if (isCorrect) {
      _hapticService.success();
      _soundService.playCorrect();
      _isAnswered.value = true;
      _isCorrect.value = true;
      context.read<ReadingBloc>().add(const SubmitAnswer(true));
    } else {
      _hapticService.error();
      _soundService.playWrong();
      _isAnswered.value = true;
      _isCorrect.value = false;
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
          final isRetry = _isAnswered.value && !state.answerStatus.isAnswered;
          final livesChanged =
              _lastLives != null && state.livesRemaining > _lastLives!;

          if (isNewQuestion || isRetry || livesChanged) {
            _lastProcessedIndex = state.currentIndex;
            _isAnswered.value = false;
            _isCorrect.value = null;
            _dockedOption.value = null;
            _pendingDockedOption.value = null;
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
            title: context.tr('reading_games.semantic_master', fallback: 'SEMANTIC MASTER!'),
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final ReadingQuest? quest = (state is ReadingLoaded)
            ? state.currentQuest as ReadingQuest?
            : null;

        return ListenableBuilder(
          listenable: Listenable.merge([_isAnswered, _isCorrect, _showConfetti, _dockedOption, _pendingDockedOption]),
          builder: (context, _) {
            return ReadingBaseLayout(
              gameType: widget.gameType,
              level: widget.level,
              isAnswered: _isAnswered.value,
              isCorrect: _isCorrect.value,
              showConfetti: _showConfetti.value,
          onContinue: () =>
              context.read<ReadingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<ReadingBloc>().add(const ReadingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    RawScrollbar(
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
                                        _dockedOption.value ?? _pendingDockedOption.value,
                                    wordCategory: quest.wordCategory,
                                    isAnswered: _isAnswered.value,
                                    onDock: (opt) =>
                                        _onDock(opt, quest.correctAnswer ?? ""),
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
                                  SizedBox(height: 40.h),
                                  ClozeTestFuelCells(
                                    options: quest.options ?? [],
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                    dockedOption:
                                        _dockedOption.value ?? _pendingDockedOption.value,
                                  ),
                                  SizedBox(height: (_pendingDockedOption.value != null && !_isAnswered.value) ? 380.h : 60.h),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_pendingDockedOption.value != null && !_isAnswered.value)
                      DynamicAnagramWrapper(
                        expectedText: quest.targetWord ?? quest.correctAnswer ?? "",
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, quest.correctAnswer ?? ""),
                        onFailed: () => _submitFinalAnswer(false, quest.correctAnswer ?? ""),
                      ),
                  ],
                ),
            );
          },
        );
      },
    );
  }
}
