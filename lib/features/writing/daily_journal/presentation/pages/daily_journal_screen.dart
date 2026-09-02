import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
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
import 'package:vowl/core/presentation/game_mechanics/speak_to_confirm_overlay.dart';

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

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _controller = TextEditingController();

  final ValueNotifier<bool> _showConfetti = ValueNotifier(false);
  final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);
  final ValueNotifier<int> _wordCount = ValueNotifier(0);
  final ValueNotifier<double> _journalProgress = ValueNotifier(0.0);
  WritingQuest? _lastQuest;
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    _showConfetti.dispose();
    _showSpeakToConfirm.dispose();
    _wordCount.dispose();
    _journalProgress.dispose();
    _isSubmitting.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    _wordCount.value = words;
    _journalProgress.value = (text.length / 80).clamp(0.0, 1.0);
  }

  Future<void> _submitAnswer(
    List<String> targetKeywords,
    bool isAnswered,
  ) async {
    if (isAnswered || _controller.text.trim().isEmpty || _isSubmitting.value)
      return;

    _isSubmitting.value = true;

    final rawText = _controller.text.trim();
    if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
      CustomSnackBar.show(
        context: context,
        message: "Please start your journal entry with a capital letter.",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
    if (!['.', '!', '?'].contains(lastChar)) {
      CustomSnackBar.show(
        context: context,
        message:
            "Please end your entry with a full stop, exclamation mark, or question mark.",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    final text = rawText.toLowerCase();

    int matchedCount = 0;
    for (var kw in targetKeywords) {
      if (text.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }

    if (_wordCount.value < 10) {
      CustomSnackBar.show(
        context: context,
        message:
            "Keep writing! A valid journal entry requires at least 10 words.",
        type: CustomSnackBarType.info,
      );
      _hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    if (matchedCount < 2) {
      CustomSnackBar.show(
        context: context,
        message: "Use at least 2 reflection terms to complete your entry!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      _isSubmitting.value = false;
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
      CustomSnackBar.show(
        context: context,
        message:
            "Your answer must be written in English. Please write a natural sentence!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.warning();
      _isSubmitting.value = false;
      return;
    }

    _hapticService.success();
    _soundService.playCorrect();

    _soundService.playCorrect();

    _showSpeakToConfirm.value = true;
    _isSubmitting.value = false;
  }

  void _onSpeakConfirmed() {
    _showSpeakToConfirm.value = false;
    context.read<WritingBloc>().add(const SubmitAnswer(true));
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
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          _controller.clear();
          _wordCount.value = 0;
          _journalProgress.value = 0.0;
          _showSpeakToConfirm.value = false;
        }
        if (state is WritingGameComplete) {
          _showConfetti.value = true;
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'REFLECTIVE MASTER!',
            enableDoubleUp: true,
          );
        }
      },
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
          showConfetti: _showConfetti.value,
          useScrolling: false,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: ListenableBuilder(
            listenable: Listenable.merge([
              _showConfetti,
              _showSpeakToConfirm,
              _wordCount,
              _journalProgress,
              _isSubmitting,
            ]),
            builder: (context, _) {
              return activeQuest == null
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
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                            border: Border.all(
                                              color: theme.primaryColor
                                                  .withValues(alpha: 0.3),
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
                                                    "GUIDING QUESTIONS",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 10.sp,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: theme.primaryColor,
                                                      letterSpacing: 2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 8.h),
                                              ...activeQuest.promptQuestions!
                                                  .map(
                                                    (q) => Padding(
                                                      padding: EdgeInsets.only(
                                                        bottom: 4.h,
                                                      ),
                                                      child: Text(
                                                        "• $q",
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 12.sp,
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
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 24.w,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (!_showSpeakToConfirm.value &&
                                          !isAnswered)
                                        ScaleButton(
                                          onTap: () => _submitAnswer(
                                            targetKeywords,
                                            isAnswered,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color: _wordCount.value >= 10
                                                  ? theme.primaryColor
                                                  : Colors.grey,
                                              boxShadow: [
                                                if (_wordCount.value >= 10)
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 15,
                                                  ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "CRYSTALLIZE MEMORY",
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
                                      SizedBox(
                                        height: !isAnswered ? 380.h : 160.h,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_showSpeakToConfirm.value && !isAnswered)
                          SpeakToConfirmOverlay(
                            expectedText: _controller.text.trim(),
                            primaryColor: theme.primaryColor,
                            onConfirmed: _onSpeakConfirmed,
                            onSkipped: () {
                              _showSpeakToConfirm.value = false;
                              context.read<WritingBloc>().add(
                                const SubmitAnswer(false),
                              );
                            },
                          ),
                      ],
                    );
            },
          ),
        );
      },
    );
  }
}
