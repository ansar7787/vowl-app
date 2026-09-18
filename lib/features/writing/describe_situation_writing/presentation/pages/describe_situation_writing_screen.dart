import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/mixins/writing_game_screen_mixin.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_instruction.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_prompt_card.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_writing_area.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_constellation_map.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';

class DescribeSituationScreen extends StatefulWidget {
  final int level;
  final GameSubtype gameType;
  const DescribeSituationScreen({
    super.key,
    required this.level,
    this.gameType = GameSubtype.describeSituationWriting,
  });

  @override
  State<DescribeSituationScreen> createState() =>
      _DescribeSituationScreenState();
}

class _DescribeSituationScreenState extends State<DescribeSituationScreen> with WritingGameScreenMixin {
  @override
  GameSubtype get gameType => widget.gameType;

  @override
  int get level => widget.level;

  @override
  String getCompletionTitle(BuildContext context) => 'LEVEL COMPLETE!';

      final _textController = TextEditingController();

  final ValueNotifier<List<String>> _usedKeywords = ValueNotifier([]);
  final ValueNotifier<int?> _expandedEmojiIndex = ValueNotifier(null);

    final ValueNotifier<bool> _showSpeakToConfirm = ValueNotifier(false);
  final ValueNotifier<int> _wordCount = ValueNotifier(0);
  WritingQuest? _lastQuest;
  final ValueNotifier<bool> _isSubmitting = ValueNotifier(false);

  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    isAnsweredNotifier.addListener(() {
      if (isAnsweredNotifier.value && mounted && _scrollController.hasClients) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && _scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });

    _scrollController = ScrollController();
    initWritingGame();
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _usedKeywords.dispose();
    _expandedEmojiIndex.dispose();
        _showSpeakToConfirm.dispose();
    _wordCount.dispose();
    _isSubmitting.dispose();
    disposeWritingGame();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    _wordCount.value = words;
  }

  void _onEmojiTap(int index, bool isAnswered) {
    if (isAnswered) return;
    hapticService.selection();
    _expandedEmojiIndex.value = (_expandedEmojiIndex.value == index
        ? null
        : index);
  }

  void _injectKeyword(String keyword, bool isAnswered) {
    if (isAnswered) return;
    hapticService.selection();

    final text = _textController.text;
    final selection = _textController.selection;

    String newText;
    int newCursorPosition;
    String insertText = keyword;
    if (selection.isValid) {
      final before = text.substring(0, selection.start);
      final after = text.substring(selection.end);
      if (before.isNotEmpty &&
          !before.endsWith(' ') &&
          !before.endsWith('\n')) {
        insertText = ' $insertText';
      }
      if (after.isNotEmpty &&
          !after.startsWith(' ') &&
          !after.startsWith('\n')) {
        insertText = '$insertText ';
      }
      newText = text.replaceRange(selection.start, selection.end, insertText);
      newCursorPosition = selection.start + insertText.length;
    } else {
      if (text.isNotEmpty && !text.endsWith(' ') && !text.endsWith('\n')) {
        insertText = ' $insertText';
      }
      newText = text + insertText;
      newCursorPosition = newText.length;
    }

    _textController.text = newText;
    _textController.selection = TextSelection.collapsed(
      offset: newCursorPosition,
    );

    if (!_usedKeywords.value.contains(keyword)) {
      _usedKeywords.value = List.from(_usedKeywords.value)..add(keyword);
    }
    _expandedEmojiIndex.value = null;
  }

  Future<void> _submitAnswer(
    int minWords,
    List<String> availableKeywords,
    bool isAnswered,
  ) async {
    if (isAnswered ||
        _textController.text.trim().isEmpty ||
        _isSubmitting.value) {
      return;
    }

    _isSubmitting.value = true;

    final rawText = _textController.text.trim();
    if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
      CustomSnackBar.show(
        context: context,
        message: "Please start your description with a capital letter.",
        type: CustomSnackBarType.warning,
      );
      hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    final lastChar = rawText.isNotEmpty ? rawText[rawText.length - 1] : '';
    if (!['.', '!', '?'].contains(lastChar)) {
      CustomSnackBar.show(
        context: context,
        message:
            "Please end your description with proper punctuation (., !, or ?).",
        type: CustomSnackBarType.warning,
      );
      hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    final composedText = rawText.toLowerCase();

    int matchedCount = 0;
    for (var kw in availableKeywords) {
      if (composedText.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }

    if (_wordCount.value < minWords) {
      CustomSnackBar.show(
        context: context,
        message: "Keep writing! You need at least $minWords words.",
        type: CustomSnackBarType.info,
      );
      hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    if (matchedCount < 2) {
      CustomSnackBar.show(
        context: context,
        message: "Inject at least 2 narrative keywords from the emojis!",
        type: CustomSnackBarType.warning,
      );
      hapticService.selection();
      _isSubmitting.value = false;
      return;
    }

    final wordsList = composedText.split(RegExp(r'\s+'));
    final uniqueWords = wordsList.toSet();
    if (uniqueWords.length < (minWords * 0.5).ceil()) {
      CustomSnackBar.show(
        context: context,
        message: "Your description lacks variety. Try using different words!",
        type: CustomSnackBarType.warning,
      );
      hapticService.warning();
      _isSubmitting.value = false;
      return;
    }

    int nonKeywordCount = 0;
    for (var word in wordsList) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w\s]'), '');
      if (!availableKeywords.any((kw) => kw.toLowerCase() == cleanWord)) {
        nonKeywordCount++;
      }
    }

    // We require at least 50% of the minimum words to be "glue/structure" words
    // to prevent students from just chaining booster keywords together (word salad).
    if (nonKeywordCount < (minWords * 0.5).ceil()) {
      CustomSnackBar.show(
        context: context,
        message:
            "This looks like a list of keywords! Please write full, complete sentences connecting the words.",
        type: CustomSnackBarType.warning,
      );
      hapticService.warning();
      _isSubmitting.value = false;
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, rawText)) {
      _isSubmitting.value = false;
      return;
    }

    // ML Kit Language ID Gibberish Check
    final langIdService = di.sl<LanguageIdService>();
    final language = await langIdService.identifyLanguage(composedText);

    if (!mounted) return;

    if (language != 'en') {
      CustomSnackBar.show(
        context: context,
        message:
            "Your answer must be written in English. Please write a natural sentence!",
        type: CustomSnackBarType.warning,
      );
      hapticService.warning();
      _isSubmitting.value = false;
      return;
    }

    hapticService.success();
    soundService.playCorrect();

    soundService.playCorrect();

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

        final emojis = activeQuest?.emojis ?? ["🌍", "💧", "🔬", "🚀"];
        final rawKeywords =
            activeQuest?.keywords ??
            {
              "0": ["VENTING", "MAGMA", "PLUME"],
              "1": ["OCEANIC", "THERMAL", "PRESSURE"],
              "2": ["MINERAL", "CHEMICAL", "HYDROUS"],
              "3": ["CREATURE", "BENTHIC", "ABYSSAL"],
            };

        final allKeywordPool = rawKeywords.values
            .expand((element) => element)
            .toList();
        final minWords = activeQuest?.minWords ?? 15;
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
              _isSubmitting,
              _expandedEmojiIndex,
              _usedKeywords,
            ]),
            builder: (context, _) {
              return activeQuest == null
                  ? GameShimmerLoading(primaryColor: theme.primaryColor)
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
                                      DescribeSituationInstruction(
                                        primaryColor: theme.primaryColor,
                                        instruction: activeQuest.instruction,
                                      ),
                                      SizedBox(height: 24.h),

                                      DescribeSituationPromptCard(
                                        prompt: activeQuest.situation ?? "",
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 24.h),

                                      DescribeSituationWritingArea(
                                        textController: _textController,
                                        minWords: minWords,
                                        wordCount: _wordCount.value,
                                        usedKeywords: _usedKeywords.value,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                      ),
                                      SizedBox(height: 24.h),

                                      DescribeSituationConstellationMap(
                                        emojis: emojis,
                                        keywords: rawKeywords,
                                        color: theme.primaryColor,
                                        isDark: isDark,
                                        expandedEmojiIndex:
                                            _expandedEmojiIndex.value,
                                        onEmojiTap: (idx) =>
                                            _onEmojiTap(idx, isAnswered),
                                        onInjectKeyword: (kw) =>
                                            _injectKeyword(kw, isAnswered),
                                      ),
                                      if (activeQuest.modelAnswer != null &&
                                          isAnswered) ...[
                                        SizedBox(height: 32.h),
                                        Container(
                                          padding: EdgeInsets.all(20.r),
                                          decoration: BoxDecoration(
                                            color: theme.primaryColor
                                                .withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              20.r,
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
                                              Text(
                                                "MODEL ANSWER",
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: theme.primaryColor,
                                                  letterSpacing: 2,
                                                ),
                                              ),
                                              SizedBox(height: 12.h),
                                              Text(
                                                activeQuest.modelAnswer!,
                                                style: TextStyle(
                                                  fontFamily: 'Outfit',
                                                  fontSize: 14.sp,
                                                  color: isDark
                                                      ? Colors.white70
                                                      : Colors.black87,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: 30.h),
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
                                            minWords,
                                            allKeywordPool,
                                            isAnswered,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            height: 60.h,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(20.r),
                                              color:
                                                  _wordCount.value >= minWords
                                                  ? theme.primaryColor
                                                  : Colors.grey,
                                              boxShadow: [
                                                if (_wordCount.value >=
                                                    minWords)
                                                  BoxShadow(
                                                    color: theme.primaryColor
                                                        .withValues(alpha: 0.3),
                                                    blurRadius: 15,
                                                  ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                "SEAL NARRATIVE",
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
                                        height: !isAnswered ? MediaQuery.viewInsetsOf(context).bottom + 40.h : 160.h,
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
                            expectedText: _textController.text.trim(),
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
