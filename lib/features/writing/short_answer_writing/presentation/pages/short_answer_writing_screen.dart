import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_instruction.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_quill_prompt.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_booster_tokens.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_inkwell.dart';
import 'package:vowl/core/presentation/game_mechanics/context_sentence_builder.dart';

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
  final _hapticService = di.sl<HapticService>();
  final _answerController = TextEditingController();

  bool _showConfetti = false;
  bool _showContextSentence = false;
  double _inkLevel = 0.0;
  int _wordCount = 0;
  WritingQuest? _lastQuest;

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

  Future<void> _submitAnswer(
    List<String> targetKeywords,
    bool isAnswered,
  ) async {
    if (isAnswered || _answerController.text.trim().isEmpty) return;

    final rawText = _answerController.text.trim();
    if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
      CustomSnackBar.show(
        context: context,
        message: "Please start your answer with a capital letter.",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
    if (!['.', '!', '?'].contains(lastChar)) {
      CustomSnackBar.show(
        context: context,
        message: "Please end your answer with proper punctuation (., !, or ?).",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    final text = rawText.toLowerCase();

    int matchedCount = 0;
    for (var kw in targetKeywords) {
      if (RegExp(
        r'\b' + RegExp.escape(kw.toLowerCase()) + r'\b',
      ).hasMatch(text)) {
        matchedCount++;
      }
    }

    if (_wordCount < 10) {
      CustomSnackBar.show(
        context: context,
        message: "Keep writing! A valid answer requires at least 10 words.",
        type: CustomSnackBarType.info,
      );
      _hapticService.selection();
      return;
    }

    // --- ML KIT LANGUAGE ID CHECK ---
    final languageIdService = di.sl<LanguageIdService>();
    final String languageCode = await languageIdService.identifyLanguage(
      rawText,
    );

    if (!mounted) return;

    if (languageCode != 'en') {
      CustomSnackBar.show(
        context: context,
        message:
            "Your answer must be written in English. Please write a natural sentence!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    // --- GIBBERISH LOOPHOLE CHECKS ---
    if (!GibberishDetectorService.isNaturalSentence(context, rawText)) return;
    // ---------------------------------

    if (matchedCount < 2) {
      CustomSnackBar.show(
        context: context,
        message: "Use at least 2 key terms to complete your answer!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      return;
    }

    _hapticService.success();
    setState(() {
      _showContextSentence = true;
    });
  }

  void _onContextSentenceConfirmed() {
    setState(() => _showContextSentence = false);
    context.read<WritingBloc>().add(const SubmitAnswer(true));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          setState(() {
            _answerController.clear();
            _inkLevel = 0.0;
            _wordCount = 0;
            _showContextSentence = false;
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
        if (isLoaded && state.currentQuest != _lastQuest) {
          _lastQuest = state.currentQuest;
        }
        final WritingQuest? quest = isLoaded ? state.currentQuest : _lastQuest;

        final targetKeywords =
            quest?.options ?? ["bacteria", "sulfide", "chemosynthesis"];
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = isLoaded ? state.isFinalFailure : false;
        final int livesRemaining = state.livesRemaining;

        return WritingBaseLayout(
          gameType: widget.gameType,
          level: widget.level,
          isAnswered: isAnswered,
          isCorrect: isCorrect,
          isFinalFailure: isFinalFailure,
          showConfetti: _showConfetti,
          useScrolling: false,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: quest == null
              ? const SizedBox()
              : Stack(
                  children: [
                    CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          children: [
                            SizedBox(height: 16.h),
                            ShortAnswerInstruction(
                              primaryColor: theme.primaryColor,
                              instruction: quest.instruction,
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

                            if ((isCorrect == true || isFinalFailure) &&
                                quest.sampleAnswer != null)
                              Container(
                                margin: EdgeInsets.only(bottom: 36.h),
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: theme.primaryColor.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.lightbulb_rounded,
                                          color: theme.primaryColor,
                                          size: 18.r,
                                        ),
                                        SizedBox(width: 8.w),
                                        Text(
                                          "SAMPLE ANSWER",
                                          style: TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 12.sp,
                                            fontWeight: FontWeight.w900,
                                            color: theme.primaryColor,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      quest.sampleAnswer!,
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontSize: 14.sp,
                                        color: isDark ? Colors.white : Colors.black87,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (!_showContextSentence && !isAnswered && livesRemaining > 0)
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
                            SizedBox(height: isAnswered ? 160.h : 60.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (_showContextSentence && !isAnswered)
                  ContextSentenceBuilder(
                    targetKeyword: targetKeywords.first,
                    primaryColor: theme.primaryColor,
                    onConfirmed: _onContextSentenceConfirmed,
                    onSkipped: () {
                      setState(() => _showContextSentence = false);
                      context.read<WritingBloc>().add(const SubmitAnswer(false));
                    },
                    allowSkip: true,
                    isPositioned: true,
                  ),
              ],
            ),
        );
      },
    );
  }
}
