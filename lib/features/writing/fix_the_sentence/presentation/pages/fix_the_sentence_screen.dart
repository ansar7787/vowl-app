import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_instruction.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_digital_blackboard.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_correction_options.dart';
import 'package:vowl/core/presentation/widgets/type_to_confirm_overlay.dart';

class FixTheSentenceScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const FixTheSentenceScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.fixTheSentence,
  });

  @override
  State<FixTheSentenceScreen> createState() => _FixTheSentenceScreenState();
}

class _FixTheSentenceScreenState extends State<FixTheSentenceScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();

  final List<Offset> _erasePoints = [];
  bool _isWiped = false;
  String? _selectedOption;
  String? _pendingSelectedOption;
  bool _showConfetti = false;
  int _erasedAmount = 0;
  WritingQuest? _lastQuest;
  List<String>? _shuffledOptions;
  final _ttsService = di.sl<TtsService>();

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
  }

  void _onErase(Offset localPosition, bool isAnswered) {
    if (isAnswered || _isWiped) return;
    setState(() {
      _erasePoints.add(localPosition);
      _erasedAmount++;
      if (_erasedAmount % 6 == 0) _hapticService.selection();
    });

    if (_erasedAmount > 35) {
      _hapticService.success();
      _soundService.playHint();
      setState(() => _isWiped = true);
    }
  }

  void _submitFinalAnswer(bool nailedTyping, WritingQuest quest) {
    if (_pendingSelectedOption == null) return;

    if (!nailedTyping) {
      _hapticService.error();
      _soundService.playWrong();
      setState(() {
        _selectedOption = _pendingSelectedOption;
      });
      context.read<WritingBloc>().add(const SubmitAnswer(false));
      return;
    }

    final selected = _pendingSelectedOption!;
    final correct = quest.correctAnswer ?? "";
    final bool isAnsCorrect = selected == correct;

    setState(() {
      _selectedOption = _pendingSelectedOption;
    });

    context.read<WritingBloc>().add(SubmitAnswer(isAnsCorrect));
    if (isAnsCorrect) {
      final fullText = quest.passage ?? "";
      final targetWord = quest.missingWord ?? "";
      final correctedText = fullText.replaceFirst(targetWord, selected);
      _ttsService.speak(correctedText);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && curr.lastAnswerCorrect == null),
      listener: (context, state) {
        if (state is WritingLoaded && state.lastAnswerCorrect == null) {
          setState(() {
            _isWiped = false;
            _selectedOption = null;
            _pendingSelectedOption = null;
            _erasePoints.clear();
            _erasedAmount = 0;
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'SYNTAX SURGEON!',
            enableDoubleUp: true,
          );
        }

        if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () =>
                context.read<WritingBloc>().add(const RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        if (isLoaded && state.currentQuest != _lastQuest) {
          _lastQuest = state.currentQuest;
          _shuffledOptions = List.from(_lastQuest!.options ?? [])..shuffle();
        }
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          isFinalFailure: isLoaded ? state.isFinalFailure : false,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
          onContinue: () =>
              context.read<WritingBloc>().add(const NextQuestion()),
          onHint: () =>
              context.read<WritingBloc>().add(const WritingHintUsed()),
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
                            FixTheSentenceInstruction(
                              isWiped: _isWiped,
                              primaryColor: theme.primaryColor,
                              instruction: quest.instruction,
                            ),
                            SizedBox(height: 32.h),

                            FixTheSentenceDigitalBlackboard(
                              fullText: quest.passage ?? "",
                              targetWord: quest.missingWord ?? "",
                              selectedReplacement:
                                  _selectedOption ?? _pendingSelectedOption,
                              isWiped: _isWiped,
                              erasePoints: _erasePoints,
                              onErase: (pos) => _onErase(pos, isAnswered),
                              color: theme.primaryColor,
                              isDark: isDark,
                            ),
                            SizedBox(height: 32.h),

                            if (_isWiped && !isAnswered)
                              FixTheSentenceWipedAlert(
                                primaryColor: theme.primaryColor,
                              ),
                            if (_isWiped && !isAnswered) SizedBox(height: 16.h),

                            if (_isWiped)
                              FixTheSentenceCorrectionOptions(
                                options:
                                    _shuffledOptions ?? quest.options ?? [],
                                correct: quest.correctAnswer ?? "",
                                color: theme.primaryColor,
                                isDark: isDark,
                                onSelect: (selected, correct) {
                                  if (isAnswered ||
                                      _pendingSelectedOption != null) {
                                    return;
                                  }
                                  setState(
                                    () => _pendingSelectedOption = selected,
                                  );
                                },
                              ),

                            SizedBox(height: 160.h),
                          ],
                        ),
                      ),
                    ),
                    if (_pendingSelectedOption != null && !isAnswered)
                      TypeToConfirmOverlay(
                        expectedText: _pendingSelectedOption!,
                        primaryColor: theme.primaryColor,
                        onConfirmed: () => _submitFinalAnswer(true, quest),
                        onSkipped: () => _submitFinalAnswer(false, quest),
                        allowSkip: true,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
