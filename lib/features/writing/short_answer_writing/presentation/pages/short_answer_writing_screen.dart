import 'package:vowl/core/utils/instruction_helper.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_instruction.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_quill_prompt.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_booster_tokens.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_inkwell.dart';

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

class _ShortAnswerScreenState extends State<ShortAnswerScreen>
    with
        GameScreenMixin<ShortAnswerScreen>,
        WritingGameScreenMixin<ShortAnswerScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final _answerController = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  final ValueNotifier<double> _inkLevel = ValueNotifier(0.0);
  final ValueNotifier<int> _wordCount = ValueNotifier(0);
  WritingQuest? _lastQuest;

  int _strikeCount = 0;
  String? _savedTextForRetry;

  void _handleValidationFailure(
    String message, {
    CustomSnackBarType type = CustomSnackBarType.warning,
  }) {
    _strikeCount++;
    if (_strikeCount >= 3) {
      _savedTextForRetry = _answerController.text;
      if (_lastQuest != null) {
        submitWrongAnswer(quest: _lastQuest!);
      }
    } else {
      CustomSnackBar.show(
        context: context,
        message: "$message (${3 - _strikeCount} tries left)",
        type: type,
      );
      if (type == CustomSnackBarType.warning) {
        hapticService.warning();
      } else {
        hapticService.selection();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initWritingGame();
    _answerController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    _inkLevel.dispose();
    _wordCount.dispose();
    disposeWritingGame();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _answerController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    _wordCount.value = words;
    _inkLevel.value = (text.length / 75).clamp(0.0, 1.0);
  }

  Future<void> _submitAnswer(
    List<String> targetKeywords,
    bool isAnswered,
  ) async {
    if (isAnswered || _answerController.text.trim().isEmpty) return;

    final rawText = _answerController.text.trim();
    if (!RegExp(r'^[A-Z]').hasMatch(
      rawText.trimLeft().replaceAll(
        RegExp(
          r'^["'
          "'"
          r']',
        ),
        '',
      ),
    )) {
      _handleValidationFailure(
        "Please start your answer with a capital letter.",
      );
      return;
    }

    final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
    if (!['.', '!', '?', '"', "'"].contains(lastChar)) {
      _handleValidationFailure(
        "Please end your answer with proper punctuation (., !, or ?).",
      );
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

    if (_wordCount.value < 4) {
      _handleValidationFailure(
        "Keep writing! A valid answer requires at least 4 words.",
        type: CustomSnackBarType.info,
      );
      return;
    }

    // --- ML KIT LANGUAGE ID CHECK ---
    final languageIdService = di.sl<LanguageIdService>();
    final String languageCode = await languageIdService.identifyLanguage(
      rawText,
    );

    if (!mounted) return;

    if (languageCode != 'en') {
      _handleValidationFailure(
        "Your answer must be written in English. Please write a natural sentence!",
      );
      return;
    }

    // --- GIBBERISH LOOPHOLE CHECKS ---
    if (!GibberishDetectorService.isNaturalSentence(context, rawText)) return;
    // ---------------------------------

    if (matchedCount < targetKeywords.length) {
      _handleValidationFailure("Use all key words to complete your answer!");
      return;
    }

    hapticService.success();
    submitCorrectAnswer();
  }

  @override
  void onQuestionReset() {
    _inkLevel.value = 0.0;
    _wordCount.value = 0;

    if (_savedTextForRetry != null) {
      _answerController.text = _savedTextForRetry!;
      _savedTextForRetry = null;
      _strikeCount = 0;
      _onTextChanged();
    } else {
      _answerController.clear();
      _strikeCount = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = LevelThemeHelper.getTheme('writing', level: widget.level);

    return BlocConsumer<WritingBloc, WritingState>(
      listenWhen: (prev, curr) =>
          (curr is WritingGameComplete && prev is! WritingGameComplete) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
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
          showConfetti: showConfettiNotifier.value,
          useScrolling: false,
          disablePadding: true,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              showConfettiNotifier,
              _inkLevel,
              _wordCount,
            ]),
            builder: (context, _) {
              return quest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
                  : RawScrollbar(
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
                                  ShortAnswerInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction:
                                        InstructionHelper.getInstruction(quest),
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
                                    focusNode: _focusNode,
                                    isAnswered: isAnswered,
                                    wordCount: _wordCount.value,
                                    inkLevel: _inkLevel.value,
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
                                        color: theme.primaryColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          16.r,
                                        ),
                                        border: Border.all(
                                          color: theme.primaryColor.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                  fontWeight: FontWeight.w700,
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
                                              color: isDark
                                                  ? Colors.white
                                                  : Colors.black87,
                                              height: 1.5,
                                            ),
                                          ),
                                          if (quest.explanation != null &&
                                              quest
                                                  .explanation!
                                                  .isNotEmpty) ...[
                                            SizedBox(height: 12.h),
                                            Container(
                                              padding: EdgeInsets.all(12.r),
                                              decoration: BoxDecoration(
                                                color: isDark
                                                    ? Colors.black26
                                                    : Colors.black.withValues(
                                                        alpha: 0.03,
                                                      ),
                                                borderRadius:
                                                    BorderRadius.circular(12.r),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.info_outline_rounded,
                                                    size: 16.r,
                                                    color: theme.primaryColor,
                                                  ),
                                                  SizedBox(width: 8.w),
                                                  Expanded(
                                                    child: Text(
                                                      quest.explanation!,
                                                      style: TextStyle(
                                                        fontFamily: 'Outfit',
                                                        fontSize: 13.sp,
                                                        color: isDark
                                                            ? Colors.white70
                                                            : Colors.black87,
                                                        height: 1.4,
                                                        fontStyle:
                                                            FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  if (!isAnswered && livesRemaining > 0) ...[
                                    ScaleButton(
                                      onTap: () => _submitAnswer(
                                        targetKeywords,
                                        isAnswered,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        height: 60.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            30.r,
                                          ),
                                          color: _wordCount.value >= 4
                                              ? theme.primaryColor
                                              : Colors.grey,
                                          boxShadow: [
                                            if (_wordCount.value >= 4)
                                              BoxShadow(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 15,
                                              ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.approval_rounded,
                                                color: Colors.white,
                                                size: 24.r,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                "SUBMIT",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  SizedBox(height: 40.h),
                                ],
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 120.h +
                                  MediaQuery.of(context).viewInsets.bottom,
                            ),
                          ),
                        ],
                      ),
                    );
            },
          ),
        );
      },
    );
  }
}
