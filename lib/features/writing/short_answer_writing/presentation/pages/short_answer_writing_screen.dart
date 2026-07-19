import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_instruction.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_quill_prompt.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_booster_tokens.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_inkwell.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_explanation_card.dart';

class ShortAnswerScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const ShortAnswerScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.shortAnswerWriting,
  });

  @override
  State<ShortAnswerScreen> createState() => _ShortAnswerScreenState();
}

class _ShortAnswerScreenState extends State<ShortAnswerScreen> {
  final _answerController = TextEditingController();

  bool _showConfetti = false;
  double _inkLevel = 0.0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
    _answerController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _answerController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
      _inkLevel = (text.length / 75).clamp(0.0, 1.0);
    });
  }

  void _submitAnswer(List<String> targetKeywords, bool isAnswered) {
    if (isAnswered || _answerController.text.trim().isEmpty) return;

    final text = _answerController.text.trim().toLowerCase();

    int matchedCount = 0;
    for (var kw in targetKeywords) {
      if (text.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }

    bool isMinLengthMet = _wordCount >= 10;
    bool isKeywordsMet = matchedCount >= 2;

    final isCorrect = isMinLengthMet && isKeywordsMet;

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
            _answerController.clear();
            _inkLevel = 0.0;
            _wordCount = 0;
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CREATIVE AUTHOR!',
            enableDoubleUp: true,
          );
        }
      },
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        final targetKeywords =
            quest?.options ?? ["bacteria", "sulfide", "chemosynthesis"];
        final bool isAnswered = isLoaded && state.lastAnswerCorrect != null;
        final bool? isCorrect = isLoaded ? state.lastAnswerCorrect : null;
        final bool isFinalFailure = isLoaded ? state.isFinalFailure : false;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
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
                        ShortAnswerInstruction(
                          primaryColor: theme.primaryColor,
                        ),
                        SizedBox(height: 24.h),

                        ShortAnswerQuillPrompt(
                          prompt: quest.prompt ?? "",
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),

                        ShortAnswerBoosterTokens(
                          keywords: targetKeywords,
                          text: _answerController.text,
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),

                        ShortAnswerInkwell(
                          controller: _answerController,
                          isAnswered: isAnswered,
                          wordCount: _wordCount,
                          inkLevel: _inkLevel,
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 36.h),

                        if (!isAnswered)
                          ScaleButton(
                            onTap: () =>
                                _submitAnswer(targetKeywords, isAnswered),
                            child: Container(
                              width: double.infinity,
                              height: 60.h,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.r),
                                color: _wordCount >= 10
                                    ? theme.primaryColor
                                    : Colors.grey,
                                boxShadow: [
                                  if (_wordCount >= 10)
                                    BoxShadow(
                                      color: theme.primaryColor.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 15,
                                    ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "SEAL WITH WAX",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),

                        if (isAnswered) ...[
                          SizedBox(height: 30.h),
                          ShortAnswerExplanationCard(
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
