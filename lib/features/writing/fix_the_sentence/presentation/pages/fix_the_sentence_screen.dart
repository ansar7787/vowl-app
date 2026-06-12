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
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_instruction.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_digital_blackboard.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_correction_options.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_explanation_card.dart';

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
  bool _showConfetti = false;
  int _erasedAmount = 0;

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
      _soundService.playCorrect();
      setState(() => _isWiped = true);
    }
  }

  void _selectReplacement(String selected, String correct, bool isAnswered) {
    if (isAnswered) return;

    bool isCorrect =
        selected.trim().toLowerCase() == correct.trim().toLowerCase();

    setState(() {
      _selectedOption = selected;
    });

    context.read<WritingBloc>().add(SubmitAnswer(isCorrect));
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
        } else if (state is WritingGameOver) {
          GameDialogHelper.showGameOver(
            context,
            onRestore: () => context.read<WritingBloc>().add(RestoreLife()),
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded ? state.currentQuest : null;
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 16.h),
                        FixTheSentenceInstruction(
                          isWiped: _isWiped,
                          primaryColor: theme.primaryColor,
                        ),
                        SizedBox(height: 32.h),

                        FixTheSentenceDigitalBlackboard(
                          fullText: quest.passage ?? "",
                          targetWord: quest.missingWord ?? "",
                          selectedReplacement: _selectedOption,
                          isWiped: _isWiped,
                          erasePoints: _erasePoints,
                          onErase: (pos) => _onErase(pos, isAnswered),
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 32.h),

                        if (_isWiped && !isAnswered) ...[
                          FixTheSentenceWipedAlert(
                            primaryColor: theme.primaryColor,
                          ),
                          SizedBox(height: 20.h),
                          FixTheSentenceCorrectionOptions(
                            options: quest.options ?? [],
                            correct: quest.correctAnswer ?? "",
                            color: theme.primaryColor,
                            isDark: isDark,
                            onSelect: (selected, correct) => _selectReplacement(selected, correct, isAnswered),
                          ),
                        ],

                        if (isAnswered) ...[
                          SizedBox(height: 30.h),
                          FixTheSentenceExplanationCard(
                            quest: quest,
                            isCorrect: isCorrect == true,
                            primaryColor: theme.primaryColor,
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
