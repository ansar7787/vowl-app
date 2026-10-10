import 'package:vowl/core/presentation/mixins/game_screen_mixin.dart';
import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_instruction.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_prompt.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_booster_tokens.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_scratch_area.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class DailyJournalScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DailyJournalScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.dailyJournal,
  });

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen>
    with
        GameScreenMixin<DailyJournalScreen>,
        WritingGameScreenMixin<DailyJournalScreen> {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);
  final ValueNotifier<int> _wordCount = ValueNotifier(0);
  final ValueNotifier<double> _journalProgress = ValueNotifier(0.0);
  WritingQuest? _lastQuest;
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  int _strikeCount = 0;
  String? _savedTextForRetry;

  void _handleValidationFailure(
    String message, {
    CustomSnackBarType type = CustomSnackBarType.warning,
  }) {
    _strikeCount++;
    if (_strikeCount >= 3) {
      _savedTextForRetry = _controller.text;
      _isSubmitting.value = false;
      submitWrongAnswer(quest: _lastQuest!);
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
      _isSubmitting.value = false;
    }
  }

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _showSpeakToConfirm.addListener(() {
      if (_showSpeakToConfirm.value &&
          mounted &&
          _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          }
        });
      }
    });
    _scrollController = ScrollController();
    initWritingGame();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    _showSpeakToConfirm.dispose();
    _wordCount.dispose();
    _journalProgress.dispose();
    _isSubmitting.dispose();
    disposeWritingGame();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final words = text.isEmpty
        ? 0
        : text
              .split(RegExp(r'\s+'))
              .map((w) => w.replaceAll(RegExp(r'[^\w\s]'), ''))
              .where((w) => w.isNotEmpty)
              .length;
    _wordCount.value = words;
    _journalProgress.value = (text.length / 80).clamp(0.0, 1.0);
  }

  Future<void> _submitAnswer(
    List<String> targetKeywords,
    bool isAnswered,
  ) async {
    if (isAnswered || _controller.text.trim().isEmpty || _isSubmitting.value) {
      return;
    }

    _isSubmitting.value = true;

    final rawText = _controller.text.trim();
    if (rawText.isEmpty) return;

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
        "Please start your journal entry with a capital letter.",
      );
      return;
    }

    final lastChar = rawText[rawText.length - 1];
    if (!['.', '!', '?', '"', "'", '”'].contains(lastChar)) {
      _handleValidationFailure(
        "Please end your entry with proper punctuation (e.g., full stop).",
      );
      return;
    }

    final text = rawText.toLowerCase();

    int matchedCount = 0;
    for (var kw in targetKeywords) {
      final regExp = RegExp(r'\b' + RegExp.escape(kw.toLowerCase()));
      if (regExp.hasMatch(text)) {
        matchedCount++;
      }
    }

    if (_wordCount.value < 10) {
      _handleValidationFailure(
        "Keep writing! A valid journal entry requires at least 10 words.",
        type: CustomSnackBarType.info,
      );
      return;
    }

    if (matchedCount < 2) {
      _handleValidationFailure(
        "Use at least 2 target words to complete your entry!",
      );
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, rawText)) {
      _isSubmitting.value = false;
      return;
    }

    // ML Kit Language ID Gibberish Check
    final langIdService = di.sl<LanguageIdService>();
    final language = await langIdService.identifyLanguage(text);

    if (!mounted) return;

    if (language != 'en') {
      _handleValidationFailure(
        "Your answer must be written in English. Please write a natural sentence!",
      );
      return;
    }

    hapticService.success();
    soundService.playCorrect();

    _showSpeakToConfirm.value = true;
    _isSubmitting.value = false;
  }

  void _onSpeakConfirmed() {
    _showSpeakToConfirm.value = false;
    submitCorrectAnswer();
  }

  @override
  void onQuestionReset() {
    bool isNewQuest = true;
    if (mounted) {
      final bloc = context.read<WritingBloc>();
      if (bloc.state is WritingLoaded) {
        isNewQuest = (bloc.state as WritingLoaded).currentQuest != _lastQuest;
      }
    }

    _showSpeakToConfirm.value = false;
    _wordCount.value = 0;
    _journalProgress.value = 0.0;
    _isSubmitting.value = false;

    if (_savedTextForRetry != null && !isNewQuest) {
      _controller.text = _savedTextForRetry!;
      _savedTextForRetry = null;
      _strikeCount = 0;
      _onTextChanged();
    } else {
      _controller.clear();
      _savedTextForRetry = null;
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
          (curr is WritingGameOver && prev is! WritingGameOver) ||
          (curr is WritingLoaded && !curr.answerStatus.isAnswered),
      listener: onWritingStateChanged,
      builder: (context, state) {
        final isLoaded = state is WritingLoaded;
        final WritingQuest? quest = isLoaded
            ? state.currentQuest as WritingQuest?
            : null;

        if (quest != null) {
          _lastQuest = quest;
        }

        final activeQuest = quest ?? _lastQuest;

        final targetKeywords =
            activeQuest?.options ?? ["submersible", "mariana", "trench"];
        final bool isAnswered = isLoaded && state.answerStatus.isAnswered;
        final bool? isCorrect = isLoaded
            ? state.answerStatus.asBoolOrNull
            : null;
        final bool isFinalFailure = state.livesRemaining == 0;

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
              _showSpeakToConfirm,
              _wordCount,
              _journalProgress,
              _isSubmitting,
              _controller,
            ]),
            builder: (context, _) {
              return activeQuest == null
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
                                  DailyJournalInstruction(
                                    primaryColor: theme.primaryColor,
                                    instruction: activeQuest.instruction,
                                  ),
                                  SizedBox(height: 24.h),

                                  DailyJournalPrompt(
                                    text: activeQuest.prompt ?? "",
                                    primaryColor: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 16.h),
                                  if (activeQuest.promptQuestions != null)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16.w,
                                        vertical: 12.h,
                                      ),
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
                                                Icons.help_outline,
                                                color: theme.primaryColor,
                                                size: 16.sp,
                                              ),
                                              SizedBox(width: 8.w),
                                              Text(
                                                "Guiding Questions",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w600,
                                                  color: theme.primaryColor,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.h),
                                          ...activeQuest.promptQuestions!.map(
                                            (q) => Padding(
                                              padding: EdgeInsets.only(
                                                bottom: 6.h,
                                              ),
                                              child: Text(
                                                "• $q",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w400,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(height: 24.h),

                                  DailyJournalBoosterTokens(
                                    keywords: targetKeywords,
                                    text: _controller.text,
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 24.h),

                                  DailyJournalScratchArea(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    isAnswered: isAnswered,
                                    wordCount: _wordCount.value,
                                    journalProgress: _journalProgress.value,
                                    color: theme.primaryColor,
                                    isDark: isDark,
                                  ),
                                  SizedBox(height: 32.h),
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
                                  if (!_showSpeakToConfirm.value && !isAnswered)
                                    ScaleButton(
                                      onTap: () => _submitAnswer(
                                        targetKeywords,
                                        isAnswered,
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        height: 56.h,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            16.r,
                                          ),
                                          color: _wordCount.value >= 10
                                              ? theme.primaryColor
                                              : Colors.grey,
                                          boxShadow: [
                                            if (_wordCount.value >= 10)
                                              BoxShadow(
                                                color: theme.primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 10,
                                              ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            "SAVE ENTRY",
                                            style: TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 15.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          if (_showSpeakToConfirm.value && !isAnswered)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24.w),
                                child: SpeakToConfirmOverlay(
                                  expectedText: _controller.text.trim(),
                                  primaryColor: theme.primaryColor,
                                  onConfirmed: _onSpeakConfirmed,
                                  onSkipped: () {
                                    _showSpeakToConfirm.value = false;
                                    submitCorrectAnswer();
                                  },
                                ),
                              ),
                            ),
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: !isAnswered
                                  ? (_showSpeakToConfirm.value
                                        ? 20.h
                                        : (MediaQuery.of(
                                                    context,
                                                  ).viewInsets.bottom >
                                                  0
                                              ? MediaQuery.of(
                                                      context,
                                                    ).viewInsets.bottom +
                                                    20.h
                                              : 40.h))
                                  : 200.h, // Space for Feedback Card
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
