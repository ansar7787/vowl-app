import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_dialog_helper.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/custom_snack_bar.dart';
import 'package:vowl/core/utils/gibberish_detector_service.dart';
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_instruction.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_prompt_card.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_writing_area.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_constellation_map.dart';

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

class _DescribeSituationScreenState extends State<DescribeSituationScreen> {
  final _hapticService = di.sl<HapticService>();
  final _soundService = di.sl<SoundService>();
  final _textController = TextEditingController();

  final List<String> _usedKeywords = [];
  int? _expandedEmojiIndex;

  bool _showConfetti = false;
  int _wordCount = 0;
  WritingQuest? _lastQuest;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    context.read<WritingBloc>().add(
      FetchWritingQuests(gameType: widget.gameType, level: widget.level),
    );
    _textController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _textController.text.trim();
    final words = text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    setState(() {
      _wordCount = words;
    });
  }

  void _onEmojiTap(int index, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();
    setState(
      () => _expandedEmojiIndex = (_expandedEmojiIndex == index ? null : index),
    );
  }

  void _injectKeyword(String keyword, bool isAnswered) {
    if (isAnswered) return;
    _hapticService.selection();

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

    setState(() {
      if (!_usedKeywords.contains(keyword)) {
        _usedKeywords.add(keyword);
      }
      _expandedEmojiIndex = null;
    });
  }

  Future<void> _submitAnswer(
    int minWords,
    List<String> availableKeywords,
    bool isAnswered,
  ) async {
    if (isAnswered || _textController.text.trim().isEmpty || _isSubmitting) {
      return;
    }

    setState(() => _isSubmitting = true);

    final rawText = _textController.text.trim();
    if (!RegExp(r'^[A-Z]').hasMatch(rawText)) {
      CustomSnackBar.show(
        context: context,
        message: "Please start your description with a capital letter.",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      setState(() => _isSubmitting = false);
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
      _hapticService.selection();
      setState(() => _isSubmitting = false);
      return;
    }

    final composedText = rawText.toLowerCase();

    int matchedCount = 0;
    for (var kw in availableKeywords) {
      if (composedText.contains(kw.toLowerCase())) {
        matchedCount++;
      }
    }

    if (_wordCount < minWords) {
      CustomSnackBar.show(
        context: context,
        message: "Keep writing! You need at least $minWords words.",
        type: CustomSnackBarType.info,
      );
      _hapticService.selection();
      setState(() => _isSubmitting = false);
      return;
    }

    if (matchedCount < 2) {
      CustomSnackBar.show(
        context: context,
        message: "Inject at least 2 narrative keywords from the emojis!",
        type: CustomSnackBarType.warning,
      );
      _hapticService.selection();
      setState(() => _isSubmitting = false);
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
      _hapticService.warning();
      setState(() => _isSubmitting = false);
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
      _hapticService.warning();
      setState(() => _isSubmitting = false);
      return;
    }

    if (!GibberishDetectorService.isNaturalSentence(context, rawText)) {
      setState(() => _isSubmitting = false);
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
      _hapticService.warning();
      setState(() => _isSubmitting = false);
      return;
    }

    _hapticService.success();
    _soundService.playCorrect();

    context.read<WritingBloc>().add(SubmitAnswer(true));

    if (mounted) {
      setState(() => _isSubmitting = false);
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
      listener: (context, state) {
        if (state is WritingLoaded && !state.answerStatus.isAnswered) {
          setState(() {
            _usedKeywords.clear();
            _textController.clear();
            _expandedEmojiIndex = null;
          });
        }
        if (state is WritingGameComplete) {
          setState(() => _showConfetti = true);
          GameDialogHelper.showCompletion(
            context,
            xp: state.xpEarned,
            coins: state.coinsEarned,
            title: 'CREATIVE GENIUS!',
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
          showConfetti: _showConfetti,
          onContinue: () => context.read<WritingBloc>().add(NextQuestion()),
          onHint: () => context.read<WritingBloc>().add(WritingHintUsed()),
          child: activeQuest == null
              ? const SizedBox()
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
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
                          wordCount: _wordCount,
                          usedKeywords: _usedKeywords,
                          color: theme.primaryColor,
                          isDark: isDark,
                        ),
                        SizedBox(height: 24.h),

                        DescribeSituationConstellationMap(
                          emojis: emojis,
                          keywords: rawKeywords,
                          color: theme.primaryColor,
                          isDark: isDark,
                          expandedEmojiIndex: _expandedEmojiIndex,
                          onEmojiTap: (idx) => _onEmojiTap(idx, isAnswered),
                          onInjectKeyword: (kw) =>
                              _injectKeyword(kw, isAnswered),
                        ),
                        SizedBox(height: 30.h),

                        if (!isAnswered)
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
                                borderRadius: BorderRadius.circular(20.r),
                                color: _wordCount >= minWords
                                    ? theme.primaryColor
                                    : Colors.grey,
                                boxShadow: [
                                  if (_wordCount >= minWords)
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
